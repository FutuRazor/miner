extends Node2D

signal destroyed

@export var max_health: int = 30
var health := 30
var attack_damage := 1
var dead := false
@export var speed: float = 100.0
@export var capacity: int = 10
@export_range(1, 10000, 1) var mining_speed: int = 100
@export var deposit_duration: float = 0.6
@export var pickup_duration: float = 0.6
@export_range(1, 100, 1) var mining_power: int = 1
@export var tint := Color("f4c86b")
var collects_money := false
var passive := false
var hostile := false
var is_tower := false
var combat_target: Node2D
var combat_ai: RefCounted
var attack_flash := 0.0
var cash_carried := 0
var cash_source := -1
var mechanic := false
var mechanic_ai: RefCounted
var is_moving := false

const DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
var world: Node2D
var collector_index: int
var carried := 0
var returning := false
var choose_from_collector := false
var deposit_elapsed := 0.0
var target: StaticBody2D
var path: Array[Vector2] = []
var retry_time := 0.0
var status: Label


func _ready() -> void:
	z_index = 3
	add_to_group("enemy_drones" if hostile else "friendly_drones")
	if passive:
		add_to_group("barracks_drones")
	if passive or hostile:
		combat_ai = preload("res://scripts/combat_ai.gd").new(self)
	if mechanic:
		mechanic_ai = preload("res://scripts/mechanic_ai.gd").new(self)
	status = Label.new()
	status.z_as_relative = false
	status.z_index = 100
	status.position = Vector2(-25, -36)
	status.add_theme_font_size_override("font_size", 13)
	add_child(status)
	if passive or hostile:
		health = max_health
		status.position = Vector2(-55, -48)
		status.size = Vector2(110, 42)
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_update_status()


func _physics_process(delta: float) -> void:
	if dead:
		return
	if attack_flash > 0.0:
		attack_flash = maxf(0.0, attack_flash - delta)
		queue_redraw()
	if passive or hostile:
		var before := position
		combat_ai.tick(delta)
		is_moving = not position.is_equal_approx(before)
		return
	if mechanic:
		mechanic_ai.tick(delta)
		return
	if collects_money and cash_source >= 0 and world.buildings[cash_source].money <= 0:
		# The player may have emptied the collector while this drone was en route.
		cash_source = -1
		path.clear()
		deposit_elapsed = 0.0
		retry_time = 0.0
		_update_status()
	if collects_money and cash_carried > 0 and (world.BASE_AREA.has_point(position) or position.distance_to(world.get_node("Player").position) <= 24.0):
		path.clear()
		_cash_deliver()
		return
	if not path.is_empty():
		position = position.move_toward(path[0], speed * delta)
		if position.distance_to(path[0]) < 0.01:
			path.pop_front()
		return
	if collects_money:
		_cash_tick(delta)
		return
	if returning:
		# The return path ends inside the drone's home building.
		deposit_elapsed += delta
		_update_status()
		if deposit_elapsed >= deposit_duration:
			world.deposit_drone_blocks(collector_index, carried)
			carried = 0
			deposit_elapsed = 0.0
			returning = false
			choose_from_collector = true
			world.queue_redraw()
			_update_status()
		return
	if is_instance_valid(target) and not target.is_queued_for_deletion():
		if not target.claim_for_drone(self):
			target = null
			_plan(false)
			return
		if target.mine(delta * float(mining_speed) / 100.0, false, self):
			carried += 1
			if target.depleted:
				target = null
			_update_status()
			if carried >= capacity:
				_plan(true)
		return
	target = null
	retry_time -= delta
	if retry_time <= 0.0:
		_plan(false)
		retry_time = 0.5


func _has_block(cell: Vector2i) -> bool:
	return world.block_cells.has(cell) and is_instance_valid(world.block_cells[cell]) and not world.block_cells[cell].is_queued_for_deletion()


