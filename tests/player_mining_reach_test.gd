extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	var player = world.get_node("Player")
	var block: Node = world.block_cells[Vector2i(3, 0)]
	block.mining_duration = 0.15
	player.set_physics_process(false)
	player.position = Vector2(101, 0)
	assert(player._nearby_mining_target() == null)
	player.position = Vector2(103, 0)
	assert(player._nearby_mining_target() == block)
	player.position = Vector2.ZERO
	player.navigation_path = world._walk_path(Vector2(144, 0))
	player.set_physics_process(true)
	for tick in 120:
		await physics_frame
	assert(not is_instance_valid(block))
	assert(world.collected_count == 4 and player.carried == 4)
	assert(player.navigation_path.is_empty())
	assert(player.position.distance_to(Vector2(107, 0)) <= 1.0)
	player.set_physics_process(false)
	var next: Node = world.block_cells[Vector2i(4, 0)]
	player.position = Vector2(155, 0)
	assert(player._nearby_mining_target() == next)
	world.collected_count = 10
	world._update_counters()
	player._physics_process(1.0)
	assert(next.progress == 0.0 and not next.depleted)
	world.collected_count = 0
	world._update_counters()
	next.hardness = 2
	assert(player._nearby_mining_target() == null)
	next.hardness = 1
	world._set_build_mode(world.BuildMode.MENU)
	player._physics_process(1.0)
	assert(next.progress == 0.0)
	print("PASS: 6px extra reach, mouse arrival automatically mines, radius boundary, capacity, hardness and menu lock")
	world.queue_free()
	quit()
