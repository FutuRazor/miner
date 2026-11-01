extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.money = 0
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.collector_cost = 0
	world.get_node("Player").position = Vector2(96, 0)
	world.block_cells[Vector2i(3, 0)].queue_free()
	world.block_cells[Vector2i(3, 1)].queue_free()
	world._place_building()
	var drone: Node2D
	for child in world.get_children():
		if child.get_script() == world.Drone:
			drone = child
	assert(is_instance_valid(drone))
	drone.set_physics_process(false)
	drone.speed = 10000
	drone._plan(false)
	assert(is_instance_valid(drone.target))
	var home_center := Vector2(2.5, 0.5)
	var chosen_distance: float = drone.target.position.distance_squared_to(drone.position)
	for cell in world.block_cells:
		if drone._has_block(cell):
			assert(chosen_distance <= (Vector2(cell) * 48).distance_squared_to(drone.position))
	var delivered := false
	for tick in 3000:
		drone._physics_process(0.1)
		assert(drone.carried <= 10)
		assert(world.collected_count == 0 and world.money == 0)
		if drone.returning and drone.path.is_empty() and drone.deposit_elapsed < 0.5:
			assert(world.buildings[0].money == 0)
		if world.buildings[0].money > 0:
			assert(world.buildings[0].money == 10)
			assert(drone.carried == 0 and not drone.returning)
			delivered = true
			break
		await process_frame
	assert(delivered)
	assert(drone.choose_from_collector)
	# Move away from home to distinguish the two selection origins clearly.
	drone.position = Vector2(-96, -96)
	drone._plan(false)
	var collector_target: Vector2 = drone.target.position
	chosen_distance = (collector_target / 48).distance_squared_to(home_center)
	for cell in world.block_cells:
		if drone._has_block(cell):
			assert(chosen_distance <= Vector2(cell).distance_squared_to(home_center))
	assert(not drone.choose_from_collector)
	drone._plan(false)
	assert(drone.target.position != collector_target)
	chosen_distance = drone.target.position.distance_squared_to(drone.position)
	for cell in world.block_cells:
		if drone._has_block(cell):
			assert(chosen_distance <= (Vector2(cell) * 48).distance_squared_to(drone.position))
	# With no remaining blocks, a partial load is still taken home.
	for block in world.block_cells.values():
		if is_instance_valid(block):
			block.queue_free()
	drone.target = null
	drone.carried = 3
	world.money_per_block = 2
	drone._plan(false)
	assert(drone.returning)
	for tick in 100:
		drone._physics_process(0.1)
		if world.buildings[0].money == 16:
			break
	assert(world.buildings[0].money == 16 and drone.carried == 0)
	assert(world.money == 0 and world.collected_count == 0)
	print("PASS: nearest block, autonomous mining, capacity 10, return path, delayed deposit, local money and partial final load")
	world.queue_free()
	quit()
