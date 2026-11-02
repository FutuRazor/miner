extends Node2D

signal income_received(amount: int)

const Block = preload("res://scripts/block.gd")
const Drone = preload("res://scripts/drone.gd")
const Balance = preload("res://scripts/balance.gd")
const CELL := 48
const RADIUS := 22
@export var map_radius: int = RADIUS
const BASE_AREA := Rect2(-72, -72, 144, 144)
const BASE_COLOR := Color("66e5db")
var base_drone_settings: Dictionary = {"anchor": Vector2i(-1, -1), "pending_drones": 0, "production": 0.0}
@export var money_per_block: int = 1
@export_range(1, 100000, 1) var base_max_health: int = 100
var base_health := 100
var base_health_label: Label
var is_game_over := false
var game_over_screen: CanvasLayer
var play_button: Button
var pause_button: Button
const GAME_SPEEDS := [1.0, 1.5, 2.0, 3.0]
var game_speed_index := 0
var speed_button: Button
var normal_physics_rate := Engine.physics_ticks_per_second
var main_menu_button: Button
var return_dialog_open := false
@export_range(0, 100000, 1) var collector_cost: int = 30
@export_range(0, 100000, 1) var barracks_cost: int = 25
@export_range(0, 100000, 1) var tower_cost: int = 20
var collected_count := 0
var money := 40
var money_label: Label
var drone_count_label: Label
var enemy_count_label: Label
var wave_timer: ProgressBar
var wave_pause_button: Button
var combat_assignment_time := 0.0
var combat_reassign_pending := false
var was_in_base := true
enum BuildMode { PLAY, MENU, PLACE, SKILLS }
const SKILLS := [
	{"id": "base_health", "group": "Basis", "name": "Lebenspunkte", "cost": 40, "icon": "res://assets/icons/skills.svg", "description": "Erhöht die maximalen und aktuellen Lebenspunkte der Basis um 25."},
	{"id": "mining_level", "group": "Basis", "name": "Abbaustufe", "cost": 20, "icon": "res://assets/icons/build.svg", "description": "Erhöht die Abbaustufe der Spielfigur und aller bestehenden und zukünftigen Abbaudrohnen."},
	{"id": "cash_drone", "group": "Basis", "name": "Geld-Sammeldrohne", "cost": 25, "icon": "res://assets/icons/drone.svg", "description": "Holt Geld beim Sammler mit dem höchsten Guthaben.\nAbholung: 0,6 Sekunden\nAbgabe an Spielfigur oder Basis: sofort."},
	{"id": "collector_drones", "group": "Sammler", "name": "Drohne", "cost": 80, "icon": "res://assets/icons/drone.svg", "description": "Eine zusätzliche Drohne für jeden bestehenden und zukünftigen Sammler."},
	{"id": "collector_speed", "group": "Sammler", "name": "Schneller sammeln", "cost": 25, "icon": "res://assets/icons/collector.svg", "description": "Erhöht die Bewegungsgeschwindigkeit um 10 Pixel/s und die Abbaugeschwindigkeit um 5 Prozentpunkte. Gilt für alle Sammlerdrohnen."},
	{"id": "collector_capacity", "group": "Sammler", "name": "Kapazität erhöhen", "cost": 20, "icon": "res://assets/icons/collector.svg", "description": "Erhöht die Tragkapazität aller bestehenden und zukünftigen Sammlerdrohnen um 5."},
	{"id": "barracks_drones", "group": "Kaserne", "name": "Drohne", "cost": 60, "icon": "res://assets/icons/drone.svg", "description": "Eine zusätzliche Kampfdrohne für jede bestehende und zukünftige Kaserne. Verteidigt die Basis gegen Gegner."},
	{"id": "barracks_health", "group": "Kaserne", "name": "Lebenspunkte", "cost": 30, "icon": "res://assets/icons/skills.svg", "description": "Erhöht die aktuellen und maximalen Lebenspunkte aller Kasernendrohnen um 10. Gilt auch für neue und nachproduzierte Drohnen."},
	{"id": "barracks_attack", "group": "Kaserne", "name": "Angriff", "cost": 250, "icon": "res://assets/icons/skills.svg", "description": "Erhöht den Schaden aller bestehenden, neuen und nachproduzierten Kasernen-Drohnen von 1 auf 2 je Treffer. Einmalig nach Welle 13 kaufbar."},
	{"id": "tower_health", "group": "Turm", "name": "Lebenspunkte", "cost": 25, "icon": "res://assets/icons/skills.svg", "description": "Erhöht die aktuellen und maximalen Lebenspunkte aller bestehenden und zukünftigen Türme um 20."},
	{"id": "tower_shots", "group": "Turm", "name": "Anzahl Schüsse", "cost": 100, "icon": "res://assets/icons/tower.svg", "description": "Erhöht die Anzahl gleichzeitiger Schüsse aller Türme um 1. Jeder Treffer verursacht 1 Schaden."},
	{"id": "tower_rate", "group": "Turm", "name": "Schussrate", "cost": 40, "icon": "res://assets/icons/tower.svg", "description": "Verkürzt die Zeit zwischen den Salven aller Türme um 10 %. Millisekunden werden auf ganze Zahlen abgerundet."},
	{"id": "workshop_drones", "group": "Werkstatt", "name": "Drohnenanzahl", "cost": 200, "icon": "res://assets/icons/drone.svg", "description": "Eine zusätzliche Mechaniker-Drohne. Produktion: 20 Sekunden. Maximal drei Drohnen."},
	{"id": "workshop_repair", "group": "Werkstatt", "name": "Reparatur erhöhen", "cost": 200, "icon": "res://assets/icons/workshop.svg", "description": "Erhöht die Reparatur jeder Mechaniker-Drohne um 1 LP pro Sekunde. Maximal 3 LP/s."},
	{"id": "workshop_speed", "group": "Werkstatt", "name": "Bewegungsgeschwindigkeit", "cost": 60, "icon": "res://assets/icons/workshop.svg", "description": "Erhöht das Bewegungstempo aller Mechaniker-Drohnen um 20. Maximal 160 Pixel/s."},
]
var cleared_waves := 0
var spawned_waves := 0
var wave_alive: Dictionary = {}
var selected_skill := 0
var skill_levels: Dictionary = {"cash_drone": 0}
var collector_drone_count := 1
var collector_move_speed: int = 100
var collector_mining_speed: int = 100
var collector_capacity: int = 10
var barracks_drone_count := 2
var barracks_drone_health := 30
var barracks_attack := 1
var tower_health := 100
var tower_shots := 1
var tower_interval_ms := 1000
var mining_level := 1
var workshop_drone_count := 1
var workshop_repair := 1
var workshop_speed := 100
const BASE_HOME := -1
const BUILDINGS := ["Sammler", "Kaserne", "Turm", "Werkstatt"]
const BUILDING_COLORS := [Color("e0ac65"), Color("9e94ed"), Color("7eb7ff"), Color("8de6a4")]
var build_mode := BuildMode.PLAY
var selected_building := 0
var block_cells: Dictionary = {}
var occupied_cells: Dictionary = {}
var buildings: Array[Dictionary] = []
var build_panel: PanelContainer
var build_options: VBoxContainer
var build_status: Label
var build_preview: Node2D
const DRAG_THRESHOLD := 8.0
const MIN_ZOOM := 0.3
const MAX_ZOOM := 3.0
const ZOOM_STEP := 1.1
@export_range(0.1, 1.0, 0.05) var mouse_hold_threshold: float = 0.3
const WALK_DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
var mouse_held := false
var camera_drag_held := false
var right_press_building := -1
var building_context: PanelContainer
var drone_collisions: Node
var mouse_dragging := false
var mouse_travel := Vector2.ZERO
var mouse_placement := false
var suppress_left_release := false
var mouse_goal_active := false
var mouse_goal := Vector2.ZERO
var mouse_repath_timer := 0.0
var navigation_revision := 0
var mining_assignment_revision := 0
var mining_job_cache: Dictionary = {}
var mining_cache_revision := -1
var mining_cache_assignments := -1
var mouse_path_revision := -1
var mouse_direct_follow := false
var mouse_hold_time := 0.0


