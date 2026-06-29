class_name CharacterData
extends RefCounted

var id: String
var character_name: String
var character_class: String
var lore: String
var max_hp: int
var hp: int
var max_ap: int
var ap: int
var attack: int
var defence: int
var speed: int
var gold: int
var grid_position: Vector2i
var has_moved: bool


static func from_dict(data: Dictionary) -> CharacterData:
	var c := CharacterData.new()
	c.id = data.get("id", "")
	c.character_name = data.get("name", "")
	c.character_class = data.get("class", "")
	c.lore = data.get("lore", "")
	c.max_hp = data.get("max_hp", 10)
	c.hp = c.max_hp
	c.max_ap = data.get("max_ap", 5)
	c.ap = c.max_ap
	c.attack = data.get("attack", 3)
	c.defence = data.get("defence", 2)
	c.speed = data.get("speed", 4)
	c.gold = data.get("gold", 0)
	c.grid_position = Vector2i(1, 1)
	c.has_moved = false
	return c


func is_defeated() -> bool:
	return hp <= 0


func rest() -> void:
	ap = max_ap
