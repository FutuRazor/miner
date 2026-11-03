extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _drones(world: Node, index: int) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for child in world.get_children():
		if child.get_script() == world.Drone and child.collector_index == index and not child.is_queued_for_deletion():
			result.append(child)
	return result


func _settle() -> void:
	for frame in 4:
		await process_frame


func _build(world: Node, anchor: Vector2i) -> void:
	for y in 2:
		for x in 2:
			var cell := anchor + Vector2i(x, y)
			if world.block_cells.has(cell) and is_instance_valid(world.block_cells[cell]):
				world.block_cells[cell].queue_free()
	world.get_node("Player").position = Vector2(anchor) * 48
	world.selected_building = 1
	world._place_building()
	world._tick_production(10.0)


func _run() -> void:
	root.get_node("SessionSave").storage_path = "res://.godot/session_tests/%d/barracks_health_test.dat" % OS.get_process_id()
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.barracks_cost = 0
	world.money = 1000
	world.cleared_waves = 14
	_build(world, Vector2i(2, 0))
	_build(world, Vector2i(-2, 2))
	world.money = 10
	world._on_skills_button_pressed()
	world._on_option_clicked(8)
	assert(_drones(world, 0).size() == 2 and _drones(world, 1).size() == 2)
	var drone: Node2D = world.buildings[0].main_drone
	assert(drone.health == 30 and drone.status.text == "Lebenspunkte\n30/30")
	assert(drone.status.z_index == 100)
	drone.take_damage(12)
	assert(drone.health == 18 and drone.status.text == "Lebenspunkte\n18/30")
	drone.take_damage(-5)
	assert(drone.health == 18)
	drone.take_damage(100)
	drone.take_damage(100)
	assert(drone.dead and drone.is_queued_for_deletion() and not drone.visible)
	await _settle()
	assert(_drones(world, 0).size() == 1)
	world._tick_production(20.0)
	assert(not is_instance_valid(drone))
	assert(_drones(world, 0).size() == 2 and _drones(world, 1).size() == 2)
	assert(is_instance_valid(world.buildings[0].main_drone))
	assert(world.buildings[0].main_drone.health == 30)
	# Simultaneous deaths must restore exactly the skill limit per building.
	for index in [0, 1]:
		for worker in _drones(world, index):
			worker.take_damage(30)
	await _settle()
	world._tick_production(40.0)
	for index in [0, 1]:
		assert(_drones(world, index).size() == 2)
		for worker in _drones(world, index):
			assert(worker.health == 30 and worker.max_health == 30)
	assert(world.money == 10 and world.drone_count_label.text == "Drohnen: 4")
	# Game over prevents any further reinforcements.
	world.damage_base(100)
	_drones(world, 0)[0].take_damage(30)
	await _settle()
	assert(_drones(world, 0).size() == 1)
	print("PASS: barracks drone health 30/30, damage/death, free per-building replacement, simultaneous losses, skill limit and game-over guard")
	world.queue_free()
	quit()