func _ready() -> void:
	Engine.time_scale = 1.0
	base_health = base_max_health
	RenderingServer.set_default_clear_color(Color("151e28"))
	# The existing base occupies all nine central cells, but stays walkable.
	for y in range(-1, 2):
		for x in range(-1, 2):
			occupied_cells[Vector2i(x, y)] = true
	for y in range(-map_radius, map_radius + 1):
		for x in range(-map_radius, map_radius + 1):
			if absi(x) <= 2 and absi(y) <= 2:
				continue
			var block := Block.new()
			block.position = Vector2(x, y) * CELL
			# Block rings begin just outside the existing 5 x 5 clearing.
			block.hardness = 1 + floori(float(maxi(absi(x), absi(y)) - 3) / 2.0)
			block_cells[Vector2i(x, y)] = block
			var shade := float(posmod(x * 73 + y * 31, 9)) / 80.0
			block.tint = Color("79644f").lightened(shade)
			block.collected.connect(_on_block_collected)
			add_child(block)
	_create_boundary()
	build_preview = preload("res://scripts/build_preview.gd").new()
	build_preview.name = "BuildPreview"
	build_preview.z_as_relative = false
	build_preview.z_index = 50
	add_child(build_preview)
	_create_hud()
	drone_collisions = preload("res://scripts/drone_collisions.gd").new()
	drone_collisions.world = self
	add_child(drone_collisions)
	get_viewport().size_changed.connect(_update_camera_limits)
	_update_camera_limits()


func _physics_process(delta: float) -> void:
	_tick_production(delta)
	combat_assignment_time -= delta
	if combat_assignment_time <= 0.0:
		combat_assignment_time = 0.25
		_assign_combat_targets()
	_update_mouse_navigation(delta)
	_clamp_camera_position()
	var in_base := BASE_AREA.has_point($Player.position)
	if in_base and not was_in_base and collected_count > 0:
		receive_income(collected_count * money_per_block)
		collected_count = 0
		_update_counters()
	was_in_base = in_base
	_collect_sampler_money()
	if build_mode == BuildMode.PLACE:
		_update_build_ui()
		build_preview.queue_redraw()


func _collect_sampler_money() -> void:
	var player_position: Vector2 = $Player.position
	var player_radius: float = $Player/CollisionShape2D.shape.radius
	var transferred := false
	for index in buildings.size():
		var building := buildings[index]
		if building.kind != 0 or building.money <= 0:
			continue
		var rect := Rect2(Vector2(building.anchor) * CELL - Vector2.ONE * CELL / 2, Vector2.ONE * CELL * 2)
		var nearest := player_position.clamp(rect.position, rect.end)
		if player_position.distance_squared_to(nearest) <= player_radius * player_radius:
			receive_income(building.money)
			building.money = 0
			update_collector_label(index)
			transferred = true
	if transferred:
		_update_counters()
		_update_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if is_game_over or return_dialog_open:
		return
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		# ScrollContainers can pass wheel events through at either end. They
		# still belong to the UI whenever the cursor is over a UI control.
		var hovered := get_viewport().gui_get_hovered_control()
		if is_instance_valid(hovered) and get_node("GameUI").is_ancestor_of(hovered):
			get_viewport().set_input_as_handled()
			return
		if event.pressed:
			var direction := 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
			_zoom_camera(direction * (event.factor if event.factor > 0.0 else 1.0), event.position)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and suppress_left_release:
			suppress_left_release = false
			get_viewport().set_input_as_handled()
			return
		if build_mode == BuildMode.PLACE and mouse_placement:
			if event.pressed:
				suppress_left_release = true
				_place_building()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_held = true
			mouse_direct_follow = false
			mouse_hold_time = 0.0
			_set_mouse_goal(get_global_mouse_position())
		elif mouse_held:
			if not mouse_dragging:
				_set_mouse_goal(get_global_mouse_position())
			mouse_held = false
			mouse_dragging = false
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		var clicked_building := building_at(get_global_transform_with_canvas().affine_inverse() * event.position)
		if event.pressed:
			right_press_building = clicked_building if build_mode != BuildMode.PLACE else -1
		elif camera_drag_held and not mouse_dragging and right_press_building >= 0 and right_press_building == clicked_building:
			camera_drag_held = false
			building_context.open(right_press_building)
			right_press_building = -1
			get_viewport().set_input_as_handled()
			return
		var close_menu: bool = not event.pressed and camera_drag_held and not mouse_dragging and build_mode != BuildMode.PLAY
		camera_drag_held = event.pressed
		mouse_held = false
		mouse_dragging = false
		mouse_travel = Vector2.ZERO
		if close_menu:
			_set_build_mode(BuildMode.PLAY)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and camera_drag_held:
		mouse_travel += event.relative
		var camera: Camera2D = $Player/Camera2D
		if not mouse_dragging and mouse_travel.length() >= DRAG_THRESHOLD:
			mouse_dragging = true
			camera.position -= mouse_travel / camera.zoom
		elif mouse_dragging:
			camera.position -= event.relative / camera.zoom
		_clamp_camera_position()
		get_viewport().set_input_as_handled()


func _camera_center_bounds() -> Rect2:
	var edge := (map_radius + 0.5) * CELL
	var half_view: Vector2 = get_viewport_rect().size / ($Player/Camera2D.zoom * 2.0)
	var extent := Vector2(edge if half_view.x < edge else 0.0, edge if half_view.y < edge else 0.0)
	return Rect2(-extent, extent * 2.0)


func _clamp_camera_position() -> void:
	var camera: Camera2D = $Player/Camera2D
	var bounds := _camera_center_bounds()
	camera.global_position = camera.global_position.clamp(bounds.position, bounds.end)


func _update_camera_limits() -> void:
	var camera: Camera2D = $Player/Camera2D
	var bounds := _camera_center_bounds()
	var half_view := get_viewport_rect().size / (camera.zoom * 2.0)
	# Camera2D limits describe viewport edges, while our allowed centers reach
	# the outer block edge (at most half a screen of empty space).
	camera.limit_left = floori(bounds.position.x - half_view.x)
	camera.limit_right = ceili(bounds.end.x + half_view.x)
	camera.limit_top = floori(bounds.position.y - half_view.y)
	camera.limit_bottom = ceili(bounds.end.y + half_view.y)
	_clamp_camera_position()
	camera.force_update_scroll()


func _zoom_camera(steps: float, screen_position: Vector2) -> void:
	var camera: Camera2D = $Player/Camera2D
	var zoom_value := clampf(camera.zoom.x * pow(ZOOM_STEP, steps), MIN_ZOOM, MAX_ZOOM)
	if is_equal_approx(zoom_value, camera.zoom.x):
		return
	var world_before := get_canvas_transform().affine_inverse() * screen_position
	# Preserve the visible center even while camera follow smoothing is active.
	camera.global_position = camera.get_screen_center_position()
	camera.zoom = Vector2.ONE * zoom_value
	_update_camera_limits()
	camera.reset_smoothing()
	camera.force_update_scroll()
	var world_after := get_canvas_transform().affine_inverse() * screen_position
	camera.global_position += world_before - world_after
	_clamp_camera_position()
	camera.reset_smoothing()
	camera.force_update_scroll()
	if build_mode == BuildMode.PLACE:
		_update_build_ui()


func _set_mouse_goal(goal: Vector2) -> void:
	mouse_goal = goal
	mouse_goal_active = true
	mouse_repath_timer = 0.1
	mouse_path_revision = navigation_revision
	$Player.movement_enabled = true
	$Player.mining_enabled = true
	if mouse_direct_follow:
		$Player.navigation_path.assign([goal])
		return
	var path := _walk_path(goal)
	var old_path: Array[Vector2] = $Player.navigation_path
	# Keep an already traversed straight segment instead of returning to its cell center.
	if path.size() >= 2 and (path.size() == 2 or (not old_path.is_empty() and path[1].is_equal_approx(old_path[0]))):
		path.pop_front()
	$Player.navigation_path = path


