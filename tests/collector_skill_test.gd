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


func _count(world: Node, index: int) -> int:
	var count := 0
	for child in world.get_children():
		if child.get_script() == world.Drone and child.collector_index == index:
			count += 1
	return count


func _key(world: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	world._input(event)


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.collector_cost = 0
	world.barracks_cost = 0
	world.money = 10
	_key(world, KEY_J)
	world._on_option_clicked(3)
	assert(world.collector_drone_count == 2 and world.money == 0)
	assert(world.build_mode == world.BuildMode.SKILLS and world.build_panel.visible)
	assert(world.buildings.is_empty())
	_build(world, Vector2i(2, 0), 0)
	_build(world, Vector2i(-2, 2), 0)
	_build(world, Vector2i(0, -4), 1)
	assert(_count(world, 0) == 2 and _count(world, 1) == 2 and _count(world, 2) == 1)
	world._spawn_collector_drone(-1)
	world.money = 20
	_key(world, KEY_J)
	world.selected_skill = 3
	_key(world, KEY_E)
	assert(world.money == 10 and world.collector_drone_count == 3)
	assert(world.build_mode == world.BuildMode.SKILLS and world.build_panel.visible)
	assert(_count(world, 0) == 3 and _count(world, 1) == 3)
	assert(_count(world, -1) == 1 and _count(world, 2) == 1)
	_build(world, Vector2i(-4, 0), 0)
	assert(_count(world, 3) == 3)
	_key(world, KEY_J)
	world._on_option_clicked(3)
	assert(world.money == 0 and world.collector_drone_count == 4)
	assert(_count(world, 0) == 4 and _count(world, 1) == 4 and _count(world, 3) == 4)
	assert(world.drone_count_label.text == "Drohnen: 14")
	world.money = 9
	world._update_build_ui()
	assert(not world.build_options.current_items[3].get("placeholder", false))
	assert(world.build_options.current_items[3].current_effect == "4 Drohnen je Sammler")
	var info = world.build_options.info_panel
	assert(info.title.text == "Drohne (lvl. 4)" and info.description.text == "-baut Blöcke ab-")
	assert(info.upgrade_details.visible)
	assert(info.current_effect.text == "4 Drohnen je Sammler")
	assert(info.next_effect.text == "5 Drohnen je Sammler")
	assert(info.current_effect.get_theme_color("font_color") == Color.WHITE)
	assert(info.next_effect.get_theme_color("font_color") == Color("65e994"))
	assert(info.cost.text == "Kosten: 10 Geld")
	world._on_option_clicked(3)
	assert(world.money == 9 and world.collector_drone_count == 4)
	assert(_count(world, 0) == 4)
	# Samplers no longer expose local upgrades, even from another menu.
	world.get_node("Player").position = Vector2(96, 0)
	_key(world, KEY_U)
	assert(world.build_mode == world.BuildMode.SKILLS)
	_key(world, KEY_B)
	_key(world, KEY_U)
	assert(world.build_mode == world.BuildMode.MENU)
	print("PASS: global drone skill, one charge per level, existing/future samplers, purchase before building, isolated base/generator and removed sampler upgrades")
	world.queue_free()
	quit()
