extends CanvasLayer

var switching := false


func _ready() -> void:
	$Screen/Center/Menu/Retry.grab_focus()
	$Screen/Center/Menu/Subtitle.text = tr("Welle %d erreicht – Die Basis wurde zerstört.") % get_parent().spawned_waves
	_show_round_stats()


func _show_round_stats() -> void:
	var world = get_parent()
	var seconds := int(world.round_duration)
	$Screen/Center/Menu/Stats.text = "\n".join([
		tr("Rundendauer: %s") % ("%02d:%02d" % [floori(seconds / 60.0), seconds % 60]),
		tr("Neutralisierte Gegner: %d") % world.enemies_neutralized,
		tr("Abgebaute Sektoren: %d Blöcke") % world.sectors_mined,
		tr("Gesamteinnahmen: $%d") % world.total_revenue,
	])

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button and not switching:
			get_viewport().set_input_as_handled()
			focused.pressed.emit()


func _retry() -> void:
	var path: String = get_parent().scene_file_path
	_request_scene(path if not path.is_empty() else "res://scenes/main.tscn")


func _main_menu() -> void:
	_request_scene("res://scenes/start_menu.tscn")


func _request_scene(path: String) -> void:
	if switching:
		return
	switching = true
	_switch_scene.call_deferred(path)


func _switch_scene(path: String) -> void:
	if path == "res://scenes/start_menu.tscn":
		get_parent().record_endless_result()
	var tree := get_tree()
	var error := tree.change_scene_to_file(path)
	if error == OK:
		tree.paused = false
	else:
		switching = false
		push_error(tr("Szene konnte nicht geladen werden: %s") % error_string(error))
