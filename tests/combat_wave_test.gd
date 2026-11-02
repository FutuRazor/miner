extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame in 4:
		await process_frame


func _run() -> void:
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	await _settle()
	assert(not world.get_node("GameUI").has_node("TestWaveButton"))
	world.spawn_enemy_wave()
	var enemies: Array[Node2D] = world._live_combat_drones("enemy_drones")
	assert(enemies.size() == 6)
	assert(world.drone_count_label.text == "Drohnen: 0" and world.enemy_count_label.text == "Gegner: 6")
	var edge: float = (world.RADIUS + 0.5) * world.CELL
	var first_position := enemies[0].position
	var varied := false
	for enemy in enemies:
		enemy.set_physics_process(false)
		assert(enemy.health == 3 and enemy.max_health == 3 and enemy.speed == 100)
		assert(is_equal_approx(absf(enemy.position.x), edge) or is_equal_approx(absf(enemy.position.y), edge))
		var before: float = world._base_distance(enemy.position)
		enemy._physics_process(0.1)
		assert(world._base_distance(enemy.position) < before)
		varied = varied or enemy.position.distance_to(first_position) > 20
		enemy.position = Vector2(82, 0)
	assert(varied)
	# Ten independent timers: no lost hits, including several elapsed seconds.
	for enemy in enemies:
		enemy._physics_process(0.99)
	assert(world.base_health == 100)
	for enemy in enemies:
		enemy._physics_process(0.01)
	assert(world.base_health == 94)
	for enemy in enemies:
		enemy._physics_process(2.0)
	assert(world.base_health == 82)
	assert(world.block_cells[Vector2i(22, 0)].completed_steps == 0)
	# Add two defenders; similarly urgent threats from different directions split them.
	world.barracks_cost = 0
	for cell in [Vector2i(3, 0), Vector2i(3, 1)]:
		world.block_cells[cell].queue_free()
	world.get_node("Player").position = Vector2(96, 0)
	world.selected_building = 1
	world._place_building()
	world._tick_production(10.0)
	world._on_skills_button_pressed()
	world._on_option_clicked(6)
	var defenders: Array[Node2D] = world._live_combat_drones("barracks_drones")
	assert(defenders.size() == 2)
	for defender in defenders:
		defender.set_physics_process(false)
	enemies[0].position = Vector2(180, 0)
	enemies[1].position = Vector2(-190, 0)
	for index in range(2, 6):
		enemies[index].position = Vector2(1000, 500 + index * 10)
	world._assign_combat_targets()
	assert(defenders[0].combat_target == enemies[0])
	assert(defenders[1].combat_target == enemies[1])
	var defender := defenders[0]
	var enemy := enemies[0]
	defender.position = enemy.position - Vector2(20, 0)
	defender._physics_process(0.99)
	assert(enemy.health == 3)
	defender._physics_process(0.01)
	assert(enemy.health == 2 and enemy.combat_target == defender)
	assert(enemy.status.text == "Lebenspunkte\n2/3")
	var base_before: int = world.base_health
	enemy._physics_process(1.0)
	assert(defender.health == 29 and world.base_health == base_before)
	# All ten enemies can damage the same defender in the same simulated second.
	for attacker in enemies:
		attacker.position = defender.position + Vector2(20, 0)
		attacker.combat_ai.set_target(defender)
		attacker._physics_process(1.0)
	assert(defender.health == 23)
	# Enemy death is permanent; defenders retarget safely after the node is freed.
	enemy.take_damage(2, defender)
	assert(enemy.dead and enemy.is_queued_for_deletion())
	await _settle()
	assert(not is_instance_valid(enemy))
	assert(world._live_combat_drones("enemy_drones").size() == 5)
	var remaining: Array[Node2D] = world._live_combat_drones("enemy_drones")
	remaining[0].position = Vector2(100, 0)
	for index in range(1, remaining.size()):
		remaining[index].position = Vector2(500, 300 + index * 20)
	world._assign_combat_targets()
	assert(defender.combat_target == remaining[0])
	defender._physics_process(0.1)
	# Friendly death still restores the barracks limit with full health.
	defender.take_damage(100)
	await _settle()
	assert(world._live_combat_drones("barracks_drones").size() == 1)
	world._tick_production(20.0)
	assert(world._live_combat_drones("barracks_drones").size() == 2)
	assert(world.drone_count_label.text == "Drohnen: 2")
	assert(world.enemy_count_label.text == "Gegner: 5")
	# The last base hit ends the game and prevents more test waves.
	world.base_health = 1
	var last := remaining[0]
	last.combat_ai.set_target(null)
	last.position = Vector2(82, 0)
	last._physics_process(1.0)
	assert(world.is_game_over and paused)
	world.spawn_enemy_wave()
	assert(world._live_combat_drones("enemy_drones").size() == 5)
	print("PASS: random edge wave, flight, 10 concurrent base hits, interval catch-up, direction spread, retaliation, concurrent defender hits, permanent enemy death, retarget, respawn and game over")
	world.queue_free()
	quit()
