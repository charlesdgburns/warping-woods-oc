@tool
extends Node

const SEED: int = 42
const BLOCK_COUNT: int = 20
const OUTPUT_DIR: String = "res://resources/blocks/"

const NEIGHBOUR_OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
]


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	generate_all()
	get_tree().quit()


func generate_all() -> void:
	seed(SEED)

	var dir := DirAccess.open(OUTPUT_DIR)
	if dir == null:
		DirAccess.make_dir_recursive(OUTPUT_DIR)

	var generated: int = 0
	var attempt: int = 0
	var max_attempts: int = 500

	while generated < BLOCK_COUNT and attempt < max_attempts:
		attempt += 1
		var block := _generate_encounter_block()
		if block == null:
			continue

		var block_id := "encounter_%02d" % [generated + 1]
		block["id"] = block_id
		block["type"] = "encounter"

		var path := OUTPUT_DIR.path_join(block_id + ".json")
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			push_error("BlockGenerator: Could not open for writing: ", path)
			continue

		var json_string := JSON.stringify(block, "\t")
		file.store_string(json_string)
		file.close()
		generated += 1
		print("BlockGenerator: wrote ", path)

	print("BlockGenerator: generated ", generated, " encounter blocks (", attempt, " attempts)")


func _generate_encounter_block() -> Dictionary:
	var grid: Array[Array] = []
	grid.resize(3)
	for x in 3:
		grid[x] = []
		grid[x].resize(3)
		for y in 3:
			grid[x][y] = TileInfo.TileType.WALKABLE

	var positions: Array[Vector2i] = []
	for x in 3:
		for y in 3:
			positions.append(Vector2i(x, y))
	positions.shuffle()

	var unwalkable_placed: int = 0
	for pos in positions:
		if unwalkable_placed >= 2:
			break
		grid[pos.x][pos.y] = TileInfo.TileType.UNWALKABLE
		if _is_connected_4dir(grid):
			unwalkable_placed += 1
		else:
			grid[pos.x][pos.y] = TileInfo.TileType.WALKABLE

	if unwalkable_placed < 2:
		return {}

	var walkable_positions: Array[Vector2i] = []
	for x in 3:
		for y in 3:
			if grid[x][y] == TileInfo.TileType.WALKABLE:
				walkable_positions.append(Vector2i(x, y))

	if walkable_positions.is_empty():
		return {}

	walkable_positions.shuffle()
	var encounter_pos: Vector2i = walkable_positions[0]
	grid[encounter_pos.x][encounter_pos.y] = TileInfo.TileType.ENCOUNTER

	var tiles: Array[Dictionary] = []
	for x in 3:
		for y in 3:
			var tile_type_str: String
			match grid[x][y]:
				TileInfo.TileType.UNWALKABLE:
					tile_type_str = "unwalkable"
				TileInfo.TileType.ENCOUNTER:
					tile_type_str = "encounter"
				_:
					tile_type_str = "walkable"

			tiles.append({
				"type": tile_type_str,
				"pos": [x, y],
				"has_encounter_token": grid[x][y] == TileInfo.TileType.ENCOUNTER,
			})

	var layout_str: String = ""
	for y in 3:
		for x in 3:
			match grid[x][y]:
				TileInfo.TileType.UNWALKABLE:
					layout_str += "#"
				TileInfo.TileType.ENCOUNTER:
					layout_str += "!"
				_:
					layout_str += "."
		layout_str += "\n"

	return {
		"id": "",
		"type": "encounter",
		"tiles": tiles,
		"_layout_comment": layout_str.strip_edges(),
	}


static func _is_connected_4dir(grid: Array[Array]) -> bool:
	var start: Vector2i = Vector2i(-1, -1)
	for x in 3:
		for y in 3:
			if grid[x][y] != TileInfo.TileType.UNWALKABLE:
				start = Vector2i(x, y)
				break
		if start.x != -1:
			break

	if start.x == -1:
		return false

	var visited: Array[Array] = []
	visited.resize(3)
	for x in 3:
		visited[x] = [false, false, false]

	var stack: Array[Vector2i] = [start]
	visited[start.x][start.y] = true

	while not stack.is_empty():
		var current: Vector2i = stack.pop_back()
		for offset in NEIGHBOUR_OFFSETS:
			var nx := current.x + offset.x
			var ny := current.y + offset.y
			if nx < 0 or nx > 2 or ny < 0 or ny > 2:
				continue
			if visited[nx][ny]:
				continue
			if grid[nx][ny] == TileInfo.TileType.UNWALKABLE:
				continue
			visited[nx][ny] = true
			stack.append(Vector2i(nx, ny))

	for x in 3:
		for y in 3:
			if grid[x][y] != TileInfo.TileType.UNWALKABLE and not visited[x][y]:
				return false

	return true
