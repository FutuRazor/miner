extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _key(world: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	world._input(event)
	world.build_options._input(event)


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.money = 0
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	var options = world.build_options
	var info = options.info_panel
	assert(not info.visible)
	_key(world, KEY_B)
	assert(info.visible and info.title.text == "Sammler")
	_key(world, KEY_DOWN)
	assert(info.visible and info.title.text == "Kaserne")
	assert(info.description.text.contains("Verteidigt die Basis"))
	assert(info.cost.get_theme_color("font_color") == Color("ff7777"))
	# Keyboard details stay visible even without a mouse hover.
	options._hover_exited(0)
	assert(info.visible and info.title.text == "Kaserne")
	options._input(InputEventMouseMotion.new())
	assert(not info.visible)
	options.rows[0].button.mouse_entered.emit()
	assert(info.visible and info.title.text == "Sammler")
	assert(world.selected_building == 1)
	options.rows[0].button.mouse_exited.emit()
	assert(not info.visible)
	_key(world, KEY_UP)
	assert(info.visible and info.title.text == "Sammler")
	world.money = 30
	world._update_build_ui()
	assert(info.cost.get_theme_color("font_color") == Color("e9f6f5"))
	_key(world, KEY_ESCAPE)
	assert(not info.visible)
	world.selected_skill = 2
	_key(world, KEY_J)
	assert(info.visible and info.title.text == "Geld-Sammeldrohne (lvl. 0)")
	assert(info.description.text == "-sammelt Geld ein-")
	assert(info.current_effect.text == "0 Geld-Sammeldrohnen")
	assert(info.next_effect.text == "1 Geld-Sammeldrohne")
	_key(world, KEY_ESCAPE)
	world.selected_skill = 0
	world._on_skills_button_pressed()
	assert(info.visible and info.title.text == "Lebenspunkte (lvl. 1)")
	# The same generic panel supports future skill entries.
	options.configure("SKILL-TREE", [{"name": "Testfähigkeit", "cost": 5, "icon": "res://assets/icons/skills.svg", "description": "Beschreibung einer Fähigkeit."}], 0, 30, "")
	assert(info.visible and info.title.text == "Testfähigkeit")
	assert(info.description.text == "Beschreibung einer Fähigkeit.")
	print("PASS: keyboard selection info, mouse hover only, input-mode switch, affordability, closed-menu cleanup and skill support")
	world.queue_free()
	quit()
