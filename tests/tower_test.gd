extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame in 4:
		await process_frame


func _enemy(world: Node, point: Vector2) -> Node2D:
	var enemy = world.Drone.new()
	enemy.world = world
	enemy.hostile = true
	enemy.collector_index = -2
	enemy.max_health = 3
	enemy.position = point
	world.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy


func _projectiles(world: Node) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node in get_nodes_in_group("tower_projectiles"):
		if node.world == world and not node.is_queued_for_deletion():
			node.set_physics_process(false)
			result.append(node)
	return result


func _build(world: Node, anchor: Vector2i) -> Node2D:
	for y in 2:
		for x in 2:
			var cell := anchor + Vector2i(x, y)
			if world.block_cells.has(cell) and is_instance_valid(world.block_cells[cell]):
				world.block_cells[cell].queue_free()
	world.get_node("Player").position = Vector2(anchor) * 48
	world.selected_building = 2
	world._place_building()
	world._tick_production(10.0)
	var tower: Node2D = world.buildings[-1].tower
	tower.set_physics_process(false)
	return tower


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	assert(world.BUILDINGS[2] == "Turm" and world.tower_cost == 20)
	var tower := _build(world, Vector2i(2, 0))
	assert(world.money == 20 and tower.health == 100 and tower.max_health == 100)
	assert(tower.shots == 1 and tower.fire_interval_ms == 1000)
	var outside := _enemy(world, tower.position + Vector2(241, 0))
	tower._physics_process(2.0)
	assert(_projectiles(world).is_empty())
	var far := _enemy(world, tower.position + Vector2(220, 0))
	var nearest := _enemy(world, tower.position + Vector2(200, 0))
	assert(tower.nearest_enemy() == nearest)
	tower._physics_process(0.99)
	assert(_projectiles(world).is_empty())
	tower._physics_process(0.01)
	var bullets := _projectiles(world)
	assert(bullets.size() == 1 and bullets[0].target == nearest)
	assert(nearest.health == 3)
	var before := bullets[0].position
	bullets[0]._physics_process(0.1)
	assert(bullets[0].position != before and nearest.health == 3)
	bullets[0]._physics_process(0.5)
	assert(nearest.health == 2 and nearest.combat_target == tower)
	# Enemy retaliates against the tower's footprint, leaving base health intact.
	nearest._physics_process(1.0)
	assert(tower.health == 100)
	nearest._physics_process(0.42)
	nearest._physics_process(1.0)
	assert(tower.health == 99 and world.base_health == 100)
	world.money = 10000
	world.cleared_waves = 14
	world._on_skills_button_pressed()
	world._on_option_clicked(10)
	assert(tower.health == 119 and tower.max_health == 120)
	world._on_option_clicked(11)
	assert(tower.shots == 2)
	world._on_option_clicked(12)
	assert(tower.fire_interval_ms == 900)
	world._on_option_clicked(12)
	assert(tower.fire_interval_ms == 810 and world.money == 9765)
	assert(world.build_options.current_items[12].level == 3)
	assert(world.build_mode == world.BuildMode.SKILLS)
	world.money = 0
	world._on_option_clicked(10)
	assert(tower.max_health == 120)
	await _settle()
	tower._physics_process(0.81)
	bullets = _projectiles(world)
	assert(bullets.size() == 2)
	for bullet in bullets:
		bullet._physics_process(1.0)
	assert(nearest.dead)
	await _settle()
	assert(tower.nearest_enemy() == far)
	world.money = 25
	var future := _build(world, Vector2i(-2, 2))
	assert(future.max_health == 120 and future.health == 120)
	assert(future.shots == 2 and future.fire_interval_ms == 810)
	# Concurrent contacts deduct every damage point from the tower.
	var last_attacker: Node2D
	for index in 5:
		var attacker := _enemy(world, tower.position + Vector2(58, 0))
		last_attacker = attacker
		attacker.combat_ai.set_target(tower)
		attacker._physics_process(1.0)
	assert(tower.health == 114)
	tower.take_damage(1000)
	assert(tower.dead and world.buildings[0].destroyed)
	assert(world._can_build(Vector2i(2, 0)))
	await _settle()
	last_attacker._physics_process(0.1)
	assert(last_attacker.combat_target == null)
	assert(world._live_combat_drones("towers").size() == 1)
	assert(future.health == 120)
	print("PASS: 2x2 tower, cost 10, range 5, nearest enemy, 1s visible projectiles, retaliation, concurrent damage, global upgrades, new towers and destruction cleanup")
	world.queue_free()
	quit()
