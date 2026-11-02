extends "res://scripts/world.gd"

# Income milestones exclude start money, purchases, sale proceeds and stored
# resources that have not reached the player's account yet.
const INCOME_STEPS := [20, 65, 130, 180, 220, 285]
var phase := 0
var earned := 0
var capacity_message_seen := false
var dialog_open := false
var was_paused := false
var dialog: CanvasLayer
var objective: Label
var blink_build := false
var blink_skills := false
var new_buildings: Dictionary = {}
var new_skills: Dictionary = {}
var defense_wait := -1.0
var timer_started := false
var timer_income := 0
var first_wave_done := false
var workshop_unlocked := false
var check_pending := false

func _ready() -> void:
	money = 20
	super._ready()
	income_received.connect(_on_tutorial_income)
	wave_timer.set_timer_paused(true)
	wave_timer.hide()
	wave_pause_button.hide()
	dialog = preload("res://scripts/tutorial_dialog.gd").new()
	dialog.tutorial = self
	add_child(dialog)
	objective = Label.new()
	objective.position = Vector2(20, 78)
	objective.custom_minimum_size = Vector2(440, 70)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_node("GameUI").add_child(objective)
	_refresh_tutorial_ui()

func _physics_process(delta: float) -> void:
	if dialog_open:
		return
	super._physics_process(delta)
	_check_progress()
	if dialog_open:
		return
	if phase >= 6 and not timer_started:
		if _defense_ready():
			if defense_wait < 0.0:
				defense_wait = 10.0
			else:
				defense_wait = maxf(0.0, defense_wait - delta)
				if defense_wait <= 0.0:
					timer_started = true
					# Preserve income already earned while building the defense.
					timer_income = INCOME_STEPS[5]
					wave_timer.remaining = wave_timer.DURATION
					wave_timer.set_timer_paused(false)
					wave_timer.show()
		else:
			defense_wait = -1.0
	_update_objective()

func is_build_menu_available() -> bool:
	return phase >= 1

func is_skill_menu_available() -> bool:
	return phase >= 2

func _available_building_indices() -> Array:
	var result: Array = []
	if phase >= 1:
		result.append(0)
	if phase >= 6:
		result.append_array([1, 2])
	if workshop_unlocked:
		result.append(3)
	return result

func _available_skill_indices() -> Array:
	var ids: Array = []
	if phase >= 2:
		ids.append_array(["collector_speed", "collector_capacity"])
	if phase >= 3:
		ids.append_array(["base_health", "cash_drone"])
	if phase >= 5:
		ids.append("mining_level")
	if phase >= 7:
		ids.append_array(["barracks_health", "tower_health", "tower_rate"])
	var result: Array = []
	for index in SKILLS.size():
		if ids.has(SKILLS[index].get("id", "")):
			result.append(index)
	return result

func _building_limit(kind: int) -> int:
	if not _available_building_indices().has(kind):
		return 0
	return (2 if phase >= 4 else 1) if kind == 0 else (2 if kind == 2 else 1)

func _skill_block_reason(id: String) -> String:
	var found := false
	for index in _available_skill_indices():
		if SKILLS[index].id == id:
			found = true
	if not found:
		return "Im Tutorial noch nicht verfügbar"
	var limit := (2 if phase >= 8 else 1) if id == "mining_level" else 1
	if _skill_purchases(id) >= limit:
		return "Maximum erreicht" if id != "mining_level" or phase >= 8 else "Abbaustufe 3 später im Tutorial"
	var kind := 0 if id.begins_with("collector_") or id == "cash_drone" else (1 if id.begins_with("barracks_") else (2 if id.begins_with("tower_") else -1))
	if kind >= 0:
		var ready_building := false
		for building in buildings:
			if building.kind == kind and not building.get("destroyed", false) and building.construction <= 0.0:
				ready_building = true
		if not ready_building:
			return "%s fertigstellen" % BUILDINGS[kind]
	return ""

func _on_tutorial_income(amount: int) -> void:
	earned += amount
	_schedule_check()

func _schedule_check() -> void:
	if not check_pending:
		check_pending = true
		_check_progress.call_deferred()

