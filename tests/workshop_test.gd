extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _build(world: Node, kind: int, anchor: Vector2i) -> void:
	for y in 2:
		for x in 2:
			var cell := anchor + Vector2i(x, y)
			if world.block_cells.has(cell) and is_instance_valid(world.block_cells[cell]):
				world.block_cells[cell].queue_free()
	world.get_node("Player").position = Vector2(anchor) * 48
	world.selected_building = kind
	world._place_building()

func _buy(world: Node, index: int) -> void:
	world.selected_skill = index
	world._confirm_skill()

func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	world.money = 10000
	assert(world._building_cost(3) == 180 and world._building_limit(3) == 1)
	_build(world, 3, Vector2i(2, 0))
	assert(world.money == 9820 and not world.buildings[0].has("main_drone"))
	_build(world, 3, Vector2i(-2, 2))
	assert(world.buildings.size() == 1)
	world._tick_production(14.0)
	assert(not world.buildings[0].has("main_drone"))
	world._tick_production(1.0)
	var mechanic: Node2D = world.buildings[0].main_drone
	mechanic.set_physics_process(false)
	assert(mechanic.mechanic and mechanic.speed == 100)
	_build(world, 2, Vector2i(-2, 2))
	world._tick_production(6.0)
	var tower: Node2D = world.buildings[1].tower
	tower.set_physics_process(false)
	_build(world, 1, Vector2i(0, -4))
	world._tick_production(10.0)
	var defender: Node2D = world.buildings[2].main_drone
	for drone in world._live_combat_drones("friendly_drones"):
		drone.set_physics_process(false)
	defender.health = 20
	tower.health = 90
	world.base_health = 90
	mechanic.position = Vector2.ZERO
	mechanic._physics_process(0.99)
	assert(world.base_health == 90 and mechanic.mechanic_ai.repair_target == world)
	mechanic._physics_process(0.01)
	assert(world.base_health == 91 and tower.health == 90 and defender.health == 20)
	mechanic.position = Vector2(1000, 1000)
	mechanic._physics_process(1.0)
	assert(world.base_health == 91, "Repairs require arrival at the target")
	world.base_health = world.base_max_health
	mechanic.position = tower.position
	mechanic._physics_process(1.0)
	assert(tower.health == 91 and defender.health == 20)
	assert(mechanic.mechanic_ai.repair_target == tower)
	# New base damage interrupts a lower-priority repair immediately.
	world.base_health -= 1
	mechanic._physics_process(0.1)
	assert(mechanic.mechanic_ai.repair_target == world)
	world.base_health = world.base_max_health
	tower.health = tower.max_health
	mechanic.position = defender.position
	mechanic._physics_process(1.0)
	assert(defender.health == 21)
	# A drone in its barracks footprint but returning home is still moving.
	defender.position += Vector2(5, 0)
	mechanic._physics_process(2.0)
	assert(defender.health == 21 and mechanic.mechanic_ai.repair_target == null)
	defender.position = Vector2(world.buildings[2].anchor) * world.CELL
	defender.is_moving = true
	mechanic._physics_process(2.0)
	assert(defender.health == 21)
	defender.is_moving = false
	mechanic.position = defender.position
	mechanic._physics_process(0.5)
	defender.position += Vector2(150, 0)
	mechanic._physics_process(0.5)
	assert(defender.health == 21 and mechanic.mechanic_ai.elapsed == 0.0)
	defender.position = Vector2(world.buildings[2].anchor) * world.CELL
	mechanic.position = defender.position
	mechanic._physics_process(0.5)
	assert(defender.health == 21)
	mechanic._physics_process(0.5)
	assert(defender.health == 22)
	assert(world._skill_block_reason("workshop_drones") == "Freischaltung nach Welle 9")
	world.cleared_waves = 8
	_buy(world, 13)
	_buy(world, 14)
	assert(world.workshop_drone_count == 1 and world.workshop_repair == 1)
	world.cleared_waves = 9
	_buy(world, 13)
	_buy(world, 14)
	assert(world.workshop_drone_count == 2 and world.workshop_repair == 2)
	assert(world.buildings[0].pending_drones == 1)
	world._tick_production(20.0)
	assert(world._live_combat_drones("friendly_drones").filter(func(drone: Node2D) -> bool: return drone.mechanic).size() == 2)
	assert(world._skill_block_reason("workshop_drones") == "Freischaltung nach Welle 14")
	world.cleared_waves = 14
	_buy(world, 13)
	_buy(world, 14)
	for purchase in 4:
		_buy(world, 15)
	assert(world.workshop_speed == 160 and mechanic.speed == 160)
	assert(world.workshop_drone_count == 3 and world.workshop_repair == 3)
	assert(world._skill_block_reason("workshop_repair") == "Maximum erreicht")
	# Removing a damaged target while a mechanic is en route must retarget safely.
	world.base_health = world.base_max_health
	tower.health -= 1
	mechanic._physics_process(0.1)
	assert(mechanic.mechanic_ai.repair_target == tower)
	world.sell_building(1)
	mechanic._physics_process(0.1)
	assert(mechanic.mechanic_ai.repair_target != tower)
	world.base_health = world.base_max_health - 1
	mechanic.position = Vector2.ZERO
	mechanic._physics_process(1.0)
	assert(world.base_health == world.base_max_health)
	world.sell_building(0)
	assert(world._building_count(3) == 0)
	world._tick_production(60.0)
	assert(world._live_combat_drones("friendly_drones").filter(func(drone: Node2D) -> bool: return drone.mechanic).is_empty())
	_build(world, 3, Vector2i(2, 0))
	world._tick_production(15.0)
	assert(world._building_count(3) == 1 and world.buildings[-1].main_drone.speed == 160)
	assert(world._live_combat_drones("friendly_drones").filter(func(drone: Node2D) -> bool: return drone.mechanic).size() == 3)
	world.queue_free()
	print("PASS: unique workshop, construction, repair priorities/rate, stationary barracks eligibility, interruption, upgrade gates/caps and sale/rebuild")
	quit()
