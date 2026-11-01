extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.money = 0
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.get_node("Player").position = Vector2(100, 0)
	world._physics_process(0.0)
	for index in 5:
		world._on_block_collected()
	assert(world.collected_count == 5 and world.money == 0)
	# The free outer ring is outside the central 3 x 3 deposit area.
	world._physics_process(0.0)
	assert(world.collected_count == 5)
	world.get_node("Player").position = Vector2(71, 0)
	world._physics_process(0.0)
	assert(world.collected_count == 0 and world.money == 5)
	world._physics_process(0.0)
	assert(world.money == 5)
	world.get_node("Player").position = Vector2(100, 0)
	world._physics_process(0.0)
	world.money_per_block = 2
	world._on_block_collected()
	world._on_block_collected()
	world.get_node("Player").position = Vector2.ZERO
	world._physics_process(0.0)
	assert(world.collected_count == 0 and world.money == 9)
	assert(world.money_label.text == "Basis: 9 Geld")
	print("PASS: base deposit, reset, repeated visits and money rate")
	world.queue_free()
	quit()
