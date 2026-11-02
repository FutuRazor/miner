extends Control

var starting := false


func _ready() -> void:
	$Center/Menu/StartButton.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			var focused := get_viewport().gui_get_focus_owner()
			if focused is Button:
				get_viewport().set_input_as_handled()
				focused.pressed.emit()
		elif event.keycode in [KEY_W, KEY_S]:
			var focused := get_viewport().gui_get_focus_owner()
			var buttons := [$Center/Menu/StartButton, $Center/Menu/TutorialButton, $Center/Menu/StatsButton, $Center/Menu/RankingButton, $Center/Menu/OptionsButton]
			var direction := -1 if event.keycode == KEY_W else 1
			buttons[posmod(buttons.find(focused) + direction, buttons.size())].grab_focus()
			get_viewport().set_input_as_handled()


func _start_game() -> void:
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