func _update_mouse_navigation(delta: float) -> void:
	if not mouse_goal_active or (build_mode == BuildMode.PLACE and mouse_placement):
		return
	if $Player.keyboard_movement_enabled and Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") != Vector2.ZERO:
		mouse_goal_active = false
		mouse_held = false
		return
	if mouse_held:
		mouse_hold_time += delta
		var current_goal := get_global_mouse_position()
		if not mouse_direct_follow and mouse_hold_time >= mouse_hold_threshold:
			mouse_direct_follow = true
			_set_mouse_goal(current_goal)
	mouse_repath_timer -= delta
	if mouse_repath_timer > 0.0:
		return
	mouse_repath_timer = 0.1
	var goal := get_global_mouse_position() if mouse_held else mouse_goal
	if goal.distance_squared_to(mouse_goal) >= 16.0 or mouse_path_revision != navigation_revision:
		_set_mouse_goal(goal)
	if not mouse_held and $Player.position.distance_to(mouse_goal) <= 1.0:
		mouse_goal_active = false


func _walk_path(requested: Vector2) -> Array[Vector2]:
	# Search only the connected free cells, never through a block.
	var start := Vector2i(($Player.position / CELL).round())
	var previous: Dictionary = {start: start}
	var frontier: Array[Vector2i] = [start]
	var cursor := 0
	var destination := start
	var nearest := $Player.position as Vector2
	var best_distance := INF
	while cursor < frontier.size():
		var cell := frontier[cursor]
		cursor += 1
		var candidate := _walk_target_in_cell(cell, requested)
		var distance := candidate.distance_squared_to(requested)
		if distance < best_distance:
			best_distance = distance
			destination = cell
			nearest = candidate
		for direction in WALK_DIRECTIONS:
			var next: Vector2i = cell + direction
			if previous.has(next) or not _walkable_cell(next):
				continue
			previous[next] = cell
			frontier.append(next)
	var result: Array[Vector2] = [nearest]
	var step := destination
	while step != start:
		result.push_front(Vector2(step) * CELL)
		step = previous[step]
	result.push_front(Vector2(start) * CELL)
	return result


func _walkable_cell(cell: Vector2i) -> bool:
	if absi(cell.x) > map_radius or absi(cell.y) > map_radius:
		return false
	return not (block_cells.has(cell) and is_instance_valid(block_cells[cell]) and not block_cells[cell].is_queued_for_deletion())


func _walk_target_in_cell(cell: Vector2i, requested: Vector2) -> Vector2:
	var center := Vector2(cell) * CELL
	var minimum := center - Vector2.ONE * CELL / 2.0
	var maximum := center + Vector2.ONE * CELL / 2.0
	var clearance: float = $Player/CollisionShape2D.shape.radius + 1.0
	if not _walkable_cell(cell + Vector2i.LEFT):
		minimum.x += clearance
	if not _walkable_cell(cell + Vector2i.RIGHT):
		maximum.x -= clearance
	if not _walkable_cell(cell + Vector2i.UP):
		minimum.y += clearance
	if not _walkable_cell(cell + Vector2i.DOWN):
		maximum.y -= clearance
	var candidate := requested.clamp(minimum, maximum)
	for diagonal in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		if not _walkable_cell(cell + diagonal):
			var corner := center + Vector2(diagonal) * CELL / 2.0
			var away := candidate - corner
			if away.length() < clearance:
				if away.is_zero_approx():
					away = -Vector2(diagonal)
				candidate = (corner + away.normalized() * clearance).clamp(minimum, maximum)
	return candidate


func _input(event: InputEvent) -> void:
	if is_game_over or return_dialog_open:
		return
	# Capture the release of a map gesture even if the pointer is now over a menu.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and mouse_held:
		_unhandled_input(event)
		return
	# Finish an active right-button gesture even when released over the UI.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed and camera_drag_held:
		_unhandled_input(event)
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_B:
		_on_build_button_pressed()
	elif event.keycode == KEY_ESCAPE and build_mode != BuildMode.PLAY:
		_set_build_mode(BuildMode.PLAY)
	elif event.keycode == KEY_J:
		_on_skills_button_pressed()
	elif build_mode == BuildMode.SKILLS:
		if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
			selected_skill = _cycle_available(_available_skill_indices(), selected_skill, 1)
		elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
			selected_skill = _cycle_available(_available_skill_indices(), selected_skill, -1)
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E]:
			_confirm_skill()
		_update_build_ui()
	elif build_mode == BuildMode.MENU:
		if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
			selected_building = _cycle_available(_available_building_indices(), selected_building, 1)
		elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
			selected_building = _cycle_available(_available_building_indices(), selected_building, -1)
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E]:
			_set_build_mode(BuildMode.PLACE)
		_update_build_ui()
	elif build_mode == BuildMode.PLACE and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E]:
		_place_building()


func _set_build_mode(mode: BuildMode) -> void:
	if (mode in [BuildMode.MENU, BuildMode.PLACE] and not is_build_menu_available()) or (mode == BuildMode.SKILLS and not is_skill_menu_available()):
		return
	build_mode = mode
	build_options.clear_hover()
	if mode != BuildMode.PLACE:
		mouse_placement = false
	# Menus capture keyboard movement, but automatic mining stays active.
	$Player.movement_enabled = true
	$Player.mining_enabled = true
	$Player.keyboard_movement_enabled = mode not in [BuildMode.MENU, BuildMode.SKILLS]
	mouse_held = false
	camera_drag_held = false
	mouse_dragging = false
	if mode in [BuildMode.MENU, BuildMode.SKILLS]:
		$Player.navigation_path.clear()
		mouse_goal_active = false
	if mode == BuildMode.PLACE and mouse_placement:
		mouse_goal_active = false
	_update_build_ui()
	queue_redraw()


func _build_anchor() -> Vector2i:
	if mouse_placement:
		return Vector2i((get_global_mouse_position() / CELL).round())
	return Vector2i(($Player.position / CELL).round())


func _confirm_skill() -> void:
	if not _available_skill_indices().has(selected_skill):
		return
	var skill: Dictionary = SKILLS[selected_skill].duplicate(true)
	var id: String = skill.get("id", "")
	if not _skill_block_reason(id).is_empty():
		return
	skill.cost = _skill_cost(id)
	var money_before := money
	if id.begins_with("workshop_") and money >= skill.cost:
		money -= skill.cost
		match id:
			"workshop_drones":
				workshop_drone_count += 1
				for index in buildings.size():
					if buildings[index].kind == 3:
						_queue_drone(index)
			"workshop_repair": workshop_repair += 1
			"workshop_speed": workshop_speed += 20
		for child in get_children():
			if child.get_script() == Drone and child.mechanic:
				child.speed = workshop_speed
		_update_counters()
	elif skill.get("id", "") == "base_health" and money >= skill.cost:
		money -= skill.cost
		base_max_health += 25
		base_health += 25
		_update_base_health()
		_update_counters()
	elif skill.get("id", "") == "collector_drones" and money >= skill.cost:
		money -= skill.cost
		collector_drone_count += 1
		for index in buildings.size():
			if buildings[index].kind == 0:
				_queue_drone(index)
		_update_counters()
	elif skill.get("id", "") == "cash_drone" and money >= skill.cost:
		money -= skill.cost
		base_drone_settings.pending_drones += 1
		_update_counters()
	elif skill.get("id", "") == "barracks_drones" and money >= skill.cost:
		money -= skill.cost
		barracks_drone_count += 1
		for index in buildings.size():
			if buildings[index].kind == 1:
				_queue_drone(index)
		_update_counters()
	elif skill.get("id", "") == "mining_level" and money >= skill.cost:
		money -= skill.cost
		mining_level += 1
		$Player.mining_power = mining_level
		for child in get_children():
			if child.get_script() == Drone and not child.hostile:
				child.mining_power = mining_level
				child.retry_time = 0.0
		navigation_revision += 1
		_update_counters()
	elif skill.get("id", "") == "collector_speed" and money >= skill.cost:
		money -= skill.cost
		collector_move_speed += 10
		collector_mining_speed += 5
		_refresh_collector_stats()
		_update_counters()
	elif skill.get("id", "") == "collector_capacity" and money >= skill.cost:
		money -= skill.cost
		collector_capacity += 5
		_refresh_collector_stats()
		_update_counters()
	elif id == "barracks_attack" and money >= skill.cost:
		money -= skill.cost
		barracks_attack = 2
		for child in get_children():
			if child.get_script() == Drone and child.passive and not child.is_queued_for_deletion():
				child.attack_damage = barracks_attack
		_update_counters()
	elif skill.get("id", "") == "barracks_health" and money >= skill.cost:
		money -= skill.cost
		barracks_drone_health += 10
		for child in get_children():
			if child.get_script() == Drone and child.passive and not child.is_queued_for_deletion():
				child.max_health = barracks_drone_health
				child.health = mini(child.health + 10, child.max_health)
				child._update_status()
		_update_counters()
	elif skill.get("id", "") in ["tower_health", "tower_shots", "tower_rate"] and money >= skill.cost:
		money -= skill.cost
		var health_bonus := 0
		match skill.id:
			"tower_health":
				tower_health += 20
				health_bonus = 20
			"tower_shots": tower_shots += 1
			"tower_rate": tower_interval_ms = maxi(1, floori(tower_interval_ms * 0.9))
		for tower in _live_combat_drones("towers"):
			tower.max_health = tower_health
			tower.health = mini(tower.health + health_bonus, tower.max_health)
			tower.shots = tower_shots
			tower.fire_interval_ms = tower_interval_ms
			tower.update_health()
		_update_counters()
	if money < money_before:
		skill_levels[id] = int(skill_levels.get(id, 1)) + 1
	_update_build_ui()


