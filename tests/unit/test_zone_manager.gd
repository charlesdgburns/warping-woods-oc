extends GutTest

var zm: ZoneManager
var gm: GameManager
var bs: BoardState

func before_each() -> void:
	# Setup GameManager
	gm = Node.new()
	gm.set_script(load("res://scripts/game_manager.gd"))
	add_child(gm)
	gm._load_characters()
	
	# Setup BoardState
	bs = BoardState.new()
	gm.board_state = bs
	
	# Setup ZoneManager
	zm = Node.new()
	zm.set_script(load("res://scripts/zone_manager.gd"))
	add_child(zm)
	
	# Manually connect since we are in a test env without full scene tree
	gm.character_moved.connect(zm._on_character_moved)

func after_each() -> void:
	gm.free()
	zm.free()

func test_encounter_trigger() -> void:
	# Setup a mock encounter tile
	var pos = Vector2i(1, 1)
	bs.tile_type_grid[pos.x][pos.y] = "encounter"
	
	var char_id = gm.characters[0].id
	
	# Watch for the signal
	watch_signals(zm)
	
	gm.character_moved.emit(char_id, Vector2i(0, 0), pos)
	
	assert_signal_emitted(zm, "encounter_triggered", "Landing on encounter tile should trigger card draw")

func test_no_trigger_on_walkable() -> void:
	var pos = Vector2i(1, 1)
	bs.tile_type_grid[pos.x][pos.y] = "walkable"
	
	var char_id = gm.characters[0].id
	watch_signals(zm)
	
	gm.character_moved.emit(char_id, Vector2i(0, 0), pos)
	
	assert_signal_not_emitted(zm, "encounter_triggered", "Walkable tile should not trigger encounter")

func test_tile_resolution() -> void:
	var pos = Vector2i(1, 1)
	bs.tile_type_grid[pos.x][pos.y] = "encounter"
	
	var char_id = gm.characters[0].id
	gm.character_moved.emit(char_id, Vector2i(0, 0), pos)
	
	assert_eq(bs.tile_type_grid[pos.x][pos.y], "walkable", "Encounter tile should become walkable after trigger")
