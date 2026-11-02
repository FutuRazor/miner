extends "res://tests/workshop_test.gd"

func _run() -> void:
	root.size = Vector2i(1152, 720)
	root.get_node("MetaStats").persistence_enabled = false
	var localization := root.get_node("Localization")
	localization.persistence_enabled = false
	assert(localization.set_language("en"))
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	world.cleared_waves = 14
	world.money = 10000
	for kind in 4:
		_build(world, kind, [Vector2i(2, 0), Vector2i(-2, 2), Vector2i(0, -4), Vector2i(3, 3)][kind])
		world._tick_production(15.0)
	for drone in world._live_combat_drones("friendly_drones"):
		drone.set_physics_process(false)
	world.buildings[2].tower.set_physics_process(false)
	world._on_build_button_pressed()
	var names := ["Collector", "Barracks", "Tower", "Workshop"]
	for index in 4:
		assert(world.build_options.current_items[index].name.begins_with(names[index]))
		assert(world.build_options.current_items[index].description.begins_with("Size: 2 × 2"))
		world.building_context.open(index)
		assert(world.building_context.title.text == names[index])
		assert(world.building_context.refund.text.begins_with("Refund:"))
	world.building_context.close()
	world._on_skills_button_pressed()
	for index in world.SKILLS.size():
		var source: Dictionary = world.SKILLS[index]
		var item: Dictionary = world.build_options.current_items[index]
		assert(item.name == world.tr(source.name))
		assert(item.group == world.tr(source.group))
	assert(world.build_options.current_items[13].name == "Increase repair rate")
	world._cycle_game_speed()
	assert(world.speed_button.text == "1.5×")
	world.wave_timer._refresh()
	assert(world.wave_timer.caption.text.begins_with("Next wave: 1"))
	world.base_health = 90
	var mechanic: Node2D = world.buildings[3].main_drone
	mechanic.position = Vector2.ZERO
	mechanic._physics_process(1.0)
	assert(mechanic.status.text == "Repair: 1 HP/s")
	world.queue_free()
	await process_frame
	var tutorial = load("res://scenes/tutorial.tscn").instantiate()
	root.add_child(tutorial)
	tutorial.set_physics_process(false)
	tutorial.get_node("Player").set_physics_process(false)
	tutorial.collected_count = 10
	tutorial._check_progress()
	for frame in 4:
		await process_frame
	assert(tutorial.dialog.heading.text == "Carrying capacity reached")
	assert(tutorial.dialog.description.text.begins_with("You are carrying 10 resource units."))
	assert(tutorial.dialog.ok.get_global_rect().end.y <= root.get_visible_rect().size.y)
	tutorial.acknowledge_message()
	tutorial.queue_free()
	await process_frame
	var statistics = load("res://scenes/meta_stats.tscn").instantiate()
	root.add_child(statistics)
	assert(statistics.summary.text.begins_with("Resource units collected:"))
	assert(statistics.back_button.text == "Back to main menu")
	statistics.queue_free()
	print("PASS: real English catalog across all buildings, context menus, skill metadata, speed/timer/repair HUD, tutorial layout and statistics")
	quit()
