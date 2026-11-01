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
	world.collector_cost = 0
	for cell in [Vector2i(3, 0), Vector2i(3, 1)]:
		world.block_cells[cell].queue_free()
	player.position = Vector2(96, 0)
	world._place_building()
	var drone: Node2D = world.buildings[0].main_drone
	drone.set_physics_process(false)
	for block in world.block_cells.values():
		if is_instance_valid(block) and block.hardness == 1:
			block.queue_free()
	player.position = Vector2(203, 0)
	drone.position = Vector2(192, 0)
	assert(player._nearby_mining_target() == null)
	drone._plan(false)
	assert(not is_instance_valid(drone.target))
	world.money = 9
	world._on_skills_button_pressed()
	world._on_option_clicked(1)
	assert(world.mining_level == 1 and player.mining_power == 1 and drone.mining_power == 1)
	assert(world.money == 9)
	world.money = 20
	world._on_option_clicked(1)
	assert(world.money == 10 and world.mining_level == 2)
	assert(player.mining_power == 2 and drone.mining_power == 2)
	assert(world.build_mode == world.BuildMode.SKILLS)
	assert(world.build_options.current_items[1].current_effect == "Abbaustufe 2")
	assert(world.build_options.current_items[1].next_effect == "Abbaustufe 3")
	assert(player._nearby_mining_target().hardness == 2)
	# New drones at an existing sampler inherit the global level.
	world._on_option_clicked(3)
	var added: Node2D = world.get_child(world.get_child_count() - 1)
	added.set_physics_process(false)
	assert(added.mining_power == 2)
	# New sampler buildings also inherit it.
	player.position = Vector2(-96, 96)
	world.selected_building = 0
	world._place_building()
	assert(world.buildings[1].main_drone.mining_power == 2)
	world.buildings[1].main_drone.set_physics_process(false)
	player.position = Vector2(203, 0)
	player.movement_enabled = true
	player._physics_process(0.85)
	assert(world.collected_count == 1)
	drone._plan(false)
	assert(is_instance_valid(drone.target) and drone.target.hardness == 2)
	drone.path.clear()
	drone._physics_process(0.85)
	assert(drone.carried == 1 and world.collected_count == 1)
	world.money = 10
	world._on_skills_button_pressed()
	world._on_option_clicked(1)
	assert(world.mining_level == 3 and world.money == 0)
	assert(player.mining_power == 3 and added.mining_power == 3)
	print("PASS: mining level purchase, insufficient money, existing/new drones and buildings, actual hardness-2 mining, repeated upgrades and live info")
	world.queue_free()
	quit()
