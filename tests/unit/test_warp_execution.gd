extends GutTest

var _shielded_id := "summoning"
var _unshielded_ids: Array[String] = []


func before_each() -> void:
	GameManager.characters.clear()
	GameManager.board_state = BoardState.new()

	for i in 5:
		var c := CharacterData.new()
		c.id = "char_%d" % [i + 1]
		c.grid_position = Vector2i(i % 3, i / 3)
		c.speed = 3
		c.has_moved = false
		GameManager.characters.append(c)

	_unshielded_ids = []
	for i in 15:
		var bid := "block_%02d" % [i + 1]
		_unshielded_ids.append(bid)

	GameManager.board_state.set_block(0, 0, _shielded_id)
	GameManager.board_state.set_block(0, 1, _unshielded_ids[0])
	GameManager.board_state.set_block(0, 2, _unshielded_ids[1])
	GameManager.board_state.set_block(0, 3, _unshielded_ids[2])
	GameManager.board_state.set_block(1, 0, _unshielded_ids[3])
	GameManager.board_state.set_block(1, 1, _unshielded_ids[4])
	GameManager.board_state.set_block(1, 2, _unshielded_ids[5])
	GameManager.board_state.set_block(1, 3, _unshielded_ids[6])
	GameManager.board_state.set_block(2, 0, _unshielded_ids[7])
	GameManager.board_state.set_block(2, 1, _unshielded_ids[8])
	GameManager.board_state.set_block(2, 2, _unshielded_ids[9])
	GameManager.board_state.set_block(2, 3, _unshielded_ids[10])
	GameManager.board_state.set_block(3, 0, _unshielded_ids[11])
	GameManager.board_state.set_block(3, 1, _unshielded_ids[12])
	GameManager.board_state.set_block(3, 2, _unshielded_ids[13])
	GameManager.board_state.set_block(3, 3, _unshielded_ids[14])

	GameManager.board_state.set_rotation(_shielded_id, 180)
	for bid in _unshielded_ids:
		GameManager.board_state.set_rotation(bid, 0)


func test_shielded_block_stays_at_original_position() -> void:
	var orig_pos := _find_block_pos(_shielded_id)
	GameManager.execute_warp()
	var new_pos := _find_block_pos(_shielded_id)
	assert_eq(new_pos, orig_pos, "Shielded block should not move")


func test_shielded_rotation_preserved() -> void:
	GameManager.execute_warp()
	assert_eq(GameManager.board_state.get_rotation(_shielded_id), 180,
			"Shielded block should keep its rotation")


func test_all_grid_cells_filled_after_warp() -> void:
	GameManager.execute_warp()
	for bx in 4:
		for by in 4:
			var bid := GameManager.board_state.get_block(bx, by)
			assert_ne(bid, "", "Cell (%d, %d) should have a block" % [bx, by])


func test_no_blocks_lost_after_warp() -> void:
	var before: Array[String] = []
	for bx in 4:
		for by in 4:
			before.append(GameManager.board_state.get_block(bx, by))

	GameManager.execute_warp()

	var after: Array[String] = []
	for bx in 4:
		for by in 4:
			after.append(GameManager.board_state.get_block(bx, by))

	before.sort()
	after.sort()
	assert_eq(before, after, "Same set of block IDs should be present after warp")


func test_unshielded_blocks_get_rotation() -> void:
	GameManager.execute_warp()
	for bid in _unshielded_ids:
		var rot := GameManager.board_state.get_rotation(bid)
		assert_true(rot in [0, 90, 180, 270],
				"Unshielded block %s rotation %d should be valid" % [bid, rot])


func test_warp_signals_emitted() -> void:
	assert_signal_emitted(GameManager, "warp_started", "",
			null,
			func (): GameManager.execute_warp())

	assert_signal_emitted(GameManager, "warp_completed", "",
			null,
			func (): GameManager.execute_warp())


func test_shielded_blocks_from_multiple_characters() -> void:
	GameManager.characters[0].grid_position = Vector2i(0, 0)
	GameManager.characters[1].grid_position = Vector2i(8, 8)

	var shielded2 := "block_03"
	GameManager.board_state.set_block(2, 2, shielded2)
	GameManager.board_state.set_rotation(shielded2, 90)

	var warp_start := _find_block_pos(shielded2)
	GameManager.execute_warp()
	var warp_end := _find_block_pos(shielded2)
	assert_eq(warp_end, warp_start,
			"Second character's block should also be shielded")


func test_warp_no_crash_with_empty_characters() -> void:
	GameManager.characters.clear()
	GameManager.execute_warp()
	assert_true(true, "Should not crash when no characters exist")


func _find_block_pos(bid: String) -> Vector2i:
	for bx in 4:
		for by in 4:
			if GameManager.board_state.get_block(bx, by) == bid:
				return Vector2i(bx, by)
	return Vector2i(-1, -1)
