extends RefCounted

const CELL := 6.0
var actor: Node2D
var route: Array[Vector2] = []
var goal := Vector2(INF, INF)
var remaining := 0.0

func _init(drone: Node2D) -> void:
	actor = drone

func move_to(destination: Vector2, distance: float, delta: float, reach: float = 0.0) -> void:
	if actor.position.distance_to(destination) <= reach + 0.001:
		return
	var endpoint: Vector2 = actor.position.move_toward(destination, maxf(0.0, actor.position.distance_to(destination) - reach))
	if _clear_segment(actor.position, endpoint):
		route.clear()
		actor.position = actor.position.move_toward(endpoint, distance)
		return
	remaining -= delta
	if goal.distance_to(destination) > 12.0 or remaining <= 0.0:
		if not actor.world.drone_collisions.try_navigation_plan():
			return
		goal = destination
		remaining = 0.4
		_plan(destination, reach)
	var budget := distance
	while not route.is_empty() and budget > 0.0:
		var step := minf(budget, actor.position.distance_to(route[0]))
		actor.position = actor.position.move_toward(route[0], step)
		budget -= step
		if actor.position.distance_to(route[0]) <= 0.01:
			route.pop_front()
		else:
			break

func _clear_segment(start: Vector2, end: Vector2) -> bool:
	var neighbors: Array[Node2D] = actor.world._live_combat_drones("friendly_drones")
	neighbors.append_array(actor.world._live_combat_drones("enemy_drones"))
	for drone in neighbors:
		if drone == actor:
			continue
		var nearest := Geometry2D.get_closest_point_to_segment(drone.position, start, end)
		if nearest.distance_squared_to(drone.position) < 20.5 * 20.5:
			if nearest.is_equal_approx(start) and end.distance_squared_to(drone.position) >= start.distance_squared_to(drone.position):
				continue
			return false
	if not actor.mechanic and not actor.passive and not actor.hostile:
		var steps := maxi(1, ceili(start.distance_to(end) / CELL))
		for step in range(steps + 1):
			var point := start.lerp(end, float(step) / steps)
			if not actor.world._walkable_cell(Vector2i((point / actor.world.CELL).round())):
				return false
	return true

func _plan(destination: Vector2, reach: float) -> void:
	route.clear()
	var start: Vector2 = actor.position
	var local_goal := start.move_toward(destination, 144.0)
	var bounds := Rect2(start, Vector2.ZERO).expand(local_goal).grow(66.0)
	var origin := Vector2i((bounds.position / CELL).floor())
	var size := Vector2i((bounds.size / CELL).ceil()) + Vector2i.ONE
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, size)
	grid.cell_size = Vector2.ONE * CELL
	grid.offset = Vector2(origin) * CELL
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var neighbors: Array[Node2D] = actor.world._live_combat_drones("friendly_drones")
	neighbors.append_array(actor.world._live_combat_drones("enemy_drones"))
	var obstacles: Array[Vector2] = []
	for drone in neighbors:
		if drone != actor and bounds.grow(24.0).has_point(drone.position):
			obstacles.append(drone.position)
	var best := Vector2i.ZERO
	var score := INF
	var start_cell := Vector2i((start / CELL).round()) - origin
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			var point := Vector2(origin + cell) * CELL
			var blocked := false
			if not actor.mechanic and not actor.passive and not actor.hostile:
				blocked = not actor.world._walkable_cell(Vector2i((point / actor.world.CELL).round()))
			for obstacle in obstacles:
				if point.distance_squared_to(obstacle) < 20.5 * 20.5:
					blocked = true
					break
			grid.set_point_solid(cell, blocked)
			if not blocked:
				var candidate := point.distance_squared_to(local_goal)
				# Prefer exact reachable endpoints; a free point within reach is
				# sufficient when docking or approaching another drone.
				if start.distance_to(destination) <= 144.0 and point.distance_to(destination) <= reach:
					candidate = point.distance_squared_to(start) * 0.0001
				if candidate < score:
					score = candidate
					best = cell
	grid.set_point_solid(start_cell, false)
	if score == INF:
		return
	var points := grid.get_point_path(start_cell, best, true)
	if points.size() == 1 and start.distance_to(points[0]) > 0.01:
		route.append(points[0])
	# The first grid point may be behind the actor after collision displacement.
	for index in range(1, points.size()):
		route.append(points[index])
	if start.distance_to(destination) <= 144.0 and score < 0.01 and reach == 0.0:
		route.append(destination)
