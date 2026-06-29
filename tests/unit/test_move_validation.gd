extends GutTest

var _char_a: CharacterData
var _char_b: CharacterData


func before_each() -> void:
	GameManager.characters.clear()
	GameManager.board_state = BoardState.new()
	GameManager.current_character_index = 0
	GameManager.round_number = 1
	GameManager.turn_phase = GameManager.TurnPhase.IDLE

	_char_a = CharacterData.new()
	_char_a.id = "char_a"
	_char_a.grid_position = Vector2i(2, 2)
	_char_a.speed = 2
	_char_a.has_moved = false
	GameManager.characters.append(_char_a)

	_char_b = CharacterData.new()
	_char_b.id = "char_b"
	_char_b.grid_position = Vector2i(5, 5)
	_char_b.speed = 3
	_char_b.has_moved = false
	GameManager.characters.append(_char_b)


func test_valid_positions_within_speed() -> void:
	var valid := GameManager._get_valid_move_positions()
	for pos in valid:
		var dist := abs(pos.x - 2) + abs(pos.y - 2)
		assert_true(dist <= 2, "Position %s is too far (dist=%d)" % [pos, dist])
		assert_true(dist > 0, "Position %s is the start tile" % [pos])


func test_valid_positions_excludes_unwalkable() -> void:
	GameManager.board_state.tile_type_grid[2][3] = "unwalkable"
	var valid := GameManager._get_valid_move_positions()
	assert_false(Vector2i(2, 3) in valid, "Unwalkable tile should be excluded")


func test_valid_positions_excludes_occupied() -> void:
	var valid := GameManager._get_valid_move_positions()
	assert_false(Vector2i(5, 5) in valid, "Occupied tile should be excluded")


func test_valid_positions_includes_walkable_unoccupied() -> void:
	var valid := GameManager._get_valid_move_positions()
	assert_true(Vector2i(2, 1) in valid, "Adjacent walkable tile should be valid")
	assert_true(Vector2i(3, 3) in valid, "Diagonal within speed should be valid")


func test_valid_positions_returns_empty_when_no_current_character() -> void:
	GameManager.characters.clear()
	var valid := GameManager._get_valid_move_positions()
	assert_eq(valid.size(), 0)


func test_click_valid_tile_moves_character() -> void:
	GameManager.enter_move_mode()
	var target := Vector2i(2, 1)
	GameManager.handle_tile_click(target)
	assert_eq(_char_a.grid_position, target)
	assert_true(_char_a.has_moved)


func test_click_valid_tile_emits_character_moved() -> void:
	GameManager.enter_move_mode()
	var target := Vector2i(2, 1)
	assert_signal_emitted(GameManager, "character_moved",
			"move should emit character_moved",
			[["char_a", Vector2i(2, 2), target]],
			func do_click(): GameManager.handle_tile_click(target))


func test_click_invalid_tile_cancels_move_mode() -> void:
	GameManager.enter_move_mode()
	GameManager.handle_tile_click(Vector2i(10, 10))
	assert_eq(GameManager.turn_phase, GameManager.TurnPhase.IDLE)
	assert_false(_char_a.has_moved)
	assert_eq(_char_a.grid_position, Vector2i(2, 2))


func test_click_outside_move_mode_ignored() -> void:
	GameManager.handle_tile_click(Vector2i(3, 3))
	assert_eq(GameManager.turn_phase, GameManager.TurnPhase.IDLE)
	assert_eq(_char_a.grid_position, Vector2i(2, 2))


func test_enter_move_mode_fails_if_already_moved() -> void:
	_char_a.has_moved = true
	GameManager.enter_move_mode()
	assert_eq(GameManager.turn_phase, GameManager.TurnPhase.IDLE)


func test_enter_move_mode_fails_if_no_character() -> void:
	GameManager.characters.clear()
	GameManager.enter_move_mode()
	assert_eq(GameManager.turn_phase, GameManager.TurnPhase.IDLE)


func test_enter_move_mode_emits_valid_positions() -> void:
	assert_signal_emitted(GameManager, "move_mode_entered",
			"should emit with valid positions",
			null,
			func do_enter(): GameManager.enter_move_mode())


func test_exit_move_mode_clears_phase() -> void:
	GameManager.enter_move_mode()
	GameManager.exit_move_mode()
	assert_eq(GameManager.turn_phase, GameManager.TurnPhase.IDLE)


func test_move_then_enter_move_mode_fails() -> void:
	GameManager.enter_move_mode()
	GameManager.handle_tile_click(Vector2i(3, 2))
	GameManager.enter_move_mode()
	assert_eq(GameManager.turn_phase, GameManager.TurnPhase.IDLE)
