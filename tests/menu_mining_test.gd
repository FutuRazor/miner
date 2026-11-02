extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _key(world: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	world._input(event)

func _run() -> void:
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	var player = world.get_node("Player")
	player.set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	player.position = Vector2(103, 0)
	var block: Node = world.block_cells[Vector2i(3, 0)]
	player._physics_process(0.4)
	assert(player.mining_target == block and is_equal_approx(block.progress, 0.4))
	_key(world, KEY_B)
	assert(player.mining_target == block and is_equal_approx(block.progress, 0.4), "Opening the build menu must preserve mining progress")
	player._physics_process(0.2)
	assert(is_equal_approx(block.progress, 0.6))
	_key(world, KEY_J)
	assert(player.mining_target == block and is_equal_approx(block.progress, 0.6))
	# WASD controls menu selection without moving the character.
	Input.action_press("ui_right")
	player._physics_process(0.2)
	Input.action_release("ui_right")
	assert(player.position.is_equal_approx(Vector2(103, 0)))
	assert(is_equal_approx(block.progress, 0.8))
	_key(world, KEY_ESCAPE)
	assert(is_equal_approx(block.progress, 0.8))
	player._physics_process(0.21)
	assert(world.collected_count == 1)
	# Starting through a map command while a menu is open remains supported.
	_key(world, KEY_J)
	world._set_mouse_goal(player.position)
	player._physics_process(0.4)
	assert(player.mining_target == block and is_equal_approx(block.progress, 0.4))
	_key(world, KEY_J)
	assert(is_equal_approx(block.progress, 0.4))
	# Full inventory and global pause still stop actual resource production.
	world.collected_count = player.capacity
	world._update_counters()
	player._physics_process(1.0)
	assert(world.collected_count == player.capacity and block.progress == 0.0)
	world._set_paused(true)
	assert(not player.can_process())
	world._set_paused(false)
	world.queue_free()
	print("PASS: uninterrupted mining across build/skill menus, preserved progress, menu keyboard isolation and inventory/pause limits")
	quit()
