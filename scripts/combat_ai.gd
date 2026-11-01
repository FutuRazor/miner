extends RefCounted

const ATTACK_INTERVAL := 1.0
var actor: Node2D
var contact_time := 0.0


func _init(drone: Node2D) -> void:
	actor = drone


func set_target(next: Node2D) -> void:
	if actor.combat_target != next:
		contact_time = 0.0
		actor.combat_target = next


func _alive(node) -> bool:
	return is_instance_valid(node) and not node.is_queued_for_deletion() and not node.dead


func will_move() -> bool:
	if _alive(actor.combat_target):
		return actor.position.distance_to(actor.combat_target.position) > 20.001
	var home: Vector2 = Vector2(actor.world.buildings[actor.collector_index].anchor) * actor.world.CELL
	return not actor.position.is_equal_approx(home)


func tick(delta: float) -> void:
	if actor.dead or actor.world.is_game_over:
		return
	if not _alive(actor.combat_target):
		set_target(null)
		if not actor.hostile:
			actor.world._assign_combat_targets()
	if not actor.hostile and not _alive(actor.combat_target):
		contact_time = 0.0
		var home: Vector2 = Vector2(actor.world.buildings[actor.collector_index].anchor) * actor.world.CELL
		actor.position = actor.position.move_toward(home, actor.speed * delta)
		return
	var attacking_base: bool = actor.hostile and not _alive(actor.combat_target)
	var destination: Vector2
	var reach := 20.0
	if attacking_base:
		var area: Rect2 = actor.world.BASE_AREA
		destination = actor.position.clamp(area.position, area.end)
		reach = 10.0
	elif actor.combat_target.is_tower:
		var area: Rect2 = actor.combat_target.get_world_rect()
		destination = actor.position.clamp(area.position, area.end)
		reach = 10.0
	else:
		destination = actor.combat_target.position
	var distance: float = actor.position.distance_to(destination)
	var travel := maxf(0.0, distance - reach)
	var step := minf(travel, actor.speed * delta)
	if step > 0.0:
		actor.position = actor.position.move_toward(destination, step)
	if travel > step + 0.001:
		contact_time = 0.0
		return
	# Intercept on contact, not on the first damage tick. Otherwise an equally
	# fast fleeing enemy consumes the defender's entire tick in pursuit forever.
	if actor.passive and _alive(actor.combat_target) and actor.combat_target.hostile:
		var opponent: Node2D = actor.combat_target
		if not _alive(opponent.combat_target) or opponent.combat_target.is_tower:
			opponent.combat_ai.set_target(actor)
	# Count only time actually spent in contact, with a separate clock per attacker.
	var contact_delta := delta - step / maxf(actor.speed, 0.001)
	contact_time += maxf(0.0, contact_delta)
	while contact_time + 0.000001 >= ATTACK_INTERVAL:
		contact_time = maxf(0.0, contact_time - ATTACK_INTERVAL)
		if actor.dead or actor.world.is_game_over:
			break
		actor.attack_flash = 0.15
		actor.queue_redraw()
		if attacking_base:
			actor.world.damage_base(1)
		elif _alive(actor.combat_target):
			actor.combat_target.take_damage(actor.attack_damage, actor)
		else:
			set_target(null)
			break
