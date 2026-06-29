class_name ActionOption
extends Button

signal option_clicked(action_name: String)

var action_name: String
var is_available: bool = false


func setup(name: String, label: String, available: bool) -> void:
	action_name = name
	text = label
	is_available = available
	_update_state()


func set_available(val: bool) -> void:
	is_available = val
	_update_state()


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	option_clicked.emit(action_name)


func _update_state() -> void:
	disabled = not is_available
	if not is_available:
		modulate = Color(0.5, 0.5, 0.5, 0.7)
		mouse_default_cursor_shape = CURSOR_FORBIDDEN
	else:
		modulate = Color.WHITE
		mouse_default_cursor_shape = CURSOR_POINTING_HAND
