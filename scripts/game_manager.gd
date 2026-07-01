extends Node

enum TurnPhase { IDLE, MOVING }

signal turn_started(char_id: String)
signal turn_ended(char_id: String)
signal round_started(round_num: int)
signal warp_started
signal warp_completed
signal move_mode_entered(valid_positions: Array[Vector2i])
signal move_mode_exited
signal character_moved(char_id: String, from_pos: Vector2i, to_pos: Vector2i)
signal encounter_resolved(card: CardData)
signal character_defeated(char_id: String)
signal character_revived(char_id: String)

var characters: Array[CharacterData]
var current_character_index: int = 0
var round_number: int = 1
var turn_phase: TurnPhase = TurnPhase.IDLE
var board_state: BoardState
var board_ready: bool = false

const CHAR_DIR := "res://resources/characters/"
const TILE_COUNT := 12
const BLOCK_COUNT := 4


func _ready() -> void:
	_load_characters()
	board_state = BoardState.new()
	
	# Connect to ZoneManager
	var zm = get_node_or_null("/root/ZoneManager")
	if zm:
		zm.encounter_triggered.connect(_on_encounter_triggered)


func _load_characters() -> void:
	characters.clear()
	var dir := DirAccess.open(CHAR_DIR)
	if dir == null:
		push_error("GameManager: Cannot open char directory: ", CHAR_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var path := CHAR_DIR.path_join(file_name)
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var json: Variant = JSON.parse_string(file.get_as_text())
				if json is Dictionary:
					var char_data := CharacterData.from_dict(json)
					characters.append(char_data)
		file_name = dir.get_next()
	dir.list_dir_end()


func on_board_ready() -> void:
	board_ready = true
	round_started.emit(1)
	start_turn()


func get_current_character() -> CharacterData:
	if characters.is_empty():
		return null
	if current_character_index < 0 or current_character_index >= characters.size():
		return null
	return characters[current_character_index]


func end_turn() -> void:
	if turn_phase == TurnPhase.MOVING:
		exit_move_mode()

	var prev_char := get_current_character()
	if prev_char:
		turn_ended.emit(prev_char.id)
		prev_char.has_moved = false

	current_character_index += 1
	if current_character_index >= characters.size():
		current_character_index = 0
		round_number += 1
		round_started.emit(round_number)
		if round_number > 24:
			return
		if round_number in [6, 12, 18]:
			execute_warp()

	start_turn()


func start_turn() -> void:
	var char_data: CharacterData = get_current_character()
	if char_data == null:
		return
	
	if char_data.hp <= 0:
		# Defeated characters skip their turn
		get_node("/root/EventBus").log_event("%s is defeated and cannot act." % char_data.character_name)
		end_turn()
		return

	char_data.has_moved = false
	turn_phase = TurnPhase.IDLE
	turn_started.emit(char_data.id)
	get_node("/root/EventBus").log_event("Turn started: %s" % char_data.character_name)


func enter_move_mode() -> void:
	if turn_phase != TurnPhase.IDLE:
		return
	if get_current_character() == null:
		return
	if get_current_character().has_moved:
		return

	turn_phase = TurnPhase.MOVING
	var valid := _get_valid_move_positions()
	move_mode_entered.emit(valid)


func exit_move_mode() -> void:
	if turn_phase != TurnPhase.MOVING:
		return
	turn_phase = TurnPhase.IDLE
	move_mode_exited.emit()


func handle_tile_click(pos: Vector2i) -> void:
	if turn_phase != TurnPhase.MOVING:
		return

	var valid := _get_valid_move_positions()
	if pos in valid:
		var char_data := get_current_character()
		var old_pos := char_data.grid_position
		char_data.grid_position = pos
		char_data.has_moved = true
		board_state.set_character_position(char_data.id, pos)
		turn_phase = TurnPhase.IDLE
		character_moved.emit(char_data.id, old_pos, pos)
		get_node("/root/EventBus").log_event("%s moved to %s" % [char_data.character_name, str(pos)])
	else:
		exit_move_mode()


func handle_rest() -> void:
	var char_data := get_current_character()
	if char_data == null:
		return
	char_data.rest()
	end_turn()


func _get_valid_move_positions() -> Array[Vector2i]:
	var char_data := get_current_character()
	if char_data == null:
		return []

	var result: Array[Vector2i] = []
	var start := char_data.grid_position
	var max_dist := char_data.speed

	for gx in TILE_COUNT:
		for gy in TILE_COUNT:
			var dist: int = abs(gx - start.x) + abs(gy - start.y)
			if dist > 0 and dist <= max_dist:
				if _is_tile_walkable(Vector2i(gx, gy)):
					result.append(Vector2i(gx, gy))

	return result


func _is_tile_walkable(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= TILE_COUNT or pos.y < 0 or pos.y >= TILE_COUNT:
		return false
	return board_state.tile_type_grid[pos.x][pos.y] != "unwalkable"



func _is_tile_occupied(pos: Vector2i) -> bool:
	for c in characters:
		if c.grid_position == pos:
			return true
	return false


func execute_warp() -> void:
	get_node("/root/EventBus").log_event("THE WOODS ARE WARPING!")
	warp_started.emit()

	var shielded_blocks: Array[String] = []
	for c in characters:
		var block_pos := Vector2i(c.grid_position.x / 3, c.grid_position.y / 3)
		var block_id := board_state.get_block(block_pos.x, block_pos.y)
		if not block_id.is_empty() and not block_id in shielded_blocks:
			shielded_blocks.append(block_id)

	var shielded_set: Dictionary = {}
	for sid in shielded_blocks:
		shielded_set[sid] = true

	var unshielded: Array[String] = []
	for bx in BLOCK_COUNT:
		for by in BLOCK_COUNT:
			var bid := board_state.get_block(bx, by)
			if not bid.is_empty() and not shielded_set.has(bid):
				unshielded.append(bid)

	unshielded.shuffle()

	var new_grid: Array[Array] = []
	new_grid.resize(BLOCK_COUNT)
	for bx in BLOCK_COUNT:
		new_grid[bx] = []
		new_grid[bx].resize(BLOCK_COUNT)
		for by in BLOCK_COUNT:
			var bid := board_state.get_block(bx, by)
			if shielded_set.has(bid):
				new_grid[bx][by] = bid
			else:
				new_grid[bx][by] = ""

	var unshielded_index := 0
	for bx in BLOCK_COUNT:
		for by in BLOCK_COUNT:
			if new_grid[bx][by] == "" and unshielded_index < unshielded.size():
				new_grid[bx][by] = unshielded[unshielded_index]
				unshielded_index += 1

	var new_rotations: Dictionary = {}
	for bx in BLOCK_COUNT:
		for by in BLOCK_COUNT:
			var bid: String = new_grid[bx][by]
			if not bid.is_empty():
				if shielded_set.has(bid):
					new_rotations[bid] = board_state.get_rotation(bid)
				else:
					new_rotations[bid] = [0, 90, 180, 270].pick_random()

	board_state.block_grid = new_grid
	board_state.block_rotations = new_rotations

	warp_completed.emit()

func handle_defeat(char_id: String) -> void:
	var char_data: CharacterData = characters.filter(func(c): return c.id == char_id)[0]
	if not char_data: return
	
	# Find summoning block position
	var summoning_pos := Vector2i(0, 0)
	for bx in BLOCK_COUNT:
		for by in BLOCK_COUNT:
			if board_state.block_grid[bx][by] == "summoning":
				summoning_pos = Vector2i(bx * 3, by * 3)
				break
	
	char_data.grid_position = summoning_pos
	board_state.set_character_position(char_id, summoning_pos)
	character_defeated.emit(char_id)
	get_node("/root/EventBus").log_event("%s has been defeated and sent to the Summoning Block!" % char_data.character_name)

func handle_revival(char_id: String) -> void:
	var char_data: CharacterData = characters.filter(func(c): return c.id == char_id)[0]
	if not char_data: return
	
	char_data.hp = char_data.max_hp / 2
	character_revived.emit(char_id)
	get_node("/root/EventBus").log_event("%s has been revived!" % char_data.character_name)

func _on_encounter_triggered(card: CardData, char_id: String) -> void:
	var char_data: CharacterData = characters.filter(func(c): return c.id == char_id)[0]
	if not char_data: return
	
	# 1. Log the encounter
	get_node("/root/EventBus").log_event("%s encountered: %s!" % [char_data.character_name, card.name])
	
	# 2. Handle the card type
	if card.sub_type == CardData.SubType.HOSTILE:
		# Hostile: Enter combat (Phase 4)
		get_node("/root/EventBus").log_event("A hostile creature appears! Combat begins...")
		turn_phase = TurnPhase.IDLE
	else:
		# Neutral/Quest: Resolve effects immediately
		_resolve_card_effects(card, char_data)
	
	# 3. UI: Show in ActiveSlot via HandManager
	var hm := get_node_or_null("/root/Main/UI/HandManager")
	if hm and hm.has_method("show_drawn_card"):
		hm.show_drawn_card(card)
	
	# All encounters end the turn immediately
	end_turn()

func _resolve_card_effects(card: CardData, char_data: CharacterData) -> void:
	for effect in card.effects:
		var type: String = effect.get("type", "")
		match type:
			"heal":
				var val: int = effect.get("value", 0)
				char_data.hp = min(char_data.max_hp, char_data.hp + val)
				get_node("/root/EventBus").log_event("Healed for %d HP." % val)
			"gain_gold":
				var val: int = effect.get("value", 0)
				char_data.gold += val
				get_node("/root/EventBus").log_event("Gained %d gold." % val)
			"grant_quest":
				var q_id: String = effect.get("quest_id", "")
				get_node("/root/EventBus").log_event("Started quest: %s" % q_id)
			_:
				get_node("/root/EventBus").log_event("Unknown effect: %s" % type)
