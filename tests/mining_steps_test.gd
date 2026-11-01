extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	var player = world.get_node("Player")
	player.set_physics_process(false)
	var block: Node = world.block_cells[Vector2i(3, 0)]
	assert(block.mining_steps == 4)
	for step in 3:
		assert(block.mine(1.0))
		assert(block.completed_steps == step + 1)
		assert(world.collected_count == step + 1 and player.carried == step + 1)
		assert(not block.depleted and not block.is_queued_for_deletion())
		assert(not world._walkable_cell(Vector2i(3, 0)))
	block.mine(0.2)
	block.reset_progress()
	assert(block.progress == 0.0 and block.completed_steps == 3)
	assert(block.mine(1.0))
	assert(block.depleted and block.is_queued_for_deletion())
	assert(world.collected_count == 4 and world._walkable_cell(Vector2i(3, 0)))
	# Player capacity can be reached in the middle of a block.
	var partial: Node = world.block_cells[Vector2i(4, 0)]
	world.collected_count = 9
	world._update_counters()
	player.position = Vector2(155, 0)
	player._physics_process(1.0)
	assert(player.carried == 10 and partial.completed_steps == 1)
	player._physics_process(1.0)
	assert(partial.completed_steps == 1 and partial.progress == 0.0)
	# A full drone releases a partially mined block for the next worker.
	world.collector_cost = 0
	player.position = Vector2(96, 0)
	world.block_cells[Vector2i(3, 1)].queue_free()
	world._place_building()
	world._tick_production(10.0)
	var drone: Node2D = world.buildings[0].main_drone
	drone.set_physics_process(false)
	drone.carried = 9
	drone.position = Vector2(144, 0)
	drone.target = partial
	drone._physics_process(1.0)
	assert(drone.carried == 10 and drone.returning)
	assert(partial.completed_steps == 2 and not partial.depleted)
	assert(not is_instance_valid(partial.mining_drone))
	assert(partial.progress == 0.0)
	world._spawn_collector_drone(0)
	var second: Node2D = world.get_child(world.get_child_count() - 1)
	second.set_physics_process(false)
	second.position = Vector2(144, 0)
	second.target = partial
	second._physics_process(1.0)
	assert(second.carried == 1 and partial.completed_steps == 3)
	assert(second.target == partial)
	second._physics_process(1.0)
	assert(second.carried == 2 and partial.depleted)
	assert(player.carried == 10)
	print("PASS: four steps, immediate per-step inventory, solid until fourth step, interruption persistence, capacity mid-block and drone handoff")
	world.queue_free()
	quit()
