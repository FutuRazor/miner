extends RefCounted

var actor: Node2D
var repair_target: Node2D
var elapsed := 0.0

func _init(drone: Node2D) -> void:
	actor = drone

func _damaged(target: Node2D) -> bool:
	return is_instance_valid(target) and target != actor.world and not target.is_queued_for_deletion() and not target.dead and target.health < target.max_health

func can_repair_drone(drone: Node2D) -> bool:
	if not _damaged(drone) or not drone.passive or drone.is_moving:
		return false
	var building: Dictionary = actor.world.buildings[drone.collector_index]
	return not building.get("destroyed", false) and actor.world.building_rect(drone.collector_index).has_point(drone.position) and not drone.combat_ai.will_move()

func _reserved(target: Node2D) -> bool:
	if target == actor.world:
		return false
	for drone in actor.world._live_combat_drones("friendly_drones"):
		if drone != actor and drone.mechanic and drone.mechanic_ai.repair_target == target:
			# Invalid assignments stop reserving immediately, even before their
			# owner's next physics tick (e.g. a departing barracks drone).
			if _damaged(target) and (target.is_tower or can_repair_drone(target)):
				return true
	return false

func _lowest_health(candidates: Array[Node2D], towers: bool) -> Node2D:
	var best: Node2D = null
	for target in candidates:
		if not (_damaged(target) if towers else can_repair_drone(target)) or _reserved(target):
			continue
		if best == null or target.health < best.health or (target.health == best.health and actor.position.distance_squared_to(target.position) < actor.position.distance_squared_to(best.position)):
			best = target
	return best

func _choose_target() -> Node2D:
	var world: Node2D = actor.world
	if world.base_health < world.base_max_health:
		return world
	# Finish an assigned target instead of oscillating as its HP increases.
	# Higher-priority categories may still interrupt the assignment.
	if _damaged(repair_target) and repair_target.is_tower and not _reserved(repair_target):
		return repair_target
	var best := _lowest_health(world._live_combat_drones("towers"), true)
	if best != null:
		return best
	if is_instance_valid(repair_target) and repair_target != world and can_repair_drone(repair_target) and not _reserved(repair_target):
		return repair_target
	return _lowest_health(world._live_combat_drones("barracks_drones"), false)

func tick(delta: float) -> void:
	if actor.dead or actor.world.is_game_over:
		return
	var next := _choose_target()
	if repair_target != next:
		repair_target = next
		elapsed = 0.0
	if next == null:
		elapsed = 0.0
		actor.park_home(delta)
		actor._update_status()
		return
	var destination: Vector2
	if next == actor.world:
		var area: Rect2 = actor.world.BASE_AREA
		destination = actor.position.clamp(area.position, area.end)
	elif next.is_tower:
		var area: Rect2 = next.get_world_rect()
		destination = actor.position.clamp(area.position, area.end)
	else:
		destination = next.position
	var reach: float = 10.0 if next == actor.world or next.is_tower else actor.COLLISION_RADIUS + next.COLLISION_RADIUS + 4.0
	var travel := maxf(0.0, actor.position.distance_to(destination) - reach)
	var step := minf(travel, actor.speed * delta)
	actor.navigation.move_to(destination, step, delta, reach)
	if actor.position.distance_to(destination) > reach + 0.001:
		elapsed = 0.0
		actor._update_status()
		return
	if travel > step + 0.001:
		elapsed = 0.0
		actor._update_status()
		return
	elapsed += maxf(0.0, delta - step / maxf(actor.speed, 0.001))
	while elapsed + 0.000001 >= 1.0:
		elapsed = maxf(0.0, elapsed - 1.0)
		if next == actor.world:
			next.base_health = mini(next.base_max_health, next.base_health + next.workshop_repair)
			next._update_base_health()
		else:
			next.health = mini(next.max_health, next.health + actor.world.workshop_repair)
			if next.is_tower:
				next.update_health()
			else:
				next._update_status()
		actor.attack_flash = 0.15
		if (next == actor.world and next.base_health == next.base_max_health) or (next != actor.world and next.health == next.max_health):
			elapsed = 0.0
			break
	actor._update_status()
