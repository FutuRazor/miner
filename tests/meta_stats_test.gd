extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _store(path: String) -> Node:
	var store = load("res://scripts/meta_stats.gd").new()
	store.storage_path = path
	root.add_child(store)
	store.set_process(false)
	return store


func _run() -> void:
	var meta := root.get_node("MetaStats")
	meta.persistence_enabled = false
	meta.collected_by_hardness.clear()
	meta.destroyed_by_hardness.clear()
	meta.enemy_drones_defeated = 0
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	var block: Node = world.block_cells[Vector2i(3, 0)]
	for step in 4:
		assert(block.mine(0.85, step % 2 == 0))
		assert(meta.collected_by_hardness["1"] == step + 1)
		assert(int(meta.destroyed_by_hardness.get("1", 0)) == (1 if step == 3 else 0))
	assert(not block.mine(10.0))
	var hard: Node = world.block_cells[Vector2i(5, 0)]
	assert(not hard.mine(1.0))
	assert(hard.mine(0.85, false, null, 2))
	assert(meta.collected_by_hardness["2"] == 1)
	var enemy = world.Drone.new()
	enemy.world = world
	enemy.hostile = true
	enemy.max_health = 3
	enemy.collector_index = -2
	world.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.take_damage(3)
	enemy.take_damage(3)
	assert(meta.enemy_drones_defeated == 1)
	var friendly = world.Drone.new()
	friendly.world = world
	friendly.passive = true
	world.add_child(friendly)
	friendly.set_physics_process(false)
	friendly.take_damage(30)
	assert(meta.enemy_drones_defeated == 1)
	world.queue_free()
	await process_frame
	assert(meta.total_collected() == 5 and meta.total_destroyed() == 1)
	assert(meta.enemy_drones_defeated == 1)
	# Persistence is exercised with isolated workspace files, never the user's save.
	var path := "res://.godot/meta_stats_tests/%d/stats.json" % OS.get_process_id()
	var store := _store(path)
	assert(store.total_collected() == 0)
	store.record_block_step(1, false)
	assert(store.save_now())
	for step in 3:
		store.record_block_step(2, step == 2)
	store.record_enemy_defeated()
	assert(store.save_now())
	var loaded := _store(path)
	assert(loaded.total_collected() == 4 and loaded.total_destroyed() == 1)
	assert(loaded.collected_by_hardness["2"] == 3 and loaded.enemy_drones_defeated == 1)
	assert(FileAccess.file_exists(path + ".bak"))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("invalid save")
	file.close()
	var recovered := _store(path)
	assert(recovered.total_collected() == 1 and recovered.enemy_drones_defeated == 0)
	assert(not recovered.load_warning.is_empty())
	recovered.record_block_step(3, false)
	assert(recovered.save_now())
	var final_store := _store(path)
	assert(final_store.total_collected() == 2 and final_store.collected_by_hardness["3"] == 1)
	assert(final_store.load_warning.is_empty())
	var directory := DirAccess.open(ProjectSettings.globalize_path(path).get_base_dir())
	assert(Array(directory.get_files()).any(func(name: String) -> bool: return name.begins_with("stats.json.corrupt-")))
	var autosave := _store(path + ".autosave")
	autosave.record_enemy_defeated()
	autosave.save_delay = 0.0
	autosave.set_process(true)
	paused = true
	for frame in 3:
		await process_frame
	paused = false
	var auto_loaded := _store(path + ".autosave")
	assert(auto_loaded.enemy_drones_defeated == 1)
	var on_exit := _store(path + ".exit")
	on_exit.record_block_step(4, false)
	on_exit.queue_free()
	await process_frame
	var exit_loaded := _store(path + ".exit")
	assert(exit_loaded.collected_by_hardness["4"] == 1)
	# The screen is reached from the start menu and exposes all aggregate values.
	assert(change_scene_to_file("res://scenes/start_menu.tscn") == OK)
	for frame in 3:
		await process_frame
	current_scene.get_node("Center/Menu/StatsButton").pressed.emit()
	for frame in 4:
		await process_frame
	assert(current_scene.name == "MetaStatistics")
	assert(current_scene.summary.text.contains("Gesammelte Blockeinheiten: 5"))
	assert(current_scene.summary.text.contains("Besiegte Gegnerdrohnen: 1"))
	assert(current_scene.grid.get_child_count() == 33)
	current_scene.back_button.pressed.emit()
	for frame in 4:
		await process_frame
	assert(current_scene.name == "StartMenu")
	assert(meta.total_collected() == 5 and meta.enemy_drones_defeated == 1)
	current_scene.get_node("Center/Menu/StartButton").pressed.emit()
	for frame in 4:
		await process_frame
	assert(current_scene.money == 10 and meta.total_collected() == 5)
	current_scene.damage_base(100)
	current_scene.game_over_screen._retry()
	for frame in 4:
		await process_frame
	assert(not paused and current_scene.money == 10 and meta.total_collected() == 5)
	assert(meta.enemy_drones_defeated == 1)
	for instance in [store, loaded, recovered, final_store, autosave, auto_loaded, exit_loaded]:
		instance.queue_free()
	print("PASS: per-hardness step/full-block stats, player/drone credit, enemy-only kills, scene persistence, disk reload, backup recovery and start-menu statistics UI")
	quit()
