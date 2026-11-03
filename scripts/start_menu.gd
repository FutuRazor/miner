extends Control

var starting := false
var new_game_dialog: ConfirmationDialog


func _ready() -> void:
	$Center/Menu/StartButton.grab_focus()
	$Center/Menu/ContinueButton.disabled = not get_node("/root/SessionSave").has_save()
	new_game_dialog = ConfirmationDialog.new()
	new_game_dialog.dialog_text = tr("Neues Spiel starten? Der gespeicherte Spielstand wird verworfen.")
	new_game_dialog.ok_button_text = tr("Neues Spiel")
	new_game_dialog.cancel_button_text = tr("Abbrechen")
	add_child(new_game_dialog)
	new_game_dialog.confirmed.connect(_confirm_new_game)


func _unhandled_key_input(event: InputEvent) -> void:
	if new_game_dialog.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			var focused := get_viewport().gui_get_focus_owner()
			if focused is Button and not focused.disabled:
				get_viewport().set_input_as_handled()
				focused.pressed.emit()
		elif event.keycode in [KEY_W, KEY_S]:
			var focused := get_viewport().gui_get_focus_owner()
			var buttons := [$Center/Menu/StartButton, $Center/Menu/ContinueButton, $Center/Menu/TutorialButton, $Center/Menu/StatsButton, $Center/Menu/RankingButton, $Center/Menu/OptionsButton]
			var direction := -1 if event.keycode == KEY_W else 1
			var index: int = buttons.find(focused)
			for step in buttons.size():
				index = posmod(index + direction, buttons.size())
				if not buttons[index].disabled:
					buttons[index].grab_focus()
					break
			get_viewport().set_input_as_handled()


func _start_game() -> void:
	if starting:
		return
	if get_node("/root/SessionSave").has_save():
		new_game_dialog.popup_centered()
	else:
		_confirm_new_game()


func _confirm_new_game() -> void:
	if not get_node("/root/SessionSave").clear_save():
		push_error(tr("Der gespeicherte Spielstand konnte nicht entfernt werden."))
		return
	_change_scene("res://scenes/main.tscn")


func _continue_game() -> void:
	if starting:
		return
	if get_node("/root/SessionSave").request_resume():
		_change_scene("res://scenes/main.tscn")


func _start_tutorial() -> void:
	_change_scene("res://scenes/tutorial.tscn")


func _open_statistics() -> void:
	_change_scene("res://scenes/meta_stats.tscn")


func _open_ranking() -> void:
	_change_scene("res://scenes/ranking.tscn")


func _open_options() -> void:
	_change_scene("res://scenes/options.tscn")


func _change_scene(path: String) -> void:
	if starting:
		return
	starting = true
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		starting = false
		push_error(tr("Spiel konnte nicht gestartet werden: %s") % error_string(error))
