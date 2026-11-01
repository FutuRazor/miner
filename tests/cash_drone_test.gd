extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _build(world: Node, anchor: Vector2i) -> void:
	for y in 2:
		for x in 2:
			var cell := anchor + Vector2i(x, y)
			if world.block_cells.has(cell) and is_instance_valid(world.block_cells[cell]):
				world.block_cells[cell].queue_free()
	world.get_node("Player").position = Vector2(anchor) * 48
	world._place_building()
	world._tick_production(10.0)
	world.buildings[-1].main_drone.set_physics_process(false)


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.money = 0
	world.set_physics_process(false)
	var player = world.get_node("Player")
	player.set_physics_process(false)
	assert(world.collector_cost == 30 and world.barracks_cost == 25)
	world.collector_cost = 0
	_build(world, Vector2i(2, 0))
	world.money = world._building_cost(0)
	_build(world, Vector2i(-2, 2))
	world.buildings[0].money = 5
	world.buildings[1].money = 20
	# An unreachable rich source must not strand the drone.
	world.buildings.append({"kind": 0, "anchor": Vector2i(10, 10), "money": 999})
	player.position = Vector2.ZERO
	world._spawn_collector_drone(-1)
	var drone: Node2D = world.base_drone_settings.main_drone
	drone.set_physics_process(false)
	drone.speed = 10000
	drone._physics_process(0.1)
	assert(drone.cash_source == 1)
	for tick in 100:
		drone._physics_process(0.1)
		if drone.cash_source == 1 and drone.path.is_empty() and drone.deposit_elapsed > 0.0 and drone.deposit_elapsed < 0.5:
			assert(world.buildings[1].money == 20 and drone.cash_carried == 0)
		if drone.cash_carried > 0:
			break
	assert(drone.cash_carried == 20 and world.money == 0)
	assert(world.buildings[1].money == 0 and world.buildings[0].money == 5)
	# Deliver to the player, away from the base.
	assert(not world.BASE_AREA.has_point(drone.position))
	player.position = drone.position
	drone.path.clear()
	drone._physics_process(0.001)
	assert(world.money == 20 and drone.cash_carried == 0)
	# With the player far away, the next delivery goes to the base.
	player.position = Vector2(400, 400)
	for tick in 150:
		drone._physics_process(0.1)
		if world.money == 25:
			break
	assert(world.money == 25 and world.BASE_AREA.has_point(drone.position))
	assert(world.collected_count == 0 and drone.carried == 0)
	assert(world.block_cells[Vector2i(4, 0)].completed_steps == 0)
	# Two arrivals cannot duplicate the same deposit.
	world._spawn_collector_drone(-1)
	var second: Node2D = world.get_child(world.get_child_count() - 1)
	second.set_physics_process(false)
	world.buildings[0].money = 7
	for worker in [drone, second]:
		worker.position = Vector2(96, 0)
		worker.path.clear()
		worker.cash_source = 0
		for tick in 6:
			worker._physics_process(0.1)
	assert(drone.cash_carried + second.cash_carried == 7)
	assert(world.buildings[0].money == 0)
	assert(drone.status.text.contains("Geld"))
	print("PASS: prices 10, richest reachable source, cash in transit, player/base delivery, no mining and no duplicate withdrawals")
	world.queue_free()
	quit()
