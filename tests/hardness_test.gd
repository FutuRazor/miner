extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	var player = world.get_node("Player")
	player.set_physics_process(false)
	assert(player.mining_power == 1)
	for cell in world.block_cells:
		var ring := maxi(absi(cell.x), absi(cell.y)) - 2
		assert(world.block_cells[cell].hardness == ceili(float(ring) / 2.0))
	var hard: Node = world.block_cells[Vector2i(5, 0)]
	assert(hard.hardness == 2)
	assert(not hard.mine(10.0))
	assert(hard.progress == 0.0 and not hard.depleted)
	world.collector_cost = 0
	player.position = Vector2(96, 0)
	for cell in [Vector2i(3, 0), Vector2i(3, 1)]:
		world.block_cells[cell].queue_free()
	world._place_building()
	world._tick_production(10.0)
	var drone: Node2D = world.buildings[0].main_drone
	drone.set_physics_process(false)
	assert(drone.mining_power == 1)
	assert(not hard.claim_for_drone(drone))
	assert(not hard.mine(10.0, false, drone))
	assert(hard.progress == 0.0)
	# Remove every mineable block; harder blocks still form impassable walls.
	for block in world.block_cells.values():
		if is_instance_valid(block) and block.hardness == 1:
			block.queue_free()
	drone._plan(false)
	assert(not is_instance_valid(drone.target))
	assert(drone.path.is_empty())
	drone.carried = 3
	drone._plan(false)
	assert(drone.returning)
	# Stronger miners can later be configured without bypassing block checks.
	drone.mining_power = 2
	drone.carried = 0
	drone._plan(false)
	assert(is_instance_valid(drone.target) and drone.target.hardness == 2)
	# Workplaces are now reserved before arrival; the player cannot steal one.
	if hard.mining_drone == drone:
		assert(not hard.mine(10.0, true, null, 2))
		hard.release_drone(drone)
	assert(hard.mine(10.0, true, null, 2))
	print("PASS: all hardness rings, player/drone strength 1, hard block rejection, drone filtering and partial-load return")
	world.queue_free()
	quit()
