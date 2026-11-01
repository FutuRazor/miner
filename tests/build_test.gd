extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _key(world: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	world._input(event)


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.money = 0
	world.set_physics_process(false)
	var player = world.get_node("Player")
	player.set_physics_process(false)
	_key(world, KEY_B)
	assert(world.build_mode == world.BuildMode.MENU)
	assert(player.movement_enabled and player.mining_enabled and not player.keyboard_movement_enabled)
	assert(world.build_panel.visible)
	_key(world, KEY_S)
	assert(world.selected_building == 1)
	_key(world, KEY_ENTER)
	assert(world.build_mode == world.BuildMode.PLACE)
	assert(player.movement_enabled and player.mining_enabled)
	assert(not world._can_build(Vector2i.ZERO))
	assert(not world._can_build(Vector2i(-2, -2)))
	assert(not world._can_build(Vector2i(1, 1)))
	assert(not world._can_build(Vector2i(2, 0)))
	assert(not world._can_build(Vector2i(22, 22)))
	player.position = Vector2(96, 0)
	_key(world, KEY_ENTER)
	assert(world.buildings.is_empty())
	assert(world.money == 0)
	# A single uncleared cell must prevent the entire 2 x 2 footprint.
	for cell in [Vector2i(3, 0), Vector2i(2, 1), Vector2i(3, 1)]:
		if world.block_cells.has(cell):
			world.block_cells[cell].queue_free()
	assert(world._can_build(Vector2i(2, 0)))
	_key(world, KEY_ENTER)
	assert(world.buildings.is_empty() and world.money == 0)
	world.money = 9
	_key(world, KEY_ENTER)
	assert(world.buildings.is_empty() and world.money == 9)
	_key(world, KEY_ESCAPE)
	assert(world.buildings.is_empty() and player.mining_enabled)
	assert(world.money == 9)
	world.money = 25
	_key(world, KEY_B)
	_key(world, KEY_ENTER)
	_key(world, KEY_ENTER)
	assert(world.buildings.size() == 1 and world.occupied_cells.size() == 13)
	assert(world.money == 0 and world.money_label.text == "Basis: 0 Geld")
	world._place_building()
	world._tick_production(10.0)
	assert(world.money == 0 and world.buildings.size() == 1)
	assert(not world._can_build(Vector2i.ZERO))
	assert(not world._can_build(Vector2i(-1, -1)))
	assert(world.build_mode == world.BuildMode.PLAY)
	# Storage can be placed for exactly its price, leaving a zero balance.
	player.position = Vector2(-96, 96)
	world.selected_building = 0
	world.money = 30
	for cell in [Vector2i(-2, 3), Vector2i(-1, 3)]:
		world.block_cells[cell].queue_free()
	_key(world, KEY_B)
	_key(world, KEY_ENTER)
	_key(world, KEY_ENTER)
	assert(world.money == 0 and world.buildings.size() == 2)
	_key(world, KEY_B)
	_key(world, KEY_B)
	assert(world.build_mode == world.BuildMode.PLAY and player.movement_enabled)
	_key(world, KEY_B)
	_key(world, KEY_ESCAPE)
	assert(world.build_mode == world.BuildMode.PLAY)
	print("PASS: build menu, WASD selection, modes, blocked cells, footprint, overlap, placement and cancellation")
	world.queue_free()
	quit()
