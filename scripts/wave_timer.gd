extends ProgressBar

signal wave_due(number: int)

const DURATION := 100.0
const INTERVAL := 80.0
var remaining := DURATION
var next_wave := 1
var timer_paused := false
var caption: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	min_value = 0
	max_value = DURATION
	show_percentage = false
	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_refresh()


func _physics_process(delta: float) -> void:
	if timer_paused or get_tree().paused or get_parent().world.is_game_over:
		return
	remaining -= delta
	while remaining <= 0.0:
		var number := next_wave
		next_wave += 1
		remaining += INTERVAL
		max_value = INTERVAL
		wave_due.emit(number)
	_refresh()


func set_timer_paused(paused: bool) -> void:
	timer_paused = paused
	_refresh()


func _refresh() -> void:
	value = remaining
	caption.text = tr("Zeit bis Welle %d · %d s%s") % [next_wave, ceili(remaining), tr(" · Pause") if timer_paused else ""]
