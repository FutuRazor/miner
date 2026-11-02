extends StaticBody2D

signal collected(by_player: bool)

@export var mining_duration: float = 1.0
@export_range(1, 16, 1) var mining_steps: int = 4
@export_range(1, 100, 1) var hardness: int = 1
var completed_steps := 0
var progress: float = 0.0
var tint := Color("79644f")
var depleted := false
var mining_drone: Node


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48, 48)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)


func available_for_drone(drone: Node) -> bool:
	return not depleted and hardness <= drone.mining_power and (not is_instance_valid(mining_drone) or mining_drone == drone)


func claim_for_drone(drone: Node) -> bool:
	if not available_for_drone(drone):
		return false
	if mining_drone != drone:
		progress = 0.0
		mining_drone = drone
		if get_parent().has_method("_mining_jobs_changed"):
			get_parent()._mining_jobs_changed()
	return true


func release_drone(drone: Node) -> void:
	if mining_drone == drone:
		mining_drone = null
		if get_parent().has_method("_mining_jobs_changed"):
			get_parent()._mining_jobs_changed()
		reset_progress()


func mine(delta: float, by_player: bool = true, drone: Node = null, mining_power: int = 1) -> bool:
	var power: int = drone.mining_power if is_instance_valid(drone) else mining_power
	if hardness > power:
		return false
	if depleted or (is_instance_valid(mining_drone) and mining_drone != drone):
		return false
	progress += delta
	queue_redraw()
	if progress >= mining_duration:
		progress = 0.0
		completed_steps += 1
		depleted = completed_steps >= mining_steps
		var stats := get_node_or_null("/root/MetaStats")
		if stats != null:
			stats.record_block_step(hardness, depleted)
		if depleted and get_parent().has_method("has_mission_limit"):
			get_parent().sectors_mined += 1
		collected.emit(by_player)
		if depleted:
			queue_free()
		return true
	return false


func reset_progress() -> void:
	if is_instance_valid(mining_drone):
		return
	progress = 0.0
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-24, -24, 48, 48), Color("26292d"))
	draw_rect(Rect2(-22, -22, 44, 44), tint)
	draw_line(Vector2(-19, -19), Vector2(19, -19), tint.lightened(0.2), 2)
	draw_line(Vector2(10, -8), Vector2(16, 0), tint.darkened(0.25), 2)
	draw_string(ThemeDB.fallback_font, Vector2(-5, 4), str(hardness), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff1d7"))
	for step in mining_steps:
		var width := 38.0 / mining_steps
		var color := Color("66e5db") if step < completed_steps else tint.darkened(0.4)
		draw_rect(Rect2(-19 + step * width, -15, width - 2, 3), color)
	if progress > 0:
		draw_rect(Rect2(-19, 12, 38, 6), Color("18212b"))
		draw_rect(Rect2(-19, 12, 38 * clampf(progress / mining_duration, 0, 1), 6), Color("f4c86b"))
