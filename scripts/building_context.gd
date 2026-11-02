extends PanelContainer

var world: Node2D
var building_index := -1
var title := Label.new()
var details := Label.new()
var refund := Label.new()
var demolish := Button.new()
var confirmation := VBoxContainer.new()
var yes := Button.new()
var no := Button.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 150
	mouse_force_pass_scroll_events = false
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)
	var rows := VBoxContainer.new()
	margin.add_child(rows)
	title.add_theme_color_override("font_color", Color("66e5db"))
	rows.add_child(title)
	details.custom_minimum_size.x = 230
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(details)
	rows.add_child(refund)
	demolish.icon = preload("res://assets/icons/bulldozer.svg")
	demolish.tooltip_text = tr("Gebäude verkaufen und abreißen")
	demolish.custom_minimum_size = Vector2(40, 36)
	demolish.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rows.add_child(demolish)
	rows.add_child(confirmation)
	var question := Label.new()
	question.text = tr("Abreißen?")
	confirmation.add_child(question)
	var buttons := HBoxContainer.new()
	confirmation.add_child(buttons)
	yes.text = tr("Ja")
	no.text = tr("Nein")
	buttons.add_child(yes)
	buttons.add_child(no)
	demolish.pressed.connect(func() -> void:
		confirmation.show()
		demolish.hide()
		reset_size()
		_reposition()
	)
	no.pressed.connect(func() -> void:
		confirmation.hide()
		demolish.show()
		reset_size()
	)
	yes.pressed.connect(func() -> void:
		world.sell_building(building_index)
		close()
	)
	hide()

func open(index: int) -> void:
	building_index = index
	confirmation.hide()
	demolish.show()
	show()
	_refresh()
	reset_size()
	_reposition()

func close() -> void:
	building_index = -1
	hide()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE] and not get_global_rect().has_point(event.position):
		close()
		if event.button_index == MOUSE_BUTTON_LEFT:
			world.suppress_left_release = true
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not visible:
		return
	if world.is_game_over or world.return_dialog_open or building_index < 0 or world.buildings[building_index].get("destroyed", false):
		close()
		return
	_refresh()
	_reposition()

func _refresh() -> void:
	var building: Dictionary = world.buildings[building_index]
	title.text = tr(world.BUILDINGS[building.kind])
	var count := 0
	for drone in world._live_combat_drones("friendly_drones"):
		if drone.collector_index == building_index:
			count += 1
	var text := tr("Drohnen: %d") % count
	if building.get("construction", 0.0) > 0.0:
		text += tr("\nIm Bau: %d s") % ceili(building.construction)
	if building.get("pending_drones", 0) > 0:
		text += tr("\nIn Produktion: %d") % building.pending_drones
	if building.kind == 0:
		text += tr("\nGuthaben: %d Geld\nTempo: %d · Abbau: %d %%\nKapazität: %d · Abbaustufe: %d") % [building.money, world.collector_move_speed, world.collector_mining_speed, world.collector_capacity, world.mining_level]
	elif building.kind == 1:
		text += tr("\nDrohnen-LP: %d\nSchaden je Treffer: %d") % [world.barracks_drone_health, world.barracks_attack]
	elif building.kind == 3:
		text += tr("\nReparatur: %d LP/s je Drohne\nTempo: %d\nPriorität: Basis → Türme → Kampfdrohnen") % [world.workshop_repair, world.workshop_speed]
	elif building.has("tower") and is_instance_valid(building.tower):
		text += tr("\nLP: %d/%d\nSchüsse: %d · Intervall: %d ms") % [building.tower.health, building.tower.max_health, world.tower_shots, world.tower_interval_ms]
	text += tr("\nVerstärkungen:")
	var upgrades := 0
	for skill in world.SKILLS:
		var id: String = skill.get("id", "")
		var applies: bool = (building.kind == 0 and (id.begins_with("collector_") or id == "mining_level")) or (building.kind == 1 and id.begins_with("barracks_")) or (building.kind == 2 and id.begins_with("tower_")) or (building.kind == 3 and id.begins_with("workshop_"))
		if applies and world._skill_purchases(id) > 0:
			text += tr("\n%s: +%d") % [tr(skill.name), world._skill_purchases(id)]
			upgrades += 1
	if upgrades == 0:
		text += tr(" keine")
	details.text = text
	refund.text = tr("Rückzahlung: %d Geld (75 %% Baupreis)") % world.building_refund(building_index)

func _reposition() -> void:
	var rect: Rect2 = world.building_rect(building_index)
	var transform := world.get_global_transform_with_canvas()
	var right: Vector2 = transform * Vector2(rect.end.x, rect.position.y)
	var left: Vector2 = transform * rect.position
	var viewport_size := get_viewport_rect().size
	var x := right.x + 8.0
	if x + size.x > viewport_size.x - 8.0:
		x = left.x - size.x - 8.0
	position = Vector2(clampf(x, 8.0, maxf(8.0, viewport_size.x - size.x - 8.0)), clampf(right.y, 8.0, maxf(8.0, viewport_size.y - size.y - 8.0)))
