extends PanelContainer

signal build_requested
signal skills_requested

var expanded := false


func _toggle_expanded() -> void:
	expanded = not expanded
	$Margin/Rows/ToggleRow/Title.visible = expanded
	$Margin/Rows/BuildRow/Title.visible = expanded
	$Margin/Rows/SkillsRow/Title.visible = expanded
	$Margin/Rows/ToggleRow/Toggle.text = "<" if expanded else ">"
	$Margin/Rows/ToggleRow/Toggle.tooltip_text = "Menü einklappen" if expanded else "Menü ausklappen"
	reset_size()


func _request_build() -> void:
	build_requested.emit()


func _request_skills() -> void:
	skills_requested.emit()