func _exit_tree() -> void:
	if is_instance_valid(target):
		target.release_drone(self)


func _plan(go_home: bool) -> void:
	if is_instance_valid(target):
		target.release_drone(self)
	target = null
	# Flood the reachable free grid; record paths and exposed mining faces.
	var start := Vector2i((position / world.CELL).round())
	var at_base: bool = collector_index == world.BASE_HOME
	var home: Vector2i = Vector2i(-1, -1) if at_base else world.buildings[collector_index].anchor
	var home_size := 3 if at_base else 2
	var home_center := Vector2(home) + Vector2.ONE * (home_size - 1) / 2.0
	var search_origin: Vector2 = home_center if choose_from_collector else position / world.CELL
	var previous: Dictionary = {start: start}
	var frontier: Array[Vector2i] = [start]
	var cursor := 0
	var best_distance := INF
	var destination := start
	var found := false
	var candidate: StaticBody2D = null
	while cursor < frontier.size():
		var cell := frontier[cursor]
		cursor += 1
		if go_home and cell.x >= home.x and cell.x < home.x + home_size and cell.y >= home.y and cell.y < home.y + home_size:
			destination = cell
			found = true
			break
		for direction in DIRECTIONS:
			var next: Vector2i = cell + direction
			if absi(next.x) > world.RADIUS or absi(next.y) > world.RADIUS:
				continue
			if _has_block(next):
				if not world.block_cells[next].available_for_drone(self):
					continue
				var distance := Vector2(next).distance_squared_to(search_origin)
				if not go_home and distance < best_distance:
					best_distance = distance
					destination = cell
					candidate = world.block_cells[next]
					found = true
			elif not previous.has(next):
				previous[next] = cell
				frontier.append(next)
	if not found:
		if carried > 0 and not go_home:
			_plan(true)
		return
	path.clear()
	var step := destination
	while step != start:
		path.push_front(Vector2(step) * world.CELL)
		step = previous[step]
	# Align even if the search started between cell centers.
	path.push_front(Vector2(start) * world.CELL)
	returning = go_home
	if not go_home:
		choose_from_collector = false
	target = candidate
	deposit_elapsed = 0.0
	_update_status()


func _update_status() -> void:
	if mechanic:
		status.text = "Reparatur: %d LP/s" % world.workshop_repair if is_instance_valid(mechanic_ai.repair_target) else "Mechaniker: bereit"
	elif passive or hostile:
		status.text = "Lebenspunkte\n%d/%d" % [health, max_health]
	elif collects_money:
		status.text = "%d Geld%s" % [cash_carried, " Abholen…" if cash_source >= 0 and path.is_empty() else ""]
	else:
		status.text = "%d/%d%s" % [carried, capacity, " Abgabe…" if returning and path.is_empty() else ""]
	queue_redraw()


func take_damage(amount: int, attacker: Node2D = null) -> void:
	if not (passive or hostile) or dead or amount <= 0:
		return
	health = maxi(0, health - amount)
	if hostile and is_instance_valid(attacker) and (attacker.passive or attacker.is_tower) and not attacker.dead and health > 0:
		combat_ai.set_target(attacker)
	_update_status()
	if health == 0:
		dead = true
		if hostile:
			var stats := get_node_or_null("/root/MetaStats")
			if stats != null:
				stats.record_enemy_defeated()
		hide()
		destroyed.emit()
		queue_free()


