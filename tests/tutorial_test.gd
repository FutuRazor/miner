extends "res://tests/workshop_test.gd"

func _earn_to(world: Node, amount: int) -> void:
	world.receive_income(amount - world.earned)
	world._check_progress()

func _ok(world: Node) -> void:
	assert(world.dialog_open and paused)
	world.dialog.ok.pressed.emit()
	assert(not world.dialog_open and not paused)

func _buy_id(world: Node, id: String) -> void:
	for index in world.SKILLS.size():
		if world.SKILLS[index].get("id", "") == id:
			world.selected_skill = index
			world._confirm_skill()
			return
	assert(false, "Unknown tutorial skill")

func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/tutorial.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	assert(world.map_radius == 8 and world.block_cells.size() == 264 and world.money == 20)
	var hardness_one_income := 0
	var hardness_two_income := 0
	for block in world.block_cells.values():
		assert(block.hardness <= 3)
		if block.hardness == 1:
			hardness_one_income += block.mining_steps
		if block.hardness <= 2:
			hardness_two_income += block.mining_steps
	assert(world.INCOME_STEPS[4] <= hardness_one_income)
	assert(world.INCOME_STEPS[5] + 125 <= hardness_two_income)
	assert(world.wave_timer.timer_paused and not world.wave_timer.visible)
	assert(not world.is_build_menu_available() and not world.is_skill_menu_available())
	world._on_build_button_pressed()
	world._on_skills_button_pressed()
	assert(world.build_mode == world.BuildMode.PLAY)
	world.spawn_enemy_wave()
	assert(world.spawned_waves == 0)
	for unit in 10:
		world._on_block_collected()
	world._check_progress()
	assert(world.dialog.heading.text == "Maximale Tragkraft erreicht")
	world._set_paused(false)
	assert(paused)
	world._on_build_button_pressed()
	assert(world.build_mode == world.BuildMode.PLAY)
	_ok(world)
	world.was_in_base = false
	world._physics_process(0.0)
	assert(world.money == 30 and world.collected_count == 0)
	for unit in 10:
		world._on_block_collected()
	world.was_in_base = false
	world._physics_process(0.0)
	assert(world.money == 40 and world.earned == 20 and world.phase == 1)
	assert(world.dialog.heading.text == "Baumenü verfügbar" and world.blink_build)
	_ok(world)
	world._on_build_button_pressed()
	assert(not world.blink_build and world.build_options.current_items.size() == 1)
	assert(world._building_limit(0) == 1 and world._building_limit(1) == 0)
	world._on_option_clicked(0)
	assert(not world.new_buildings.has(0))
	world.mouse_placement = false
	_build(world, 0, Vector2i(2, 0))
	world._tick_production(8.0)
	assert(world.money == 10)
	_earn_to(world, world.INCOME_STEPS[1])
	assert(world.dialog.heading.text == "Skilltree verfügbar")
	_ok(world)
	world._on_skills_button_pressed()
	assert(world.build_options.current_items.size() == 2 and not world.blink_skills)
	world._on_option_clicked(0)
	world._on_option_clicked(1)
	assert(world.collector_move_speed == 110 and world.collector_capacity == 15)
	assert(world.new_skills.is_empty())
	assert(world._skill_block_reason("collector_speed") == "Maximum erreicht")
	_earn_to(world, world.INCOME_STEPS[2])
	assert(world.dialog.heading.text == "Basis-Skills verfügbar")
	_ok(world)
	_buy_id(world, "base_health")
	_buy_id(world, "cash_drone")
	assert(world.base_max_health == 125 and world.skill_levels.cash_drone == 1)
	_earn_to(world, world.INCOME_STEPS[3])
	assert(world.phase == 4 and not world.dialog_open and not paused)
	assert(world.blink_build and world._building_limit(0) == 2)
	_build(world, 0, Vector2i(-2, 2))
	world._tick_production(8.0)
	_earn_to(world, world.INCOME_STEPS[4])
	assert(world.dialog.heading.text == "Erhöhung der Abbaustufe verfügbar")
	_ok(world)
	_buy_id(world, "mining_level")
	assert(world.mining_level == 2)
	_buy_id(world, "mining_level")
	assert(world.mining_level == 2)
	_earn_to(world, world.INCOME_STEPS[5])
	assert(world.dialog.heading.text == "Verteidigung planen")
	_ok(world)
	assert(world._available_building_indices() == [0, 1, 2])
	_build(world, 1, Vector2i(0, -4))
	world._tick_production(10.0)
	_build(world, 2, Vector2i(2, 2))
	world._tick_production(6.0)
	_build(world, 2, Vector2i(-4, -2))
	world._physics_process(0.0)
	assert(world.defense_wait == -1.0)
	world._tick_production(6.0)
	world._physics_process(0.0)
	assert(world.defense_wait == 10.0 and not world.timer_started)
	world._physics_process(9.99)
	assert(not world.timer_started)
	world._physics_process(0.01)
	assert(world.timer_started and world.wave_timer.remaining == 100.0)
	assert(not world.wave_timer.timer_paused and world.wave_timer.visible)
	_earn_to(world, world.timer_income + 95)
	assert(world.dialog.heading.text == "Verteidigung upgraden")
	_ok(world)
	_buy_id(world, "barracks_health")
	_buy_id(world, "tower_health")
	_buy_id(world, "tower_rate")
	assert(world.barracks_drone_health == 40 and world.tower_health == 120 and world.tower_interval_ms == 900)
	_earn_to(world, world.timer_income + 125)
	assert(world.phase == 8 and not paused and world.new_skills.has("mining_level"))
	_buy_id(world, "mining_level")
	assert(world.mining_level == 3)
	world.wave_timer._physics_process(100.0)
	assert(world.spawned_waves == 1 and not world.wave_timer.timer_paused)
	var enemies: Array[Node2D] = world._live_combat_drones("enemy_drones")
	assert(enemies.size() == 6)
	for enemy in enemies:
		enemy.set_physics_process(false)
		enemy.take_damage(100)
	world._check_progress()
	assert(world.dialog.heading.text == "Defekte Gebäude und Einheiten")
	assert(world.workshop_unlocked and world.new_buildings.has(3))
	_ok(world)
	assert(world._available_building_indices() == [0, 1, 2, 3])
	world.wave_timer._physics_process(80.0)
	assert(world.spawned_waves == 2)
	# Selling is not counted as new income and does not re-lock any tutorial step.
	var earned_before: int = world.earned
	world.sell_building(0)
	assert(world.earned == earned_before and world._building_limit(0) == 2)
	world.queue_free()
	await process_frame
	assert(Engine.time_scale == 1.0)
	print("PASS: tutorial map/start, modal capacity guidance, income milestones, hidden/restricted menus, blink acknowledgments, upgrade caps, defense construction and delayed first wave, workshop unlock")
	quit()
