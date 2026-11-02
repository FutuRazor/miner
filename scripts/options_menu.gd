extends Control

var title := Label.new()
var language_label := Label.new()
var language_picker := OptionButton.new()
var notice := Label.new()
var back_button := Button.new()
var changing_scene := false

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("151e28")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.custom_minimum_size.x = 360
	rows.add_theme_constant_override("separation", 18)
	margin.add_child(rows)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("66e5db"))
	rows.add_child(title)
	rows.add_child(language_label)
	language_picker.custom_minimum_size.y = 44
	rows.add_child(language_picker)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(notice)
	back_button.custom_minimum_size.y = 44
	rows.add_child(back_button)
	language_picker.item_selected.connect(_select_language)
	back_button.pressed.connect(_back)
	get_node("/root/Localization").language_changed.connect(_refresh_texts.unbind(1))
	_refresh_texts()
	language_picker.grab_focus()

func _refresh_texts() -> void:
	title.text = tr("OPTIONEN")
	language_label.text = tr("Sprache")
	back_button.text = tr("Zurück zum Hauptmenü")
	var localization := get_node("/root/Localization")
	language_picker.clear()
	for locale in localization.SUPPORTED_LANGUAGES:
		language_picker.add_item(localization.LANGUAGE_NAMES[locale])
	language_picker.select(localization.SUPPORTED_LANGUAGES.find(localization.language))
	notice.text = tr("Die Sprachauswahl wird automatisch gespeichert.")

func _select_language(index: int) -> void:
	var localization := get_node("/root/Localization")
	if not localization.set_language(localization.SUPPORTED_LANGUAGES[index]):
		notice.text = tr("Die Sprache konnte nicht gespeichert werden.")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_back()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		var focused := get_viewport().gui_get_focus_owner()
		if focused == back_button:
			get_viewport().set_input_as_handled()
			_back()
		elif focused == language_picker:
			get_viewport().set_input_as_handled()
			language_picker.show_popup()

func _back() -> void:
	if changing_scene:
		return
	changing_scene = true
	var error := get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
	if error != OK:
		changing_scene = false