func _set_collector_stats(drone: Node2D) -> void:
	drone.speed = collector_move_speed
	drone.mining_speed = collector_mining_speed
	drone.capacity = collector_capacity
	if drone.is_inside_tree():
		drone._update_status()


func _refresh_collector_stats() -> void:
	for child in get_children():
		if child.get_script() == Drone and child.collector_index >= 0 and buildings[child.collector_index].kind == 0:
			_set_collector_stats(child)


func _spawn_collector_drone(index: int) -> void:
	var building: Dictionary = base_drone_settings if index == BASE_HOME else buildings[index]
	var drone := Drone.new()
	drone.world = self
	drone.collector_index = index
	drone.position = Vector2(building.anchor) * CELL
	if index == BASE_HOME:
		drone.position = Vector2.ZERO
		drone.tint = BASE_COLOR
		drone.collects_money = true
		drone.speed = 140.0
	elif building.kind == 1:
		drone.passive = true
		drone.tint = BUILDING_COLORS[1]
		drone.max_health = barracks_drone_health
		drone.attack_damage = barracks_attack
	elif building.kind == 3:
		drone.mechanic = true
		drone.tint = BUILDING_COLORS[3]
	if building.has("main_drone") and is_instance_valid(building.main_drone) and not building.main_drone.is_queued_for_deletion():
		var main: Node2D = building.main_drone
		drone.speed = main.speed
		drone.capacity = main.capacity
		drone.deposit_duration = main.deposit_duration
		drone.pickup_duration = main.pickup_duration
		drone.mining_power = main.mining_power
	else:
		building["main_drone"] = drone
	drone.mining_power = mining_level
	if index != BASE_HOME and building.kind == 0:
		_set_collector_stats(drone)
	if drone.mechanic:
		drone.speed = workshop_speed
	add_child(drone)
	if drone.passive:
		drone.destroyed.connect(_on_barracks_drone_destroyed.bind(index))
		_assign_combat_targets()
	_update_drone_count()
	drone.tree_exited.connect(_update_drone_count)


func _on_barracks_drone_destroyed(index: int) -> void:
	_queue_drone(index)


func _update_drone_count() -> void:
	if not is_instance_valid(drone_count_label) or not is_inside_tree():
		return
	var count := 0
	for child in get_children():
		if child.get_script() == Drone and not child.hostile and child.is_inside_tree() and not child.is_queued_for_deletion():
			count += 1
	drone_count_label.text = tr("Drohnen: %d") % count
	if is_instance_valid(enemy_count_label):
		enemy_count_label.text = tr("Gegner: %d") % _live_combat_drones("enemy_drones").size()


func _live_combat_drones(group: String) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if not is_inside_tree():
		return result
	for node in get_tree().get_nodes_in_group(group):
		if node.world == self and not node.dead and not node.is_queued_for_deletion():
			result.append(node)
	return result


func spawn_enemy_wave() -> void:
	if is_game_over or get_tree().paused:
		return
	var edge := (map_radius + 0.5) * CELL
	spawned_waves += 1
	var number := spawned_waves
	wave_alive[number] = 6 + 2 * (number - 1)
	for index in int(wave_alive[number]):
		var enemy := Drone.new()
		enemy.world = self
		enemy.collector_index = -2
		enemy.hostile = true
		enemy.max_health = 3 + floori(float(number - 1) / 4.0)
		enemy.tint = Color("ff7373")
		var along := randf_range(-edge + 12, edge - 12)
		match randi_range(0, 3):
			0: enemy.position = Vector2(-edge, along)
			1: enemy.position = Vector2(edge, along)
			2: enemy.position = Vector2(along, -edge)
			3: enemy.position = Vector2(along, edge)
		add_child(enemy)
		enemy.destroyed.connect(_on_enemy_destroyed.bind(number))
		enemy.tree_exited.connect(_update_drone_count)
	_update_drone_count()
	_assign_combat_targets()


func _on_enemy_destroyed(number: int) -> void:
	wave_alive[number] -= 1
	var before := cleared_waves
	while wave_alive.has(cleared_waves + 1) and wave_alive[cleared_waves + 1] == 0:
		cleared_waves += 1
	if cleared_waves != before:
		_update_build_ui()
	_update_drone_count()
	if not combat_reassign_pending:
		combat_reassign_pending = true
		_flush_combat_reassignment.call_deferred()


func _flush_combat_reassignment() -> void:
	combat_reassign_pending = false
	_assign_combat_targets()


func _base_distance(point: Vector2) -> float:
	return point.distance_to(point.clamp(BASE_AREA.position, BASE_AREA.end))


func _assign_combat_targets() -> void:
	if is_game_over or not is_inside_tree():
		return
	var enemies := _live_combat_drones("enemy_drones")
	var defenders := _live_combat_drones("barracks_drones")
	enemies.sort_custom(func(a: Node2D, b: Node2D) -> bool: return _base_distance(a.position) < _base_distance(b.position))
	var assigned: Dictionary = {}
	var sectors: Dictionary = {}
	var engaged: Dictionary = {}
	# Keep defenders in mutual melee and account for their assignments before
	# spreading the remaining defenders over approaching threats.
	for defender in defenders:
		var target: Node2D = defender.combat_target
		if is_instance_valid(target) and not target.dead and not target.is_queued_for_deletion() and target.combat_target == defender and defender.position.distance_to(target.position) <= 20.001:
			engaged[defender.get_instance_id()] = true
			assigned[target.get_instance_id()] = int(assigned.get(target.get_instance_id(), 0)) + 1
			var sector := posmod(floori((target.position.angle() + PI) / TAU * 8.0), 8)
			sectors[sector] = int(sectors.get(sector, 0)) + 1
	for defender in defenders:
		if engaged.has(defender.get_instance_id()):
			continue
		var best: Node2D = null
		var best_score := INF
		for enemy in enemies:
			var sector := posmod(floori((enemy.position.angle() + PI) / TAU * 8.0), 8)
			# Prefer urgent threats, spreading additional defenders across approach directions.
			var score: float = _base_distance(enemy.position) + int(assigned.get(enemy.get_instance_id(), 0)) * CELL * 4 + int(sectors.get(sector, 0)) * CELL * 2
			if score < best_score:
				best_score = score
				best = enemy
		defender.combat_ai.set_target(best)
		if best != null:
			assigned[best.get_instance_id()] = int(assigned.get(best.get_instance_id(), 0)) + 1
			var sector := posmod(floori((best.position.angle() + PI) / TAU * 8.0), 8)
			sectors[sector] = int(sectors.get(sector, 0)) + 1


func _can_build(anchor: Vector2i) -> bool:
	for y in 2:
		for x in 2:
			var cell := anchor + Vector2i(x, y)
			if absi(cell.x) > map_radius or absi(cell.y) > map_radius or occupied_cells.has(cell):
				return false
			if block_cells.has(cell) and is_instance_valid(block_cells[cell]):
				if not block_cells[cell].is_queued_for_deletion():
					return false
	return true


