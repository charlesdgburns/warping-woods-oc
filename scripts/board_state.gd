class_name BoardState
extends RefCounted

var block_grid: Array[Array]
var block_rotations: Dictionary
var character_positions: Dictionary
var block_data_cache: Dictionary
var tile_type_grid: Array[Array]


func _init():
	block_grid = []
	tile_type_grid = []
	for x in 4:
		block_grid.append([])
		block_grid[x].append("")
		block_grid[x].append("")
		block_grid[x].append("")
		block_grid[x].append("")

	tile_type_grid = []
	for x in 12:
		tile_type_grid.append([])
		for y in 12:
			tile_type_grid[x].append("walkable")


func set_block(grid_x: int, grid_y: int, block_id: String) -> void:
	block_grid[grid_x][grid_y] = block_id


func get_block(grid_x: int, grid_y: int) -> String:
	return block_grid[grid_x][grid_y]


func set_rotation(block_id: String, degrees: int) -> void:
	block_rotations[block_id] = degrees


func get_rotation(block_id: String) -> int:
	return block_rotations.get(block_id, 0)


func set_character_position(char_id: String, global_tile: Vector2i) -> void:
	character_positions[char_id] = global_tile


func get_character_position(char_id: String) -> Vector2i:
	return character_positions.get(char_id, Vector2i(-1, -1))
