extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _build(world: Node, anchor: Vector2i) -> void:
	for y in 2:
		for x in 2:
			var cell := anchor + Vector2i(x, y)
			if world.block_cells.has(cell) and is_instance_valid(world.block_cells[cell]):
				world.block_cells[cell].queue_free()
	world.get_node("Player").position = Vector2(anchor) * 48
	world.selected_building = 1
	world._place_building()


func _count(world: Node, index: int) -> int:
	var count := 0
	for child in world.get_children():
		if child.get_script() == world.Drone and child.collector_index == index:
			count += 1
	return count


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	assert(world.BUILDINGS[1] == "Kaserne" and world.barracks_cost == 10)
	world.barracks_cost = 0
	_build(world, Vector2i(2, 0))
	assert(_count(world, 0) == 1)
	world.money = 10
	world._on_skills_button_pressed()
	world._on_option_clicked(6)
	assert(world.barracks_drone_count == 2 and _count(world, 0) == 2)
	assert(world.money == 0 and world.build_mode == world.BuildMode.SKILLS)
	_build(world, Vector2i(-2, 2))
	assert(_count(world, 1) == 2)
	world.money = 10
	world._on_skills_button_pressed()
	world._on_option_clicked(6)
	assert(_count(world, 0) == 3 and _count(world, 1) == 3)
	_build(world, Vector2i(0, -4))
	assert(_count(world, 2) == 3)
	assert(world.collector_drone_count == 1)
	for child in world.get_children():
		if child.get_script() == world.Drone:
			child.set_physics_process(false)
			var before: Vector2 = child.position
			child._physics_process(10.0)
			assert(child.passive and not child.collects_money)
			assert(child.position == before and child.carried == 0 and child.cash_carried == 0)
			assert(child.tint == world.BUILDING_COLORS[1])
	world.money = 9
	world._on_skills_button_pressed()
	world._on_option_clicked(6)
	assert(world.money == 9 and world.barracks_drone_count == 3)
	for index in [8, 9]:
		assert(world.SKILLS[index].placeholder)
		world._on_option_clicked(index)
		assert(world.money == 9 and world.barracks_drone_count == 3)
	world.build_options.keyboard_mode = true
	world._update_build_ui()
	for frame in 8:
		await process_frame
	assert(world.build_options.rows.size() == 13)
	assert(world.build_options.entry_scroll.scroll_vertical > 0)
	assert(world.build_panel.global_position.y >= 0)
	print("PASS: barracks initial drone, global count upgrades, future buildings, passive role, price 10, placeholders and keyboard scrolling")
	world.queue_free()
	quit()
