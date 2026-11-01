extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame in 5:
		await process_frame


func _run() -> void:
	root.get_node("MetaStats").persistence_enabled = false
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.money = 0
	world.set_physics_process(false)
	world.get_node("Player").set_physics_process(false)
	world._set_build_mode(world.BuildMode.MENU)
	await _settle()
	var panel: Control = world.build_panel
	var menu: Control = panel.get_parent().get_node("ActionMenu")
	var initial_x := panel.global_position.x
	assert(is_equal_approx(initial_x, menu.get_global_rect().end.x + 8))
	assert(is_equal_approx(panel.get_global_rect().end.y, menu.get_global_rect().end.y))
	menu._toggle_expanded()
	await _settle()
	assert(panel.global_position.x > initial_x)
	assert(is_equal_approx(panel.global_position.x, menu.get_global_rect().end.x + 8))
	menu._toggle_expanded()
	await _settle()
	assert(is_equal_approx(panel.global_position.x, initial_x))
	world._set_build_mode(world.BuildMode.PLAY)
	world._on_skills_button_pressed()
	await _settle()
	assert(world.build_options.heading.text == "SKILL-TREE")
	assert(is_equal_approx(panel.global_position.x, menu.get_global_rect().end.x + 8))
	assert(is_equal_approx(panel.get_global_rect().end.y, menu.get_global_rect().end.y))
	assert(is_equal_approx(menu.get_global_rect().end.y, root.get_visible_rect().size.y - 20))
	var options = world.build_options
	assert(options.rows[0].icon.texture != null)
	assert(options.rows[2].cost_label.get_theme_color("font_color") == options.COST_UNAFFORDABLE)
	world.money = 40
	world._update_build_ui()
	assert(options.rows[2].cost_label.get_theme_color("font_color") == options.COST_NORMAL)
	options.rows[0].button.pressed.emit()
	assert(world.money == 0 and world.base_max_health == 125)
	world._set_build_mode(world.BuildMode.MENU)
	assert(options.rows.size() == 3)
	assert(options.rows[0].name_label.text == "Sammler (0/2)")
	assert(options.rows[1].name_label.text == "Kaserne (0/1)")
	options.rows[1].button.pressed.emit()
	assert(world.build_mode == world.BuildMode.PLACE and world.selected_building == 1)
	menu.get_node("Margin/Rows/SkillsRow/Skills").pressed.emit()
	await _settle()
	assert(world.build_mode == world.BuildMode.SKILLS and panel.visible)
	assert(options.heading.text == "SKILL-TREE" and options.rows.size() == 13)
	assert(is_equal_approx(panel.global_position.x, menu.get_global_rect().end.x + 8))
	menu._toggle_expanded()
	await _settle()
	assert(menu.get_node("Margin/Rows/SkillsRow/Title").visible)
	assert(is_equal_approx(panel.global_position.x, menu.get_global_rect().end.x + 8))
	menu.get_node("Margin/Rows/SkillsRow/Skills").pressed.emit()
	assert(world.build_mode == world.BuildMode.PLAY and not panel.visible)
	menu.get_node("Margin/Rows/SkillsRow/Skills").pressed.emit()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	world._input(escape)
	assert(world.build_mode == world.BuildMode.PLAY and not panel.visible)
	print("PASS: build and upgrade menus dock right with 8px gap, expand/collapse follows, bottom aligned")
	world.queue_free()
	quit()
