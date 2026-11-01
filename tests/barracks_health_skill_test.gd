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


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.barracks_cost = 0
	_build(world, Vector2i(2, 0))
	var drone: Node2D = world.buildings[0].main_drone
	drone.take_damage(12)
	world.money = 20
	world._on_skills_button_pressed()
	world._on_option_clicked(7)
	assert(drone.health == 28 and drone.max_health == 40)
	assert(drone.status.text == "Lebenspunkte\n28/40")
	assert(world.money == 10 and world.barracks_drone_health == 40)
	assert(world.build_options.info_panel.title.text == "Lebenspunkte (lvl. 2)")
	world._on_option_clicked(7)
	assert(drone.health == 38 and drone.max_health == 50 and world.money == 0)
	assert(world.build_options.current_items[7].next_effect == "60 maximale Lebenspunkte")
	world._on_option_clicked(7)
	assert(drone.max_health == 50 and world.skill_levels.barracks_health == 3)
	assert(world.base_max_health == 100)
	drone.take_damage(100)
	for frame in 4:
		await process_frame
	var replacement: Node2D = world.buildings[0].main_drone
	assert(replacement.health == 50 and replacement.max_health == 50)
	_build(world, Vector2i(-2, 2))
	assert(world.buildings[1].main_drone.health == 50)
	assert(world.buildings[1].main_drone.max_health == 50)
	print("PASS: +10 health per purchase, current/max, damage preserved, levels, no-money rejection, replacements and new barracks")
	world.queue_free()
	quit()
