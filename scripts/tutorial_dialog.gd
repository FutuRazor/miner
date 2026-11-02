extends CanvasLayer

var tutorial: Node2D
var screen := ColorRect.new()
var heading := Label.new()
var description := Label.new()
var ok := Button.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	screen.color = Color(0.02, 0.04, 0.06, 0.8)
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	screen.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 18)
	margin.add_child(rows)
	heading.custom_minimum_size.x = 420
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", Color("66e5db"))
	rows.add_child(heading)
	description.custom_minimum_size.x = 420
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(description)
	ok.text = "OK"
	ok.custom_minimum_size = Vector2(120, 42)
	rows.add_child(ok)
	ok.pressed.connect(func() -> void: tutorial.acknowledge_message())
	screen.hide()

func show_message(title: String, detail: String) -> void:
	heading.text = title
	description.text = detail
	screen.show()
	ok.grab_focus()

func _input(event: InputEvent) -> void:
	if tutorial.dialog_open and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE]:
			tutorial.acknowledge_message()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	tutorial.update_tutorial_blinks()
