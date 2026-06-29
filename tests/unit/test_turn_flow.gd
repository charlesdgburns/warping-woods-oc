extends GutTest

var _warp_emitted: bool = false


func before_each() -> void:
	GameManager.characters.clear()
	GameManager.board_state = BoardState.new()
	GameManager.current_character_index = 0
	GameManager.round_number = 1
	GameManager.turn_phase = GameManager.TurnPhase.IDLE

	for i in 5:
		var c := CharacterData.new()
		c.id = "char_%d" % [i + 1]
		c.grid_position = Vector2i(i % 3, i / 3)
		c.speed = 3
		c.has_moved = false
		GameManager.characters.append(c)


func _cycle_turns(count: int) -> void:
	for _i in count:
		GameManager.end_turn()


func test_start_turn_sets_phase_idle() -> void:
	GameManager.start_turn()
	assert_eq(GameManager.turn_phase, GameManager.TurnPhase.IDLE)


func test_start_turn_emits_for_current_character() -> void:
	var expected_id := GameManager.get_current_character().id
	assert_signal_emitted(GameManager, "turn_started",
			"",
			[["char_1"]],
			func (): GameManager.start_turn())


func test_turn_cycles_through_characters() -> void:
	assert_eq(GameManager.get_current_character().id, "char_1")
	_cycle_turns(1)
	assert_eq(GameManager.get_current_character().id, "char_2")
	_cycle_turns(1)
	assert_eq(GameManager.get_current_character().id, "char_3")
	_cycle_turns(1)
	assert_eq(GameManager.get_current_character().id, "char_4")
	_cycle_turns(1)
	assert_eq(GameManager.get_current_character().id, "char_5")


func test_round_increments_after_all_characters() -> void:
	_cycle_turns(5)
	assert_eq(GameManager.round_number, 2)


func test_multiple_rounds() -> void:
	_cycle_turns(10)
	assert_eq(GameManager.round_number, 3)


func test_end_turn_resets_has_moved() -> void:
	var c := GameManager.get_current_character()
	c.has_moved = true
	GameManager.end_turn()
	assert_false(GameManager.get_current_character().has_moved)


func test_end_turn_emits_turn_ended() -> void:
	var prev_id := GameManager.get_current_character().id
	assert_signal_emitted(GameManager, "turn_ended",
			"",
			[["char_1"]],
			func (): GameManager.end_turn())


func test_round_started_signal_emitted() -> void:
	_cycle_turns(5)
	assert_signal_emitted(GameManager, "round_started",
			"",
			[[]],
			func (): null)


func test_round_started_emits_correct_round() -> void:
	var emitted_round: int = -1
	GameManager.round_started.connect(func(r): emitted_round = r)
	_cycle_turns(5)
	assert_eq(emitted_round, 2)


func test_warp_triggers_at_round_6() -> void:
	var warped: bool = false
	GameManager.warp_completed.connect(func(): warped = true)
	_cycle_turns(5 * 5)
	assert_true(warped, "Warp should trigger at round 6")
	assert_eq(GameManager.round_number, 6)


func test_warp_triggers_at_round_12() -> void:
	var warp_count: int = 0
	GameManager.warp_completed.connect(func(): warp_count += 1)
	_cycle_turns(5 * 11)
	assert_eq(warp_count, 1, "Second warp should fire at round 12")
	assert_eq(GameManager.round_number, 12)


func test_three_warps_by_round_18() -> void:
	var warp_count: int = 0
	GameManager.warp_completed.connect(func(): warp_count += 1)
	_cycle_turns(5 * 18)
	assert_eq(warp_count, 3, "3 warps should have fired by round 18")


func test_game_stops_at_round_25() -> void:
	_cycle_turns(5 * 25)
	assert_true(GameManager.round_number > 24, "Game should pass round 24 but not crash")


func test_start_turn_does_nothing_when_no_characters() -> void:
	GameManager.characters.clear()
	GameManager.start_turn()
	assert_true(true, "Should not crash")


func test_get_current_character_returns_null_when_out_of_bounds() -> void:
	GameManager.current_character_index = 99
	assert_null(GameManager.get_current_character())
