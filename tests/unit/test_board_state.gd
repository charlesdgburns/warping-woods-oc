extends GutTest

func test_block_grid_is_4x4_after_init() -> void:
	var bs := BoardState.new()
	assert_eq(bs.block_grid.size(), 4)
	for x in 4:
		assert_eq(bs.block_grid[x].size(), 4)


func test_tile_type_grid_is_12x12_after_init() -> void:
	var bs := BoardState.new()
	assert_eq(bs.tile_type_grid.size(), 12)
	for x in 12:
		assert_eq(bs.tile_type_grid[x].size(), 12)


func test_tile_type_grid_defaults_to_walkable() -> void:
	var bs := BoardState.new()
	for x in 12:
		for y in 12:
			assert_eq(bs.tile_type_grid[x][y], "walkable")


func test_set_block_round_trips() -> void:
	var bs := BoardState.new()
	bs.set_block(2, 3, "my_block")
	assert_eq(bs.get_block(2, 3), "my_block")


func test_get_block_returns_empty_string_initially() -> void:
	var bs := BoardState.new()
	for x in 4:
		for y in 4:
			assert_eq(bs.get_block(x, y), "")


func test_set_rotation_round_trips() -> void:
	var bs := BoardState.new()
	bs.set_block(0, 0, "test_block")
	bs.set_rotation("test_block", 90)
	assert_eq(bs.get_rotation("test_block"), 90)


func test_get_rotation_defaults_to_zero() -> void:
	var bs := BoardState.new()
	assert_eq(bs.get_rotation("nonexistent"), 0)


func test_character_position_round_trips() -> void:
	var bs := BoardState.new()
	bs.set_character_position("hero", Vector2i(5, 7))
	assert_eq(bs.get_character_position("hero"), Vector2i(5, 7))


func test_character_position_defaults_to_negative_one() -> void:
	var bs := BoardState.new()
	assert_eq(bs.get_character_position("nonexistent"), Vector2i(-1, -1))
