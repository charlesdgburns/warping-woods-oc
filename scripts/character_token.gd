class_name CharacterToken
extends Node2D

var character_id: String
var grid_position: Vector2i
var token_color: Color = Color.WHITE
var _offset_index: int = 0

const TOKEN_SIZE := 12


func setup(char_data: CharacterData, color_hex: String, index: int = 0) -> void:
	character_id = char_data.id
	grid_position = char_data.grid_position
	token_color = Color(color_hex)
	_offset_index = index
	queue_redraw()


func move_to(tile_global_pos: Vector2i, tile_size: int) -> void:
	grid_position = tile_global_pos
	
	var offsets := [
		Vector2(0, 0),
		Vector2(-4, -4),
		Vector2(4, -4),
		Vector2(-4, 4),
		Vector2(4, 4)
	]
	var offset: Vector2 = offsets[_offset_index % offsets.size()]
	
	position = Vector2(
		tile_global_pos.x * tile_size + (tile_size - TOKEN_SIZE) / 2.0 + offset.x,
		tile_global_pos.y * tile_size + (tile_size - TOKEN_SIZE) / 2.0 + offset.y
	)


func set_active(active: bool) -> void:
	if active:
		scale = Vector2(1.3, 1.3)
	else:
		scale = Vector2(1.0, 1.0)


func _draw() -> void:
	var cx := TOKEN_SIZE / 2.0
	var cy := TOKEN_SIZE / 2.0
	draw_circle(Vector2(cx, cy), TOKEN_SIZE / 2.0, Color.BLACK)
	draw_circle(Vector2(cx, cy), TOKEN_SIZE / 2.0 - 2, token_color)
	draw_circle(Vector2(cx, cy), TOKEN_SIZE / 2.0 - 4, token_color.lightened(0.3))
