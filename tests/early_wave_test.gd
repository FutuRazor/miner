extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame in 4:
		await process_frame


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	assert(change_scene_to_file("res://scenes/main.tscn") == OK)
	await _settle()
	var world = current_scene
	world.set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	var clock = world.wave_timer
	var button = world.wave_start_button
	clock.remaining = 47.8
	clock._refresh()
	assert(button.visible and not button.disabled and "47" in button.text)
	assert(button.get_rect().position.x > clock.get_rect().end.x)
	var before: int = world.money
	button.pressed.emit()
	assert(world.money == before + 47 and world.total_revenue == 47)
	assert(world.spawned_waves == 1 and clock.next_wave == 2 and clock.remaining == 80.0)
	assert(world._live_combat_drones("enemy_drones").size() == 6)
	world._set_paused(true)
	assert(button.disabled)
	button.pressed.emit()
	assert(world.spawned_waves == 1 and world.money == before + 47)
	world._set_paused(false)
	world._set_wave_timer_paused(true)
	assert(button.disabled)
	button.pressed.emit()
	assert(world.spawned_waves == 1)
	world._set_wave_timer_paused(false)
	world._cycle_game_speed()
	world._cycle_game_speed()
	world._cycle_game_speed()
	assert(Engine.time_scale == 3.0)
	clock.remaining = 12.9
	button.pressed.emit()
	assert(world.spawned_waves == 2 and world.total_revenue == 59)
	assert(world._live_combat_drones("enemy_drones").size() == 14)
	clock._physics_process(80.0)
	assert(world.spawned_waves == 3 and world.total_revenue == 59)
	world.spawned_waves = 9
	clock.next_wave = 10
	clock.remaining = 0.9
	button.pressed.emit()
	assert(world.spawned_waves == 10 and world.wave_alive[10] == 1)
	assert(world.total_revenue == 59)
	world.spawned_waves = 19
	clock.next_wave = 20
	clock.remaining = 30.0
	button.pressed.emit()
	assert(world.spawned_waves == 20 and world.wave_alive[20] == 1)
	assert(not button.visible and world.total_revenue == 89)
	button.pressed.emit()
	assert(world.spawned_waves == 20 and world.total_revenue == 89)
	world._end_game(true)
	world.continue_endless()
	assert(button.visible and not button.disabled)
	button.pressed.emit()
	assert(world.spawned_waves == 21 and clock.next_wave == 22)
	assert(world.total_revenue == 169)
	world.damage_base(100)
	assert(button.disabled)
	button.pressed.emit()
	assert(world.spawned_waves == 21 and world.total_revenue == 169)
	paused = false
	assert(change_scene_to_file("res://scenes/tutorial.tscn") == OK)
	await _settle()
	assert(not current_scene.wave_start_button.visible)
	print("PASS: early wave bonus, flooring, speed independence, countdown reset, overlapping waves, pause guards, bosses, final cap, endless and tutorial exclusion")
	quit()
