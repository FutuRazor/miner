extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame in 4:
		await process_frame


func _run() -> void:
	root.get_node("SessionSave").storage_path = "res://.godot/session_tests/%d/game_over_test.dat" % OS.get_process_id()
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	assert(change_scene_to_file("res://scenes/main.tscn") == OK)
	await _settle()
	var world = current_scene
	world.round_duration = 125.0
	world.spawned_waves = 7
	world.enemies_neutralized = 42
	world.sectors_mined = 18
	world.receive_income(123)
	world.money = 77
	world.mining_level = 3
	world._set_build_mode(world.BuildMode.MENU)
	world.damage_base(99)
	assert(world.base_health == 1 and not paused and not world.is_game_over)
	world.damage_base(1)
	assert(paused and world.is_game_over and world.base_health == 0)
	assert(not world.build_panel.visible and not world.build_preview.visible)
	var overlay: CanvasLayer = world.game_over_screen
	assert(overlay.layer == 100 and overlay.process_mode == Node.PROCESS_MODE_ALWAYS)
	assert(overlay.get_node("Screen/Center/Menu/Retry").has_focus())
	assert(not overlay.has_node("Screen/Center/Menu/Endless"))
	assert("7" in overlay.get_node("Screen/Center/Menu/Subtitle").text)
	var stats: String = overlay.get_node("Screen/Center/Menu/Stats").text
	assert("02:05" in stats and "42" in stats and "18" in stats and "$123" in stats)
	world.damage_base(20)
	assert(world.game_over_screen == overlay)
	var event := InputEventKey.new()
	event.keycode = KEY_B
	event.pressed = true
	world._input(event)
	assert(not world.build_panel.visible)
	overlay.get_node("Screen/Center/Menu/Retry").pressed.emit()
	await _settle()
	world = current_scene
	assert(world.name == "Miner" and not paused)
	assert(world.base_health == 100 and world.money == 40 and world.mining_level == 1)
	assert(world.buildings.is_empty() and not world.is_game_over)
	world.damage_base(100)
	world.game_over_screen.get_node("Screen/Center/Menu/MainMenu").pressed.emit()
	await _settle()
	assert(current_scene.name == "StartMenu" and not paused)
	assert(current_scene.get_node("Center/Menu/StartButton").has_focus())
	print("PASS: zero health game over, frozen simulation, modal input, retry resets session and main menu unpauses")
	quit()
