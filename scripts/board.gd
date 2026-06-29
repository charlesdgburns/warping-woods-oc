class_name GameBoard
extends Node2D

var _gm

var _block_nodes: Dictionary = {}
var _character_tokens: Dictionary = {}
var _tile_grid: Dictionary = {}
var _initialized: bool = false

var _turn_bar: TurnBar
var _action_btns: Dictionary = {}
var _end_turn_btn: Button
var _char_info: Label

const TILE_SIZE := 28
const BLOCK_PIXEL := 84
const TILES_PER_BLOCK := 3
const GRID_SIZE := 12


func _ready() -> void:
	_gm = get_node("/root/GameManager")
	_find_ui_elements()
	_connect_ui()
	position = Vector2(342, 182)
	_build_board()
	_create_character_tokens()
	_connect_game_signals()
	if _turn_bar:
		_turn_bar.setup_characters(_gm.characters)
	_initialized = true
	_gm.on_board_ready()


func _find_ui_elements() -> void:
	var ui := get_node("../UI") as CanvasLayer
	if not ui:
		return
	_turn_bar = ui.get_node("TurnBar") as TurnBar
	_end_turn_btn = ui.get_node("RightPanel/EndTurnBtn") as Button
	_char_info = ui.get_node("BottomBar/CharInfo") as Label

	var grid := ui.get_node("RightPanel/ActionGrid")
	if grid:
		for btn in grid.get_children():
			if btn is Button:
				_action_btns[btn.name] = btn


func _connect_ui() -> void:
	var action_map := {
		"MoveBtn": "move",
		"AttackBtn": "attack",
		"EscapeBtn": "escape",
		"TradeBtn": "trade",
		"ItemBtn": "item",
		"RestBtn": "rest",
	}
	for btn_name in action_map:
		var btn: Button = _action_btns.get(btn_name)
		if btn:
			var action_name: String = action_map[btn_name]
			btn.pressed.connect(func() -> void: _on_action_selected(action_name))
	if _end_turn_btn:
		_end_turn_btn.pressed.connect(_on_end_turn)


func _on_action_selected(action_name: String) -> void:
	match action_name:
		"move":
			_gm.enter_move_mode()
		"rest":
			_gm.handle_rest()


func _on_end_turn() -> void:
	_gm.end_turn()


func _build_board() -> void:
	_load_block_data()
	_select_blocks()
	_create_blocks()
	_connect_tile_signals()


func _load_block_data() -> void:
	var dir := DirAccess.open("res://resources/blocks/")
	if dir == null:
		push_error("Board: Cannot open blocks directory")
		return

	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			var path := "res://resources/blocks/".path_join(fname)
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var json: Variant = JSON.parse_string(file.get_as_text())
				if json is Dictionary:
					var bid: String = json.get("id", "")
					if not bid.is_empty():
						_gm.board_state.block_data_cache[bid] = json
		fname = dir.get_next()
	dir.list_dir_end()


func _select_blocks() -> void:
	var encounter_ids: Array[String] = []
	for bid in _gm.board_state.block_data_cache:
		var data: Dictionary = _gm.board_state.block_data_cache[bid]
		if data.get("type", "") == "encounter":
			encounter_ids.append(bid)

	encounter_ids.shuffle()
	var selected_encounters := encounter_ids.slice(0, 13)

	var grid_layout := [
		["summoning", null, null, null],
		[null, null, null, null],
		[null, "shop", null, null],
		[null, null, null, "warp_wizard"],
	]

	var enc_index := 0
	for bx in 4:
		for by in 4:
			if grid_layout[bx][by] == null:
				if enc_index < selected_encounters.size():
					grid_layout[bx][by] = selected_encounters[enc_index]
					enc_index += 1

	for bx in 4:
		for by in 4:
			var bid: String = grid_layout[bx][by]
			if not bid.is_empty():
				_gm.board_state.set_block(bx, by, bid)
				_gm.board_state.set_rotation(bid, 0)


func _create_blocks() -> void:
	for bx in 4:
		for by in 4:
			var bid: String = _gm.board_state.get_block(bx, by)
			if bid.is_empty():
				continue
			var block_data: Dictionary = _gm.board_state.block_data_cache.get(bid, {})
			var block := BoardBlock.new()
			block.build_from_data(block_data)
			block.position = Vector2(bx * BLOCK_PIXEL, by * BLOCK_PIXEL)
			block.name = "Block_%d_%d" % [bx, by]

			var rot: int = _gm.board_state.get_rotation(bid)
			block.apply_rotation(rot)

			add_child(block)
			_block_nodes[bid] = block

			for tile in block.get_tiles():
				var tile_pos_in_block := _get_tile_visual_pos(tile.grid_position, rot)
				var global_pos := Vector2i(bx * TILES_PER_BLOCK + tile_pos_in_block.x,
										  by * TILES_PER_BLOCK + tile_pos_in_block.y)
				tile.grid_position = global_pos
				_tile_grid[global_pos] = tile
				_gm.board_state.tile_type_grid[global_pos.x][global_pos.y] = tile.tile_type


