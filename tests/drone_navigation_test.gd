extends "res://tests/workshop_test.gd"

func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	world.money = 10000
	world.collector_drone_count = 4
	world.mining_level = 10
	_build(world, 0, Vector2i(2, 0))
	world._tick_production(8.0)
	var miners: Array[Node2D] = world._live_combat_drones("friendly_drones")
	var worked: Dictionary = {}
	for miner in miners:
		miner.set_physics_process(false)
	for frame in 1800:
		for miner in miners:
			miner._physics_process(1.0 / 60.0)
			if miner.carried > 0:
				worked[miner.get_instance_id()] = true
		world.drone_collisions.resolve()
	assert(worked.size() == 4, "All four miners must escape the spawn cluster and mine")
	assert(world.buildings[0].money >= 20, "Crowded miners must complete delivery cycles")
	# Different collectors sharing a congested crossing must also make progress.
	world.cleared_waves = 14
	_build(world, 0, Vector2i(-2, 2))
	world._tick_production(8.0)
	miners = world._live_combat_drones("friendly_drones")
	worked.clear()
	var first_money: int = world.buildings[0].money
	for miner in miners:
		miner.set_physics_process(false)
		if is_instance_valid(miner.target):
			miner.target.release_drone(miner)
		miner.target = null
		miner.position = Vector2.ZERO
		miner.path.clear()
		miner.carried = 0
		miner.returning = false
		miner.retry_time = 0.0
	var assigned_blocks: Dictionary = {}
	for miner in miners:
		miner._plan(false)
		assert(is_instance_valid(miner.target))
		assert(not assigned_blocks.has(miner.target.get_instance_id()))
		assigned_blocks[miner.target.get_instance_id()] = true
		assert(miner.target.mining_drone == miner)
	for frame in 2400:
		for miner in miners:
			miner._physics_process(1.0 / 60.0)
			if miner.carried > 0:
				worked[miner.get_instance_id()] = true
		world.drone_collisions.resolve()
	assert(worked.size() == 8, "Mixed collector cluster must not starve any worker")
	assert(world.buildings[0].money > first_money and world.buildings[1].money > 0)
	# Remove the miners before isolating the blocked repair approach.
	world.sell_building(0)
	world.sell_building(1)
	world.barracks_drone_count = 5
	_build(world, 1, Vector2i(2, 0))
	world._tick_production(10.0)
	_build(world, 3, Vector2i(-2, 2))
	world._tick_production(15.0)
	var defenders: Array[Node2D] = world._live_combat_drones("barracks_drones")
	var points := [Vector2(145, 24), Vector2(125, 24), Vector2(105, 24), Vector2(125, 44), Vector2(125, 4)]
	for index in defenders.size():
		defenders[index].set_physics_process(false)
		defenders[index].position = points[index]
	defenders[0].health = 10
	var mechanic: Node2D = world.buildings[3].main_drone
	mechanic.set_physics_process(false)
	mechanic.position = Vector2(75, 24)
	for frame in 1800:
		for defender in defenders:
			defender._physics_process(1.0 / 60.0)
		mechanic._physics_process(1.0 / 60.0)
		world.drone_collisions.resolve()
		if defenders[0].health == 30:
			break
	assert(defenders[0].health == 30, "Mechanic must navigate around the front row and complete repair")
	for defender in defenders:
		assert(defender.position.distance_to(mechanic.position) >= 19.99)
	world.queue_free()
	print("PASS: single/mixed collector clusters mine and deliver, exclusive jobs before departure, blocked repair approach")
	quit()
