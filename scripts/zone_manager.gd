extends Node

signal encounter_triggered(card: CardData, char_id: String)

func _ready() -> void:
	# Connect to GameManager's movement signal
	var gm := get_node("/root/GameManager")
	gm.character_moved.connect(_on_character_moved)

func _on_character_moved(char_id: String, _from_pos: Vector2i, to_pos: Vector2i) -> void:
	var gm: Node = get_node("/root/GameManager")
	var board_state: BoardState = gm.board_state
	
	# Check if the tile is an encounter tile
	if _is_encounter_tile(to_pos, board_state):
		var card: CardData = get_node("/root/CardDatabase").draw_encounter_card()
		if card:
			encounter_triggered.emit(card, char_id)
			# Mark tile as resolved so it doesn't trigger again
			_resolve_encounter_tile(to_pos, board_state)

func _is_encounter_tile(pos: Vector2i, board_state: BoardState) -> bool:
	# This is a simplification. In a full implementation, 
	# we check the block's layout and whether the token is present.
	# For now, we check if the tile_type_grid says "encounter".
	return board_state.tile_type_grid[pos.x][pos.y] == "encounter"

func _resolve_encounter_tile(pos: Vector2i, board_state: BoardState) -> void:
	# Set the tile type to "walkable" to remove the encounter token
	board_state.tile_type_grid[pos.x][pos.y] = "walkable"
	get_node("/root/EventBus").log_event("The encounter token has been removed from the board.")