func _get_tile_visual_pos(data_pos: Vector2i, degrees: int) -> Vector2i:
	match degrees % 360:
		90:
			return Vector2i(2 - data_pos.y, data_pos.x)
		180:
			return Vector2i(2 - data_pos.x, 2 - data_pos.y)
		270:
			return Vector2i(data_pos.y, 2 - data_pos.x)
		_:
			return data_pos


func _connect_tile_signals() -> void:
	for pos in _tile_grid:
		var tile := _tile_grid[pos] as BoardTile
		if tile:
			tile.tile_clicked.connect(_on_tile_clicked)


func _connect_game_signals() -> void:
	_gm.turn_started.connect(_on_turn_started)
	_gm.round_started.connect(_on_round_started)
	_gm.move_mode_entered.connect(_on_move_mode_entered)
	_gm.move_mode_exited.connect(_on_move_mode_exited)
	_gm.character_moved.connect(_on_character_moved)
	_gm.warp_completed.connect(_on_warp_completed)


func _on_tile_clicked(pos: Vector2i) -> void:
	_gm.handle_tile_click(pos)


func _on_turn_started(char_id: String) -> void:
	if _turn_bar:
		_turn_bar.set_active_character(char_id)

	for cid in _character_tokens:
		_character_tokens[cid].set_active(cid == char_id)

	var char_data: CharacterData = _gm.get_current_character()
	if not char_data:
		return
	if _char_info:
		_char_info.text = "Active: %s  |  HP %d/%d  AP %d/%d  SPD %d" % [
			char_data.character_name, char_data.hp, char_data.max_hp,
			char_data.ap, char_data.max_ap, char_data.speed
		]
	_set_btn_available("MoveBtn", true)
	_set_btn_available("RestBtn", true)


func _on_round_started(round_num: int) -> void:
	if _turn_bar:
		_turn_bar.set_round(round_num)


func _on_move_mode_entered(valid_positions: Array[Vector2i]) -> void:
	for pos in valid_positions:
		var tile: BoardTile = _tile_grid.get(pos) as BoardTile
		if tile:
			tile.set_highlight(true)


func _on_move_mode_exited() -> void:
	for pos in _tile_grid:
		_tile_grid[pos].set_highlight(false)


func _on_character_moved(char_id: String, from_pos: Vector2i, to_pos: Vector2i) -> void:
	var token: CharacterToken = _character_tokens.get(char_id) as CharacterToken
	if token:
		token.move_to(to_pos, TILE_SIZE)
	_on_move_mode_exited()

	var char_data: CharacterData = _gm.get_current_character()
	if char_data:
		_set_btn_available("MoveBtn", not char_data.has_moved)

func _set_btn_available(btn_name: String, available: bool) -> void:
	var btn: Button = _action_btns.get(btn_name)
	if btn:
		btn.disabled = not available
		btn.modulate = Color.WHITE if available else Color(0.5, 0.5, 0.5, 0.7)


func _on_warp_completed() -> void:
	_rebuild_board_visuals()


func _rebuild_board_visuals() -> void:
	_on_move_mode_exited()

	for bid in _block_nodes:
		var block: BoardBlock = _block_nodes[bid] as BoardBlock
		remove_child(block)
		block.queue_free()
	_block_nodes.clear()
	_tile_grid.clear()

	_create_blocks()
	_connect_tile_signals()

	for cid in _character_tokens:
		var pos: Vector2i = _gm.board_state.get_character_position(cid)
		if pos != Vector2i(-1, -1):
			_character_tokens[cid].move_to(pos, TILE_SIZE)


func _create_character_tokens() -> void:
	var colors := ["#e74c3c", "#3498db", "#2ecc71", "#f39c12", "#9b59b6"]
	for i in _gm.characters.size():
		var char_data: CharacterData = _gm.characters[i]
		var token := CharacterToken.new()
		token.setup(char_data, colors[i % colors.size()])

		var start_pos := Vector2i(i % 3, i / 3)
		char_data.grid_position = start_pos
		_gm.board_state.set_character_position(char_data.id, start_pos)

		token.move_to(start_pos, TILE_SIZE)
		token.name = "Token_" + char_data.id
		add_child(token)
		_character_tokens[char_data.id] = token
