extends Node

var world: Node2D
const ITERATIONS := 16
const MAX_PLANS_PER_TICK := 2
var planning_frame := -1
var planning_count := 0

func try_navigation_plan() -> bool:
	# Manual simulation tests manage their own time; live play shares a budget.
	if not world.is_physics_processing():
		return true
	var frame := Engine.get_physics_frames()
	if frame != planning_frame:
		planning_frame = frame
		planning_count = 0
	if planning_count >= MAX_PLANS_PER_TICK:
		return false
	planning_count += 1
	return true

func _ready() -> void:
	process_physics_priority = 100

func _physics_process(_delta: float) -> void:
	if not world.is_game_over and world.is_physics_processing():
		resolve()

func resolve() -> void:
	var drones: Array[Node2D] = world._live_combat_drones("friendly_drones")
	drones.append_array(world._live_combat_drones("enemy_drones"))
	# Positional circle constraints: overlap causes actual displacement, not
	# merely a steering suggestion. Rebuild broad-phase buckets after each pass.
	for iteration in ITERATIONS:
		var buckets: Dictionary = {}
		var changed := false
		for drone in drones:
			var cell := Vector2i((drone.position / 20.0).floor())
			for y in range(-1, 2):
				for x in range(-1, 2):
					for other in buckets.get(cell + Vector2i(x, y), []):
						var difference: Vector2 = drone.position - other.position
						var distance := difference.length()
						var overlap: float = drone.COLLISION_RADIUS + other.COLLISION_RADIUS - distance
						if overlap <= 0.001:
							continue
						var normal := difference / distance if distance > 0.001 else Vector2.from_angle(float(posmod(drone.get_instance_id() + other.get_instance_id(), 360)) * PI / 180.0)
						var correction := normal * (overlap + 0.001) * 0.5
						drone.position += correction
						other.position -= correction
						if drone.passive:
							drone.is_moving = true
						if other.passive:
							other.is_moving = true
						changed = true
			var final_cell := Vector2i((drone.position / 20.0).floor())
			if not buckets.has(final_cell):
				buckets[final_cell] = []
			buckets[final_cell].append(drone)
		if not changed:
			break
