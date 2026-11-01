extends "res://tests/workshop_test.gd"

func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	world.money = 10000
	_build(world, 3, Vector2i(2, 0))
	world._tick_production(15.0)
	_build(world, 2, Vector2i(-2, 2))
	world._tick_production(6.0)
	_build(world, 2, Vector2i(0, -4))
	world._tick_production(6.0)
	_build(world, 1, Vector2i(-4, 0))
	world._tick_production(10.0)
	world._spawn_collector_drone(0)
	world._spawn_collector_drone(0)
	var workers: Array[Node2D] = []
	var defenders: Array[Node2D] = []
	for drone in world._live_combat_drones("friendly_drones"):
		drone.set_physics_process(false)
		if drone.mechanic:
			workers.append(drone)
		elif drone.passive:
			defenders.append(drone)
	var near: Node2D = world.buildings[1].tower
	var far: Node2D = world.buildings[2].tower
	near.set_physics_process(false)
	far.set_physics_process(false)
	near.health = 40
	far.max_health = 40
	far.health = 30
	defenders[0].health = 5
	defenders[1].health = 20
	for worker in workers:
		worker.position = near.position
		worker._physics_process(0.01)
	assert(workers[0].mechanic_ai.repair_target == far, "Select lowest absolute HP, not nearest target or lowest percentage")
	assert(workers[1].mechanic_ai.repair_target == near, "Reserve the first tower during travel")
	assert(workers[2].mechanic_ai.repair_target == defenders[0], "Skip reserved towers and select the weakest eligible drone")
	# Keep an assignment within its category until completion, not HP oscillation.
	near.health = 1
	workers[0]._physics_process(0.01)
	assert(workers[0].mechanic_ai.repair_target == far)
	far.health = far.max_health
	workers[0]._physics_process(0.01)
	assert(workers[0].mechanic_ai.repair_target == defenders[1])
	# All three may reserve and repair the base together, releasing other targets.
	world.base_health = 90
	for worker in workers:
		worker.position = Vector2.ZERO
		worker._physics_process(1.0)
		assert(worker.mechanic_ai.repair_target == world)
	assert(world.base_health == 93)
	world.base_health = world.base_max_health
	for worker in workers:
		worker._physics_process(0.01)
	assert(workers[0].mechanic_ai.repair_target == near)
	assert(workers[1].mechanic_ai.repair_target == defenders[0])
	assert(workers[2].mechanic_ai.repair_target == defenders[1])
	# A removed mechanic must not leave a permanent tower reservation.
	workers[0].queue_free()
	workers[1]._physics_process(0.01)
	assert(workers[1].mechanic_ai.repair_target == near)
	# Moving targets release immediately, even before their previous owner ticks.
	defenders[1].is_moving = true
	assert(not workers[1].mechanic_ai._reserved(defenders[1]))
	workers[2]._physics_process(0.01)
	assert(workers[2].mechanic_ai.repair_target == defenders[0])
	world.sell_building(1)
	workers[1]._physics_process(0.01)
	assert(workers[1].mechanic_ai.repair_target == null)
	defenders[1].is_moving = false
	workers[1]._physics_process(0.01)
	assert(workers[1].mechanic_ai.repair_target == defenders[1])
	world.queue_free()
	print("PASS: exclusive repair assignments, lowest absolute HP per category, stable fixation, shared base and released reservations")
	quit()
