class_name TileInfo
extends RefCounted

enum TileType { WALKABLE, UNWALKABLE, ENCOUNTER }

var tile_type: TileType
var local_position: Vector2i
var has_encounter_token: bool


static func from_dict(data: Dictionary) -> TileInfo:
	var t := TileInfo.new()
	t.tile_type = _parse_tile_type(data.get("type", "walkable"))
	t.local_position = Vector2i(data["pos"][0], data["pos"][1])
	t.has_encounter_token = data.get("has_encounter_token", false)
	return t


static func _parse_tile_type(s: String) -> TileType:
	match s:
		"unwalkable": return TileType.UNWALKABLE
		"encounter": return TileType.ENCOUNTER
		_: return TileType.WALKABLE


func get_type_string() -> String:
	match tile_type:
		TileType.UNWALKABLE: return "unwalkable"
		TileType.ENCOUNTER: return "encounter"
		_: return "walkable"


func is_walkable() -> bool:
	return tile_type != TileType.UNWALKABLE


func to_dict() -> Dictionary:
	return {
		"type": get_type_string(),
		"pos": [local_position.x, local_position.y],
		"has_encounter_token": has_encounter_token,
	}
