extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame in 6:
		await process_frame


func _run() -> void:
	root.get_node("SessionSave").storage_path = "res://.godot/session_tests/%d/return_menu_test.dat" % OS.get_process_id()
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	assert(change_scene_to_file("res://scenes/main.tscn") == OK)
	await _settle()
	var world = current_scene
	var ui: CanvasLayer = world.get_node("GameUI")
	var info: Control = ui.get_node("InfoButton")
	assert(world.main_menu_button.get_rect().end.y + 8 <= info.position.y)
	world.main_menu_button.pressed.emit()
	assert(paused and world.return_dialog_open and ui.return_screen.visible)
	assert(ui.continue_button.has_focus())
	assert(not ui.pause_badge.visible and world.play_button.disabled)
	var time_before: float = world.wave_timer.remaining
	await _settle()
	assert(world.wave_timer.remaining == time_before)
	world._set_paused(false)
	assert(paused)
	var event := InputEventKey.new()
	event.keycode = KEY_B
	event.pressed = true
	ui._input(event)
	assert(world.build_mode == world.BuildMode.PLAY)
	ui.continue_button.pressed.emit()
	assert(paused and not world.return_dialog_open and not ui.return_screen.visible)
	assert(ui.pause_badge.visible and not world.play_button.disabled)
	await _settle()
	assert(world.wave_timer.remaining == time_before)
	world.play_button.pressed.emit()
	assert(not paused and not ui.pause_badge.visible)
	world.main_menu_button.pressed.emit()
	event.keycode = KEY_ESCAPE
	ui._input(event)
	assert(paused and ui.pause_badge.visible and not world.return_dialog_open)
	# Opening from an already paused game also keeps pause when cancelled.
	world.main_menu_button.pressed.emit()
	ui.continue_button.pressed.emit()
	assert(paused and ui.pause_badge.visible)
	world.main_menu_button.pressed.emit()
	ui.exit_button.pressed.emit()
	await _settle()
	assert(current_scene.name == "StartMenu" and not paused)
	assert(current_scene.get_node("Center/Menu/StartButton").has_focus())
	print("PASS: main-menu button above info, modal pauses gameplay, cancel stays paused with badge, play resumes and confirm returns to start")
	quit()
