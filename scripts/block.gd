class_name BoardBlock
extends Node2D

var block_id: String
var block_type: String

const TILE_SIZE := 28


func _ready() -> void:
	pass


func build_from_data(block_data: Dictionary) -> void:
	block_id = block_data.get("id", "")
	block_type = block_data.get("type", "encounter")

	for tile_data in block_data.get("tiles", []):
		var pos_arr: Array = tile_data.get("pos", [0, 0])
		var tile_pos := Vector2i(pos_arr[0], pos_arr[1])
		var tile_type: String = tile_data.get("type", "walkable")

		var tile := BoardTile.new()
		tile.setup(tile_pos, tile_type)
		add_child(tile)


func apply_rotation(degrees: int) -> void:
	for tile in get_tiles():
		var data_pos := tile.grid_position
		var rotated := _rotate_local(data_pos, degrees)
		tile.position = Vector2(rotated.x * TILE_SIZE, rotated.y * TILE_SIZE)


func get_tiles() -> Array[BoardTile]:
	var result: Array[BoardTile] = []
	for child in get_children():
		if child is BoardTile:
			result.append(child)
	return result


func get_tile_at(local_pos: Vector2i) -> BoardTile:
	for tile in get_tiles():
		if tile.grid_position == local_pos:
			return tile
	return null


static func _rotate_local(data_pos: Vector2i, degrees: int) -> Vector2i:
	match degrees % 360:
		90:
			return Vector2i(2 - data_pos.y, data_pos.x)
		180:
			return Vector2i(2 - data_pos.x, 2 - data_pos.y)
		270:
			return Vector2i(data_pos.y, 2 - data_pos.x)
		_:
			return data_pos
