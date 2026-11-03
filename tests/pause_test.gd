extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("SessionSave").storage_path = "res://.godot/session_tests/%d/pause_test.dat" % OS.get_process_id()
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	var player = world.get_node("Player")
	player.position = Vector2(103, 0)
	player._physics_process(0.1)
	var block: Node = world.block_cells[Vector2i(3, 0)]
	assert(block.progress > 0.0)
	player.navigation_path.assign([Vector2(0, 80)])
	world.spawn_enemy_wave()
	var enemies: Array[Node2D] = world._live_combat_drones("enemy_drones")
	for drone in enemies:
		drone.set_physics_process(false)
	var enemy := enemies[0]
	enemy.position = Vector2(82, 0)
	enemy._physics_process(0.4)
	enemy.set_physics_process(true)
	var player_before: Vector2 = player.position
	var block_before: float = block.progress
	var clock_before: float = enemy.combat_ai.contact_time
	assert(world.play_button.disabled and not world.pause_button.disabled)
	world.pause_button.pressed.emit()
	assert(paused and not world.play_button.disabled and world.pause_button.disabled)
	assert(world.play_button.can_process())
	for frame in 30:
		await process_frame
	assert(player.position == player_before)
	assert(block.progress == block_before)
	assert(enemy.combat_ai.contact_time == clock_before)
	assert(world.base_health == 100)
	world.play_button.pressed.emit()
	assert(not paused and world.play_button.disabled and not world.pause_button.disabled)
	for tick in 30:
		await physics_frame
	assert(player.position.distance_to(player_before) > 1)
	assert(world.base_health == 100)
	for tick in 15:
		await physics_frame
	assert(world.base_health == 99)
	world.damage_base(100)
	assert(paused and world.play_button.disabled and world.pause_button.disabled)
	world._set_paused(false)
	assert(paused and world.is_game_over)
	print("PASS: pause freezes movement/mining/attack clocks, toolbar remains usable, resume continues timers and cannot bypass game over")
	world.queue_free()
	quit()
