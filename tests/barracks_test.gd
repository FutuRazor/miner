extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	world.money = 10000
	world.cleared_waves = 14
	for kind in 3:
		var anchor: Vector2i = [Vector2i(2, 0), Vector2i(-2, 2), Vector2i(0, -4)][kind]
		for y in 2:
			for x in 2:
				var cell: Vector2i = anchor + Vector2i(x, y)
				if world.block_cells.has(cell): world.block_cells[cell].queue_free()
		world.selected_building = kind
		world.get_node("Player").position = Vector2(anchor) * 48
		world._place_building()
		world._tick_production(10.0)
	world.base_health -= 12
	world.buildings[1].main_drone.take_damage(12)
	world.selected_skill = 6
	var prices: Array = world.Balance.PRICES["barracks_drones"]
	for price in prices:
		var before: int = world.money
		world._confirm_skill()
		assert(world.money == before - price)
		world._tick_production(60.0)
	var before: int = world.money
	world._confirm_skill()
	assert(world.money == before)
	assert(world._skill_block_reason("barracks_drones") == "Maximum erreicht")
	assert(world.barracks_drone_count == 5)
	assert(world._live_combat_drones("barracks_drones").size() == 5)
	world._on_skills_button_pressed()
	assert(world.build_options.current_items[6].lock_reason == "Maximum erreicht")
	world.queue_free()
	print("PASS: barracks_drones prices, effects, production, cap and menu state")
	quit()
