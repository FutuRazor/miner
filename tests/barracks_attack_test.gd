extends "res://tests/workshop_test.gd"

func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	world.money = 1000
	_build(world, 1, Vector2i(2, 0))
	world._tick_production(10.0)
	var defender: Node2D = world.buildings[0].main_drone
	for drone in world._live_combat_drones("friendly_drones"):
		drone.set_physics_process(false)
	assert(world.SKILLS[8].id == "barracks_attack")
	for skill in world.SKILLS:
		assert(not (skill.group == "Kaserne" and skill.name == "Verteidigung"))
	var enemy = world.Drone.new()
	enemy.world = world
	enemy.hostile = true
	enemy.max_health = 10
	enemy.position = defender.position + Vector2(20, 0)
	world.add_child(enemy)
	enemy.set_physics_process(false)
	defender.combat_ai.set_target(enemy)
	defender._physics_process(0.99)
	assert(enemy.health == 10)
	defender._physics_process(0.01)
	assert(enemy.health == 9)
	world.cleared_waves = 12
	assert(world._skill_block_reason("barracks_attack") == "Freischaltung nach Welle 13")
	_buy(world, 8)
	assert(world.barracks_attack == 1)
	world.cleared_waves = 13
	world.money = 249
	_buy(world, 8)
	assert(world.barracks_attack == 1 and world.money == 249)
	world.money = 250
	_buy(world, 8)
	assert(world.barracks_attack == 2 and defender.attack_damage == 2 and world.money == 0)
	defender._physics_process(1.0)
	assert(enemy.health == 7 and enemy.attack_damage == 1)
	world.money = 1000
	_buy(world, 8)
	assert(world.money == 1000 and world._skill_block_reason("barracks_attack") == "Maximum erreicht")
	_build(world, 1, Vector2i(-2, 2))
	world._tick_production(10.0)
	assert(world.buildings[1].main_drone.attack_damage == 2)
	defender.take_damage(100)
	world._tick_production(20.0)
	for drone in world._live_combat_drones("barracks_drones"):
		assert(drone.attack_damage == 2)
	world._on_skills_button_pressed()
	assert(world.build_options.current_items[8].current_effect == "2 Schaden je Treffer")
	world.queue_free()
	print("PASS: removed defense entry, attack unlock after wave 13, price/cap, 1-to-2 actual damage and new/replacement inheritance")
	quit()
