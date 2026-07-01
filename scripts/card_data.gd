class_name CardData
extends RefCounted

enum Type { ENCOUNTER, TREASURE }
enum SubType { HOSTILE, NEUTRAL, QUEST, ITEM }

var id: String
var name: String
var type: Type
var sub_type: SubType
var effects: Array = []
var description: String
var condition: String
var texture: String

static func from_dict(data: Dictionary) -> CardData:
	var card := CardData.new()
	card.id = data.get("id", "")
	card.name = data.get("name", "")
	
	# Parse Type
	var type_str: String = data.get("type", "encounter").to_lower()
	card.type = Type.TREASURE if type_str == "treasure" else Type.ENCOUNTER
	
	# Parse SubType
	var sub_type_str: String = data.get("sub_type", "neutral").to_lower()
	match sub_type_str:
		"hostile": card.sub_type = SubType.HOSTILE
		"neutral": card.sub_type = SubType.NEUTRAL
		"quest": card.sub_type = SubType.QUEST
		"item": card.sub_type = SubType.ITEM
		_: card.sub_type = SubType.NEUTRAL
		
	card.effects = data.get("effects", [])
	card.description = data.get("description", "")
	card.condition = data.get("condition", "")
	card.texture = data.get("texture", "")
	
	return card
