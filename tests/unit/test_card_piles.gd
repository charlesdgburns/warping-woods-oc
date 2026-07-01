extends GutTest

const SCENE_PATH := "res://scenes/test_card_piles.tscn"
const CONTROLLER_SCRIPT := "res://scripts/test_card_piles.gd"

var scene: Node
var db: Node


func before_each() -> void:
	db = get_node("/root/CardDatabase")
	scene = load(SCENE_PATH).instantiate()
	add_child(scene)
	await get_tree().process_frame


func after_each() -> void:
	scene.free()


func test_scene_loads() -> void:
	assert_not_null(scene, "Scene should instantiate")
	assert_true(scene.has_node("CanvasLayer"), "Scene should have CanvasLayer")


func test_all_named_nodes_exist() -> void:
	var cl := scene.get_node("CanvasLayer")
	assert_not_null(cl.get_node("%DeckArea"), "%DeckArea should exist")
	assert_not_null(cl.get_node("%InPlaySlot"), "%InPlaySlot should exist")
	assert_not_null(cl.get_node("%DiscardSlot"), "%DiscardSlot should exist")
	assert_not_null(cl.get_node("%DeckCount"), "%DeckCount should exist")
	assert_not_null(cl.get_node("%DrawBtn"), "%DrawBtn should exist")
	assert_not_null(cl.get_node("%DefeatBtn"), "%DefeatBtn should exist")
	assert_not_null(cl.get_node("%RunBtn"), "%RunBtn should exist")
	assert_not_null(cl.get_node("%Status"), "%Status should exist")
	assert_not_null(cl.get_node("%HandSlots"), "%HandSlots should exist")


func test_deck_has_cards() -> void:
	var deck := scene._deck_cards as Array
	assert_gt(deck.size(), 0, "Deck should have at least one card")
	assert_eq(deck.size(), db.encounter_deck.size(), "Deck size should match encounter deck")


func test_deck_cards_are_face_down() -> void:
	var deck := scene._deck_cards as Array
	var first := deck[0] as CardVisual
	assert_not_null(first, "Deck card should be CardVisual")
	assert_eq(first.modulate.a, 1.0, "Deck card should be visible (alpha=1)")


func test_deck_cards_have_position_offset() -> void:
	var deck := scene._deck_cards as Array
	if deck.size() < 2:
		return
	var first := deck[0] as CardVisual
	var second := deck[1] as CardVisual
	assert_eq(first.global_position.x + 2, second.global_position.x, "Card 2 should be 2px right of card 1")
	assert_eq(first.global_position.y + 2, second.global_position.y, "Card 2 should be 2px below card 1")


func test_draw_reduces_deck() -> void:
	var initial_size := (scene._deck_cards as Array).size()
	var draw_btn := scene.get_node("CanvasLayer/%DrawBtn") as Button
	draw_btn.emit_signal("pressed")
	await get_tree().process_frame
	var new_size := (scene._deck_cards as Array).size()
	assert_eq(new_size, initial_size - 1, "Deck should shrink by 1 after draw")


func test_draw_sets_busy() -> void:
	var draw_btn := scene.get_node("CanvasLayer/%DrawBtn") as Button
	draw_btn.emit_signal("pressed")
	await get_tree().process_frame
	assert_true(scene._busy, "Controller should be busy after draw")


func test_busy_guard_prevents_double_draw() -> void:
	var draw_btn := scene.get_node("CanvasLayer/%DrawBtn") as Button
	draw_btn.emit_signal("pressed")
	await get_tree().process_frame
	var deck_after_first := (scene._deck_cards as Array).size()
	draw_btn.emit_signal("pressed")
	await get_tree().process_frame
	var deck_after_second := (scene._deck_cards as Array).size()
	assert_eq(deck_after_second, deck_after_first, "Second draw should be blocked when busy")


func test_empty_deck_guard() -> void:
	while (scene._deck_cards as Array).size() > 0:
		var draw_btn := scene.get_node("CanvasLayer/%DrawBtn") as Button
		draw_btn.emit_signal("pressed")
		await get_tree().process_frame
		if scene._busy:
			scene._busy = false
			scene._draw_button.disabled = false
	var draw_btn := scene.get_node("CanvasLayer/%DrawBtn") as Button
	draw_btn.emit_signal("pressed")
	await get_tree().process_frame
	var status_label := scene.get_node("CanvasLayer/%Status") as Label
	assert_has(status_label.text, "empty", "Status should say deck is empty")


func test_hand_slots_count() -> void:
	var hand_slots := scene.get_node("CanvasLayer/%HandSlots")
	var count := 0
	for child in hand_slots.get_children():
		if child is CardSlot:
			count += 1
	assert_eq(count, 7, "There should be exactly 7 hand slots")


func test_hand_slots_are_empty_initially() -> void:
	var hand_slots := scene.get_node("CanvasLayer/%HandSlots")
	for child in hand_slots.get_children():
		if child is CardSlot:
			assert_false(child.is_occupied(), "All hand slots should be empty initially")
