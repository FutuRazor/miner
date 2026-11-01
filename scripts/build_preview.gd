extends Node2D


func _draw() -> void:
	var world := get_parent()
	var anchor: Vector2i = world._build_anchor()
	var cell: float = world.CELL
	var preview := Rect2(Vector2(anchor) * cell - Vector2.ONE * cell / 2, Vector2.ONE * cell * 2)
	var valid: bool = world._can_build(anchor) and world.money >= world._building_cost(world.selected_building)
	var color := Color("65e994") if valid else Color("f17777")
	draw_rect(preview, Color(color, 0.25))
	draw_rect(preview.grow(-2), color, false, 3)
	draw_line(preview.position + Vector2(cell, 0), preview.position + Vector2(cell, cell * 2), color)
	draw_line(preview.position + Vector2(0, cell), preview.position + Vector2(cell * 2, cell), color)
