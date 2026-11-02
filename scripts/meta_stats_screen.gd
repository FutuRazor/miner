extends Control

var stats: Node
var summary: Label
var grid: GridContainer
var notice: Label
var back_button: Button
var changing_scene := false


func _ready() -> void:
	stats = get_node("/root/MetaStats")
	stats.save_now()
	var background := ColorRect.new()
	background.color = Color("151e28")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	add_child(panel)
	panel.anchor_left = 0.12
	panel.anchor_right = 0.88
	panel.anchor_top = 0.06
	panel.anchor_bottom = 0.94
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var title := Label.new()
	title.text = tr("GESAMTSTATISTIK")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("66e5db"))
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = tr("Alle Partien · dauerhaft gespeichert")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(subtitle)
	summary = Label.new()
	content.add_child(summary)
	content.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	var explanation := Label.new()
	explanation.text = tr("Jeder Abbauschritt zählt als eine gesammelte Einheit.\nNach dem vierten Schritt zählt der Block zusätzlich als vollständig abgebaut.")
	explanation.add_theme_font_size_override("font_size", 13)
	content.add_child(explanation)
	notice = Label.new()
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_font_size_override("font_size", 13)
	content.add_child(notice)
	back_button = Button.new()
	back_button.text = tr("Zurück zum Hauptmenü")
	back_button.custom_minimum_size.y = 44
	content.add_child(back_button)
	back_button.pressed.connect(_back)
	back_button.grab_focus()
	stats.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	summary.text = tr("Gesammelte Blockeinheiten: %d\nVollständig abgebaute Blöcke: %d\nBesiegte Gegnerdrohnen: %d") % [stats.total_collected(), stats.total_destroyed(), stats.enemy_drones_defeated]
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for text in [tr("Härtegrad"), "Gesammelt", tr("Vollständig abgebaut")]:
		_add_cell(text, true)
	var highest := 10
	for key in stats.collected_by_hardness:
		highest = maxi(highest, int(key))
	for hardness in range(1, highest + 1):
		_add_cell(str(hardness))
		_add_cell(str(stats.collected_by_hardness.get(str(hardness), 0)))
		_add_cell(str(stats.destroyed_by_hardness.get(str(hardness), 0)))
	notice.text = stats.save_error if not stats.save_error.is_empty() else stats.load_warning
	notice.visible = not notice.text.is_empty()
	notice.add_theme_color_override("font_color", Color("f4c86b"))


func _add_cell(text: String, header: bool = false) -> void:
	var cell := Label.new()
	cell.text = tr(text)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if header:
		cell.add_theme_color_override("font_color", Color("66e5db"))
	grid.add_child(cell)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_E]:
		get_viewport().set_input_as_handled()
		_back()


func _back() -> void:
	if changing_scene:
		return
	changing_scene = true
	var error := get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
	if error != OK:
		changing_scene = false
		push_error(tr("Hauptmenü konnte nicht geladen werden: %s") % error_string(error))
