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
	world.barracks_drone_count = 5
	world.workshop_drone_count = 3
	_build(world, 1, Vector2i(2, 0))
	world._tick_production(10.0)
	_build(world, 3, Vector2i(-2, 2))
	world._tick_production(15.0)
	var drones: Array[Node2D] = world._live_combat_drones("friendly_drones")
	for drone in drones:
		drone.set_physics_process(false)
	# Spawned together: resolve overlap, then settle freely inside each home.
	for frame in 240:
		for drone in drones:
			drone._physics_process(1.0 / 60.0)
		world.drone_collisions.resolve()
	for drone in drones:
		assert(drone.home_area().has_point(drone.position))
		for other in drones:
			if drone != other:
				assert(drone.position.distance_to(other.position) >= 19.99)
	# A valid, non-central resting position must stay exactly where it is.
	var parked := drones[0].position
	drones[0].park_home(1.0)
	assert(drones[0].position == parked)
	drones[0].health = 20
	var mechanic: Node2D = world.buildings[1].main_drone
	assert(mechanic.mechanic_ai.can_repair_drone(drones[0]))
	drones[0].health = 30
	# Simulate being shoved entirely outside: dynamically find space to return.
	drones[0].position = Vector2(200, 0)
	for frame in 240:
		for drone in drones:
			drone._physics_process(1.0 / 60.0)
		world.drone_collisions.resolve()
	assert(drones[0].home_area().has_point(drones[0].position))
	# Opposing factions also occupy solid circles and displace each other.
	var enemy = world.Drone.new()
	enemy.world = world
	enemy.hostile = true
	enemy.position = drones[0].position
	world.add_child(enemy)
	enemy.set_physics_process(false)
	world.drone_collisions.resolve()
	assert(enemy.position.distance_to(drones[0].position) >= 19.99)
	assert(drones[0].is_moving)
	# Displaced targets cannot be repaired while they are moving.
	drones[0].health = 20
	assert(not mechanic.mechanic_ai.can_repair_drone(drones[0]))
	world.queue_free()
	print("PASS: hard circular drone collisions, dense free parking, stable noncentral rest, return after pushing and repair interruption")
	quit()
