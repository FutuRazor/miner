extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _key(ui: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	ui._input(event)


func _settle() -> void:
	for frame in 6:
		await process_frame


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await _settle()
	var ui: CanvasLayer = world.get_node("GameUI")
	world.pause_button.pressed.emit()
	assert(paused and ui.can_process())
	var info: Button = ui.get_node("InfoButton")
	assert(info.can_process())
	info.button_pressed = true
	assert(ui.get_node("MinerInfo").visible)
	info.button_pressed = false
	assert(not ui.get_node("MinerInfo").visible)
	_key(ui, KEY_B)
	assert(world.build_mode == world.BuildMode.MENU and world.build_panel.can_process())
	_key(ui, KEY_J)
	assert(world.build_mode == world.BuildMode.SKILLS and paused)
	world.build_options.rows[2].button.pressed.emit()
	assert(world.money == 0 and world.build_mode == world.BuildMode.SKILLS)
	var cash: Node2D = world.base_drone_settings.main_drone
	assert(not cash.can_process())
	var before: Vector2 = cash.position
	var camera: Camera2D = world.get_node("Player/Camera2D")
	var camera_before := camera.position
	var button := InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_RIGHT
	button.pressed = true
	ui._unhandled_input(button)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(40, 20)
	ui._unhandled_input(motion)
	button.pressed = false
	ui._input(button)
	assert(camera.position == camera_before - Vector2(40, 20))
	assert(world.build_mode == world.BuildMode.SKILLS)
	await _settle()
	assert(cash.position == before and paused)
	assert(not world.wave_pause_button.disabled and world.wave_pause_button.can_process())
	world.spawn_enemy_wave()
	assert(world._live_combat_drones("enemy_drones").is_empty())
	world.play_button.pressed.emit()
	assert(not paused and cash.can_process() and not world.wave_pause_button.disabled)
	print("PASS: paused UI input, camera pan, info toggle, menu switching, skill purchase, frozen drones and wave-button lock")
	world.queue_free()
	quit()
