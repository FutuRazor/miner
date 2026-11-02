extends "res://scripts/meta_stats_screen.gd"


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
	var subtitle := Label.new()
	subtitle.text = tr("Gewonnene Partien · kürzeste Spielzeit zuerst")
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
	summary.text = tr("Gewonnene Spiele: %d") % stats.victories.size()
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for heading in [tr("Platz"), tr("Spielzeit"), tr("Gegner"), tr("Blöcke"), tr("Einnahmen")]:
		_add_cell(heading, true)
	for index in stats.victories.size():
		var entry: Dictionary = stats.victories[index]
		var seconds := int(entry.duration)
		_add_cell(str(index + 1))
		_add_cell("%02d:%02d" % [seconds / 60, seconds % 60])
		_add_cell(str(int(entry.enemies)))
		_add_cell(str(int(entry.blocks)))
		_add_cell("$%d" % int(entry.revenue))
	if stats.victories.is_empty():
		_add_cell(tr("Noch keine gewonnenen Spiele."))
	notice.text = stats.save_error if not stats.save_error.is_empty() else stats.load_warning
	notice.visible = not notice.text.is_empty()
	notice.add_theme_color_override("font_color", Color("f4c86b"))
