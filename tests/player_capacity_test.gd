extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.money = 0
	world.set_physics_process(false)
	var player = world.get_node("Player")
	player.position = Vector2(96, 0)
	world._physics_process(0.0)
	world.collected_count = 9
	world._update_counters()
	assert(player.load_label.text == "9/10" and player.can_mine())
	world.block_cells[Vector2i(3, 0)].mining_duration = 0.01
	world.block_cells[Vector2i(3, 0)].mining_steps = 1
	Input.action_press("ui_right")
	for tick in 100:
		await physics_frame
	Input.action_release("ui_right")
	assert(world.collected_count == 10 and player.carried == 10)
	assert(not player.can_mine() and player.load_label.text == "10/10 Voll")
	assert(is_instance_valid(world.block_cells[Vector2i(4, 0)]))
	assert(world.block_cells[Vector2i(4, 0)].progress == 0.0)
	# Deposit restores both the label and the ability to mine.
	player.position = Vector2.ZERO
	world._physics_process(0.0)
	assert(world.collected_count == 0 and world.money == 10)
	assert(player.can_mine() and player.load_label.text == "0/10")
	player.position = Vector2(144, 0)
	world.block_cells[Vector2i(4, 0)].mining_duration = 0.01
	world.block_cells[Vector2i(4, 0)].mining_steps = 1
	Input.action_press("ui_right")
	for tick in 30:
		await physics_frame
	Input.action_release("ui_right")
	assert(world.collected_count == 1 and player.carried == 1)
	print("PASS: character load label, capacity 10, blocked mining at capacity, base deposit and resumed mining")
	world.queue_free()
	quit()