func _check_progress() -> void:
	check_pending = false
	if dialog_open or is_game_over or return_dialog_open:
		return
	if not capacity_message_seen and collected_count >= $Player.capacity:
		capacity_message_seen = true
		_show_message("Maximale Tragkraft erreicht", "Du trägst 10 Rohstoffeinheiten. Gehe in die Basis, um sie abzugeben. Für jede Einheit bekommst du Geld.")
		return
	if first_wave_done and not workshop_unlocked:
		workshop_unlocked = true
		blink_build = true
		new_buildings[3] = true
		_show_message("Defekte Gebäude und Einheiten", "Die Werkstatt ist jetzt verfügbar. Ihre Mechaniker reparieren zuerst die Basis, dann Türme und zuletzt ruhende Kampfdrohnen auf dem Kasernengelände.")
		return
	if phase == 0 and money >= 40:
		phase = 1
		blink_build = true
		new_buildings[0] = true
		_show_message("Baumenü verfügbar", "Öffne das blinkende Baumenü unten links und baue deinen ersten Sammler auf einer freien Fläche von 2 × 2 Feldern.")
	elif phase == 1 and earned >= INCOME_STEPS[1]:
		phase = 2
		_unlock_skills(["collector_speed", "collector_capacity"])
		_show_message("Skilltree verfügbar", "Verbessere deinen Sammler mit »Schneller sammeln« und »Kapazität erhöhen«.")
	elif phase == 2 and earned >= INCOME_STEPS[2]:
		phase = 3
		_unlock_skills(["base_health", "cash_drone"])
		_show_message("Basis-Skills verfügbar", "Du kannst jetzt die Lebenspunkte der Basis erhöhen und eine Geld-Sammeldrohne kaufen. Sie bringt das Guthaben deiner Sammler automatisch zur Basis oder zu dir.")
	elif phase == 3 and earned >= INCOME_STEPS[3]:
		phase = 4
		blink_build = true
		new_buildings[0] = true
		_refresh_tutorial_ui()
		_schedule_check()
	elif phase == 4 and earned >= INCOME_STEPS[4]:
		phase = 5
		_unlock_skills(["mining_level"])
		_show_message("Erhöhung der Abbaustufe verfügbar", "Kaufe Abbaustufe 2, um die nächsten beiden Blockreihen abzubauen. Abbaustufe 3 wird später freigeschaltet.")
	elif phase == 5 and earned >= INCOME_STEPS[5]:
		phase = 6
		blink_build = true
		new_buildings[1] = true
		new_buildings[2] = true
		_show_message("Verteidigung planen", "Baue eine Kaserne und zwei Türme. Sobald alle drei fertig sind, beginnt nach 10 Sekunden der 100-Sekunden-Countdown zur ersten Welle.")
	elif phase == 6 and timer_started and earned >= timer_income + 95:
		phase = 7
		_unlock_skills(["barracks_health", "tower_health", "tower_rate"])
		_show_message("Verteidigung upgraden", "Verbessere die Lebenspunkte deiner Kasernen-Drohnen und Türme sowie die Schussrate der Türme.")
	elif phase == 7 and earned >= timer_income + 125:
		phase = 8
		_unlock_skills(["mining_level"])
		_refresh_tutorial_ui()

func _unlock_skills(ids: Array) -> void:
	blink_skills = true
	for id in ids:
		new_skills[id] = true

func _show_message(title: String, detail: String) -> void:
	was_paused = get_tree().paused
	dialog_open = true
	building_context.close()
	_refresh_tutorial_ui()
	super._set_paused(true)
	get_node("GameUI").show_pause_badge(false)
	dialog.show_message(title, detail)

func acknowledge_message() -> void:
	if not dialog_open:
		return
	dialog_open = false
	dialog.screen.hide()
	super._set_paused(was_paused)
	_schedule_check()

func _refresh_tutorial_ui() -> void:
	var actions := get_node_or_null("GameUI/MenuDock/ActionMenu")
	if actions != null:
		actions.visible = is_build_menu_available()
		actions.get_node("Margin/Rows/BuildRow").visible = is_build_menu_available()
		actions.get_node("Margin/Rows/SkillsRow").visible = is_skill_menu_available()
	var available := _available_skill_indices()
	if not available.is_empty() and not available.has(selected_skill):
		selected_skill = available[0]
	_update_build_ui()
	_update_objective()
	update_tutorial_blinks()

func update_tutorial_blinks() -> void:
	var actions := get_node_or_null("GameUI/MenuDock/ActionMenu")
	if actions == null:
		return
	var pulse := Color.WHITE.lerp(Color("f4c86b"), 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0))
	actions.get_node("Margin/Rows/BuildRow/Build").modulate = pulse if blink_build else Color.WHITE
	actions.get_node("Margin/Rows/SkillsRow/Skills").modulate = pulse if blink_skills else Color.WHITE
	for index in build_options.rows.size():
		var highlight := false
		if build_mode == BuildMode.MENU:
			var available := _available_building_indices()
			if index < available.size():
				highlight = new_buildings.has(available[index])
		elif build_mode == BuildMode.SKILLS and index < build_options.current_items.size():
			highlight = new_skills.has(build_options.current_items[index].get("id", ""))
		build_options.rows[index].button.modulate = pulse if highlight else Color.WHITE

