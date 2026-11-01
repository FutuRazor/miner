extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _click(world: Node, button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	world._unhandled_input(event)


func _point_at(world: Node2D, point: Vector2) -> void:
	var camera: Camera2D = world.get_node("Player/Camera2D")
	camera.position_smoothing_enabled = false
	camera.force_update_scroll()
	camera.position += point - world.get_global_mouse_position()
	camera.force_update_scroll()


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	var player = world.get_node("Player")
	player.set_physics_process(false)
	world.money = 30
	world._set_build_mode(world.BuildMode.MENU)
	world._on_option_clicked(1)
	assert(world.mouse_placement and world.build_mode == world.BuildMode.PLACE)
	_point_at(world, Vector2.ZERO)
	assert(world._build_anchor() == Vector2i.ZERO)
	_click(world, MOUSE_BUTTON_LEFT, true)
	_click(world, MOUSE_BUTTON_LEFT, false)
	assert(world.buildings.is_empty() and world.money == 30)
	assert(world.build_mode == world.BuildMode.PLACE and player.navigation_path.is_empty())
	for cell in [Vector2i(3, 0), Vector2i(3, 1)]:
		world.block_cells[cell].queue_free()
	_point_at(world, Vector2(96, 0))
	assert(world._build_anchor() == Vector2i(2, 0))
	assert(player.position == Vector2.ZERO)
	_click(world, MOUSE_BUTTON_LEFT, true)
	_click(world, MOUSE_BUTTON_LEFT, false)
	assert(world.buildings.size() == 1 and world.buildings[0].anchor == Vector2i(2, 0))
	assert(world.money == 20 and world.build_mode == world.BuildMode.PLAY)
	assert(player.navigation_path.is_empty() and not world.mouse_placement)
	world._set_build_mode(world.BuildMode.MENU)
	world._on_option_clicked(0)
	var camera: Camera2D = player.get_node("Camera2D")
	var camera_before := camera.position
	_click(world, MOUSE_BUTTON_RIGHT, true)
	assert(world.build_mode == world.BuildMode.PLACE)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(40, 20)
	world._unhandled_input(motion)
	_click(world, MOUSE_BUTTON_RIGHT, false)
	assert(camera.position == camera_before - Vector2(40, 20))
	assert(world.build_mode == world.BuildMode.PLACE and world.mouse_placement)
	assert(world.money == 20 and player.navigation_path.is_empty())
	_click(world, MOUSE_BUTTON_RIGHT, true)
	assert(world.build_mode == world.BuildMode.PLACE)
	_click(world, MOUSE_BUTTON_RIGHT, false)
	assert(world.build_mode == world.BuildMode.PLAY and world.money == 20)
	assert(world.buildings.size() == 1)
	# Keyboard selection still anchors the footprint to the player.
	world._set_build_mode(world.BuildMode.MENU)
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_E
	world._input(event)
	assert(not world.mouse_placement and world._build_anchor() == Vector2i.ZERO)
	print("PASS: mouse-anchored preview, invalid click, paid mouse placement, no walk-through, right-click cancel and keyboard placement")
	world.queue_free()
	quit()