func _cash_tick(delta: float) -> void:
	if cash_carried > 0:
		var at_delivery: bool = world.BASE_AREA.has_point(position) or position.distance_to(world.get_node("Player").position) <= 24.0
		if not at_delivery:
			deposit_elapsed = 0.0
			path = _cash_route(-1)
			return
		_cash_deliver()
		return
	if cash_source >= 0:
		var source: Dictionary = world.buildings[cash_source]
		if source.money <= 0:
			cash_source = -1
			deposit_elapsed = 0.0
			_update_status()
			return
		deposit_elapsed += delta
		_update_status()
		if deposit_elapsed < pickup_duration:
			return
		deposit_elapsed = 0.0
		cash_carried = source.money
		source.money = 0
		world.update_collector_label(cash_source)
		cash_source = -1
		if cash_carried > 0:
			returning = true
			path = _cash_route(-1)
			_update_status()
			return
	retry_time -= delta
	if retry_time > 0.0:
		return
	retry_time = 0.5
	var highest := 0
	for index in world.buildings.size():
		var building: Dictionary = world.buildings[index]
		if building.get("destroyed", false) or building.kind != 0 or building.money <= highest or _cash_source_reserved(index):
			continue
		var route := _cash_route(index)
		if not route.is_empty():
			highest = building.money
			cash_source = index
			path = route


func _cash_source_reserved(index: int) -> bool:
	# The active pickup assignment is the reservation. No separate state can
	# become stale after cancellation, pickup, or removal of the owner.
	for drone in world._live_combat_drones("friendly_drones"):
		if drone != self and drone.collects_money and drone.cash_source == index:
			return true
	return false


func _cash_deliver() -> void:
	world.money += cash_carried
	cash_carried = 0
	returning = false
	deposit_elapsed = 0.0
	world._update_counters()
	world._update_build_ui()
	_update_status()


func _cash_route(source_index: int) -> Array[Vector2]:
	var start := Vector2i((position / world.CELL).round())
	var player: Node2D = world.get_node("Player")
	var player_cell := Vector2i((player.position / world.CELL).round())
	var previous: Dictionary = {start: start}
	var frontier: Array[Vector2i] = [start]
	var cursor := 0
	while cursor < frontier.size():
		var cell := frontier[cursor]
		cursor += 1
		var reached := false
		if source_index >= 0:
			var anchor: Vector2i = world.buildings[source_index].anchor
			reached = cell.x >= anchor.x and cell.x <= anchor.x + 1 and cell.y >= anchor.y and cell.y <= anchor.y + 1
		else:
			reached = (absi(cell.x) <= 1 and absi(cell.y) <= 1) or cell == player_cell
		if reached:
			var route: Array[Vector2] = []
			var step := cell
			while step != start:
				route.push_front(Vector2(step) * world.CELL)
				step = previous[step]
			route.push_front(Vector2(start) * world.CELL)
			if source_index < 0 and cell == player_cell:
				route.append(world._walk_target_in_cell(cell, player.position))
			return route
		for direction in DIRECTIONS:
			var next: Vector2i = cell + direction
			if not previous.has(next) and world._walkable_cell(next):
				previous[next] = cell
				frontier.append(next)
	return []


func _draw() -> void:
	draw_circle(Vector2(0, 3), 12, Color("172332"))
	draw_circle(Vector2.ZERO, 10, tint)
	draw_line(Vector2(-15, -6), Vector2(15, -6), tint.lightened(0.5), 3)
	draw_circle(Vector2.ZERO, 4, Color("554e79"))
	if mechanic:
		draw_line(Vector2(-5, 0), Vector2(5, 0), Color("d8ffe1"), 3)
		draw_line(Vector2(0, -5), Vector2(0, 5), Color("d8ffe1"), 3)
	if attack_flash > 0.0:
		draw_arc(Vector2.ZERO, 14, 0, TAU, 24, tint.lightened(0.5), 3)
		if is_instance_valid(combat_target):
			draw_line(Vector2.ZERO, combat_target.position - position, tint.lightened(0.5), 2)
	if (returning and not collects_money and path.is_empty()) or (collects_money and cash_source >= 0 and path.is_empty()):
		draw_rect(Rect2(-16, 14, 32, 4), Color("172332"))
		var duration := pickup_duration if collects_money else deposit_duration
		draw_rect(Rect2(-16, 14, 32 * clampf(deposit_elapsed / duration, 0, 1), 4), tint)
