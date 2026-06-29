class_name BlockData
extends RefCounted

enum BlockType { SUMMONING, SHOP, WARP_WIZARD, ENCOUNTER }

var block_id: String
var block_type: BlockType
var tiles: Array[TileInfo]


static func from_dict(data: Dictionary) -> BlockData:
	var b := BlockData.new()
	b.block_id = data.get("id", "")
	b.block_type = _parse_block_type(data.get("type", "encounter"))
	b.tiles = []
	for tile_data in data.get("tiles", []):
		b.tiles.append(TileInfo.from_dict(tile_data))
	return b


static func _parse_block_type(s: String) -> BlockType:
	match s:
		"summoning": return BlockType.SUMMONING
		"shop": return BlockType.SHOP
		"warp_wizard": return BlockType.WARP_WIZARD
		_: return BlockType.ENCOUNTER


func get_type_string() -> String:
	match block_type:
		BlockType.SUMMONING: return "summoning"
		BlockType.SHOP: return "shop"
		BlockType.WARP_WIZARD: return "warp_wizard"
		_: return "encounter"


func get_tile_at(local_pos: Vector2i) -> TileInfo:
	for t in tiles:
		if t.local_position == local_pos:
			return t
	return null


func to_dict() -> Dictionary:
	var tile_dicts: Array[Dictionary] = []
	for t in tiles:
		tile_dicts.append(t.to_dict())
	return {
		"id": block_id,
		"type": get_type_string(),
		"tiles": tile_dicts,
	}
