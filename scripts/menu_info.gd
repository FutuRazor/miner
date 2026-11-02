extends PanelContainer

var title: Label
var description: Label
var cost: Label
var upgrade_details: VBoxContainer
var current_effect: Label
var next_effect: Label


func _ready() -> void:
	custom_minimum_size.x = 250
	size_flags_vertical = Control.SIZE_SHRINK_END
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	title = Label.new()
	title.add_theme_color_override("font_color", Color("66e5db"))
	content.add_child(title)
	description = Label.new()
	description.custom_minimum_size.x = 226
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)
	upgrade_details = VBoxContainer.new()
	upgrade_details.add_theme_constant_override("separation", 5)
	content.add_child(upgrade_details)
	upgrade_details.add_child(HSeparator.new())
	current_effect = Label.new()
	current_effect.add_theme_color_override("font_color", Color.WHITE)
	upgrade_details.add_child(current_effect)
	var arrow := Label.new()
	arrow.text = tr("↓")
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 22)
	arrow.add_theme_color_override("font_color", Color("65e994"))
	upgrade_details.add_child(arrow)
	next_effect = Label.new()
	next_effect.add_theme_color_override("font_color", Color("65e994"))
	upgrade_details.add_child(next_effect)
	upgrade_details.add_child(HSeparator.new())
	cost = Label.new()
	content.add_child(cost)
	hide()


func show_item(item: Dictionary, money: int) -> void:
	title.text = tr(item.name)
	if item.has("level"):
		title.text += tr(" (lvl. %d)") % item.level
	description.text = tr(item.get("description", tr("Noch keine Beschreibung verfügbar.")))
	upgrade_details.visible = item.has("current_effect") and item.has("next_effect")
	if upgrade_details.visible:
		current_effect.text = item.current_effect
		next_effect.text = item.next_effect
	if item.get("placeholder", false):
		cost.text = tr("Platzhalter · Noch nicht upgradebar")
		cost.add_theme_color_override("font_color", Color("adbdc8"))
		show()
		return
	var locked: String = item.get("lock_reason", "")
	cost.text = locked if not locked.is_empty() else tr("Kosten: %d Geld") % item.cost
	cost.add_theme_color_override("font_color", Color("ff7777") if money < item.cost else Color("e9f6f5"))
	show()
