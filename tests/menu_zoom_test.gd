extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _settle() -> void:
	for frame in 4:
		await process_frame

func _wheel(point: Vector2, button: MouseButton) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = button
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func _run() -> void:
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world.wave_timer.set_physics_process(false)
	world._on_skills_button_pressed()
	await _settle()
	var camera: Camera2D = world.get_node("Player/Camera2D")
	var scroll: ScrollContainer = world.build_options.entry_scroll
	var point := scroll.get_global_rect().get_center()
	var initial_zoom := camera.zoom
	# Scroll the actual GUI, including repeated attempts beyond either end.
	for step in 60:
		_wheel(point, MOUSE_BUTTON_WHEEL_DOWN)
	assert(scroll.scroll_vertical > 0)
	assert(camera.zoom == initial_zoom)
	var bottom := scroll.scroll_vertical
	_wheel(point, MOUSE_BUTTON_WHEEL_UP)
	assert(scroll.scroll_vertical < bottom)
	for step in 60:
		_wheel(point, MOUSE_BUTTON_WHEEL_UP)
	assert(scroll.scroll_vertical == 0 and camera.zoom == initial_zoom)
	# The same protection covers non-scrollable menu areas and paused UI.
	point = world.build_panel.global_position + Vector2(8, 8)
	_wheel(point, MOUSE_BUTTON_WHEEL_UP)
	assert(camera.zoom == initial_zoom)
	world._set_paused(true)
	_wheel(point, MOUSE_BUTTON_WHEEL_DOWN)
	assert(camera.zoom == initial_zoom)
	world._set_paused(false)
	# Wheel events over the free map still zoom normally.
	point = Vector2(root.get_visible_rect().size.x - 120, 100)
	_wheel(point, MOUSE_BUTTON_WHEEL_UP)
	assert(camera.zoom.x > initial_zoom.x)
	world.queue_free()
	print("PASS: skill scrolling at both limits, menu hover and pause block map zoom; free map zoom works")
	quit()
