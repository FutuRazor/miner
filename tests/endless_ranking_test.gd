extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame in 4:
		await process_frame


func _world():
	assert(change_scene_to_file("res://scenes/main.tscn") == OK)
	await _settle()
	current_scene.set_physics_process(false)
	current_scene.wave_timer.set_physics_process(false)
	return current_scene


func _run() -> void:
	TranslationServer.set_locale("de")
	var stats = root.get_node("MetaStats")
	stats.persistence_enabled = false
	stats.endless_games = []
	var world = await _world()
	world.endless_freeplay = true
	world.cleared_waves = 20
	world.record_endless_result()
	assert(stats.endless_games.is_empty())
	world.cleared_waves = 21
	world.round_duration = 100.5
	world.enemies_neutralized = 42
	world.sectors_mined = 18
	world.total_revenue = 123
	var ui = world.get_node("GameUI")
	ui.open_return_dialog()
	ui.cancel_return()
	assert(stats.endless_games.is_empty())
	ui.open_return_dialog()
	ui.confirm_return()
	await _settle()
	assert(current_scene.name == "StartMenu" and not paused)
	assert(stats.endless_games.size() == 1)
	assert(stats.endless_games[0].wave == 21 and stats.endless_games[0].duration == 100.5)
	assert(stats.endless_games[0].revenue == 123 and stats.endless_games[0].enemies == 42)
	world = await _world()
	world.endless_freeplay = true
	world.cleared_waves = 25
	world.spawned_waves = 26
	world.round_duration = 200.0
	world.damage_base(100)
	assert(stats.endless_games.size() == 1)
	world.game_over_screen.get_node("Screen/Center/Menu/MainMenu").pressed.emit()
	await _settle()
	assert(stats.endless_games.size() == 2 and stats.endless_games[0].wave == 25)
	world = await _world()
	world.endless_freeplay = true
	world.cleared_waves = 30
	world.damage_base(100)
	world.game_over_screen.get_node("Screen/Center/Menu/Retry").pressed.emit()
	await _settle()
	assert(stats.endless_games.size() == 2)
	world = current_scene
	world.endless_freeplay = true
	world.cleared_waves = 25
	world.round_duration = 150.0
	world.record_endless_result()
	world.record_endless_result()
	assert(stats.endless_games.size() == 3)
	assert(stats.endless_games[0].duration == 150.0 and stats.endless_games[1].duration == 200.0)
	assert(change_scene_to_file("res://scenes/ranking.tscn") == OK)
	await _settle()
	assert(current_scene.grid.columns == 5)
	current_scene.endless_button.button_pressed = true
	current_scene.endless_button.pressed.emit()
	assert(current_scene.endless_button.button_pressed and not current_scene.mission_button.button_pressed)
	assert(current_scene.grid.columns == 6)
	assert(current_scene.grid.get_child(7).text == "25")
	await _settle()
	assert(current_scene.grid.size.x <= current_scene.grid.get_parent().size.x + 1.0)
	var store = load("res://scripts/meta_stats.gd").new()
	store.storage_path = "res://.godot/endless_ranking_tests/%d/stats.json" % OS.get_process_id()
	root.add_child(store)
	store.record_victory(99.0, 1, 2, 3)
	store.record_endless_game(20, 100.0, 1, 2, 3)
	assert(store.endless_games.is_empty())
	store.record_endless_game(21, 100.0, 4, 5, 6)
	store.load_stats()
	assert(store.endless_games.size() == 1 and store.endless_games[0].wave == 21)
	assert(store.victories.size() == 1)
	assert(not store._valid_endless_games([{"wave": 20, "duration": 1, "enemies": 1, "blocks": 1, "revenue": 1}]))
	store.queue_free()
	print("PASS: endless threshold, exit cancellation, menu/defeat snapshots, retry exclusion, deduplication, sorting, categories and persistence")
	quit()
