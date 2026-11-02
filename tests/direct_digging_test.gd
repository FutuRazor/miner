extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	var player = world.get_node("Player")
	player.set_physics_process(false)
	player.position = Vector2(0, 96)
	var block = world.Block.new()
	block.position = Vector2(0, 48)
	block.mining_duration = 0.15
	block.collected.connect(world._on_block_collected)
	world.block_cells[Vector2i(0, 1)] = block
	world.add_child(block)
	# A free route exists around this block. A short click may use it.
	var path: Array[Vector2] = world._walk_path(Vector2(0, -96))
	assert(path.any(func(point: Vector2) -> bool: return absf(point.x) >= 48))
	var camera: Camera2D = player.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	camera.force_update_scroll()
	camera.position += Vector2(0, -96) - world.get_global_mouse_position()
	camera.force_update_scroll()
	world.mouse_held = true
	world._set_mouse_goal(Vector2(0, -96))
	world._update_mouse_navigation(0.2)
	assert(not world.mouse_direct_follow)
	world._update_mouse_navigation(0.11)
	assert(world.mouse_direct_follow)
	assert(player.navigation_path.size() == 1)
	assert(player.navigation_path[0].is_equal_approx(Vector2(0, -96)))
	# Releasing keeps the direct destination rather than restoring the detour.
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	world._unhandled_input(release)
	assert(not world.mouse_held and world.mouse_direct_follow)
	world.set_physics_process(true)
	player.set_physics_process(true)
	for tick in 180:
		await physics_frame
		assert(absf(player.position.x) <= 1.0)
	assert(not is_instance_valid(block))
	assert(player.position.distance_to(Vector2(0, -96)) <= 1.0)
	print("PASS: short-click detour retained, holding digs directly through block, no lateral detour, release target preserved")
	world.queue_free()
	quit()
