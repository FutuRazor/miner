extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.collector_cost = 0
	world.get_node("Player").position = Vector2(96, 0)
	for cell in [Vector2i(3, 0), Vector2i(3, 1)]:
		world.block_cells[cell].queue_free()
	world._place_building()
	world._spawn_collector_drone(0)
	world._spawn_collector_drone(0)
	var drones: Array[Node] = []
	var block: Node = world.block_cells[Vector2i(4, 0)]
	for child in world.get_children():
		if child.get_script() == world.Drone:
			child.set_physics_process(false)
			child.position = Vector2(144, 0)
			child.target = block
			drones.append(child)
	# Same-frame arrivals are processed atomically: exactly one starts mining.
	for drone in drones:
		drone._physics_process(0.1)
	assert(block.mining_drone == drones[0])
	assert(is_equal_approx(block.progress, 0.1))
	for index in [1, 2]:
		assert(drones[index].target != block)
		assert(is_instance_valid(drones[index].target))
		assert(drones[index].carried == 0)
	# Player resets cannot erase the active drone's progress.
	block.reset_progress()
	assert(is_equal_approx(block.progress, 0.1))
	drones[0]._physics_process(0.8)
	assert(not block.depleted and block.completed_steps == 1 and drones[0].carried == 1)
	for step in 3:
		drones[0]._physics_process(0.85)
	assert(block.depleted and drones[0].carried == 4)
	assert(world.collected_count == 0)
	assert(not block.mine(1.0, false, drones[1]))
	# Ownership is released if the active drone disappears.
	var other: Node = drones[1].target
	drones[1].path.clear()
	drones[1]._physics_process(0.1)
	assert(other.mining_drone == drones[1])
	drones[1].queue_free()
	await process_frame
	assert(other.available_for_drone(drones[2]))
	assert(other.progress == 0.0)
	assert(other.claim_for_drone(drones[2]))
	print("PASS: simultaneous arrivals, exclusive progress, immediate retargeting, single collection and owner cleanup")
	world.queue_free()
	quit()
