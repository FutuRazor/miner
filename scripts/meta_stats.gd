extends Node

signal changed

const SAVE_VERSION := 1
var storage_path := "user://meta_stats.json"
var persistence_enabled := true
var collected_by_hardness: Dictionary = {}
var destroyed_by_hardness: Dictionary = {}
var victories: Array = []
var enemy_drones_defeated := 0
var load_warning := ""
var save_error := ""
var dirty := false
var save_delay := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_stats()


func record_block_step(hardness: int, fully_destroyed: bool) -> void:
	if hardness < 1:
		return
	var key := str(hardness)
	collected_by_hardness[key] = int(collected_by_hardness.get(key, 0)) + 1
	if fully_destroyed:
		destroyed_by_hardness[key] = int(destroyed_by_hardness.get(key, 0)) + 1
	_mark_dirty()


func record_enemy_defeated() -> void:
	enemy_drones_defeated += 1
	_mark_dirty()


func record_victory(duration: float, enemies: int, blocks: int, revenue: int) -> void:
	victories.append({"duration": duration, "enemies": enemies, "blocks": blocks, "revenue": revenue})
	victories.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.duration < b.duration)
	_mark_dirty()
	save_now()


func _valid_victories(value: Variant) -> bool:
	if not value is Array:
		return false
	for entry in value:
		if not entry is Dictionary:
			return false
		var duration: Variant = entry.get("duration")
		if not (typeof(duration) == TYPE_INT or typeof(duration) == TYPE_FLOAT) or not is_finite(float(duration)) or float(duration) < 0:
			return false
		for key in ["enemies", "blocks", "revenue"]:
			if not _valid_count(entry.get(key)):
				return false
	return true


func _mark_dirty() -> void:
	if not dirty:
		save_delay = 0.5
	dirty = true
	changed.emit()


func _process(delta: float) -> void:
	if not dirty or not persistence_enabled:
		return
	save_delay -= delta
	if save_delay <= 0.0:
		if not save_now():
			save_delay = 5.0


func total_collected() -> int:
	var result := 0
	for amount in collected_by_hardness.values():
		result += int(amount)
	return result


func total_destroyed() -> int:
	var result := 0
	for amount in destroyed_by_hardness.values():
		result += int(amount)
	return result


func _valid_count(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and float(value) >= 0 and float(value) == floor(float(value))


func _valid_counts(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for key in value:
		if not key is String or not key.is_valid_int() or int(key) < 1 or not _valid_count(value[key]):
			return false
	return true


func _read_snapshot(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary or parsed.get("version", -1) != SAVE_VERSION:
		return {}
	if not _valid_counts(parsed.get("collected_by_hardness")) or not _valid_counts(parsed.get("destroyed_by_hardness")) or not _valid_count(parsed.get("enemy_drones_defeated")):
		return {}
	for key in parsed.destroyed_by_hardness:
		if int(parsed.destroyed_by_hardness[key]) > int(parsed.collected_by_hardness.get(key, 0)):
			return {}
	if not _valid_victories(parsed.get("victories", [])):
		return {}
	return parsed


func load_stats() -> void:
	victories = []
	collected_by_hardness = {}
	destroyed_by_hardness = {}
	enemy_drones_defeated = 0
	load_warning = ""
	dirty = false
	var snapshot := _read_snapshot(storage_path)
	if snapshot.is_empty() and FileAccess.file_exists(storage_path + ".bak"):
		snapshot = _read_snapshot(storage_path + ".bak")
		if not snapshot.is_empty():
			load_warning = tr("Die Statistik wurde aus der letzten Sicherung wiederhergestellt.")
	if snapshot.is_empty():
		if FileAccess.file_exists(storage_path) or FileAccess.file_exists(storage_path + ".bak"):
			load_warning = tr("Die gespeicherte Statistik konnte nicht gelesen werden. Beschädigte Dateien bleiben zur Wiederherstellung erhalten.")
		return
	victories = snapshot.get("victories", [])
	victories.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.duration < b.duration)
	for key in snapshot.collected_by_hardness:
		collected_by_hardness[key] = int(snapshot.collected_by_hardness[key])
	for key in snapshot.destroyed_by_hardness:
		destroyed_by_hardness[key] = int(snapshot.destroyed_by_hardness[key])
	enemy_drones_defeated = int(snapshot.enemy_drones_defeated)


func save_now() -> bool:
	if not persistence_enabled or not dirty:
		return true
	var path := ProjectSettings.globalize_path(storage_path)
	var error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK:
		return _save_failed(error)
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _save_failed(FileAccess.get_open_error())
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "victories": victories, "collected_by_hardness": collected_by_hardness, "destroyed_by_hardness": destroyed_by_hardness, "enemy_drones_defeated": enemy_drones_defeated}, "\t"))
	file.flush()
	error = file.get_error()
	file.close()
	if error != OK:
		return _save_failed(error)
	if FileAccess.file_exists(path):
		if not _read_snapshot(path).is_empty():
			if FileAccess.file_exists(path + ".bak"):
				error = DirAccess.remove_absolute(path + ".bak")
				if error != OK:
					return _save_failed(error)
			error = DirAccess.rename_absolute(path, path + ".bak")
		else:
			error = DirAccess.rename_absolute(path, path + ".corrupt-" + str(Time.get_ticks_usec()))
		if error != OK:
			return _save_failed(error)
	error = DirAccess.rename_absolute(temporary, path)
	if error != OK:
		return _save_failed(error)
	dirty = false
	save_error = ""
	return true


func _save_failed(error: int) -> bool:
	save_error = tr("Die Gesamtstatistik konnte nicht gespeichert werden: ") + error_string(error)
	push_warning(save_error)
	return false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()


func _exit_tree() -> void:
	save_now()
