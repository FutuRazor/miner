extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world._on_skills_button_pressed()
	world.money = 9
	world._on_option_clicked(0)
	assert(world.base_health == 100 and world.base_max_health == 100 and world.money == 9)
	assert(world.build_options.current_items[0].level == 1)
	world.money = 20
	world._on_option_clicked(0)
	assert(world.base_health == 150 and world.base_max_health == 150 and world.money == 10)
	assert(world.build_options.info_panel.title.text == "Lebenspunkte (lvl. 2)")
	assert(world.base_health_label.text == "Lebenspunkte\n150/150")
	world.damage_base(35)
	world._on_option_clicked(0)
	assert(world.base_health == 165 and world.base_max_health == 200 and world.money == 0)
	assert(world.build_options.info_panel.title.text == "Lebenspunkte (lvl. 3)")
	assert(world.base_health_label.text == "Lebenspunkte\n165/200")
	assert(world.build_mode == world.BuildMode.SKILLS and world.build_panel.visible)
	assert(world.build_options.current_items[0].current_effect == "200 maximale Lebenspunkte")
	assert(world.build_options.current_items[0].next_effect == "250 maximale Lebenspunkte")
	world.damage_base(165)
	assert(world.is_game_over)
	print("PASS: health upgrade costs 10, repeatable +50 current/max, damage preserved, live info and game-over threshold")
	world.queue_free()
	quit()
