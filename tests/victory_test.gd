extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame in 4:
		await process_frame


func _run() -> void:
	TranslationServer.set_locale("en")
	root.get_node("MetaStats").persistence_enabled = false
	assert(change_scene_to_file("res://scenes/main.tscn") == OK)
	await _settle()
	var world = current_scene
	world.spawned_waves = 20
	world.cleared_waves = 18
	world.wave_alive = {19: 1, 20: 1}
	world.round_duration = 125.0
	world.receive_income(123)
	var block = world.block_cells[Vector2i(3, 0)]
	for step in block.mining_steps:
		assert(block.mine(100.0))
	assert(world.sectors_mined == 1)
	world.spawn_enemy_wave()
	assert(world.spawned_waves == 20)
	world._on_enemy_destroyed(20)
	assert(not world.is_game_over)
	world._on_enemy_destroyed(19)
	assert(world.is_game_over and paused)
	var overlay = world.game_over_screen
	assert(overlay.get_node("Screen/Center/Menu/MainMenu").has_focus())
	var stats: String = overlay.get_node("Screen/Center/Menu/Stats").text
	assert("02:05" in stats and "$123" in stats)
	assert(world.enemies_neutralized == 2)
	overlay.get_node("Screen/Center/Menu/Endless").pressed.emit()
	await _settle()
	assert(not paused and not world.is_game_over and world.endless_freeplay)
	assert(world.money == 163 and world.sectors_mined == 1)
	assert(world.get_node("Player").movement_enabled)
	world.spawn_enemy_wave()
	assert(world.spawned_waves == 21)
	world.wave_alive[21] = 1
	world._on_enemy_destroyed(21)
	assert(not world.is_game_over)
	world.damage_base(100)
	world.game_over_screen.get_node("Screen/Center/Menu/Retry").pressed.emit()
	await _settle()
	world = current_scene
	assert(not paused and not world.endless_freeplay and world.total_revenue == 0)
	world._end_game(true)
	world.game_over_screen.get_node("Screen/Center/Menu/MainMenu").pressed.emit()
	await _settle()
	assert(current_scene.name == "StartMenu" and not paused)
	print("PASS: mission victory, session stats, endless continuation, retry and main menu")
	quit()