func _place_building() -> void:
	if not is_build_menu_available() or not _available_building_indices().has(selected_building):
		return
	var anchor := _build_anchor()
	var cost := _building_cost(selected_building)
	if not _can_build(anchor) or money < cost or _building_count(selected_building) >= _building_limit(selected_building):
		return
	buildings.append({"anchor": anchor, "kind": selected_building, "money": 0, "construction": Balance.BUILD_SECONDS[selected_building], "pending_drones": 0, "production": 0.0, "paid_cost": cost})
	var index := buildings.size() - 1
	var status := Label.new()
	status.position = Vector2(anchor) * CELL + Vector2(-20, -68)
	status.z_index = 100
	add_child(status)
	buildings[index]["status"] = status
	for y in 2:
		for x in 2:
			occupied_cells[anchor + Vector2i(x, y)] = true
	money -= cost
	_update_counters()
	_set_build_mode(BuildMode.PLAY)
	queue_redraw()


func _finish_building(index: int) -> void:
	var building_kind: int = buildings[index].kind
	var anchor: Vector2i = buildings[index].anchor
	if building_kind == 0:
		var label := Label.new()
		label.position = Vector2(anchor) * CELL + Vector2(-20, -48)
		label.z_as_relative = false
		label.z_index = 100
		label.add_theme_font_size_override("font_size", 15)
		add_child(label)
		buildings[index]["label"] = label
		update_collector_label(index)
		for drone in collector_drone_count:
			_spawn_collector_drone(index)
	elif building_kind == 1:
		for drone in barracks_drone_count:
			_spawn_collector_drone(index)
	elif building_kind == 2:
		var tower := preload("res://scripts/tower.gd").new()
		tower.world = self
		tower.building_index = index
		tower.position = (Vector2(anchor) + Vector2(0.5, 0.5)) * CELL
		tower.max_health = tower_health
		tower.shots = tower_shots
		tower.fire_interval_ms = tower_interval_ms
		buildings[index]["tower"] = tower
		add_child(tower)
		tower.destroyed.connect(_on_tower_destroyed.bind(tower.building_index))
	elif building_kind == 3:
		for drone in workshop_drone_count:
			_spawn_collector_drone(index)
	_update_build_ui()
	queue_redraw()


func _on_tower_destroyed(index: int) -> void:
	buildings[index]["destroyed"] = true
	var anchor: Vector2i = buildings[index].anchor
	for y in 2:
		for x in 2:
			occupied_cells.erase(anchor + Vector2i(x, y))
	_update_build_ui()
	queue_redraw()


func building_rect(index: int) -> Rect2:
	return Rect2(Vector2(buildings[index].anchor) * CELL - Vector2.ONE * CELL / 2.0, Vector2.ONE * CELL * 2.0)


func building_at(point: Vector2) -> int:
	for index in buildings.size():
		if not buildings[index].get("destroyed", false) and building_rect(index).has_point(point):
			return index
	return -1


func building_refund(index: int) -> int:
	return floori(float(buildings[index].get("paid_cost", 0)) * 0.75)


func sell_building(index: int) -> void:
	if is_game_over or return_dialog_open or index < 0 or index >= buildings.size() or buildings[index].get("destroyed", false):
		return
	var building := buildings[index]
	# Keep indices stable: removed buildings remain as inactive records.
	building.destroyed = true
	money += building_refund(index) + int(building.money)
	building.money = 0
	building.pending_drones = 0
	for child in get_children():
		if child.get_script() != Drone:
			continue
		if child.collector_index == index and not child.is_queued_for_deletion():
			money += child.carried * money_per_block
			if is_instance_valid(child.target):
				child.target.release_drone(child)
				child.target = null
			child.dead = true
			child.queue_free()
		elif child.collects_money and child.cash_source == index:
			child.cash_source = -1
			child.path.clear()
			child.deposit_elapsed = 0.0
			child.retry_time = 0.0
	if building.has("tower") and is_instance_valid(building.tower):
		building.tower.dead = true
		building.tower.queue_free()
	for key in ["label", "status"]:
		if building.has(key) and is_instance_valid(building[key]):
			building[key].queue_free()
	for y in 2:
		for x in 2:
			occupied_cells.erase(building.anchor + Vector2i(x, y))
	building_context.close()
	_update_drone_count()
	_update_counters()
	_update_build_ui()
	_assign_combat_targets()
	queue_redraw()


func update_collector_label(index: int) -> void:
	var building := buildings[index]
	building.label.text = tr("Sammler: %d Geld") % building.money


func deposit_drone_blocks(index: int, amount: int) -> void:
	var value := amount * money_per_block
	if index == BASE_HOME:
		receive_income(value)
		_update_counters()
		_update_build_ui()
	else:
		buildings[index]["money"] += value
		update_collector_label(index)


func receive_income(amount: int) -> void:
	money += amount
	if amount > 0:
		income_received.emit(amount)


func is_build_menu_available() -> bool:
	return true


func is_skill_menu_available() -> bool:
	return true


func _available_building_indices() -> Array:
	return range(BUILDINGS.size())


func _available_skill_indices() -> Array:
	return range(SKILLS.size())


func _cycle_available(indices: Array, current: int, direction: int) -> int:
	return indices[posmod(indices.find(current) + direction, indices.size())] if not indices.is_empty() else current


func _building_cost(kind: int) -> int:
	var count := _building_count(kind)
	var prices: Array = Balance.BUILD_PRICES[kind]
	return maxi(0, int(prices[mini(count, prices.size() - 1)]) + [collector_cost - 30, barracks_cost - 25, tower_cost - 20, 0][kind])


func _building_count(kind: int) -> int:
	var count := 0
	for building in buildings:
		if building.kind == kind and not building.get("destroyed", false):
			count += 1
	return count


func _building_limit(kind: int) -> int:
	return Balance.BUILD_LIMITS[kind][Balance.stage(cleared_waves, kind != 0)]


func _skill_purchases(id: String) -> int:
	return int(skill_levels.get(id, 0 if id == "cash_drone" else 1)) - (0 if id == "cash_drone" else 1)


func _skill_cost(id: String) -> int:
	var prices: Array = Balance.PRICES[id]
	return prices[mini(_skill_purchases(id), prices.size() - 1)]


func _skill_block_reason(id: String) -> String:
	if not Balance.PRICES.has(id):
		return tr("Noch nicht verfügbar")
	var bought := _skill_purchases(id)
	if bought >= Balance.PRICES[id].size():
		return tr("Maximum erreicht")
	var defense := Balance.is_defense_skill(id)
	var tier := Balance.stage(cleared_waves, defense)
	if bought >= Balance.upgrade_limit(id, tier):
		for future_tier in range(tier + 1, 4):
			if bought < Balance.upgrade_limit(id, future_tier):
				return tr("Freischaltung nach Welle %d") % Balance.unlock_waves(defense)[future_tier - 1]
		return tr("Maximum erreicht")
	var kind := -1
	if id.begins_with("collector_") or id == "cash_drone":
		kind = 0
	elif id.begins_with("barracks_"):
		kind = 1
	elif id.begins_with("tower_"):
		kind = 2
	elif id.begins_with("workshop_"):
		kind = 3
	if kind >= 0:
		var ready_building := false
		for building in buildings:
			if building.kind == kind and not building.get("destroyed", false) and building.construction <= 0.0:
				ready_building = true
		if not ready_building:
			return tr("%s fertigstellen") % tr(BUILDINGS[kind])
	return ""


func _queue_drone(index: int) -> void:
	if is_game_over or buildings[index].get("destroyed", false):
		return
	# Unfinished buildings receive their full current complement at completion.
	if buildings[index].construction > 0.0:
		return
	buildings[index].pending_drones += 1


