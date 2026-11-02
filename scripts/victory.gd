extends "res://scripts/game_over.gd"


func _ready() -> void:
	var menu := $Screen/Center/Menu
	menu.move_child(menu.get_node("MainMenu"), 3)
	$Screen/Center/Menu/MainMenu.grab_focus()
	var world = get_parent()
	var seconds := int(world.round_duration)
	$Screen/Center/Menu/Stats.text = "\n".join([
		tr("Rundendauer: %s") % ("%02d:%02d" % [seconds / 60, seconds % 60]),
		tr("Neutralisierte Gegner: %d") % world.enemies_neutralized,
		tr("Abgebaute Sektoren: %d Blöcke") % world.sectors_mined,
		tr("Gesamteinnahmen: $%d") % world.total_revenue,
	])


func _endless() -> void:
	if switching:
		return
	switching = true
	get_parent().continue_endless.call_deferred()
