extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame in 4:
		await process_frame


func _check_push_through(world: Node2D, boss: Node2D, defender: Node2D) -> void:
	boss.position = Vector2(500, 0)
	defender.position = Vector2(480, 0)
	var crowd: Array[Node2D] = [defender]
	for index in 12:
		var drone = world.Drone.new()
		drone.world = world
		drone.passive = true
		drone.collector_index = -1
		world.add_child(drone)
		drone.set_physics_process(false)
		drone.position = boss.position + Vector2.from_angle(index * TAU / 12.0) * 19.0
		crowd.append(drone)
	for frame in 60:
		for drone in crowd:
			drone.combat_ai.set_target(boss)
			drone._physics_process(1.0 / 60.0)
		boss._physics_process(1.0 / 60.0)
		var before: Vector2 = boss.position
		world.drone_collisions.resolve()
		assert(boss.position.is_equal_approx(before))
		assert(boss.combat_target == null)
	assert(is_equal_approx(boss.position.x, 500.0 - boss.speed))
	assert(is_zero_approx(boss.position.y))
	for index in range(1, crowd.size()):
		crowd[index].dead = true
		crowd[index].queue_free()
	defender.position = Vector2.ZERO


func _run() -> void:
	root.get_node("SessionSave").storage_path = "res://.godot/session_tests/%d/boss_wave_test.dat" % OS.get_process_id()
	root.get_node("MetaStats").persistence_enabled = false
	assert(change_scene_to_file("res://scenes/main.tscn") == OK)
	await _settle()
	var world = current_scene
	world.set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	world.spawned_waves = 9
	world.cleared_waves = 9
	world.spawn_enemy_wave()
	var enemies: Array[Node2D] = world._live_combat_drones("enemy_drones")
	assert(enemies.size() == 1)
	var mid = enemies[0]
	mid.set_physics_process(false)
	assert(mid.name == "MidBoss" and mid.health == 100 and mid.speed == 50.0)
	var defender = world.Drone.new()
	defender.world = world
	defender.passive = true
	defender.collector_index = -1
	world.add_child(defender)
	defender.set_physics_process(false)
	mid.position = Vector2(300, 0)
	defender.position = Vector2(280, 0)
	mid.take_damage(1, defender)
	assert(mid.combat_target == null)
	defender.combat_ai.set_target(mid)
	defender.combat_ai.tick(0.1)
	assert(mid.combat_target == null)
	mid._physics_process(1.0)
	assert(mid.position.is_equal_approx(Vector2(250, 0)))
	assert(defender.health == 30)
	_check_push_through(world, mid, defender)
	mid.take_damage(1000)
	assert(world.cleared_waves == 10 and world.wave_alive[10] == 0)
	await _settle()
	world.spawned_waves = 19
	world.cleared_waves = 19
	world.spawn_enemy_wave()
	enemies = world._live_combat_drones("enemy_drones")
	assert(enemies.size() == 1)
	var boss = enemies[0]
	boss.set_physics_process(false)
	assert(boss.name == "FinalBoss" and boss.health == 350)
	boss.take_damage(1, defender)
	assert(boss.combat_target == null)
	_check_push_through(world, boss, defender)
	assert(boss.swarmer_timer.wait_time == 5.0 and not boss.swarmer_timer.one_shot)
	boss.position = Vector2(500, 200)
	boss.swarmer_timer.timeout.emit()
	assert(boss.swarmers.size() == 3 and world.wave_alive[20] == 1)
	for swarmer in boss.swarmers:
		swarmer.set_physics_process(false)
		assert(swarmer.position == boss.position and swarmer.health == 7 and swarmer.speed == 100.0)
	boss.swarmers[0].take_damage(100)
	assert(world.wave_alive[20] == 1 and not world.is_game_over)
	paused = true
	boss._spawn_swarmers()
	assert(boss.swarmers.size() == 3)
	paused = false
	await _settle()
	boss.position = Vector2(600, 200)
	boss.swarmer_timer.timeout.emit()
	assert(boss.swarmers.size() == 5)
	boss.take_damage(1000)
	assert(world.wave_alive[20] == 0 and world.cleared_waves == 20)
	assert(world.is_game_over and paused and boss.swarmer_timer.is_stopped())
	assert(world._live_combat_drones("enemy_drones").is_empty())
	world.game_over_screen.get_node("Screen/Center/Menu/Endless").pressed.emit()
	await _settle()
	world.spawn_enemy_wave()
	assert(world.spawned_waves == 21)
	assert(world._live_combat_drones("enemy_drones").size() == 46)
	print("PASS: boss-only waves, wave-scaled health, midboss direct movement and no retaliation, timed swarmers, boss signal completion and endless continuation")
	quit()
