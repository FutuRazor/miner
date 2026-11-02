extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _wheel(receiver: Node, button: MouseButton, point: Vector2, pressed: bool = true) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = point
	receiver._unhandled_input(event)

func _run() -> void:
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	var player = world.get_node("Player")
	player.set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.force_update_scroll()
	var point := Vector2(220, 180)
	var original: Vector2 = world.get_canvas_transform().affine_inverse() * point
	player.navigation_path.assign([Vector2(30, 40)])
	_wheel(world, MOUSE_BUTTON_WHEEL_UP, point)
	assert(is_equal_approx(camera.zoom.x, 1.1))
	assert((world.get_canvas_transform().affine_inverse() * point).is_equal_approx(original))
	assert(player.navigation_path == [Vector2(30, 40)])
	_wheel(world, MOUSE_BUTTON_WHEEL_UP, point, false)
	assert(is_equal_approx(camera.zoom.x, 1.1))
	_wheel(world, MOUSE_BUTTON_WHEEL_DOWN, point)
	assert(is_equal_approx(camera.zoom.x, 1.0))
	for step in 60:
		_wheel(world, MOUSE_BUTTON_WHEEL_DOWN, point)
	assert(is_equal_approx(camera.zoom.x, world.MIN_ZOOM))
	for step in 60:
		_wheel(world, MOUSE_BUTTON_WHEEL_UP, point)
	assert(is_equal_approx(camera.zoom.x, world.MAX_ZOOM))
	# Panning must remain proportional to the zoom level.
	world.camera_drag_held = true
	world.mouse_dragging = true
	var before: Vector2 = camera.position
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(30, 15)
	world._unhandled_input(motion)
	assert(camera.position.is_equal_approx(before - motion.relative / camera.zoom))
	world.camera_drag_held = false
	# Paused gameplay still allows camera zoom through the always-active UI.
	world._set_paused(true)
	_wheel(world.get_node("GameUI"), MOUSE_BUTTON_WHEEL_DOWN, point)
	assert(camera.zoom.x < world.MAX_ZOOM and paused)
	var zoom_before := camera.zoom
	world.return_dialog_open = true
	_wheel(world.get_node("GameUI"), MOUSE_BUTTON_WHEEL_DOWN, point)
	assert(camera.zoom == zoom_before)
	world.return_dialog_open = false
	world._set_paused(false)
	world._set_build_mode(world.BuildMode.PLACE)
	world.mouse_placement = true
	_wheel(world, MOUSE_BUTTON_WHEEL_DOWN, point)
	assert(world.build_mode == world.BuildMode.PLACE and world.build_preview.visible)
	world.is_game_over = true
	zoom_before = camera.zoom
	_wheel(world, MOUSE_BUTTON_WHEEL_DOWN, point)
	assert(camera.zoom == zoom_before)
	world.queue_free()
	print("PASS: mouse wheel zoom, cursor anchor, limits, navigation preservation, scaled pan, pause and placement")
	quit()
