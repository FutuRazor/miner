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
	world.get_node("Player").set_physics_process(false)
	assert(world.base_health == 100 and world.base_max_health == 100)
	var label: Label = world.base_health_label
	assert(label.text == "Lebenspunkte\n100/100")
	assert(label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER)
	assert(label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER)
	assert(label.position + label.size / 2.0 == Vector2.ZERO)
	assert(label.z_index == 100 and not label.z_as_relative)
	assert(label.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	world.damage_base(35)
	assert(world.base_health == 65 and label.text == "Lebenspunkte\n65/100")
	world.damage_base(-20)
	assert(world.base_health == 65)
	world.damage_base(1000)
	assert(world.base_health == 0 and label.text == "Lebenspunkte\n0/100")
	print("PASS: base starts at 100/100, centered two-line overlay, damage updates and clamps at zero")
	world.queue_free()
	quit()
