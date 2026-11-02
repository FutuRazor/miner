extends "res://tests/workshop_test.gd"

func _run() -> void:
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	world.money = 10000
	world.cleared_waves = 14
	world.barracks_drone_count = 5
	world.workshop_drone_count = 3
	for anchor in [Vector2i(2, 0), Vector2i(-3, 0), Vector2i(0, 2), Vector2i(0, -3)]:
		_build(world, 1, anchor)
		world._tick_production(10.0)
	_build(world, 3, Vector2i(3, 3))
	world._tick_production(15.0)
	world.collector_drone_count = 4
	for anchor in [Vector2i(-5, 4), Vector2i(4, -5), Vector2i(-6, -5), Vector2i(6, 6), Vector2i(-7, 7)]:
		_build(world, 0, anchor)
		world._tick_production(8.0)
	for block in world.block_cells.values():
		if is_instance_valid(block):
			block.queue_free()
	var drones: Array[Node2D] = world._live_combat_drones("friendly_drones")
	for index in drones.size():
		drones[index].set_physics_process(false)
		drones[index].position = Vector2.from_angle(index * TAU / drones.size()) * 160.0
	var maximum := 0
	var started := Time.get_ticks_usec()
	for frame in 180:
		var frame_start := Time.get_ticks_usec()
		for drone in drones:
			drone._physics_process(1.0 / 60.0)
		world.drone_collisions.resolve()
		maximum = maxi(maximum, Time.get_ticks_usec() - frame_start)
	print("RETURN PROFILE: ", Time.get_ticks_usec() - started, " us total / ", maximum, " us worst simulated frame")
	assert(not world.has_mining_job(1))
	for drone in drones:
		if not drone.passive and not drone.mechanic:
			assert(drone.empty_revision == world.navigation_revision)
	world.set_physics_process(true)
	assert(world.drone_collisions.try_navigation_plan())
	assert(world.drone_collisions.try_navigation_plan())
	assert(not world.drone_collisions.try_navigation_plan())
	world.set_physics_process(false)
	world.queue_free()
	print("PASS: simultaneous post-wave return stress scenario")
	quit()
