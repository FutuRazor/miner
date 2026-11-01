extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _key(world: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	world._input(event)


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	var destinations := {KEY_B: world.BuildMode.MENU, KEY_J: world.BuildMode.SKILLS}
	for source in [world.BuildMode.PLAY, world.BuildMode.MENU, world.BuildMode.SKILLS, world.BuildMode.PLACE]:
		for key in destinations:
			world._set_build_mode(source)
			_key(world, key)
			var expected: int = world.BuildMode.PLAY if source == destinations[key] else destinations[key]
			assert(world.build_mode == expected)
	# U without a building must leave any other menu or placement untouched.
	world.get_node("Player").position = Vector2(96, 96)
	for source in [world.BuildMode.PLAY, world.BuildMode.MENU, world.BuildMode.SKILLS, world.BuildMode.PLACE]:
		world._set_build_mode(source)
		_key(world, KEY_U)
		assert(world.build_mode == source)
	_key(world, KEY_J)
	assert(world.build_mode == world.BuildMode.SKILLS)
	_key(world, KEY_ESCAPE)
	assert(world.build_mode == world.BuildMode.PLAY)
	print("PASS: all B/U/J menu transitions, toggle closing, placement switching and invalid upgrade target")
	world.queue_free()
	quit()
