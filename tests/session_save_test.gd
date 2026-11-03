extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame in 4:
		await process_frame


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var save = root.get_node("SessionSave")
	save.storage_path = "res://.godot/session_tests/%d/mission.dat" % OS.get_process_id()
	assert(change_scene_to_file("res://scenes/start_menu.tscn") == OK)
	await _settle()
	assert(current_scene.get_node("Center/Menu/ContinueButton").disabled)
	current_scene._start_game()
	await _settle()
	var world = current_scene
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	world.money = 9999
	world.cleared_waves = 19
	for kind in 4:
		world.selected_building = kind
		world.get_node("Player").position = Vector2(144 + kind * 144, 0)
		var anchor: Vector2i = world._build_anchor()
		for x in 2:
			for y in 2:
				var cell := anchor + Vector2i(x, y)
				if is_instance_valid(world.block_cells.get(cell)):
					world.block_cells[cell].free()
		world._place_building()
	world._tick_production(20.0)
	world.buildings[0].money = 33
	world.buildings[1].pending_drones = 1
	world.buildings[1].production = 3.5
	world.buildings[2].tower.health = 77
	world.buildings[2].tower.elapsed = 0.3
	world.spawned_waves = 19
	world.spawn_enemy_wave()
	var boss = world._live_combat_drones("enemy_drones")[0]
	boss.position = Vector2(800, 300)
	boss.take_damage(25)
	boss._spawn_swarmers()
	boss.swarmer_timer.start(2.5)
	var miner = world.buildings[0].main_drone
	miner.carried = 3
	miner.returning = true
	miner.path.assign([Vector2(150, 10), Vector2(155, 15)])
	var defender = world.buildings[1].main_drone
	defender.combat_ai.set_target(boss)
	defender.combat_ai.contact_time = 0.25
	var mechanic = world.buildings[3].main_drone
	mechanic.mechanic_ai.repair_target = world
	mechanic.mechanic_ai.elapsed = 0.3
	var projectile = load("res://scripts/tower_projectile.gd").new()
	projectile.world = world
	projectile.source = world.buildings[2].tower
	projectile.target = boss
	projectile.position = Vector2(400, 300)
	world.add_child(projectile)
	var block = world.block_cells[Vector2i(-3, 0)]
	block.completed_steps = 2
	block.progress = 0.45
	world.get_node("Player").mining_target = block
	world.get_node("Player").position = Vector2(99, 25)
	world.get_node("Player").capacity = 20
	world.collected_count = 4
	world.base_health = 63
	world.wave_timer.remaining = 31.25
	world.wave_timer.next_wave = 21
	world.round_duration = 125.75
	world.total_revenue = 234
	world.enemies_neutralized = 45
	world._cycle_game_speed()
	var money: int = world.money
	var friendly_count: int = world._live_combat_drones("friendly_drones").size()
	world.get_node("GameUI").open_return_dialog()
	world.get_node("GameUI").confirm_return()
	await _settle()
	assert(current_scene.name == "StartMenu" and save.has_save())
	assert(not current_scene.get_node("Center/Menu/ContinueButton").disabled)
	current_scene._start_game()
	assert(current_scene.new_game_dialog.visible)
	current_scene.new_game_dialog.hide()
	current_scene._continue_game()
	await _settle()
	world = current_scene
	assert(world.name == "Miner" and paused)
	assert(world.get_node("GameUI").pause_badge.visible and not world.return_dialog_open)
	assert(world.money == money and world.base_health == 63 and world.collected_count == 4)
	assert(world.round_duration == 125.75 and world.total_revenue == 234)
	assert(world.enemies_neutralized == 45 and world.spawned_waves == 20 and world.cleared_waves == 19)
	assert(world.wave_timer.remaining == 31.25 and world.wave_timer.next_wave == 21)
	assert(Engine.time_scale == 1.5)
	assert(world.get_node("Player").position == Vector2(99, 25))
	assert(world.get_node("Player").capacity == 20)
	assert(world.block_cells[Vector2i(-3, 0)].completed_steps == 2)
	assert(is_equal_approx(world.block_cells[Vector2i(-3, 0)].progress, 0.45))
	assert(world.get_node("Player").mining_target == world.block_cells[Vector2i(-3, 0)])
	assert(world.buildings.size() == 4 and world.buildings[0].money == 33)
	assert(world.buildings[1].pending_drones == 1 and world.buildings[1].production == 3.5)
	assert(world.buildings[2].tower.health == 77)
	assert(world._live_combat_drones("friendly_drones").size() == friendly_count)
	var restored_boss = world.get_node("FinalBoss")
	assert(restored_boss.health == 325 and restored_boss.swarmers.size() == 3)
	assert(is_equal_approx(restored_boss.swarmer_timer.time_left, 2.5))
	assert(world.buildings[0].main_drone.carried == 3 and world.buildings[0].main_drone.returning)
	assert(world.buildings[0].main_drone.path.size() == 2)
	assert(world.buildings[1].main_drone.combat_target == restored_boss)
	assert(world.buildings[1].main_drone.combat_ai.contact_time == 0.25)
	assert(world.buildings[3].main_drone.mechanic_ai.repair_target == world)
	var projectiles := get_nodes_in_group("tower_projectiles")
	assert(projectiles.size() == 1 and projectiles[0].source == world.buildings[2].tower)
	assert(projectiles[0].target == restored_boss)
	assert(restored_boss.swarmer_timer.wait_time == 5.0)
	await _settle()
	assert(world.round_duration == 125.75 and restored_boss.position == Vector2(800, 300))
	# Resume the restored simulation: timers, construction and AI must keep working.
	world._set_paused(false)
	await physics_frame
	world._set_paused(true)
	assert(save.save_world(world))
	assert(save.has_save())
	world.damage_base(100)
	assert(not save.has_save())
	world.game_over_screen._main_menu()
	await _settle()
	assert(current_scene.get_node("Center/Menu/ContinueButton").disabled)
	# Confirming New Game replaces the saved mission with a fresh run.
	current_scene._start_game()
	await _settle()
	world = current_scene
	world._set_paused(true)
	assert(save.save_world(world))
	assert(change_scene_to_file("res://scenes/start_menu.tscn") == OK)
	paused = false
	await _settle()
	current_scene._start_game()
	assert(current_scene.new_game_dialog.visible)
	current_scene.new_game_dialog.confirmed.emit()
	await _settle()
	assert(current_scene.name == "Miner" and not save.has_save())
	assert(current_scene.money == 40 and current_scene.spawned_waves == 0)
	# A completed mission also clears the slot before Endless Freeplay.
	assert(save.save_world(current_scene))
	current_scene._end_game(true)
	assert(not save.has_save())
	print("PASS: durable full mission snapshot, new-game confirmation, paused resume, entities, buildings, boss/swarm timer, mining, economy, statistics and defeat cleanup")
	quit()
