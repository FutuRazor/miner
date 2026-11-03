extends Node

const VERSION := 1
const ACTOR_SCRIPTS := ["res://scripts/block.gd", "res://scripts/drone.gd", "res://scripts/boss.gd", "res://scripts/tower.gd", "res://scripts/tower_projectile.gd"]
const TRANSIENT := ["build_mode", "return_dialog_open", "normal_physics_rate", "combat_reassign_pending", "mouse_held", "camera_drag_held", "mouse_dragging", "mouse_placement", "suppress_left_release", "mouse_hold_time", "right_press_building", "mining_job_cache", "mining_cache_revision", "mining_cache_assignments"]
var storage_path := "user://mission_save.dat"
var resume_requested := false
var pending: Dictionary = {}
var last_error := ""


func _read() -> Dictionary:
	if not FileAccess.file_exists(storage_path):
		return {}
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null or file.get_length() > 20000000:
		return {}
	var data: Variant = file.get_var(false)
	if not data is Dictionary or data.get("version") != VERSION or not data.get("actors") is Array or not data.get("world") is Dictionary or not data.get("player") is Dictionary or not data.get("timer") is Dictionary:
		return {}
	if not data.get("player_position") is Vector2 or not data.get("camera_position") is Vector2 or not data.get("camera_zoom") is Vector2 or not data.has("timer_max"):
		return {}
	for key in ["block_cells", "occupied_cells", "wave_alive"]:
		if not data.world.get(key) is Dictionary:
			return {}
	if not data.world.get("buildings") is Array or not data.world.has("money") or not data.timer.has("remaining"):
		return {}
	for actor in data.actors:
		if not actor is Dictionary or not ACTOR_SCRIPTS.has(actor.get("script")) or not actor.get("state") is Dictionary or not actor.get("ai") is Dictionary or not actor.get("position") is Vector2 or not actor.has("name"):
			return {}
	return data


func has_save() -> bool:
	return not _read().is_empty()


func clear_save() -> bool:
	pending = {}
	resume_requested = false
	if FileAccess.file_exists(storage_path):
		return DirAccess.remove_absolute(ProjectSettings.globalize_path(storage_path)) == OK
	return true


func request_resume() -> bool:
	pending = _read()
	resume_requested = not pending.is_empty()
	return resume_requested


func _encode(value: Variant, ids: Dictionary) -> Variant:
	if typeof(value) == TYPE_OBJECT:
		return {"$node": ids[value]} if is_instance_valid(value) and ids.has(value) else null
	if value is Dictionary:
		var result := {}
		for key in value:
			if typeof(value[key]) == TYPE_OBJECT and (not is_instance_valid(value[key]) or not ids.has(value[key])):
				continue
			result[key] = _encode(value[key], ids)
		return result
	if value is Array:
		var result := []
		for item in value:
			result.append(_encode(item, ids))
		return result
	return value


func _decode(value: Variant, nodes: Dictionary) -> Variant:
	if value is Dictionary:
		if value.has("$node"):
			return nodes.get(value["$node"])
		var result := {}
		for key in value:
			result[key] = _decode(value[key], nodes)
		return result
	if value is Array:
		var result := []
		for item in value:
			result.append(_decode(item, nodes))
		return result
	return value


func _capture(object: Object, ids: Dictionary, world_state: bool = false) -> Dictionary:
	var state := {}
	for property in object.get_property_list():
		var key: String = property.name
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE or (world_state and TRANSIENT.has(key)):
			continue
		var value: Variant = object.get(key)
		if typeof(value) == TYPE_OBJECT and (not is_instance_valid(value) or not ids.has(value)):
			continue
		state[key] = _encode(value, ids)
	return state


func _apply(object: Object, state: Dictionary, nodes: Dictionary) -> void:
	var allowed := {}
	for property in object.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			allowed[property.name] = true
	for key in state:
		if not allowed.has(key):
			continue
		var value: Variant = _decode(state[key], nodes)
		var existing: Variant = object.get(key)
		if existing is Array and value is Array:
			existing.assign(value)
		else:
			object.set(key, value)


func save_world(world: Node2D) -> bool:
	last_error = ""
	if not world.has_mission_limit() or world.is_game_over:
		return true
	var actors: Array[Node] = []
	var ids := {world: "world", world.get_node("Player"): "player"}
	for child in world.get_children():
		if child.get_script() != null and ACTOR_SCRIPTS.has(child.get_script().resource_path) and not child.is_queued_for_deletion() and not child.get("dead") == true and not child.get("depleted") == true:
			ids[child] = actors.size()
			actors.append(child)
	var data := {"version": VERSION, "world": _capture(world, ids, true), "player": _capture(world.get_node("Player"), ids), "player_position": world.get_node("Player").position, "camera_position": world.get_node("Player/Camera2D").position, "camera_zoom": world.get_node("Player/Camera2D").zoom, "timer": _capture(world.wave_timer, ids), "timer_max": world.wave_timer.max_value, "actors": []}
	for actor in actors:
		var entry := {"script": actor.get_script().resource_path, "name": actor.name, "position": actor.position, "state": _capture(actor, ids), "ai": {}}
		for key in ["combat_ai", "mechanic_ai", "navigation"]:
			var ai: Variant = actor.get(key)
			if is_instance_valid(ai):
				entry.ai[key] = _capture(ai, ids)
		if actor.get_script().resource_path == "res://scripts/boss.gd" and actor.final_boss:
			entry["swarmer_time"] = actor.swarmer_timer.time_left
		data.actors.append(entry)
	var path := ProjectSettings.globalize_path(storage_path)
	var error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error == OK:
		var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
		if file == null:
			error = FileAccess.get_open_error()
		else:
			file.store_var(data, false)
			file.flush()
			error = file.get_error()
			file.close()
	if error == OK:
		error = DirAccess.rename_absolute(path + ".tmp", path)
	if error != OK:
		last_error = tr("Spielstand konnte nicht gespeichert werden: %s") % error_string(error)
		return false
	return true


