extends GutTest

var gm: GameManager
var card: CardData

func before_each() -> void:
	gm = Node.new()
	gm.set_script(load("res://scripts/game_manager.gd"))
	add_child(gm)
	gm._load_characters()

func after_each() -> void:
	gm.free()

func test_heal_effect() -> void:
	var char_data = gm.characters[0]
	char_data.hp = 5
	char_data.max_hp = 20
	
	var heal_card = CardData.new()
	heal_card.effects = [{"type": "heal", "value": 10}]
	
	gm._resolve_card_effects(heal_card, char_data)
	
	assert_eq(char_data.hp, 15, "Healing should increase HP")

func test_heal_cap() -> void:
	var char_data = gm.characters[0]
	char_data.hp = 18
	char_data.max_hp = 20
	
	var heal_card = CardData.new()
	heal_card.effects = [{"type": "heal", "value": 10}]
	
	gm._resolve_card_effects(heal_card, char_data)
	
	assert_eq(char_data.hp, 20, "Healing should not exceed max HP")

func test_gold_gain() -> void:
	var char_data = gm.characters[0]
	char_data.gold = 0
	
	var gold_card = CardData.new()
	gold_card.effects = [{"type": "gain_gold", "value": 15}]
	
	gm._resolve_card_effects(gold_card, char_data)
	
	assert_eq(char_data.gold, 15, "Should gain gold from effect")
