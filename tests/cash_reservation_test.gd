extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	world.money = 1000
	for anchor in [Vector2i(2, 0), Vector2i(-2, 2)]:
		for y in 2:
			for x in 2:
				var cell: Vector2i = anchor + Vector2i(x, y)
				if world.block_cells.has(cell):
					world.block_cells[cell].queue_free()
		world.get_node("Player").position = Vector2(anchor) * 48
		world._place_building()
		world._tick_production(8.0)
		world.buildings[-1].main_drone.set_physics_process(false)
	world.get_node("Player").position = Vector2(500, 500)
	world.buildings[0].money = 50
	world.buildings[1].money = 20
	var workers: Array[Node2D] = []
	for index in 3:
		world._spawn_collector_drone(world.BASE_HOME)
		var worker: Node2D = world.get_child(world.get_child_count() - 1)
		worker.set_physics_process(false)
		workers.append(worker)
		worker._physics_process(0.1)
	assert(workers[0].cash_source == 0)
	assert(workers[1].cash_source == 1)
	assert(workers[2].cash_source == -1 and workers[2].path.is_empty())
	# Reservation covers both travel and the pickup delay.
	assert(workers[1]._cash_source_reserved(0))
	workers[0].position = Vector2(96, 0)
	workers[0].path.clear()
	workers[0]._physics_process(0.3)
	assert(workers[2]._cash_source_reserved(0))
	workers[0]._physics_process(0.3)
	assert(workers[0].cash_carried == 50 and workers[0].cash_source == -1)
	world.buildings[0].money = 15
	workers[2].retry_time = 0.0
	workers[2]._physics_process(0.1)
	assert(workers[2].cash_source == 0, "Pickup releases the collector while the owner delivers")
	# Manual collection cancels travel and frees the assignment immediately.
	world.buildings[0].money = 0
	workers[2]._physics_process(0.1)
	assert(workers[2].cash_source == -1 and workers[2].path.is_empty())
	# Removal releases a reservation even before the queued node is freed.
	workers[1].queue_free()
	workers[2].retry_time = 0.0
	workers[2]._physics_process(0.1)
	assert(workers[2].cash_source == 1)
	world.queue_free()
	print("PASS: distinct cash destinations, reservation during travel/pickup, release on pickup/cancellation/removal")
	quit()
