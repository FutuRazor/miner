extends RefCounted

const Drone = preload("res://scripts/drone.gd")
const Boss = preload("res://scripts/boss.gd")
var world: Node2D


func _init(owner_world: Node2D) -> void:
	world = owner_world


func normal_health(number: int) -> int:
	return 3 + floori(float(number - 1) / 4.0)


func _edge_position() -> Vector2:
	var edge: float = (world.map_radius + 0.5) * world.CELL
	var along := randf_range(-edge + 12, edge - 12)
	match randi_range(0, 3):
		0: return Vector2(-edge, along)
		1: return Vector2(edge, along)
		2: return Vector2(along, -edge)
	return Vector2(along, edge)


func _configure(enemy: Node2D, number: int, point: Vector2) -> void:
	enemy.world = world
	enemy.wave_number = number
	enemy.collector_index = -2
	enemy.hostile = true
	enemy.max_health = normal_health(number)
	enemy.tint = Color("ff7373")
	enemy.position = point
	enemy.tree_exited.connect(world._update_drone_count)


func spawn_wave(number: int) -> void:
	if world.has_mission_limit() and number in [10, 20]:
		world.wave_alive[number] = 1
		var boss := Boss.new()
		_configure(boss, number, _edge_position())
		boss.final_boss = number == 20
		boss.wave_number = number
		boss.name = "FinalBoss" if boss.final_boss else "MidBoss"
		boss.max_health *= 50 if boss.final_boss else 20
		boss.ignores_attackers = true
		boss.pushes_drones = true
		boss.speed = 100.0 if boss.final_boss else 50.0
		boss.tint = Color("c88aff") if boss.final_boss else Color("ffad55")
		boss.boss_defeated.connect(world._on_enemy_destroyed)
		world.add_child(boss)
	else:
		world.wave_alive[number] = 6 + 2 * (number - 1)
		for index in int(world.wave_alive[number]):
			var enemy := Drone.new()
			_configure(enemy, number, _edge_position())
			enemy.destroyed.connect(world._on_enemy_destroyed.bind(number))
			world.add_child(enemy)
	world._update_drone_count()
	world._assign_combat_targets()


func spawn_swarmer(boss: Node2D) -> Node2D:
	var enemy := Drone.new()
	_configure(enemy, boss.wave_number, boss.position)
	enemy.name = "Swarmer"
	enemy.is_swarmer = true
	enemy.destroyed.connect(world._on_swarmer_destroyed)
	world.add_child(enemy)
	world._update_drone_count()
	world._assign_combat_targets()
	return enemy
