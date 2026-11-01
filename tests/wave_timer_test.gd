extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	var clock: ProgressBar = world.wave_timer
	clock.set_physics_process(false)
	assert(clock.remaining == 100.0 and clock.next_wave == 1)
	assert(clock.caption.text == "Zeit bis Welle 1 · 100 s")
	clock._physics_process(99.0)
	assert(clock.remaining == 1.0 and world._live_combat_drones("enemy_drones").is_empty())
	clock._physics_process(1.0)
	assert(world._live_combat_drones("enemy_drones").size() == 10)
	assert(clock.next_wave == 2 and clock.remaining == 100.0)
	world.wave_pause_button.button_pressed = true
	clock._physics_process(200.0)
	assert(clock.timer_paused and clock.remaining == 100.0 and clock.next_wave == 2)
	assert(clock.caption.text.contains("Pause"))
	assert(not paused)
	world.wave_pause_button.button_pressed = false
	clock._physics_process(250.0)
	assert(clock.next_wave == 4 and clock.remaining == 50.0)
	assert(world._live_combat_drones("enemy_drones").size() == 30)
	world.pause_button.pressed.emit()
	clock._physics_process(20.0)
	assert(clock.remaining == 50.0)
	world.wave_pause_button.button_pressed = true
	world.play_button.pressed.emit()
	clock._physics_process(20.0)
	assert(clock.remaining == 50.0 and not paused)
	world.wave_pause_button.button_pressed = false
	clock._physics_process(5.0)
	assert(clock.remaining == 45.0)
	for frame in 4:
		await process_frame
	var rect: Rect2 = clock.get_global_rect()
	assert(is_equal_approx(rect.get_center().x, root.get_visible_rect().size.x / 2.0))
	var info: Control = world.get_node("GameUI/InfoButton")
	assert(world.wave_pause_button.position.y >= info.get_rect().end.y + 8)
	assert(not world.get_node("GameUI").has_node("TestWaveButton"))
	world.damage_base(100)
	clock._physics_process(1000.0)
	assert(clock.next_wave == 4 and world.wave_pause_button.disabled)
	print("PASS: 100s countdown, numbered automatic waves of 10, timer-only pause, global pause, resume, placement and game-over stop")
	world.queue_free()
	quit()
