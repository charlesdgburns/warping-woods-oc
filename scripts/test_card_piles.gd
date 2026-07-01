extends Node2D

var _deck_area: Control
var _in_play_slot: CardSlot
var _discard_slot: CardSlot
var _hand_slots: Array[CardSlot] = []
var _draw_button: Button
var _defeat_button: Button
var _run_button: Button
var _status_label: Label

var _deck_cards: Array[CardVisual] = []
var _active_card: CardVisual
var _card_database: Node
var _busy := false


func _ready() -> void:
	_card_database = get_node("/root/CardDatabase")

	_deck_area = $CanvasLayer/DeckArea
	_in_play_slot = $CanvasLayer/InPlaySlot
	_discard_slot = $CanvasLayer/DiscardSlot
	_draw_button = $CanvasLayer/DrawBtn
	_defeat_button = $CanvasLayer/DefeatBtn
	_run_button = $CanvasLayer/RunBtn
	_status_label = $CanvasLayer/Status

	for child in $CanvasLayer/HandSlots.get_children():
		if child is CardSlot:
			_hand_slots.append(child)

	_defeat_button.hide()
	_run_button.hide()

	_draw_button.pressed.connect(_on_draw_pressed)
	_defeat_button.pressed.connect(_on_defeat_pressed)
	_run_button.pressed.connect(_on_run_pressed)
	$CanvasLayer/BackBtn.pressed.connect(_on_back_pressed)

	_init_deck()


func _init_deck() -> void:
	var deck_size: int = _card_database.encounter_deck.size()
	var base_pos := _deck_area.global_position
	for i in range(deck_size):
		var card := CardVisual.new()
		add_child(card)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.modulate.a = 1.0
		card.global_position = base_pos + Vector2(i * 2, i * 2)
		card.set_home(card.global_position)
		card.z_index = i
		_deck_cards.append(card)
	_update_status("Ready — Deck: %d cards" % _deck_cards.size())


func _on_draw_pressed() -> void:
	if _busy:
		return
	if _deck_cards.is_empty():
		_update_status("Deck empty!")
		return

	var card_data: CardData = _card_database.draw_encounter_card()
	if card_data == null:
		_update_status("No cards available!")
		return

	_busy = true
	_draw_button.disabled = true

	var card := _deck_cards.pop_back() as CardVisual
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	_shift_deck_visual()

	_update_status("Drawing: %s" % card_data.name)
	_animate_card_to_in_play(card, card_data)


func _animate_card_to_in_play(card: CardVisual, data: CardData) -> void:
	var target_pos := _in_play_slot.global_position
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card, "global_position", target_pos, 0.4)
	await tween.finished
	_on_card_arrived(card, data)


func _on_card_arrived(card: CardVisual, data: CardData) -> void:
	_active_card = card
	card.set_home(card.global_position)
	card.setup(data)
	_update_status(data.name)
	await get_tree().process_frame
	await get_tree().process_frame
	_handle_flow(data)


func _handle_flow(data: CardData) -> void:
	match data.sub_type:
		CardData.SubType.NEUTRAL:
			_update_status("%s — Resolved! Discarding..." % data.name)
			await get_tree().create_timer(1.5).timeout
			_discard_card(data)

		CardData.SubType.QUEST:
			_update_status("%s — Quest added to hand!" % data.name)
			await get_tree().create_timer(1.5).timeout
			_collect_to_hand(data)

		CardData.SubType.HOSTILE:
			_update_status("%s — Defeat or Run Away?" % data.name)
			_defeat_button.show()
			_run_button.show()


func _collect_to_hand(data: CardData) -> void:
	var card := _active_card
	_active_card = null

	var target_slot: CardSlot
	for slot in _hand_slots:
		if not slot.is_occupied():
			target_slot = slot
			break

	if target_slot == null:
		_update_status("Hand full! Card stays in play.")
		_card_database.set_card_location(data.id, CardDatabase.LOC_IN_PLAY)
		_busy = false
		_draw_button.disabled = false
		return

	target_slot.set_occupied(true)
	_card_database.set_card_location(data.id, CardDatabase.LOC_HAND)

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card, "global_position", target_slot.global_position, 0.5)
	await tween.finished
	card.set_home(card.global_position)

	_update_status("Deck: %d cards" % _deck_cards.size())
	_busy = false
	_draw_button.disabled = false


func _discard_card(data: CardData) -> void:
	var card := _active_card
	_active_card = null

	_discard_slot.set_occupied(true)
	_card_database.set_card_location(data.id, CardDatabase.LOC_DISCARD)

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card, "global_position", _discard_slot.global_position, 0.5)
	await tween.finished
	card.set_home(card.global_position)

	_update_status("Deck: %d cards" % _deck_cards.size())
	_busy = false
	_draw_button.disabled = false


func _on_defeat_pressed() -> void:
	_defeat_button.hide()
	_run_button.hide()
	var data := _active_card.get_card_data()
	_update_status("Defeated! Moving to hand...")
	_collect_to_hand(data)


func _on_run_pressed() -> void:
	_defeat_button.hide()
	_run_button.hide()
	var data := _active_card.get_card_data()
	_update_status("Ran away! Discarding...")
	_discard_card(data)


func _shift_deck_visual() -> void:
	var base_pos := _deck_area.global_position
	for i in range(_deck_cards.size()):
		var card := _deck_cards[i] as CardVisual
		var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(card, "global_position", base_pos + Vector2(i * 2, i * 2), 0.3)
		card.z_index = i


func _update_status(text: String) -> void:
	_status_label.text = text


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/test_menu.tscn")
