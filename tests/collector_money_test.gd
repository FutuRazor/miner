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
	player.position = Vector2(96, 0)
	for cell in [Vector2i(3, 0), Vector2i(3, 1)]:
		world.block_cells[cell].queue_free()
	world._place_building()
	world.buildings[0].money = 17
	world.update_collector_label(0)
	world.money = 5
	world.collected_count = 3
	# Collector rectangle starts at (72, -24); player radius is 12.
	player.position = Vector2(59, 0)
	world._collect_sampler_money()
	assert(world.money == 5 and world.buildings[0].money == 17)
	# A diagonal near miss must not count as contact.
	player.position = Vector2(62, -34)
	world._collect_sampler_money()
	assert(world.money == 5)
	player.position = Vector2(60, 0)
	world._collect_sampler_money()
	assert(world.money == 22 and world.buildings[0].money == 0)
	assert(world.collected_count == 3)
	assert(world.money_label.text == "Basis: 22 Geld")
	assert(world.buildings[0].label.text == "Sammler: 0 Geld")
	assert(world.money_label.get_parent() == world and world.money_label.z_index == 100)
	world._collect_sampler_money()
	assert(world.money == 22)
	# Money deposited while the player remains touching is also collected.
	world.buildings[0].money = 4
	world._collect_sampler_money()
	assert(world.money == 26 and world.buildings[0].money == 0)
	print("PASS: sampler contact transfer, radius and corners, no duplication, carried blocks unchanged, base world label")
	world.queue_free()
	quit()