func _tick_production(delta: float) -> void:
	if is_game_over:
		return
	if base_drone_settings.pending_drones > 0:
		base_drone_settings.production += delta
		while base_drone_settings.production >= 8.0 and base_drone_settings.pending_drones > 0:
			base_drone_settings.production -= 8.0
			base_drone_settings.pending_drones -= 1
			_spawn_collector_drone(BASE_HOME)
		if base_drone_settings.pending_drones == 0:
			base_drone_settings.production = 0.0
		_update_counters()
	for index in buildings.size():
		var building := buildings[index]
		if building.get("destroyed", false):
			continue
		var available := delta
		if building.construction > 0.0:
			available = maxf(0.0, delta - building.construction)
			building.construction = maxf(0.0, building.construction - delta)
			if building.construction <= 0.0:
				_finish_building(index)
		if building.pending_drones > 0:
			building.production += available
			var duration := 20.0 if building.kind in [1, 3] else 8.0
			while building.production >= duration and building.pending_drones > 0:
				building.production -= duration
				building.pending_drones -= 1
				_spawn_collector_drone(index)
			if building.pending_drones == 0:
				building.production = 0.0
		building.status.text = tr("Bau: %d s") % ceili(building.construction) if building.construction > 0.0 else (tr("Drohnen: %d · %d s") % [building.pending_drones, ceili((20.0 if building.kind in [1, 3] else 8.0) - building.production)] if building.pending_drones > 0 else "")


func _update_build_ui() -> void:
	build_preview.visible = build_mode == BuildMode.PLACE
	if build_preview.visible:
		build_preview.queue_redraw()
	build_panel.visible = build_mode in [BuildMode.MENU, BuildMode.SKILLS]
	build_options.refresh_info()
	build_status.visible = build_mode == BuildMode.PLACE
	if build_mode == BuildMode.SKILLS:
		var skills: Array = SKILLS.duplicate(true)
		for skill in skills:
			skill.name = tr(skill.name)
			skill.group = tr(skill.group)
			skill.description = tr(skill.description)
			skill.level = int(skill_levels.get(skill.get("id", ""), 1))
			var id: String = skill.get("id", "")
			if Balance.PRICES.has(id):
				skill.cost = _skill_cost(id)
				skill.lock_reason = _skill_block_reason(id)
			if skill.get("id", "") == "base_health":
				skill.current_effect = tr("%d maximale Lebenspunkte") % base_max_health
				skill.next_effect = tr("%d maximale Lebenspunkte") % (base_max_health + 25)
			elif skill.get("id", "") == "cash_drone":
				skill.description = tr("-sammelt Geld ein-")
				var count: int = skill_levels.get("cash_drone", 0)
				skill.current_effect = tr("%d %s") % [count, tr("Geld-Sammeldrohne") if count == 1 else tr("Geld-Sammeldrohnen")]
				skill.next_effect = tr("%d %s") % [count + 1, tr("Geld-Sammeldrohne") if count == 0 else tr("Geld-Sammeldrohnen")]
			elif skill.get("id", "") == "collector_drones":
				skill.description = tr("-baut Blöcke ab-")
				skill.current_effect = tr("%d %s je Sammler") % [collector_drone_count, tr("Drohne") if collector_drone_count == 1 else tr("Drohnen")]
				skill.next_effect = tr("%d Drohnen je Sammler") % (collector_drone_count + 1)
			elif skill.get("id", "") == "barracks_drones":
				skill.current_effect = tr("%d %s je Kaserne") % [barracks_drone_count, tr("Drohne") if barracks_drone_count == 1 else tr("Drohnen")]
				skill.next_effect = tr("%d Drohnen je Kaserne") % (barracks_drone_count + 1)
			elif skill.get("id", "") == "mining_level":
				skill.current_effect = tr("Abbaustufe %d") % mining_level
				skill.next_effect = tr("Abbaustufe %d") % (mining_level + 1)
			elif skill.get("id", "") == "collector_speed":
				skill.current_effect = tr("Bewegung: %d Pixel/s\nAbbau: %d %%") % [collector_move_speed, collector_mining_speed]
				skill.next_effect = tr("Bewegung: %d Pixel/s\nAbbau: %d %%") % [collector_move_speed + 10, collector_mining_speed + 5]
			elif skill.get("id", "") == "collector_capacity":
				skill.current_effect = tr("%d Einheiten Tragkapazität") % collector_capacity
				skill.next_effect = tr("%d Einheiten Tragkapazität") % (collector_capacity + 5)
			elif skill.get("id", "") == "barracks_health":
				skill.current_effect = tr("%d maximale Lebenspunkte") % barracks_drone_health
				skill.next_effect = tr("%d maximale Lebenspunkte") % (barracks_drone_health + 10)
			elif id == "barracks_attack":
				skill.current_effect = tr("%d Schaden je Treffer") % barracks_attack
				skill.next_effect = tr("2 Schaden je Treffer")
			elif skill.get("id", "") == "tower_health":
				skill.current_effect = tr("%d maximale Lebenspunkte") % tower_health
				skill.next_effect = tr("%d maximale Lebenspunkte") % (tower_health + 20)
			elif skill.get("id", "") == "tower_shots":
				skill.current_effect = tr("%d gleichzeitige Schüsse") % tower_shots
				skill.next_effect = tr("%d gleichzeitige Schüsse") % (tower_shots + 1)
			elif skill.get("id", "") == "tower_rate":
				skill.current_effect = tr("Schussintervall: %d ms") % tower_interval_ms
				skill.next_effect = tr("Schussintervall: %d ms") % maxi(1, floori(tower_interval_ms * 0.9))
			elif id == "workshop_drones":
				skill.current_effect = tr("%d Mechaniker-Drohnen") % workshop_drone_count
				skill.next_effect = tr("%d Mechaniker-Drohnen") % (workshop_drone_count + 1)
			elif id == "workshop_repair":
				skill.current_effect = tr("%d LP/s je Drohne") % workshop_repair
				skill.next_effect = tr("%d LP/s je Drohne") % (workshop_repair + 1)
			elif id == "workshop_speed":
				skill.current_effect = tr("%d Pixel/s") % workshop_speed
				skill.next_effect = tr("%d Pixel/s") % (workshop_speed + 20)
		for skill in skills:
			if skill.get("lock_reason", "") == tr("Maximum erreicht"):
				skill.next_effect = tr("Maximum erreicht")
		var available := _available_skill_indices()
		var visible_skills: Array = []
		for index in available:
			visible_skills.append(skills[index])
		build_options.configure(tr("SKILL-TREE"), visible_skills, maxi(0, available.find(selected_skill)), money, tr("WASD / Pfeile: Auswahl · Enter / E / Klick: auswählen\nJ / Esc: schließen"))
		return
	if build_mode == BuildMode.MENU:
		var items: Array = []
		var available := _available_building_indices()
		for index in available:
			var description := tr("Größe: 2 × 2 Felder\nStartet mit %d Sammeldrohnen.\nLagert das Geld der Drohnen.\nBerühren holt das Geld ab.") % collector_drone_count if index == 0 else tr("Größe: 2 × 2 Felder\nStartet mit %d Kampfdrohnen.\nVerteidigt die Basis gegen Gegner.") % barracks_drone_count
			if index == 2:
				description = tr("Größe: 2 × 2 Felder\nReichweite: 5 Grid-Felder\n%d Lebenspunkte\n%d Schüsse je Salve · Intervall: %d ms\n1 Schaden je Treffer.") % [tower_health, tower_shots, tower_interval_ms]
			elif index == 3:
				description = tr("Größe: 2 × 2 Felder · Maximal eine Werkstatt\n%d Mechaniker-Drohnen · %d LP/s je Drohne\nPriorität: Basis, Türme, ruhende Kampfdrohnen auf dem Kasernengelände.") % [workshop_drone_count, workshop_repair]
			description += tr("\nBauzeit: %d s") % int(Balance.BUILD_SECONDS[index])
			items.append({"name": tr("%s (%d/%d)") % [tr(BUILDINGS[index]), _building_count(index), _building_limit(index)], "lock_reason": tr("Gebäudelimit erreicht") if _building_count(index) >= _building_limit(index) else "", "cost": _building_cost(index), "icon": ["res://assets/icons/collector.svg", "res://assets/icons/barracks.svg", "res://assets/icons/tower.svg", "res://assets/icons/workshop.svg"][index], "description": description})
		build_options.configure(tr("BAUEN / 2 × 2"), items, maxi(0, available.find(selected_building)), money, tr("WASD / Pfeile: Auswahl\nEnter / E / Klick: auswählen · B / Esc: schließen"))
	if build_mode == BuildMode.PLACE:
		var valid := _can_build(_build_anchor())
		var cost := _building_cost(selected_building)
		var affordable := money >= cost and _building_count(selected_building) < _building_limit(selected_building)
		var status := tr("Fläche frei") if valid else tr("Fläche blockiert (Basis, Gebäude oder Blöcke)")
		if _building_count(selected_building) >= _building_limit(selected_building):
			status += tr(" · Gebäudelimit erreicht")
		elif money < cost:
			status += tr(" · Zu wenig Geld")
		var controls := tr("Maus: positionieren · Linksklick: bauen · Rechts ziehen: Kamera\nRechtsklick / Esc: abbrechen") if mouse_placement else tr("Bewegen: positionieren · Enter / E: bauen · Rechts ziehen: Kamera\nRechtsklick / Esc: abbrechen")
		build_status.text = tr("%s / 2 × 2 / Kosten: %d / Geld: %d\n%s\n%s") % [tr(BUILDINGS[selected_building]), cost, money, controls, status]
		build_status.modulate = Color("8ef0b0") if valid and affordable else Color("ff9393")


