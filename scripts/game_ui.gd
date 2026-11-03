extends CanvasLayer

var world: Node2D
var return_layer: CanvasLayer
var return_screen: ColorRect
var pause_badge: CenterContainer
var exit_button: Button
var continue_button: Button
var changing_scene := false


func _ready() -> void:
	world = get_parent()
	_create_return_dialog()


func _input(event: InputEvent) -> void:
	if world.return_dialog_open:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				cancel_return()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_E:
				var focused := get_viewport().gui_get_focus_owner()
				if focused == exit_button or focused == continue_button:
					focused.pressed.emit()
					get_viewport().set_input_as_handled()
		return
	if get_tree().paused and not world.is_game_over:
		# Gameplay stays paused; only the world's existing menu/input handlers run.
		world._input(event)


func _unhandled_input(event: InputEvent) -> void:
	if not get_tree().paused or world.is_game_over or world.return_dialog_open:
		return
	var camera_gesture: bool = (event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]) or (event is InputEventMouseMotion and world.camera_drag_held)
	var placement: bool = world.build_mode == world.BuildMode.PLACE and world.mouse_placement
	var placement_release: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and world.suppress_left_release
	if camera_gesture or placement or placement_release:
		world._unhandled_input(event)
		if camera_gesture:
			var camera: Camera2D = world.get_node("Player/Camera2D")
			camera.reset_smoothing()
			camera.force_update_scroll()


func _process(_delta: float) -> void:
	if get_tree().paused and not world.is_game_over and world.build_mode == world.BuildMode.PLACE:
		world._update_build_ui()


func _create_return_dialog() -> void:
	pause_badge = CenterContainer.new()
	pause_badge.name = "PauseBadge"
	pause_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_badge.z_index = 200
	add_child(pause_badge)
	pause_badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var badge_panel := PanelContainer.new()
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_badge.add_child(badge_panel)
	var badge_label := Label.new()
	badge_label.text = tr("Pause")
	badge_label.custom_minimum_size = Vector2(120, 48)
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_label.add_theme_font_size_override("font_size", 24)
	badge_panel.add_child(badge_label)
	pause_badge.hide()
	return_layer = CanvasLayer.new()
	return_layer.layer = 50
	add_child(return_layer)
	return_screen = ColorRect.new()
	return_screen.color = Color(0.03, 0.05, 0.08, 0.7)
	return_layer.add_child(return_screen)
	return_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	return_screen.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	var question := Label.new()
	question.text = tr("Soll das laufende Spiel beendet werden?")
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(question)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	content.add_child(buttons)
	exit_button = Button.new()
	exit_button.text = tr("Beenden")
	exit_button.custom_minimum_size = Vector2(130, 42)
	buttons.add_child(exit_button)
	exit_button.pressed.connect(confirm_return)
	continue_button = Button.new()
	continue_button.text = tr("Weiterspielen")
	continue_button.custom_minimum_size = Vector2(150, 42)
	buttons.add_child(continue_button)
	continue_button.pressed.connect(cancel_return)
	return_screen.hide()


func show_pause_badge(value: bool) -> void:
	pause_badge.visible = value


func open_return_dialog() -> void:
	if world.is_game_over or world.return_dialog_open:
		return
	world.return_dialog_open = true
	world._set_paused(true)
	return_screen.show()
	continue_button.grab_focus()


func cancel_return() -> void:
	if changing_scene:
		return
	world.return_dialog_open = false
	return_screen.hide()
	exit_button.release_focus()
	continue_button.release_focus()
	show_pause_badge(true)
	world._update_pause_controls()


func confirm_return() -> void:
	if changing_scene:
		return
	changing_scene = true
	_return_to_start.call_deferred()


func _return_to_start() -> void:
	var save := get_node("/root/SessionSave")
	if not save.save_world(world):
		changing_scene = false
		var dialog := AcceptDialog.new()
		dialog.dialog_text = save.last_error
		add_child(dialog)
		dialog.confirmed.connect(dialog.queue_free)
		dialog.popup_centered()
		return
	world.record_endless_result()
	var tree := get_tree()
	get_node("/root/MetaStats").save_now()
	var error := tree.change_scene_to_file("res://scenes/start_menu.tscn")
	if error == OK:
		tree.paused = false
	else:
		changing_scene = false
		push_error(tr("Hauptmenü konnte nicht geladen werden: %s") % error_string(error))
