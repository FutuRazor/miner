extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _settle() -> void:
	for frame in 4:
		await process_frame

func _run() -> void:
	root.get_node("SessionSave").storage_path = "res://.godot/session_tests/%d/options_menu_test.dat" % OS.get_process_id()
	root.get_node("MetaStats").persistence_enabled = false
	var localization := root.get_node("Localization")
	localization.persistence_enabled = false
	assert(localization.set_language("en"))
	assert(change_scene_to_file("res://scenes/start_menu.tscn") == OK)
	await _settle()
	var menu := current_scene
	var buttons := menu.get_node("Center/Menu")
	assert(buttons.get_child(5).name == "OptionsButton")
	assert(buttons.get_child(5).text == "Optionen")
	buttons.get_child(4).grab_focus()
	var event := InputEventKey.new()
	event.keycode = KEY_S
	event.pressed = true
	menu._unhandled_key_input(event)
	assert(buttons.get_child(5).has_focus())
	buttons.get_child(5).pressed.emit()
	await _settle()
	assert(current_scene.name == "Options")
	assert(current_scene.title.text == "OPTIONS")
	assert(current_scene.language_picker.item_count == 2)
	assert(current_scene.language_picker.get_item_text(0) == "English")
	assert(current_scene.language_picker.get_item_text(1) == "Deutsch")
	assert(current_scene.language_label.text == "Language")
	assert(current_scene.language_picker.has_focus())
	event.keycode = KEY_E
	current_scene._unhandled_key_input(event)
	assert(current_scene.language_picker.get_popup().visible)
	current_scene.language_picker.get_popup().hide()
	current_scene.language_picker.item_selected.emit(1)
	assert(localization.language == "de")
	assert(current_scene.language_picker.selected == 1)
	assert(current_scene.title.text == "OPTIONEN" and current_scene.language_label.text == "Sprache")
	current_scene.language_picker.item_selected.emit(0)
	assert(localization.language == "en" and current_scene.title.text == "OPTIONS")
	event.keycode = KEY_ESCAPE
	current_scene._unhandled_key_input(event)
	await _settle()
	assert(current_scene.name == "StartMenu" and not paused)
	assert(current_scene.get_node("Center/Menu/StartButton").has_focus())
	print("PASS: options menu entry/order, keyboard navigation, English/German selector and live translation, selection and Escape back")
	quit()