func _create_boundary() -> void:
	# Invisible bedrock keeps the finite prototype map enclosed.
	var edge := (map_radius + 0.5) * CELL
	for side in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var body := StaticBody2D.new()
		body.position = side * (edge + CELL / 2.0)
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(CELL, edge * 2 + CELL * 2) if side.x != 0 else Vector2(edge * 2 + CELL * 2, CELL)
		collision.shape = shape
		body.add_child(collision)
		add_child(body)


func _create_hud() -> void:
	var layer := preload("res://scripts/game_ui.gd").new()
	layer.name = "GameUI"
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	building_context = preload("res://scripts/building_context.gd").new()
	building_context.world = self
	layer.add_child(building_context)
	var playback := HBoxContainer.new()
	playback.name = "PlaybackControls"
	playback.position = Vector2(20, 20)
	playback.process_mode = Node.PROCESS_MODE_ALWAYS
	playback.add_theme_constant_override("separation", 6)
	layer.add_child(playback)
	play_button = Button.new()
	play_button.name = "Play"
	play_button.icon = preload("res://assets/icons/play.svg")
	play_button.tooltip_text = tr("Fortsetzen")
	play_button.custom_minimum_size = Vector2(44, 40)
	play_button.focus_mode = Control.FOCUS_NONE
	playback.add_child(play_button)
	play_button.pressed.connect(_set_paused.bind(false))
	pause_button = Button.new()
	pause_button.name = tr("Pause")
	pause_button.icon = preload("res://assets/icons/pause.svg")
	pause_button.tooltip_text = tr("Pausieren")
	pause_button.custom_minimum_size = Vector2(44, 40)
	pause_button.focus_mode = Control.FOCUS_NONE
	playback.add_child(pause_button)
	pause_button.pressed.connect(_set_paused.bind(true))
	speed_button = Button.new()
	speed_button.name = "Speed"
	speed_button.text = tr("1×")
	speed_button.tooltip_text = tr("Spieltempo wechseln: 1× → 1,5× → 2× → 3×")
	speed_button.custom_minimum_size = Vector2(60, 40)
	speed_button.focus_mode = Control.FOCUS_NONE
	playback.add_child(speed_button)
	speed_button.pressed.connect(_cycle_game_speed)
	_update_pause_controls()
	wave_timer = preload("res://scripts/wave_timer.gd").new()
	wave_timer.name = "WaveTimer"
	wave_timer.anchor_left = 0.5
	wave_timer.anchor_right = 0.5
	wave_timer.offset_left = -180.0
	wave_timer.offset_right = 180.0
	wave_timer.offset_top = 20.0
	wave_timer.offset_bottom = 60.0
	layer.add_child(wave_timer)
	wave_timer.wave_due.connect(func(_number: int) -> void: spawn_enemy_wave())
	var panel := PanelContainer.new()
	panel.name = "MinerInfo"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -20.0
	panel.offset_right = -20.0
	panel.offset_top = 176.0
	panel.offset_bottom = 176.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	layer.add_child(panel)
	panel.hide()
	main_menu_button = Button.new()
	main_menu_button.name = "MainMenuButton"
	main_menu_button.icon = preload("res://assets/icons/home.svg")
	main_menu_button.tooltip_text = tr("Zurück zum Hauptmenü")
	main_menu_button.anchor_left = 1.0
	main_menu_button.anchor_right = 1.0
	main_menu_button.offset_left = -64.0
	main_menu_button.offset_right = -20.0
	main_menu_button.offset_top = 20.0
	main_menu_button.offset_bottom = 64.0
	main_menu_button.focus_mode = Control.FOCUS_NONE
	layer.add_child(main_menu_button)
	main_menu_button.pressed.connect(layer.open_return_dialog)
	var info_button := Button.new()
	info_button.name = "InfoButton"
	info_button.text = "i"
	info_button.tooltip_text = tr("Spielinformationen öffnen")
	info_button.custom_minimum_size = Vector2(44, 44)
	info_button.anchor_left = 1.0
	info_button.anchor_right = 1.0
	info_button.offset_left = -64.0
	info_button.offset_right = -20.0
	info_button.offset_top = 72.0
	info_button.offset_bottom = 116.0
	info_button.focus_mode = Control.FOCUS_NONE
	info_button.toggle_mode = true
	layer.add_child(info_button)
	info_button.toggled.connect(func(open: bool) -> void:
		panel.visible = open
		info_button.tooltip_text = tr("Spielinformationen schließen") if open else tr("Spielinformationen öffnen")
	)
	wave_pause_button = Button.new()
	wave_pause_button.name = "WavePauseButton"
	wave_pause_button.icon = preload("res://assets/icons/pause.svg")
	wave_pause_button.tooltip_text = tr("Wellentimer anhalten")
	wave_pause_button.toggle_mode = true
	wave_pause_button.focus_mode = Control.FOCUS_NONE
	wave_pause_button.anchor_left = 1.0
	wave_pause_button.anchor_right = 1.0
	wave_pause_button.offset_left = -64.0
	wave_pause_button.offset_right = -20.0
	wave_pause_button.offset_top = 124.0
	wave_pause_button.offset_bottom = 168.0
	layer.add_child(wave_pause_button)
	wave_pause_button.toggled.connect(_set_wave_timer_paused)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	margin.add_child(rows)
	var title := Label.new()
	title.text = tr("MINER / PROTOTYP")
	title.add_theme_color_override("font_color", Color("66e5db"))
	rows.add_child(title)
	drone_count_label = Label.new()
	rows.add_child(drone_count_label)
	enemy_count_label = Label.new()
	rows.add_child(enemy_count_label)
	_update_drone_count()
	money_label = Label.new()
	money_label.position = Vector2(-68, -100)
	money_label.z_as_relative = false
	money_label.z_index = 100
	money_label.add_theme_font_size_override("font_size", 15)
	add_child(money_label)
	base_health_label = Label.new()
	base_health_label.name = "BaseHealth"
	base_health_label.position = Vector2(-72, -24)
	base_health_label.size = Vector2(144, 48)
	base_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	base_health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	base_health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base_health_label.z_as_relative = false
	base_health_label.z_index = 100
	base_health_label.add_theme_font_size_override("font_size", 16)
	base_health_label.add_theme_constant_override("outline_size", 3)
	base_health_label.add_theme_color_override("font_outline_color", Color("172332"))
	add_child(base_health_label)
	_update_base_health()
	_update_counters()
	var help := Label.new()
	help.text = tr("WASD / Pfeiltasten: bewegen\nZum Abbauen gegen einen Block laufen und halten.\nLoslassen oder Ziel wechseln setzt den Fortschritt zurück.")
	rows.add_child(help)
	var deposit_help := Label.new()
	deposit_help.text = tr("Basis (3 × 3): Getragene Blöcke automatisch verkaufen.")
	rows.add_child(deposit_help)
	var build_help := Label.new()
	build_help.text = tr("B: Bauen · J: Skill-Tree\nLinksklick: laufen · Rechte Maustaste ziehen: Karte verschieben\nRechtsklick auf Gebäude: Infos / Abreißen\nMausrad: Karte zoomen")
	rows.add_child(build_help)
	build_panel = PanelContainer.new()
	layer.add_child(build_panel)
	var build_margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		build_margin.add_theme_constant_override("margin_" + side, 8)
	build_panel.add_child(build_margin)
	build_options = preload("res://scripts/option_menu.gd").new()
	build_margin.add_child(build_options)
	build_options.option_activated.connect(_on_option_clicked)
	build_status = Label.new()
	build_status.position = Vector2(20, 240)
	layer.add_child(build_status)
	var action_menu := preload("res://scenes/action_menu.tscn").instantiate()
	# A shared bottom-left container keeps both panels docked as widths change.
	var menu_dock := HBoxContainer.new()
	menu_dock.name = "MenuDock"
	menu_dock.anchor_top = 1.0
	menu_dock.anchor_bottom = 1.0
	menu_dock.offset_left = 20.0
	menu_dock.offset_right = 20.0
	menu_dock.offset_top = -20.0
	menu_dock.offset_bottom = -20.0
	menu_dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	menu_dock.add_theme_constant_override("separation", 8)
	layer.add_child(menu_dock)
	action_menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	action_menu.size_flags_vertical = Control.SIZE_SHRINK_END
	menu_dock.add_child(action_menu)
	build_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	build_panel.reparent(menu_dock)
	var item_info := preload("res://scripts/menu_info.gd").new()
	item_info.name = "ItemInfo"
	menu_dock.add_child(item_info)
	build_options.info_panel = item_info
	_update_pause_controls()
	action_menu.build_requested.connect(_on_build_button_pressed)
	action_menu.skills_requested.connect(_on_skills_button_pressed)
	_update_build_ui()


