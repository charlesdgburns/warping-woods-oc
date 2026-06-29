class_name TurnBar
extends HBoxContainer

signal character_icon_clicked(char_id: String)

var _char_icons: Dictionary = {}
var _round_label: Label
var _char_icons_container: HBoxContainer
var _active_style: StyleBoxFlat
var _inactive_style: StyleBoxFlat


func _ready() -> void:
	_round_label = $RoundLabel as Label
	_char_icons_container = $CharIcons as HBoxContainer

	_active_style = StyleBoxFlat.new()
	_active_style.bg_color = Color(1.0, 0.9, 0.2)
	_active_style.corner_radius_top_left = 4
	_active_style.corner_radius_top_right = 4
	_active_style.corner_radius_bottom_left = 4
	_active_style.corner_radius_bottom_right = 4
	_active_style.content_margin_left = 8
	_active_style.content_margin_right = 8
	_active_style.content_margin_top = 4
	_active_style.content_margin_bottom = 4

	_inactive_style = StyleBoxFlat.new()
	_inactive_style.bg_color = Color(0.35, 0.35, 0.35)
	_inactive_style.corner_radius_top_left = 4
	_inactive_style.corner_radius_top_right = 4
	_inactive_style.corner_radius_bottom_left = 4
	_inactive_style.corner_radius_bottom_right = 4
	_inactive_style.content_margin_left = 8
	_inactive_style.content_margin_right = 8
	_inactive_style.content_margin_top = 4
	_inactive_style.content_margin_bottom = 4


func setup_characters(characters: Array[CharacterData]) -> void:
	if not _char_icons_container:
		return

	for child in _char_icons_container.get_children():
		child.queue_free()
	_char_icons.clear()

	for char_data in characters:
		var btn := Button.new()
		btn.text = char_data.character_name.left(1).to_upper()
		btn.tooltip_text = char_data.character_name
		btn.pressed.connect(_on_icon_pressed.bind(char_data.id))
		btn.custom_minimum_size = Vector2(36, 36)
		btn.add_theme_stylebox_override("normal", _inactive_style)
		btn.add_theme_stylebox_override("hover", _inactive_style)
		_char_icons[char_data.id] = btn
		_char_icons_container.add_child(btn)


func _on_icon_pressed(char_id: String) -> void:
	character_icon_clicked.emit(char_id)


func set_active_character(char_id: String) -> void:
	for cid in _char_icons:
		var btn := _char_icons[cid] as Button
		if btn:
			if cid == char_id:
				btn.add_theme_stylebox_override("normal", _active_style)
				btn.add_theme_stylebox_override("hover", _active_style)
				btn.add_theme_color_override("font_color", Color.BLACK)
			else:
				btn.add_theme_stylebox_override("normal", _inactive_style)
				btn.add_theme_stylebox_override("hover", _inactive_style)
				btn.add_theme_color_override("font_color", Color.WHITE)


func set_round(round_num: int) -> void:
	if _round_label:
		_round_label.text = "Round %d / 24" % round_num
