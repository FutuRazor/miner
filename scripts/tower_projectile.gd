extends Node2D

var world: Node2D
var target: Node2D
var source: Node2D
var speed := 500.0
var direction := Vector2.RIGHT


func _ready() -> void:
	z_index = 20
	add_to_group("tower_projectiles")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.dead or target.is_queued_for_deletion():
		queue_free()
		return
	var difference := target.position - position
	direction = difference.normalized()
	if difference.length() <= speed * delta + 5.0:
		var attacker: Node2D = source if is_instance_valid(source) and not source.dead else null
		target.take_damage(1, attacker)
		queue_free()
	else:
		position += direction * speed * delta
	queue_redraw()


func _draw() -> void:
	draw_line(-direction * 9, Vector2.ZERO, Color("7eb7ff"), 3)
	draw_circle(Vector2.ZERO, 3, Color("e5f3ff"))