func _update_objective() -> void:
	if objective == null:
		return
	var messages := [
		"Baue Rohstoffe ab und bringe sie zur Basis. Ziel: 40 Geld auf dem Konto.",
		"Baue einen Sammler. Sammle danach weitere Einnahmen für den Skilltree.",
		"Verbessere Abbaugeschwindigkeit und Kapazität deines Sammlers.",
		"Verbessere die Basis und automatisiere den Geldtransport.",
		"Ein zweiter Sammler ist verfügbar. Erweitere deine Wirtschaft.",
		"Kaufe Abbaustufe 2 und erschließe härtere Blöcke.",
		"Baue eine Kaserne und zwei Türme, um die erste Welle vorzubereiten.",
		"Verbessere die Verteidigung und bereite dich auf die erste Welle vor.",
		"Abbaustufe 3 ist verfügbar. Besiege die erste Welle.",
	]
	objective.text = "TUTORIAL · " + messages[phase]
	if phase > 0 and phase < 6:
		objective.text += "\nEinnahmen bis zum nächsten Schritt: %d" % maxi(0, INCOME_STEPS[phase] - earned)
	elif phase == 6 and not timer_started and defense_wait >= 0.0:
		objective.text += "\nCountdown startet in %d Sekunden." % ceili(defense_wait)
	elif phase in [6, 7] and timer_started:
		objective.text += "\nWeitere Einnahmen bis zum nächsten Schritt: %d" % maxi(0, timer_income + (95 if phase == 6 else 125) - earned)
	if workshop_unlocked:
		objective.text = "TUTORIAL · Erste Welle besiegt! Baue eine Werkstatt und repariere deine Verteidigung."

func _defense_ready() -> bool:
	var barracks := 0
	var towers := 0
	for building in buildings:
		if not building.get("destroyed", false) and building.construction <= 0.0:
			barracks += int(building.kind == 1)
			towers += int(building.kind == 2)
	return barracks >= 1 and towers >= 2

func _on_block_collected(by_player: bool = true) -> void:
	super._on_block_collected(by_player)
	if by_player:
		_schedule_check()

func spawn_enemy_wave() -> void:
	if not timer_started or dialog_open:
		return
	super.spawn_enemy_wave()

func _on_enemy_destroyed(number: int) -> void:
	super._on_enemy_destroyed(number)
	if cleared_waves >= 1:
		first_wave_done = true
		_schedule_check()

func _input(event: InputEvent) -> void:
	if not dialog_open:
		super._input(event)

func _unhandled_input(event: InputEvent) -> void:
	if not dialog_open:
		super._unhandled_input(event)

func _set_paused(value: bool) -> void:
	if not dialog_open or value:
		super._set_paused(value)

func _cycle_game_speed() -> void:
	if not dialog_open:
		super._cycle_game_speed()

func _on_build_button_pressed() -> void:
	if dialog_open or not is_build_menu_available():
		return
	blink_build = false
	super._on_build_button_pressed()
	update_tutorial_blinks()

func _on_skills_button_pressed() -> void:
	if dialog_open or not is_skill_menu_available():
		return
	blink_skills = false
	if not _available_skill_indices().has(selected_skill):
		selected_skill = _available_skill_indices()[0]
	super._on_skills_button_pressed()
	update_tutorial_blinks()

func _on_option_clicked(index: int) -> void:
	if dialog_open:
		return
	if build_mode == BuildMode.MENU:
		new_buildings.erase(_available_building_indices()[index])
	elif build_mode == BuildMode.SKILLS:
		new_skills.erase(SKILLS[_available_skill_indices()[index]].id)
	super._on_option_clicked(index)
	update_tutorial_blinks()

func _confirm_skill() -> void:
	if dialog_open:
		return
	new_skills.erase(SKILLS[selected_skill].get("id", ""))
	super._confirm_skill()
	update_tutorial_blinks()

func _set_build_mode(mode: BuildMode) -> void:
	if dialog_open:
		return
	if mode == BuildMode.PLACE:
		new_buildings.erase(selected_building)
	super._set_build_mode(mode)
	update_tutorial_blinks()