func _on_build_button_pressed() -> void:
	_set_build_mode(BuildMode.PLAY if build_mode == BuildMode.MENU else BuildMode.MENU)


func _on_skills_button_pressed() -> void:
	_set_build_mode(BuildMode.PLAY if build_mode == BuildMode.SKILLS else BuildMode.SKILLS)


func _on_option_clicked(index: int) -> void:
	if build_mode == BuildMode.SKILLS:
		selected_skill = _available_skill_indices()[index]
		_confirm_skill()
	elif build_mode == BuildMode.MENU:
		selected_building = _available_building_indices()[index]
		mouse_placement = true
		$Player.navigation_path.clear()
		_set_build_mode(BuildMode.PLACE)


func _on_block_collected(by_player: bool = true) -> void:
	navigation_revision += 1
	if not by_player:
		return
	collected_count += 1
	_update_counters()


func _mining_jobs_changed() -> void:
	mining_assignment_revision += 1


func has_mining_job(power: int) -> bool:
	if mining_cache_revision != navigation_revision or mining_cache_assignments != mining_assignment_revision:
		mining_job_cache.clear()
		mining_cache_revision = navigation_revision
		mining_cache_assignments = mining_assignment_revision
	if not mining_job_cache.has(power):
		mining_job_cache[power] = false
		for block in block_cells.values():
			if is_instance_valid(block) and not block.is_queued_for_deletion() and not block.depleted and block.hardness <= power and not is_instance_valid(block.mining_drone):
				mining_job_cache[power] = true
				break
	return mining_job_cache[power]


func _set_wave_timer_paused(value: bool) -> void:
	if is_game_over:
		return
	wave_timer.set_timer_paused(value)
	wave_pause_button.icon = preload("res://assets/icons/play.svg") if value else preload("res://assets/icons/pause.svg")
	wave_pause_button.tooltip_text = tr("Wellentimer fortsetzen") if value else tr("Wellentimer anhalten")


func _cycle_game_speed() -> void:
	if is_game_over or return_dialog_open:
		return
	game_speed_index = (game_speed_index + 1) % GAME_SPEEDS.size()
	var speed: float = GAME_SPEEDS[game_speed_index]
	Engine.time_scale = speed
	# Keep simulation steps equally small at higher speed.
	Engine.physics_ticks_per_second = roundi(normal_physics_rate * speed)
	speed_button.text = [tr("1×"), tr("1,5×"), tr("2×"), tr("3×")][game_speed_index]


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = normal_physics_rate


func _set_paused(value: bool) -> void:
	if is_game_over or (return_dialog_open and not value):
		return
	mouse_held = false
	camera_drag_held = false
	mouse_dragging = false
	suppress_left_release = false
	get_tree().paused = value
	get_node("GameUI").show_pause_badge(value and not return_dialog_open)
	_update_pause_controls()


func _update_pause_controls() -> void:
	play_button.disabled = is_game_over or return_dialog_open or not get_tree().paused
	pause_button.disabled = is_game_over or return_dialog_open or get_tree().paused
	speed_button.disabled = is_game_over or return_dialog_open
	if is_instance_valid(main_menu_button):
		main_menu_button.disabled = is_game_over or return_dialog_open
	if is_instance_valid(wave_pause_button):
		wave_pause_button.disabled = is_game_over or return_dialog_open


func damage_base(amount: int) -> void:
	if amount <= 0 or is_game_over:
		return
	base_health = maxi(0, base_health - amount)
	_update_base_health()
	if base_health == 0:
		_end_game()


func _end_game() -> void:
	if is_game_over:
		return
	is_game_over = true
	get_node("/root/MetaStats").save_now()
	get_node("GameUI").show_pause_badge(false)
	_set_build_mode(BuildMode.PLAY)
	mouse_goal_active = false
	$Player.navigation_path.clear()
	$Player.velocity = Vector2.ZERO
	$Player.movement_enabled = false
	$Player.mining_enabled = false
	game_over_screen = preload("res://scenes/game_over.tscn").instantiate()
	add_child(game_over_screen)
	get_tree().paused = true
	_update_pause_controls()


func _update_base_health() -> void:
	base_health_label.text = tr("Lebenspunkte\n%d/%d") % [base_health, base_max_health]


func _update_counters() -> void:
	$Player.update_load(collected_count)
	money_label.text = tr("Basis: %d Geld") % money
	if base_drone_settings.pending_drones > 0:
		money_label.text += tr("\nGeld-Drohne: %d s") % ceili(8.0 - base_drone_settings.production)


func _draw() -> void:
	draw_rect(Rect2(-120, -120, 240, 240), Color("293c49"))
	for line in range(-2, 4):
		var offset := line * CELL - CELL / 2.0
		draw_line(Vector2(offset, -120), Vector2(offset, 120), Color("344b58"))
		draw_line(Vector2(-120, offset), Vector2(120, offset), Color("344b58"))
	draw_rect(BASE_AREA, Color("365665"))
	for offset in [-24, 24]:
		draw_line(Vector2(offset, -72), Vector2(offset, 72), Color("517b89"))
		draw_line(Vector2(-72, offset), Vector2(72, offset), Color("517b89"))
	draw_rect(BASE_AREA, BASE_COLOR, false, 3)
	draw_circle(Vector2.ZERO, 34, Color("365665"))
	draw_circle(Vector2.ZERO, 25, Color("426b79"))
	for building in buildings:
		if building.get("destroyed", false) or (building.kind == 2 and building.construction <= 0.0):
			continue
		var rect := Rect2(Vector2(building.anchor) * CELL - Vector2.ONE * CELL / 2, Vector2.ONE * CELL * 2)
		var color: Color = BUILDING_COLORS[building.kind]
		draw_rect(rect.grow(-4), color.darkened(0.5))
		draw_rect(rect.grow(-4), color, false, 3)
		if building.kind == 0:
			for offset in [Vector2(14, 14), Vector2(52, 14), Vector2(14, 52), Vector2(52, 52)]:
				draw_rect(Rect2(rect.position + offset, Vector2(28, 28)), color)
		elif building.kind == 3:
			draw_rect(Rect2(rect.position + Vector2(18, 28), Vector2(60, 50)), color)
			draw_line(rect.position + Vector2(48, 35), rect.position + Vector2(48, 69), color.darkened(0.6), 8)
			draw_line(rect.position + Vector2(31, 52), rect.position + Vector2(65, 52), color.darkened(0.6), 8)
		else:
			draw_rect(Rect2(rect.position + Vector2(14, 22), Vector2(68, 56)), color)
			draw_rect(Rect2(rect.position + Vector2(39, 48), Vector2(18, 30)), color.darkened(0.6))
			draw_line(rect.position + Vector2(10, 22), rect.position + Vector2(48, 9), color.lightened(0.3), 4)
			draw_line(rect.position + Vector2(48, 9), rect.position + Vector2(86, 22), color.lightened(0.3), 4)
