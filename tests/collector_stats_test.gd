extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _build(world: Node, anchor: Vector2i, kind: int) -> void:
	for y in 2:
		for x in 2:
			var cell := anchor + Vector2i(x, y)
			if world.block_cells.has(cell) and is_instance_valid(world.block_cells[cell]):
				world.block_cells[cell].queue_free()
	world.get_node("Player").position = Vector2(anchor) * 48
	world.selected_building = kind
	world._place_building()
	world.buildings[-1].main_drone.set_physics_process(false)


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.collector_cost = 0
	world.barracks_cost = 0
	_build(world, Vector2i(2, 0), 0)
	_build(world, Vector2i(-2, 2), 1)
	world._spawn_collector_drone(-1)
	var cash: Node2D = world.base_drone_settings.main_drone
	cash.set_physics_process(false)
	var drone: Node2D = world.buildings[0].main_drone
	var passive: Node2D = world.buildings[1].main_drone
	world.money = 40
	world._on_skills_button_pressed()
	world._on_option_clicked(4)
	assert(world.money == 30 and drone.speed == 110 and drone.mining_speed == 110)
	var before: Vector2 = drone.position
	drone.path.assign([before + Vector2(100, 0)])
	drone._physics_process(0.1)
	assert(is_equal_approx(drone.position.x - before.x, 11.0))
	drone.path.clear()
	drone.position = before
	var block: Node = world.block_cells[Vector2i(4, 0)]
	drone.target = block
	drone._physics_process(0.8)
	assert(block.completed_steps == 1 and drone.carried == 1)
	world._on_option_clicked(5)
	assert(world.money == 20 and drone.capacity == 20)
	assert(drone.carried == 1 and drone.status.text == "1/20")
	assert(passive.speed == 100 and passive.capacity == 10)
	assert(cash.speed == 100 and cash.capacity == 10)
	assert(world.get_node("Player").capacity == 10)
	world._on_option_clicked(4)
	world._on_option_clicked(5)
	assert(world.money == 0 and drone.speed == 120 and drone.mining_speed == 120 and drone.capacity == 30)
	world._on_option_clicked(5)
	assert(world.money == 0 and drone.capacity == 30)
	world._spawn_collector_drone(0)
	var added: Node2D = world.get_child(world.get_child_count() - 1)
	added.set_physics_process(false)
	assert(added.speed == 120 and added.mining_speed == 120 and added.capacity == 30)
	_build(world, Vector2i(0, -4), 0)
	var future: Node2D = world.buildings[2].main_drone
	assert(future.speed == 120 and future.mining_speed == 120 and future.capacity == 30)
	world._on_skills_button_pressed()
	assert(world.build_options.current_items[4].current_effect == "Bewegung: 120 Pixel/s\nAbbau: 120 %")
	assert(world.build_options.current_items[5].current_effect == "30 Einheiten Tragkapazität")
	assert(typeof(world.collector_move_speed) == TYPE_INT and typeof(world.collector_mining_speed) == TYPE_INT)
	print("PASS: integer speed stats, faster movement/mining, +10 capacity, repeated costs, existing/future drones, isolated other roles and live labels")
	world.queue_free()
	quit()
