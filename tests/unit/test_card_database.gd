extends GutTest

var db: CardDatabase

func before_each() -> void:
	db = Node.new()
	db.set_script(load("res://scripts/card_database.gd"))
	add_child(db)
	db._ready()

func after_each() -> void:
	db.free()

func test_load_cards() -> void:
	assert_gt(db.all_cards.size(), 0, "Should load at least some cards from resources/")
	var wolf = db.all_cards.get("wolf_01")
	assert_not_null(wolf, "Wolf card should be loaded")
	assert_eq(wolf.name, "Warped Wolf")
	assert_eq(wolf.sub_type, CardData.SubType.HOSTILE)

func test_draw_encounter_card() -> void:
	var initial_deck_size = db.encounter_deck.size()
	var card = db.draw_encounter_card()
	assert_not_null(card, "Should draw a card")
	assert_eq(db.encounter_deck.size(), initial_deck_size - 1, "Deck size should decrease")
	assert_eq(db.card_locations[card.id], CardDatabase.LOC_HAND if card.sub_type != CardData.SubType.HOSTILE else CardDatabase.LOC_IN_PLAY, "Card location should be updated")

func test_empty_deck_handling() -> void:
	db.encounter_deck.clear()
	var card = db.draw_encounter_card()
	assert_null(card, "Should return null when deck is empty")
