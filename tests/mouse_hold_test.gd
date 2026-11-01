extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _point_at(world: Node2D, point: Vector2) -> void:
	var camera: Camera2D = world.get_node("Player/Camera2D")
	camera.position_smoothing_enabled = false
	camera.force_update_scroll()
	camera.position += point - world.get_global_mouse_position()
	camera.force_update_scroll()


func _button(world: Node, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	world._unhandled_input(event)


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	var player = world.get_node("Player")
	player.set_physics_process(false)
	_point_at(world, Vector2(80, 0))
	_button(world, true)
	assert(world.mouse_goal.is_equal_approx(Vector2(80, 0)))
	assert(not player.navigation_path.is_empty())
	_point_at(world, Vector2(0, 80))
	world._update_mouse_navigation(0.11)
	assert(world.mouse_goal.is_equal_approx(Vector2(0, 80)))
	_point_at(world, Vector2(0, 96))
	_button(world, false)
	assert(not world.mouse_held and world.mouse_goal.is_equal_approx(Vector2(0, 96)))
	_point_at(world, Vector2(-80, 0))
	world.set_physics_process(true)
	player.set_physics_process(true)
	for tick in 90:
		await physics_frame
	assert(player.position.distance_to(Vector2(0, 96)) <= 1.0)
	assert(world.mouse_goal.is_equal_approx(Vector2(0, 96)))
	# A frozen release target survives mining and stops at the first harder ring.
	player.position = Vector2.ZERO
	world.block_cells[Vector2i(3, 0)].mining_duration = 0.15
	world.block_cells[Vector2i(4, 0)].mining_duration = 0.15
	world._set_mouse_goal(Vector2(300, 0))
	for tick in 240:
		await physics_frame
	assert(not is_instance_valid(world.block_cells[Vector2i(3, 0)]))
	assert(not is_instance_valid(world.block_cells[Vector2i(4, 0)]))
	assert(is_instance_valid(world.block_cells[Vector2i(5, 0)]))
	assert(player.position.distance_to(Vector2(203, 0)) <= 1.0)
	assert(player.velocity.length() <= 0.01)
	print("PASS: held pointer tracking, release position frozen, arrival, continued walking after mining and hard-block stop")
	world.queue_free()
	quit()
