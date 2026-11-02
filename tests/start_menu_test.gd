extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# Keep existing German UI expectations independent of the default language.
	TranslationServer.set_locale("de")
	root.get_node("MetaStats").persistence_enabled = false
	assert(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/start_menu.tscn")
	assert(change_scene_to_file("res://scenes/start_menu.tscn") == OK)
	await process_frame
	await process_frame
	var menu := current_scene
	assert(menu.name == "StartMenu")
	assert(not menu.has_node("Player"))
	assert(not ResourceLoader.has_cached("res://scripts/world.gd"))
	assert(not ResourceLoader.has_cached("res://scripts/drone.gd"))
	assert(menu.get_node("Center/Menu/StartButton").has_focus())
	menu.get_node("Center/Menu/StartButton").pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene.name == "Miner")
	assert(current_scene.has_node("Player"))
	print("PASS: start menu only, no world or drones loaded, focused start button and transition to game")
	quit()
