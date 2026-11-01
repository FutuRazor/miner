extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _drag(world: Node, motion: Vector2) -> void:
	world.camera_drag_held = true
	world.mouse_dragging = true
	var event := InputEventMouseMotion.new()
	event.relative = motion
	world._unhandled_input(event)
	world.camera_drag_held = false

func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	var camera: Camera2D = world.get_node("Player/Camera2D")
	var edge: float = (world.RADIUS + 0.5) * world.CELL
	for zoom in [0.3, 0.5, 1.0, 2.0, 3.0]:
		camera.zoom = Vector2.ONE * zoom
		world._update_camera_limits()
		var half_view: Vector2 = world.get_viewport_rect().size / (camera.zoom * 2.0)
		var limit := Vector2(edge if half_view.x < edge else 0.0, edge if half_view.y < edge else 0.0)
		_drag(world, Vector2(-100000, -100000))
		assert(camera.global_position.is_equal_approx(limit))
		camera.reset_smoothing()
		camera.force_update_scroll()
		assert(camera.get_screen_center_position().is_equal_approx(limit))
		_drag(world, Vector2(100000, 100000))
		assert(camera.global_position.is_equal_approx(-limit))
		camera.reset_smoothing()
		camera.force_update_scroll()
		assert(camera.get_screen_center_position().is_equal_approx(-limit))
	# Camera offsets must also be limited as the followed character moves.
	camera.zoom = Vector2.ONE
	world._update_camera_limits()
	world.get_node("Player").position = Vector2(1000, 1000)
	camera.position = Vector2(1000, 1000)
	world._clamp_camera_position()
	assert(camera.global_position == Vector2(edge, edge))
	world._set_paused(true)
	var event := InputEventMouseMotion.new()
	event.relative = Vector2(100000, 100000)
	world.camera_drag_held = true
	world.mouse_dragging = true
	world.get_node("GameUI")._unhandled_input(event)
	assert(camera.global_position == Vector2(-edge, -edge))
	world._set_paused(false)
	world.queue_free()
	print("PASS: half-screen map-edge pan limits at all zooms, centering small map axes, player follow and paused panning")
	quit()
