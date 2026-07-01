extends Node

var all_cards: Dictionary = {} # id -> CardData
var encounter_deck: Array[String] = []
var treasure_deck: Array[String] = []

# Tracking card locations
# card_id -> location (DECK, HAND, IN_PLAY, DISCARD, KEPT)
var card_locations: Dictionary = {}

const LOC_DECK = "DECK"
const LOC_HAND = "HAND"
const LOC_IN_PLAY = "IN_PLAY"
const LOC_DISCARD = "DISCARD"
const LOC_KEPT = "KEPT"

func _ready() -> void:
	_load_decks()

func _load_decks() -> void:
	_load_category("res://resources/cards/encounters/", encounter_deck)
	_load_category("res://resources/cards/treasure/", treasure_deck)
	
	encounter_deck.shuffle()
	treasure_deck.shuffle()

func _load_category(path: String, deck: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("CardDatabase: Cannot open path " + path)
		return
	
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			var file_path := path.path_join(fname)
			var file := FileAccess.open(file_path, FileAccess.READ)
			if file:
				var json: Variant = JSON.parse_string(file.get_as_text())
				if json is Dictionary:
					var card: CardData = CardData.from_dict(json)
					all_cards[card.id] = card
					deck.append(card.id)
					card_locations[card.id] = LOC_DECK
		fname = dir.get_next()
	dir.list_dir_end()

func draw_encounter_card() -> CardData:
	if encounter_deck.is_empty():
		push_error("CardDatabase: Encounter deck is empty!")
		return null
	
	var card_id: String = encounter_deck.pop_front()
	var card: CardData = all_cards[card_id]
	
	# Initial location depends on type
	if card.sub_type == CardData.SubType.HOSTILE:
		card_locations[card_id] = LOC_IN_PLAY
	else:
		card_locations[card_id] = LOC_HAND
		
	return card

func draw_treasure_card() -> CardData:
	if treasure_deck.is_empty():
		push_error("CardDatabase: Treasure deck is empty!")
		return null
	
	var card_id: String = treasure_deck.pop_front()
	var card: CardData = all_cards[card_id]
	card_locations[card_id] = LOC_HAND
	return card

func set_card_location(card_id: String, location: String) -> void:
	if card_locations.has(card_id):
		card_locations[card_id] = location
