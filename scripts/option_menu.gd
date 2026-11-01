extends VBoxContainer

signal option_activated(index: int)

const COST_NORMAL := Color("e9f6f5")
const COST_UNAFFORDABLE := Color("ff7777")
var heading: Label
var hint: Label
var entries := VBoxContainer.new()
var entry_scroll := ScrollContainer.new()
var rows: Array[Dictionary] = []
var info_panel: PanelContainer
var keyboard_mode := true
var hovered_index := -1
var selected_index := 0
var current_items: Array = []
var available_money := 0


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	heading = Label.new()
	heading.add_theme_color_override("font_color", Color("66e5db"))
	add_child(heading)
	entries.add_theme_constant_override("separation", 6)
	entry_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	entry_scroll.custom_minimum_size.x = 310
	add_child(entry_scroll)
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry_scroll.add_child(entries)
	hint = Label.new()
	hint.add_theme_font_size_override("font_size", 13)
	hint.modulate = Color("adbdc8")
	add_child(hint)
	visibility_changed.connect(refresh_info)


func configure(title: String, items: Array, selected: int, money: int, help: String) -> void:
	current_items = items
	selected_index = selected
	available_money = money
	heading.text = title
	hint.text = help
	while rows.size() > items.size():
		var old: Dictionary = rows.pop_back()
		entries.remove_child(old.wrapper)
		old.wrapper.queue_free()
	while rows.size() < items.size():
		_create_row(rows.size())
	var group_count := 0
	for index in items.size():
		var row := rows[index]
		var group: String = items[index].get("group", "")
		row.group_label.text = group
		row.group_label.visible = not group.is_empty() and (index == 0 or group != items[index - 1].get("group", ""))
		if row.group_label.visible:
			group_count += 1
		row.name_label.text = items[index].name
		var placeholder: bool = items[index].get("placeholder", false)
		var locked: String = items[index].get("lock_reason", "")
		row.cost_label.text = "Später" if placeholder else (("Maximum" if locked.contains("Maximum") or locked.contains("limit") else "Gesperrt") if not locked.is_empty() else "%d Geld" % items[index].cost)
		row.cost_label.add_theme_color_override("font_color", Color("adbdc8") if placeholder else (COST_UNAFFORDABLE if money < items[index].cost else COST_NORMAL))
		row.button.button_pressed = index == selected
		row.icon.texture = load(items[index].icon)
	entry_scroll.custom_minimum_size.y = minf(380.0, items.size() * 44.0 + maxi(0, items.size() - 1) * 6.0 + group_count * 27.0)
	if keyboard_mode:
		_scroll_to_selection.call_deferred()
	refresh_info()


func _scroll_to_selection() -> void:
	if is_inside_tree() and selected_index >= 0 and selected_index < rows.size():
		entry_scroll.ensure_control_visible(rows[selected_index].button)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		keyboard_mode = false
		refresh_info()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_B, KEY_J, KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_ENTER, KEY_KP_ENTER, KEY_E]:
			keyboard_mode = true
			refresh_info()


func clear_hover() -> void:
	hovered_index = -1
	refresh_info()


func refresh_info() -> void:
	if not is_instance_valid(info_panel):
		return
	var index := selected_index if keyboard_mode else hovered_index
	if not is_visible_in_tree() or index < 0 or index >= current_items.size():
		info_panel.hide()
		return
	info_panel.show_item(current_items[index], available_money)


func _hover_entered(index: int) -> void:
	keyboard_mode = false
	hovered_index = index
	refresh_info()


func _hover_exited(index: int) -> void:
	if hovered_index == index:
		hovered_index = -1
	refresh_info()


func _create_row(index: int) -> void:
	var wrapper := VBoxContainer.new()
	entries.add_child(wrapper)
	var group_label := Label.new()
	group_label.add_theme_color_override("font_color", Color("66e5db"))
	wrapper.add_child(group_label)
	var button := Button.new()
	button.custom_minimum_size = Vector2(290, 44)
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	wrapper.add_child(button)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name_label)
	var cost_label := Label.new()
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(cost_label)
	rows.append({"wrapper": wrapper, "group_label": group_label, "button": button, "icon": icon, "name_label": name_label, "cost_label": cost_label})
	button.pressed.connect(func() -> void: option_activated.emit(index))
	button.mouse_entered.connect(_hover_entered.bind(index))
	button.mouse_exited.connect(_hover_exited.bind(index))
