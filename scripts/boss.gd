extends "res://scripts/drone.gd"

signal boss_defeated(number: int)

var final_boss := false
var swarmer_timer: Timer
var swarmers: Array[Node2D] = []


func _ready() -> void:
	super._ready()
	status.position.y = -65
	destroyed.connect(_on_boss_destroyed)
	if final_boss:
		swarmer_timer = Timer.new()
		swarmer_timer.name = "SwarmerTimer"
		swarmer_timer.wait_time = 5.0
		swarmer_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
		swarmer_timer.timeout.connect(_spawn_swarmers)
		add_child(swarmer_timer)
		swarmer_timer.start()


func _spawn_swarmers() -> void:
	if dead or world.is_game_over or get_tree().paused:
		return
	for index in range(swarmers.size() - 1, -1, -1):
		if not is_instance_valid(swarmers[index]) or swarmers[index].dead:
			swarmers.remove_at(index)
	for index in 3:
		swarmers.append(world.spawn_manager.spawn_swarmer(self))


func _on_boss_destroyed() -> void:
	if is_instance_valid(swarmer_timer):
		swarmer_timer.stop()
	# Minions belong to this boss encounter, but never block its completion.
	for swarmer in swarmers:
		if is_instance_valid(swarmer) and not swarmer.dead:
			swarmer.dead = true
			swarmer.hide()
			swarmer.queue_free()
	boss_defeated.emit(wave_number)


func _update_status() -> void:
	super._update_status()
	status.text = (tr("FinalBoss") if final_boss else tr("MidBoss")) + "\n" + status.text


func _draw() -> void:
	draw_circle(Vector2(0, 4), 24, Color("172332"))
	draw_circle(Vector2.ZERO, 22, tint)
	draw_arc(Vector2.ZERO, 27, 0, TAU, 32, tint.lightened(0.4), 3)
	draw_line(Vector2(-30, -10), Vector2(30, -10), tint.lightened(0.5), 5)
	draw_circle(Vector2.ZERO, 8, Color("554e79"))
	if attack_flash > 0.0:
		draw_arc(Vector2.ZERO, 30, 0, TAU, 32, Color.WHITE, 3)
