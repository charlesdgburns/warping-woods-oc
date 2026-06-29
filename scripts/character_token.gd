class_name CharacterToken
extends Node2D

var character_id: String
var grid_position: Vector2i
var token_color: Color = Color.WHITE

const TOKEN_SIZE := 20


func setup(char_data: CharacterData, color_hex: String) -> void:
	character_id = char_data.id
	grid_position = char_data.grid_position
	token_color = Color(color_hex)
	queue_redraw()


func move_to(tile_global_pos: Vector2i, tile_size: int) -> void:
	grid_position = tile_global_pos
	position = Vector2(
		tile_global_pos.x * tile_size + (tile_size - TOKEN_SIZE) / 2.0,
		tile_global_pos.y * tile_size + (tile_size - TOKEN_SIZE) / 2.0
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