func restore_if_requested(world: Node2D) -> void:
	if not resume_requested or world.scene_file_path != "res://scenes/main.tscn":
		return
	resume_requested = false
	var data := pending
	pending = {}
	world.get_tree().paused = true
	for child in world.get_children():
		if child.get_script() != null and ACTOR_SCRIPTS.has(child.get_script().resource_path):
			child.free()
	var nodes := {"world": world, "player": world.get_node("Player")}
	for index in data.actors.size():
		var actor = load(data.actors[index].script).new()
		nodes[index] = actor
	_apply(world, data.world, nodes)
	for index in data.actors.size():
		var actor: Node2D = nodes[index]
		var entry: Dictionary = data.actors[index]
		_apply(actor, entry.state, nodes)
		actor.name = entry.name
		actor.position = entry.position
		world.add_child(actor)
		# Ready creates health labels, AI and timers; restore their live state afterward.
		_apply(actor, entry.state, nodes)
		for key in entry.ai:
			_apply(actor.get(key), entry.ai[key], nodes)
		_connect_actor(world, actor)
		if entry.has("swarmer_time"):
			actor.swarmer_timer.start(maxf(0.001, entry.swarmer_time))
			actor.swarmer_timer.wait_time = 5.0
		if actor.has_method("_update_status"):
			actor._update_status()
		elif actor.has_method("update_health"):
			actor.update_health()
		actor.queue_redraw()
	_rebuild_building_labels(world)
	var player: Node2D = world.get_node("Player")
	_apply(player, data.player, nodes)
	player.keyboard_movement_enabled = true
	player.movement_enabled = true
	player.mining_enabled = true
	player.position = data.player_position
	world.get_node("Player/Camera2D").position = data.camera_position
	world.get_node("Player/Camera2D").zoom = data.camera_zoom
	world.get_node("Player/Camera2D").reset_smoothing()
	_apply(world.wave_timer, data.timer, nodes)
	world.wave_timer.max_value = data.timer_max
	world.wave_timer._refresh()
	world.wave_pause_button.set_pressed_no_signal(world.wave_timer.timer_paused)
	world._set_wave_timer_paused(world.wave_timer.timer_paused)
	var speed: float = world.GAME_SPEEDS[world.game_speed_index]
	Engine.time_scale = speed
	Engine.physics_ticks_per_second = roundi(world.normal_physics_rate * speed)
	world.speed_button.text = [tr("1×"), tr("1,5×"), tr("2×"), tr("3×")][world.game_speed_index]
	world._update_counters()
	world._update_base_health()
	world._update_drone_count()
	world._update_build_ui()
	world._update_camera_limits()
	world._set_paused(true)
	world.queue_redraw()


func _connect_actor(world: Node2D, actor: Node2D) -> void:
	var path: String = actor.get_script().resource_path
	if path == "res://scripts/block.gd":
		actor.collected.connect(world._on_block_collected)
	elif path == "res://scripts/tower.gd":
		actor.destroyed.connect(world._on_tower_destroyed.bind(actor.building_index))
	elif path in ["res://scripts/drone.gd", "res://scripts/boss.gd"]:
		actor.tree_exited.connect(world._update_drone_count)
		if path == "res://scripts/boss.gd":
			actor.boss_defeated.connect(world._on_enemy_destroyed)
		elif actor.hostile:
			if actor.is_swarmer:
				actor.destroyed.connect(world._on_swarmer_destroyed)
			else:
				actor.destroyed.connect(world._on_enemy_destroyed.bind(actor.wave_number))
		elif actor.passive:
			actor.destroyed.connect(world._on_barracks_drone_destroyed.bind(actor.collector_index))


func _rebuild_building_labels(world: Node2D) -> void:
	for index in world.buildings.size():
		var building: Dictionary = world.buildings[index]
		if building.get("destroyed", false):
			continue
		var status := Label.new()
		status.position = Vector2(building.anchor) * world.CELL + Vector2(-20, -68)
		status.z_index = 100
		world.add_child(status)
		building.status = status
		if building.kind == 0 and building.construction <= 0:
			var label := Label.new()
			label.position = Vector2(building.anchor) * world.CELL + Vector2(-20, -48)
			label.z_as_relative = false
			label.z_index = 100
			label.add_theme_font_size_override("font_size", 15)
			world.add_child(label)
			building.label = label
			world.update_collector_label(index)
	world._tick_production(0.0)
