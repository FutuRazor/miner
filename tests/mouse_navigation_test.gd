extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _button(world: Node, down: bool, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = down
	world._unhandled_input(event)


func _run() -> void:
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	var player = world.get_node("Player")
	player.set_physics_process(false)
	var open_target := Vector2(24, 31)
	var path: Array[Vector2] = world._walk_path(open_target)
	assert(path[-1].is_equal_approx(open_target))
	var blocked_path: Array[Vector2] = world._walk_path(Vector2(500, 0))
	assert(blocked_path[-1].is_equal_approx(Vector2(107, 0)))
	# A free but disconnected pocket is not reachable through the intervening wall.
	world.block_cells[Vector2i(6, 0)].queue_free()
	path = world._walk_path(Vector2(288, 0))
	assert(path[-1].x == 107)
	# A reachable detour must route around the obstacle rather than through it.
	world.block_cells[Vector2i(1, 0)] = world.Block.new()
	world.block_cells[Vector2i(1, 0)].position = Vector2(48, 0)
	world.add_child(world.block_cells[Vector2i(1, 0)])
	path = world._walk_path(Vector2(96, 0))
	assert(path[-1] == Vector2(96, 0))
	assert(path.any(func(point: Vector2) -> bool: return absf(point.y) >= 48))
	assert(not path.has(Vector2(48, 0)))
	# A click creates a route; dragging pans without replacing that route.
	_button(world, true)
	_button(world, false)
	assert(not player.navigation_path.is_empty())
	var before: Array[Vector2] = player.navigation_path.duplicate()
	var camera: Camera2D = player.get_node("Camera2D")
	_button(world, true, MOUSE_BUTTON_RIGHT)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(40, 20)
	world._unhandled_input(motion)
	_button(world, false, MOUSE_BUTTON_RIGHT)
	assert(camera.position == Vector2(-40, -20))
	assert(player.navigation_path == before)
	_button(world, true)
	world._unhandled_input(motion)
	_button(world, false)
	assert(camera.position == Vector2(-40, -20))
	# Keyboard steering cancels automatic navigation.
	Input.action_press("ui_left")
	player._physics_process(1.0 / 60.0)
	Input.action_release("ui_left")
	assert(player.navigation_path.is_empty())
	player.position = Vector2.ZERO
	player.navigation_path = world._walk_path(Vector2(0, 80))
	player.set_physics_process(true)
	for tick in 90:
		await physics_frame
	assert(player.position.distance_to(Vector2(0, 80)) <= 1.0)
	assert(player.navigation_path.is_empty())
	world._set_build_mode(world.BuildMode.MENU)
	_button(world, true)
	_button(world, false)
	assert(not player.navigation_path.is_empty() and not world.mouse_held)
	assert(world.build_mode == world.BuildMode.MENU and player.movement_enabled)
	assert(world.build_panel.visible and not player.keyboard_movement_enabled)
	world._set_build_mode(world.BuildMode.PLAY)
	player.position = Vector2.ZERO
	world._set_build_mode(world.BuildMode.SKILLS)
	assert(world.build_mode == world.BuildMode.SKILLS)
	_button(world, true)
	_button(world, false)
	assert(world.build_mode == world.BuildMode.SKILLS and player.movement_enabled)
	assert(world.build_panel.visible and not player.keyboard_movement_enabled)
	assert(not player.navigation_path.is_empty())
	for mode in [world.BuildMode.MENU, world.BuildMode.SKILLS]:
		world._set_build_mode(mode)
		_button(world, true, MOUSE_BUTTON_RIGHT)
		world._unhandled_input(motion)
		_button(world, false, MOUSE_BUTTON_RIGHT)
		assert(world.build_mode == mode and world.build_panel.visible)
		_button(world, true, MOUSE_BUTTON_RIGHT)
		_button(world, false, MOUSE_BUTTON_RIGHT)
		assert(world.build_mode == world.BuildMode.PLAY and not world.build_panel.visible)
		assert(world.build_panel.get_parent().get_node("ActionMenu").visible)
	print("PASS: precise click target, unreachable boundary, disconnected area, detour, camera drag, keyboard override and arrival")
	world.queue_free()
	quit()
