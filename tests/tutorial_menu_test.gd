extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _settle() -> void:
	for frame in 4:
		await process_frame

func _click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await process_frame
	await process_frame
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = point
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func _run() -> void:
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.size = Vector2i(1152, 720)
	root.get_node("MetaStats").persistence_enabled = false
	assert(change_scene_to_file("res://scenes/start_menu.tscn") == OK)
	await _settle()
	var menu := current_scene
	var buttons := menu.get_node("Center/Menu")
	assert(buttons.get_child(0).name == "StartButton")
	assert(buttons.get_child(1).name == "TutorialButton")
	assert(buttons.get_child(2).name == "StatsButton")
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_S
	menu._unhandled_key_input(event)
	assert(buttons.get_child(1).has_focus())
	menu._unhandled_key_input(event)
	assert(buttons.get_child(2).has_focus())
	buttons.get_child(1).pressed.emit()
	await _settle()
	var world = current_scene
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	assert(world.name == "Tutorial" and world.scene_file_path == "res://scenes/tutorial.tscn")
	var actions := world.get_node("GameUI/MenuDock/ActionMenu")
	assert(not actions.visible)
	world.collected_count = 10
	world._check_progress()
	await _settle()
	assert(world.dialog_open and paused and world.dialog.ok.has_focus())
	assert(world.dialog.ok.get_global_rect().end.y <= root.get_visible_rect().size.y)
	var progress: float = world.wave_timer.remaining
	await _click(world.play_button.get_global_rect().get_center())
	assert(paused and world.dialog_open)
	await _click(world.dialog.ok.get_global_rect().get_center())
	await _settle()
	assert(not paused and not world.dialog_open and world.wave_timer.remaining == progress)
	world.collected_count = 0
	world.receive_income(20)
	world._check_progress()
	await _settle()
	assert(actions.visible and not actions.get_node("Margin/Rows/SkillsRow").visible)
	assert(world.blink_build)
	await _click(world.dialog.ok.get_global_rect().get_center())
	await _settle()
	await _click(actions.get_node("Margin/Rows/BuildRow/Build").get_global_rect().get_center())
	await _settle()
	assert(not world.blink_build and world.build_options.rows.size() == 1)
	assert(world.build_panel.get_global_rect().end.y <= root.get_visible_rect().size.y)
	await _click(world.build_options.rows[0].button.get_global_rect().get_center())
	assert(world.build_mode == world.BuildMode.PLACE and not world.new_buildings.has(0))
	# A retry must start this tutorial, with its original restrictions and money.
	world.damage_base(100)
	world.game_over_screen._retry()
	await _settle()
	assert(current_scene.name == "Tutorial" and current_scene.money == 20)
	assert(current_scene.phase == 0 and current_scene.wave_timer.timer_paused and not paused)
	current_scene.get_node("GameUI")._return_to_start()
	await _settle()
	assert(current_scene.name == "StartMenu" and not paused)
	print("PASS: tutorial start-menu order/navigation, actual modal OK and background blocking, blink clicks, stage-preserving retry and exit")
	quit()
