extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _build(world: Node, kind: int, anchor: Vector2i) -> void:
	for y in 2:
		for x in 2:
			var cell := anchor + Vector2i(x, y)
			if world.block_cells.has(cell) and is_instance_valid(world.block_cells[cell]):
				world.block_cells[cell].queue_free()
	world.get_node("Player").position = Vector2(anchor) * 48
	world.selected_building = kind
	world._place_building()

func _buy(world: Node, index: int) -> void:
	world.selected_skill = index
	world._confirm_skill()

func _run() -> void:
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	assert(world.money == 40 and world.barracks_drone_count == 2)
	assert(world.block_cells.size() == 2000)
	assert(world.block_cells[Vector2i(3, 0)].mining_duration == 1.0)
	world.money = 10000
	_buy(world, 3)
	assert(world.collector_drone_count == 1 and world.money == 10000)
	_build(world, 0, Vector2i(2, 0))
	assert(world.money == 9970 and not world.buildings[0].has("main_drone"))
	assert(world._building_cost(0) == 50)
	world._tick_production(7.9)
	assert(not world.buildings[0].has("main_drone"))
	world._tick_production(0.1)
	assert(world.buildings[0].has("main_drone"))
	_build(world, 0, Vector2i(-2, 2))
	world._tick_production(8.0)
	_build(world, 0, Vector2i(0, -4))
	assert(world.buildings.size() == 2)
	_buy(world, 3)
	assert(world.collector_drone_count == 1)
	# Clearing later waves first must not unlock an earlier milestone.
	world.wave_alive = {1: 1, 2: 0, 3: 0, 4: 1}
	world._on_enemy_destroyed(4)
	assert(world.cleared_waves == 0)
	world._on_enemy_destroyed(1)
	assert(world.cleared_waves == 4 and world._building_limit(0) == 3)
	var before: int = world.money
	_buy(world, 3)
	assert(world.money == before - 80 and world.collector_drone_count == 2)
	assert(world._live_combat_drones("friendly_drones").size() == 2)
	world._tick_production(8.0)
	assert(world._live_combat_drones("friendly_drones").size() == 4)
	_buy(world, 3)
	assert(world.collector_drone_count == 2)
	_build(world, 1, Vector2i(0, -4))
	world._tick_production(10.0)
	var defenders: Array[Node2D] = world._live_combat_drones("barracks_drones")
	assert(defenders.size() == 2)
	for defender in defenders:
		defender.take_damage(100)
	assert(world.buildings[2].pending_drones == 2)
	world._tick_production(19.0)
	assert(world._live_combat_drones("barracks_drones").is_empty())
	world._tick_production(1.0)
	assert(world._live_combat_drones("barracks_drones").size() == 1)
	world._tick_production(20.0)
	assert(world._live_combat_drones("barracks_drones").size() == 2)
	world.cleared_waves = 14
	_build(world, 2, Vector2i(2, 2))
	world._tick_production(6.0)
	var tower: Node2D = world.buildings[3].tower
	for milestone in 3:
		var defense_wave: int = [3, 8, 13][milestone]
		world.cleared_waves = defense_wave - 1
		assert(world._building_limit(1) == [1, 2, 3][milestone])
		assert(world._building_limit(2) == [2, 4, 6][milestone])
		world.skill_levels.base_health = milestone + 2
		world.skill_levels.collector_speed = milestone + 2
		assert(world._skill_block_reason("base_health") == "Freischaltung nach Welle %d" % defense_wave)
		world.cleared_waves = defense_wave
		assert(world._building_limit(1) == [2, 3, 4][milestone])
		assert(world._building_limit(2) == [4, 6, 8][milestone])
		assert(world._skill_block_reason("base_health").is_empty())
		assert(world._building_limit(0) == [2, 3, 4][milestone])
		assert(world._skill_block_reason("collector_speed") == "Freischaltung nach Welle %d" % (defense_wave + 1))
		world.cleared_waves += 1
		assert(world._building_limit(0) == [3, 4, 5][milestone])
		assert(world._skill_block_reason("collector_speed").is_empty())
	world.skill_levels.erase("base_health")
	world.skill_levels.erase("collector_speed")
	_buy(world, 10)
	_buy(world, 10)
	_buy(world, 10)
	assert(tower.shots == 3)
	for purchase in 6:
		_buy(world, 11)
	assert(tower.fire_interval_ms == 590)
	for purchase in 10:
		_buy(world, 1)
	assert(world.mining_level == 10)
	# The prototype's timer-only pause remains available.
	world.wave_alive.clear()
	world.cleared_waves = 0
	world.wave_timer.set_timer_paused(true)
	world.wave_timer._physics_process(200.0)
	assert(world.spawned_waves == 0)
	world.wave_timer.set_timer_paused(false)
	world.wave_timer._physics_process(100.0)
	assert(world.spawned_waves == 1 and world.wave_timer.remaining == 80.0)
	assert(world._live_combat_drones("enemy_drones").size() == 6)
	world.spawned_waves = 19
	world.spawn_enemy_wave()
	assert(world.wave_alive[20] == 1)
	var enemies: Array[Node2D] = world._live_combat_drones("enemy_drones")
	assert(enemies[-1].name == "FinalBoss" and enemies[-1].max_health == 350)
	world.queue_free()
	print("PASS: balance prices, construction, caps, clear-based unlocks, upgrade queues, sequential replacement, upgrade maxima and wave scaling")
	quit()
