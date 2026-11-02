extends "res://scripts/meta_stats_screen.gd"


var selected_category := 0
var mission_button: Button
var endless_button: Button
var subtitle: Label


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
	title.text = tr("Ranking")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("66e5db"))
	content.add_child(title)
	subtitle = Label.new()
	subtitle.text = tr("Gewonnene Partien · kürzeste Spielzeit zuerst")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(subtitle)
	var categories := HBoxContainer.new()
	categories.name = "Categories"
	categories.add_theme_constant_override("separation", 8)
	content.add_child(categories)
	var group := ButtonGroup.new()
	mission_button = Button.new()
	mission_button.name = "MissionButton"
	mission_button.text = tr("20-Wellen-Mission")
	endless_button = Button.new()
	endless_button.name = "EndlessButton"
	endless_button.text = tr("Endless Game")
	for button in [mission_button, endless_button]:
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size.y = 32
		categories.add_child(button)
	mission_button.button_pressed = true
	mission_button.pressed.connect(_select_category.bind(0))
	endless_button.pressed.connect(_select_category.bind(1))
	summary = Label.new()
	content.add_child(summary)
	content.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
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
	var endless := selected_category == 1
	var entries: Array = stats.endless_games if endless else stats.victories
	subtitle.text = tr("Endless Game · höchste besiegte Welle zuerst") if endless else tr("Gewonnene Partien · kürzeste Spielzeit zuerst")
	summary.text = tr("Endless-Partien: %d") % entries.size() if endless else tr("Gewonnene Spiele: %d") % entries.size()
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	grid.columns = 6 if endless else 5
	var headings := [tr("Platz"), tr("Spielzeit"), tr("Gegner"), tr("Blöcke"), tr("Einnahmen")]
	if endless:
		headings.insert(1, tr("Höchste besiegte Welle"))
	for heading in headings:
		_add_cell(heading, true)
	for index in entries.size():
		var entry: Dictionary = entries[index]
		var seconds := int(entry.duration)
		_add_cell(str(index + 1))
		if endless:
			_add_cell(str(int(entry.wave)))
		_add_cell("%02d:%02d" % [floori(seconds / 60.0), seconds % 60])
		_add_cell(str(int(entry.enemies)))
		_add_cell(str(int(entry.blocks)))
		_add_cell("$%d" % int(entry.revenue))
	if entries.is_empty():
		_add_cell(tr("Noch keine Endless-Partien mit besiegter Welle 21.") if endless else tr("Noch keine gewonnenen Spiele."))
	notice.text = stats.save_error if not stats.save_error.is_empty() else stats.load_warning
	notice.visible = not notice.text.is_empty()
	notice.add_theme_color_override("font_color", Color("f4c86b"))


func _select_category(index: int) -> void:
	selected_category = index
	_refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_back()
		elif event.keycode == KEY_E:
			var focused := get_viewport().gui_get_focus_owner()
			if focused is Button:
				get_viewport().set_input_as_handled()
				if focused.toggle_mode:
					focused.button_pressed = true
				focused.pressed.emit()
