extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame in 4:
		await process_frame


func _run() -> void:
	root.get_node("SessionSave").storage_path = "res://.godot/session_tests/%d/ranking_test.dat" % OS.get_process_id()
	TranslationServer.set_locale("de")
	var stats = root.get_node("MetaStats")
	stats.persistence_enabled = false
	stats.victories = []
	assert(change_scene_to_file("res://scenes/start_menu.tscn") == OK)
	await _settle()
	current_scene.get_node("Center/Menu/RankingButton").pressed.emit()
	await _settle()
	assert(current_scene.name == "Ranking")
	assert(current_scene.summary.text.ends_with("0"))
	assert(current_scene.back_button.has_focus())
	current_scene._back()
	await _settle()
	assert(current_scene.name == "StartMenu")
	assert(change_scene_to_file("res://scenes/main.tscn") == OK)
	await _settle()
	var world = current_scene
	world.round_duration = 100.25
	world.spawned_waves = 20
	world.cleared_waves = 19
	world.wave_alive = {20: 1}
	world._on_enemy_destroyed(20)
	assert(stats.victories.size() == 1)
	world._end_game(true)
	assert(stats.victories.size() == 1)
	world.continue_endless()
	await _settle()
	world.damage_base(100)
	assert(stats.victories.size() == 1)
	stats.record_victory(60.5, 4, 5, 6)
	stats.record_victory(100.1, 7, 8, 9)
	assert(stats.victories[0].duration == 60.5)
	assert(stats.victories[1].duration == 100.1)
	assert(stats.victories[2].duration == 100.25)
	paused = false
	assert(change_scene_to_file("res://scenes/ranking.tscn") == OK)
	await _settle()
	assert(current_scene.grid.get_child(6).text == "01:00")
	var store = load("res://scripts/meta_stats.gd").new()
	store.storage_path = "res://.godot/ranking_tests/%d/stats.json" % OS.get_process_id()
	root.add_child(store)
	store.record_victory(99.5, 42, 20, 200)
	assert(store.save_error.is_empty())
	store.load_stats()
	assert(store.victories.size() == 1 and store.victories[0].duration == 99.5)
	assert(store.victories[0].enemies == 42)
	assert(not store._valid_victories([{"duration": -1}]))
	store.queue_free()
	print("PASS: ranking menu, empty state, one entry per main-stage victory, endless exclusion, exact sorting and persistence")
	quit()
