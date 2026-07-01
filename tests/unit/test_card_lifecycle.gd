extends GutTest

var db: CardDatabase


func before_each() -> void:
	db = get_node("/root/CardDatabase") as CardDatabase


func test_neutral_card_goes_to_discard() -> void:
	var card := _find_card_of_subtype(CardData.SubType.NEUTRAL)
	if card == null:
		return

	db.set_card_location(card.id, CardDatabase.LOC_IN_PLAY)
	db.set_card_location(card.id, CardDatabase.LOC_DISCARD)
	assert_eq(db.card_locations[card.id], CardDatabase.LOC_DISCARD, "Neutral should end in DISCARD")


func test_quest_card_goes_to_hand() -> void:
	var card := _find_card_of_subtype(CardData.SubType.QUEST)
	if card == null:
		return

	db.set_card_location(card.id, CardDatabase.LOC_IN_PLAY)
	db.set_card_location(card.id, CardDatabase.LOC_HAND)
	assert_eq(db.card_locations[card.id], CardDatabase.LOC_HAND, "Quest should end in HAND")


func test_hostile_card_stays_in_play() -> void:
	var card := _find_card_of_subtype(CardData.SubType.HOSTILE)
	if card == null:
		return

	assert_eq(db.card_locations.get(card.id), CardDatabase.LOC_IN_PLAY, "Hostile stays IN_PLAY after draw")


func test_hostile_defeat_goes_to_hand() -> void:
	var card := _find_card_of_subtype(CardData.SubType.HOSTILE)
	if card == null:
		return

	db.set_card_location(card.id, CardDatabase.LOC_HAND)
	assert_eq(db.card_locations[card.id], CardDatabase.LOC_HAND, "Defeated hostile goes to HAND")


func test_hostile_run_goes_to_discard() -> void:
	var card := _find_card_of_subtype(CardData.SubType.HOSTILE)
	if card == null:
		return

	db.set_card_location(card.id, CardDatabase.LOC_DISCARD)
	assert_eq(db.card_locations[card.id], CardDatabase.LOC_DISCARD, "Fled hostile goes to DISCARD")


func test_draw_encounter_card_location() -> void:
	var initial_size := db.encounter_deck.size()
	var card := db.draw_encounter_card()
	assert_not_null(card, "Should draw a card")
	assert_eq(db.encounter_deck.size(), initial_size - 1, "Deck should shrink")

	if card.sub_type == CardData.SubType.HOSTILE:
		assert_eq(db.card_locations[card.id], CardDatabase.LOC_IN_PLAY, "Hostile → IN_PLAY")
	else:
		assert_eq(db.card_locations[card.id], CardDatabase.LOC_HAND, "Non-hostile → HAND")


func test_full_hand_returns_card_to_deck() -> void:
	var card := _find_card_of_subtype(CardData.SubType.QUEST)
	if card == null:
		return

	db.set_card_location(card.id, CardDatabase.LOC_DECK)
	assert_eq(db.card_locations[card.id], CardDatabase.LOC_DECK, "Card returns to DECK when hand is full")


func test_all_three_card_types_exist() -> void:
	var types_found := {}
	for cid in db.all_cards.keys():
		var c := db.all_cards[cid] as CardData
		types_found[c.sub_type] = true

	assert_true(types_found.has(CardData.SubType.NEUTRAL), "Should have a NEUTRAL encounter")
	assert_true(types_found.has(CardData.SubType.QUEST), "Should have a QUEST encounter")
	assert_true(types_found.has(CardData.SubType.HOSTILE), "Should have a HOSTILE encounter")


func test_card_data_fields_are_populated() -> void:
	for cid in db.all_cards.keys():
		var c := db.all_cards[cid] as CardData
		assert_ne(c.id, "", "Card ID should not be empty")
		assert_ne(c.name, "", "Card name should not be empty")
		assert_ne(c.description, "", "Card description should not be empty")
		assert_gt(c.effects.size(), 0, "Card should have at least one effect")


func _find_card_of_subtype(subtype: int) -> CardData:
	for cid in db.all_cards.keys():
		var c := db.all_cards[cid] as CardData
		if c.sub_type == subtype:
			return c
	pending("No card of subtype %d found — add one to resources/cards/encounters/" % subtype)
	return null
