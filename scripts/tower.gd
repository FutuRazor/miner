extends Node2D

signal destroyed

var world: Node2D
var building_index: int
var is_tower := true
var passive := false
var dead := false
var max_health := 100
var health := 100
var shots := 1
var fire_interval_ms := 1000
var elapsed := 0.0
var facing := Vector2.UP
var health_label: Label


func _ready() -> void:
	z_index = 2
	health = max_health
	add_to_group("towers")
	health_label = Label.new()
	health_label.position = Vector2(-65, -84)
	health_label.size = Vector2(130, 42)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_label.z_as_relative = false
	health_label.z_index = 100
	health_label.add_theme_font_size_override("font_size", 13)
	add_child(health_label)
	update_health()


func get_world_rect() -> Rect2:
	return Rect2(position - Vector2.ONE * world.CELL, Vector2.ONE * world.CELL * 2)


func nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var distance: float = pow(world.CELL * 5.0, 2)
	for enemy in world._live_combat_drones("enemy_drones"):
		var candidate := position.distance_squared_to(enemy.position)
		if candidate <= distance:
			distance = candidate
			nearest = enemy
	return nearest


func _physics_process(delta: float) -> void:
	if dead or world.is_game_over:
		return
	var enemy := nearest_enemy()
	if enemy == null:
		elapsed = 0.0
		return
	facing = (enemy.position - position).normalized()
	queue_redraw()
	elapsed += delta
	var interval := fire_interval_ms / 1000.0
	while elapsed + 0.000001 >= interval:
		elapsed = maxf(0.0, elapsed - interval)
		for shot in shots:
			var projectile := preload("res://scripts/tower_projectile.gd").new()
			projectile.world = world
			projectile.source = self
			projectile.target = enemy
			projectile.direction = facing
			projectile.position = position + facing * 25 + facing.orthogonal() * (shot - (shots - 1) / 2.0) * 8
			world.add_child(projectile)


func update_health() -> void:
	health_label.text = tr("Lebenspunkte\n%d/%d") % [health, max_health]


func take_damage(amount: int, _attacker: Node2D = null) -> void:
	if dead or amount <= 0:
		return
	health = maxi(0, health - amount)
	update_health()
	if health == 0:
		dead = true
		hide()
		destroyed.emit()
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-44, -44, 88, 88), Color("263e58"))
	draw_rect(Rect2(-44, -44, 88, 88), Color("7eb7ff"), false, 3)
	draw_circle(Vector2.ZERO, 26, Color("4d7fa9"))
	draw_line(Vector2.ZERO, facing * 35, Color("badfff"), 12)
	draw_circle(Vector2.ZERO, 14, Color("7eb7ff"))
