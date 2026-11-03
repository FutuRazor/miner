extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.get_node("SessionSave").storage_path = "res://.godot/session_tests/%d/game_speed_test.dat" % OS.get_process_id()
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var initial_rate := Engine.physics_ticks_per_second
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	assert(Engine.time_scale == 1.0 and world.speed_button.text == "1×")
	for frame in 4:
		await process_frame
	assert(world.speed_button.get_parent() == world.pause_button.get_parent())
	assert(world.speed_button.position.x >= world.pause_button.get_rect().end.x)
	var speeds := [1.5, 2.0, 3.0, 1.0]
	var labels := ["1,5×", "2×", "3×", "1×"]
	for index in speeds.size():
		world.speed_button.pressed.emit()
		assert(Engine.time_scale == speeds[index])
		assert(Engine.physics_ticks_per_second == roundi(initial_rate * speeds[index]))
		assert(world.speed_button.text == labels[index])
		var before: float = world.round_duration
		world._physics_process(10.0 * speeds[index])
		assert(is_equal_approx(world.round_duration - before, 10.0))
	world._set_paused(true)
	assert(world.speed_button.can_process())
	world.speed_button.pressed.emit()
	assert(paused and Engine.time_scale == 1.5)
	world._set_paused(false)
	assert(not paused and Engine.time_scale == 1.5)
	world.return_dialog_open = true
	world._update_pause_controls()
	assert(world.speed_button.disabled)
	world._cycle_game_speed()
	assert(Engine.time_scale == 1.5)
	world.return_dialog_open = false
	world.damage_base(100)
	assert(world.speed_button.disabled)
	world._cycle_game_speed()
	assert(Engine.time_scale == 1.5)
	world.queue_free()
	await process_frame
	assert(Engine.time_scale == 1.0 and Engine.physics_ticks_per_second == initial_rate)
	paused = false
	print("PASS: speed toolbar placement, exact cycle, scaled physics rate, pause, modal/game-over guard and scene cleanup")
	quit()
