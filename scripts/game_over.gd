extends CanvasLayer

var switching := false


func _ready() -> void:
	$Screen/Center/Menu/Retry.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button and not switching:
			get_viewport().set_input_as_handled()
			focused.pressed.emit()


func _retry() -> void:
	_request_scene("res://scenes/main.tscn")


func _main_menu() -> void:
	_request_scene("res://scenes/start_menu.tscn")


func _request_scene(path: String) -> void:
	if switching:
		return
	switching = true
	_switch_scene.call_deferred(path)


func _switch_scene(path: String) -> void:
	var tree := get_tree()
	var error := tree.change_scene_to_file(path)
	if error == OK:
		tree.paused = false
	else:
		switching = false
		push_error("Szene konnte nicht geladen werden: %s" % error_string(error))
