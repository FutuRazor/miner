extends CharacterBody2D

@export var speed: float = 190.0
@export_range(1, 100, 1) var capacity: int = 10
@export_range(1, 100, 1) var mining_power: int = 1
@export_range(0.0, 24.0, 0.5) var mining_reach: float = 6.0

var mining_target: StaticBody2D
var facing := Vector2.DOWN
var movement_enabled := true
var keyboard_movement_enabled := true
var mining_enabled := true
var carried := 0
var load_label: Label
var navigation_path: Array[Vector2] = []


func _ready() -> void:
	load_label = Label.new()
	load_label.z_as_relative = false
	load_label.z_index = 100
	load_label.position = Vector2(-27, -38)
	load_label.add_theme_font_size_override("font_size", 13)
	add_child(load_label)
	update_load(0)
	# Keep Godot's standard arrow bindings and add WASD to the same actions.
	var bindings := {"ui_left": KEY_A, "ui_right": KEY_D, "ui_up": KEY_W, "ui_down": KEY_S}
	for action in bindings:
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


func _physics_process(delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		stop_mining()
		return
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") if keyboard_movement_enabled else Vector2.ZERO
	if direction != Vector2.ZERO:
		navigation_path.clear()
	else:
		while not navigation_path.is_empty() and position.distance_to(navigation_path[0]) <= 1.0:
			navigation_path.pop_front()
		if not navigation_path.is_empty():
			var difference := navigation_path[0] - position
			direction = difference.normalized() * minf(1.0, difference.length() / maxf(speed * delta, 0.001))
	velocity = direction * speed
	if direction != Vector2.ZERO:
		facing = direction.normalized()
	move_and_slide()
	if not can_mine():
		stop_mining()
		queue_redraw()
		return
	var next_target: StaticBody2D = null
	var best_alignment := 0.0
	for index in get_slide_collision_count():
		var contact := get_slide_collision(index)
		var collider := contact.get_collider()
		var alignment := direction.dot(-contact.get_normal())
		if collider is StaticBody2D and collider.has_method("mine") and alignment > best_alignment:
			if collider.hardness > mining_power or is_instance_valid(collider.mining_drone):
				continue
			next_target = collider
			best_alignment = alignment
	if next_target == null:
		next_target = _nearby_mining_target()
	if is_instance_valid(mining_target) and mining_target != next_target:
		mining_target.reset_progress()
	mining_target = next_target
	if is_instance_valid(mining_target) and mining_enabled:
		mining_target.mine(delta, true, null, mining_power)
	queue_redraw()


func stop_mining() -> void:
	if is_instance_valid(mining_target):
		mining_target.reset_progress()
	mining_target = null


func _nearby_mining_target() -> StaticBody2D:
	var world := get_parent()
	var cell := Vector2i((position / world.CELL).round())
	var radius: float = $CollisionShape2D.shape.radius + mining_reach
	var best_distance := radius * radius
	var nearest: StaticBody2D = null
	# A small neighborhood suffices for the configured reach (max. half a cell).
	for y in range(cell.y - 1, cell.y + 2):
		for x in range(cell.x - 1, cell.x + 2):
			var key := Vector2i(x, y)
			if not world.block_cells.has(key) or not is_instance_valid(world.block_cells[key]):
				continue
			var block: StaticBody2D = world.block_cells[key]
			if not is_instance_valid(block) or block.is_queued_for_deletion():
				continue
			if block.hardness > mining_power or is_instance_valid(block.mining_drone):
				continue
			var half_size: Vector2 = Vector2.ONE * world.CELL / 2.0
			var closest := position.clamp(block.position - half_size, block.position + half_size)
			var distance := position.distance_squared_to(closest)
			if distance <= best_distance:
				if nearest == null or distance < best_distance or block == mining_target:
					nearest = block
					best_distance = distance
	return nearest


func can_mine() -> bool:
	return mining_enabled and carried < capacity


func update_load(amount: int) -> void:
	carried = amount
	load_label.text = "%d/%d%s" % [carried, capacity, " Voll" if carried >= capacity else ""]
	load_label.modulate = Color("f4c86b") if carried >= capacity else Color.WHITE


func _draw() -> void:
	draw_circle(Vector2(0, 3), 14, Color("172332"))
	draw_circle(Vector2.ZERO, 12, Color("66e5db"))
	draw_circle(facing * 7, 4, Color("f4fffe"))
