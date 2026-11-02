extends "res://scripts/game_over.gd"


func _ready() -> void:
	var menu := $Screen/Center/Menu
	menu.move_child(menu.get_node("MainMenu"), 3)
	$Screen/Center/Menu/MainMenu.grab_focus()
	_show_round_stats()


func _endless() -> void:
	if switching:
		return
	switching = true
	get_parent().continue_endless.call_deferred()
