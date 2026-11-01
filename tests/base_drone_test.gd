extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _key(world: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	world._input(event)


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	_key(world, KEY_J)
	world.selected_skill = 2
	world._update_build_ui()
	assert(world.build_options.current_items[2].level == 0)
	world.money = 9
	_key(world, KEY_E)
	assert(not world.base_drone_settings.has("main_drone") and world.money == 9)
	world.money = 10
	_key(world, KEY_ENTER)
	var drone: Node2D = world.base_drone_settings.main_drone
	drone.set_physics_process(false)
	assert(world.money == 0 and world.money_label.text == "Basis: 0 Geld")
	assert(world.build_options.current_items[2].level == 1)
	assert(world.build_options.info_panel.title.text == "Geld-Sammeldrohne (lvl. 1)")
	assert(world.build_options.info_panel.current_effect.text == "1 Geld-Sammeldrohne")
	assert(world.build_options.info_panel.next_effect.text == "2 Geld-Sammeldrohnen")
	assert(drone.tint == world.BASE_COLOR)
	assert(drone.collector_index == world.BASE_HOME)
	assert(drone.capacity == 10 and drone.mining_power == 1)
	assert(world.drone_count_label.text == "Drohnen: 1")
	assert(world.buildings.is_empty())
	assert(drone.collects_money)
	# No cash source: the drone must idle without mining any blocks.
	for tick in 20:
		drone._physics_process(0.1)
	assert(drone.carried == 0 and world.money == 0)
	world.collector_cost = 0
	for cell in [Vector2i(3, 0), Vector2i(3, 1)]:
		world.block_cells[cell].queue_free()
	world.get_node("Player").position = Vector2(96, 0)
	world._place_building()
	world.buildings[0].money = 10
	world.get_node("Player").position = Vector2.ZERO
	world.buildings[0].main_drone.set_physics_process(false)
	drone.speed = 10000
	var delivered := false
	for tick in 3000:
		drone._physics_process(0.1)
		assert(world.collected_count == 0)
		if drone.returning and drone.path.is_empty() and drone.deposit_elapsed < 0.5:
			assert(world.money == 0)
		if world.money > 0:
			assert(world.money == 10 and drone.carried == 0)
			assert(world.BASE_AREA.has_point(drone.position))
			assert(world.money_label.text == "Basis: 10 Geld")
			delivered = true
			break
		await process_frame
	assert(delivered)
	_key(world, KEY_J)
	_key(world, KEY_E)
	assert(world.money == 0 and world.drone_count_label.text == "Drohnen: 3")
	assert(world.build_options.current_items[2].level == 2)
	for child in world.get_children():
		if child.get_script() == world.Drone and child.collects_money:
			assert(child.tint == world.BASE_COLOR and child.collector_index == -1)
	print("PASS: base drone purchase, cost, color, mining, delayed 3x3 base deposit, available money and repeat purchase")
	world.queue_free()
	quit()
