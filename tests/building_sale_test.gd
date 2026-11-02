extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _settle() -> void:
	for frame in 4:
		await process_frame

func _click(point: Vector2, button: MouseButton) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = button
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func _build(world: Node, kind: int, anchor: Vector2i) -> void:
	for y in 2:
		for x in 2:
			var cell := anchor + Vector2i(x, y)
			if world.block_cells.has(cell) and is_instance_valid(world.block_cells[cell]):
				world.block_cells[cell].queue_free()
	world.selected_building = kind
	world.get_node("Player").position = Vector2(anchor) * 48
	world._place_building()
	world._tick_production(10.0)

func _run() -> void:
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.money = 1000
	_build(world, 0, Vector2i(2, 0))
	_build(world, 1, Vector2i(-2, 2))
	_build(world, 2, Vector2i(0, -4))
	world.get_node("Player").position = Vector2.ZERO
	var camera: Camera2D = world.get_node("Player/Camera2D")
	camera.reset_smoothing()
	camera.force_update_scroll()
	await _settle()
	var menu = world.building_context
	var point: Vector2 = world.get_global_transform_with_canvas() * world.building_rect(0).get_center()
	_click(point, MOUSE_BUTTON_RIGHT)
	await _settle()
	assert(menu.visible and menu.building_index == 0 and menu.title.text == "Sammler")
	assert(menu.details.text.contains("Drohnen: 1"))
	assert(not menu.get_global_rect().intersects(Rect2(point - Vector2.ONE * 10, Vector2.ONE * 20)))
	_click(menu.demolish.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _settle()
	assert(menu.confirmation.visible)
	_click(menu.no.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _settle()
	assert(not menu.confirmation.visible and not world.buildings[0].get("destroyed", false))
	_click(Vector2(900, 100), MOUSE_BUTTON_LEFT)
	assert(not menu.visible and not world.mouse_goal_active)
	# Keep earned resources and cancel cash assignments to a sold collector.
	world.buildings[0].money = 7
	world.buildings[0].main_drone.carried = 3
	world._spawn_collector_drone(world.BASE_HOME)
	var cash: Node2D = world.base_drone_settings.main_drone
	cash.set_physics_process(false)
	cash.cash_source = 0
	cash.path.assign([Vector2(96, 0)])
	world.money = 0
	menu.open(0)
	menu.demolish.pressed.emit()
	menu.yes.pressed.emit()
	assert(world.money == 32 and not menu.visible)
	assert(world.buildings[0].destroyed and world._can_build(Vector2i(2, 0)))
	assert(world._building_count(0) == 0 and world._building_cost(0) == 30)
	assert(cash.cash_source == -1 and cash.path.is_empty())
	world.sell_building(0)
	assert(world.money == 32)
	world._queue_drone(0)
	assert(world.buildings[0].pending_drones == 0)
	world.sell_building(1)
	assert(world.money == 50 and world._live_combat_drones("barracks_drones").is_empty())
	world._tick_production(60.0)
	assert(world._live_combat_drones("barracks_drones").is_empty())
	world.sell_building(2)
	assert(world.money == 65 and world._live_combat_drones("towers").is_empty())
	await _settle()
	# Rebuilding keeps global upgrades and pays back the actual price only once.
	world.money = 1000
	world.collector_capacity = 25
	_build(world, 0, Vector2i(2, 0))
	assert(world.buildings[3].main_drone.capacity == 25)
	assert(world.building_refund(3) == 22)
	# Selling unfinished construction must cancel its eventual completion.
	world.get_node("Player").position = Vector2(-96, 96)
	world.selected_building = 0
	world._place_building()
	assert(world.buildings[4].paid_cost == 50)
	assert(world.building_refund(4) == 37)
	world._set_paused(true)
	menu.open(4)
	assert(menu.can_process())
	world.sell_building(4)
	assert(paused and not menu.visible)
	world._set_paused(false)
	world._tick_production(60.0)
	assert(not world.buildings[4].has("main_drone"))
	world.queue_free()
	print("PASS: building right-click menu, confirmation/cancel/outside dismissal, 75% refunds, inventory, cleanup, stable indices and rebuild")
	quit()
