extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	# A finished barracks supplies the defender's home for the combat AI.
	world.buildings.append({"kind": 1, "anchor": Vector2i(2, 0)})
	var defender = world.Drone.new()
	defender.world = world
	defender.passive = true
	defender.collector_index = 0
	defender.position = Vector2(520, 0)
	world.add_child(defender)
	defender.set_physics_process(false)
	var enemy = world.Drone.new()
	enemy.world = world
	enemy.hostile = true
	enemy.max_health = 3
	enemy.position = Vector2(500, 0)
	world.add_child(enemy)
	enemy.set_physics_process(false)
	defender.combat_ai.set_target(enemy)
	defender.position = Vector2(600, 0)
	defender._physics_process(0.1)
	assert(enemy.combat_target == null, "Pursuit outside melee range must not stop the enemy")
	defender.position = Vector2(520, 0)
	# Enemy moves first: the defender must catch it and engage while moving.
	enemy._physics_process(1.0 / 60.0)
	defender._physics_process(1.0 / 60.0)
	assert(enemy.combat_target == defender, "A moving enemy must engage its interceptor before the first damage tick")
	var intercepted_at: Vector2 = enemy.position
	var urgent = world.Drone.new()
	urgent.world = world
	urgent.hostile = true
	urgent.max_health = 3
	urgent.position = Vector2(90, 0)
	world.add_child(urgent)
	urgent.set_physics_process(false)
	world._assign_combat_targets()
	assert(defender.combat_target == enemy, "Assignments must preserve an ongoing melee")
	urgent.queue_free()
	for frame in 59:
		enemy._physics_process(1.0 / 60.0)
		defender._physics_process(1.0 / 60.0)
	assert(enemy.health == 3, "Contact still requires the normal one-second attack interval")
	enemy._physics_process(1.0 / 60.0)
	defender._physics_process(1.0 / 60.0)
	assert(enemy.health == 2 and defender.health == 29)
	assert(enemy.position.is_equal_approx(intercepted_at))
	assert(world.base_health == 100)
	for frame in 120:
		if not enemy.dead:
			enemy._physics_process(1.0 / 60.0)
		defender._physics_process(1.0 / 60.0)
	assert(enemy.dead)
	# Also cover the reverse processing order: defender before enemy.
	var next_enemy = world.Drone.new()
	next_enemy.world = world
	next_enemy.hostile = true
	next_enemy.position = Vector2(500, 0)
	world.add_child(next_enemy)
	next_enemy.set_physics_process(false)
	defender.position = Vector2(480, 0)
	defender.combat_ai.set_target(next_enemy)
	defender._physics_process(1.0 / 60.0)
	next_enemy._physics_process(1.0 / 60.0)
	assert(next_enemy.combat_target == defender)
	assert(next_enemy.position == Vector2(500, 0))
	world.queue_free()
	print("PASS: moving interception, immediate engagement, stable melee assignment and normal damage interval")
	quit()
