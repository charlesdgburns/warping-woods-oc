extends Node2D

var _deck_area: Control
var _in_play_slot: CardSlot
var _discard_slot: CardSlot
var _hand_slot_positions: Array[Vector2] = []
var _hand_cards: Array[CardVisual] = []
var _draw_button: Button
var _defeat_button: Button
var _run_button: Button
var _status_label: Label

var _deck_cards: Array[CardVisual] = []
var _active_card: CardVisual
var _card_database: Node
var _busy := false
var _discard_stack_index: int = 0
var _top_discard_card: CardVisual


func _ready() -> void:
	_card_database = get_node("/root/CardDatabase")

	_deck_area = $CanvasLayer/DeckArea
	_in_play_slot = $CanvasLayer/InPlaySlot
	_discard_slot = $CanvasLayer/DiscardSlot
	_draw_button = $CanvasLayer/DrawBtn
	_defeat_button = $CanvasLayer/DefeatBtn
	_run_button = $CanvasLayer/RunBtn
	_status_label = $CanvasLayer/Status

	_init_hand_positions()
	for i in range(5):
		_hand_cards.append(null)

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
		card.set_back_texture(CardData.Type.ENCOUNTER)
		_deck_cards.append(card)
	if not _deck_cards.is_empty():
		_deck_cards.back().mouse_filter = Control.MOUSE_FILTER_STOP
	_update_status("Ready — Deck: %d cards" % _deck_cards.size())


func _process(delta: float) -> void:
	for i in range(5):
		var card := _hand_cards[i]
		if card and card.following_mouse:
			_handle_hand_card_drag(card, i)
			break

func _handle_hand_card_drag(card: CardVisual, current_idx: int) -> void:
	var cx := card.global_position.x + 76.0
	var new_idx := 0
	for i in range(5):
		var slot_cx := _hand_slot_positions[i].x + 75.0
		if cx < slot_cx:
			new_idx = i
			break
		new_idx = i
	if new_idx == current_idx:
		return
	if new_idx > current_idx:
		for i in range(current_idx, new_idx):
			_hand_cards[i] = _hand_cards[i + 1]
	else:
		for i in range(current_idx, new_idx, -1):
			_hand_cards[i] = _hand_cards[i - 1]
	_hand_cards[new_idx] = card
	for i in range(5):
		var c := _hand_cards[i]
		if c:
			c.set_resting_z_index(i)
			if c != card:
				c.set_home_animated(_hand_slot_positions[i])
	card.home_position = _hand_slot_positions[new_idx]

func _init_hand_positions() -> void:
	var start_x := 600.0
	var gap := 122.0
	for i in range(5):
		_hand_slot_positions.append(Vector2(start_x + i * gap, 500.0))

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
	_update_status(data.name)
	await card.flip_face(data)
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

	var first_free := -1
	for i in range(5):
		if _hand_cards[i] == null:
			first_free = i
			break

	if first_free == -1:
		_update_status("Hand full! Card stays in play.")
		_card_database.set_card_location(data.id, CardDatabase.LOC_IN_PLAY)
		_busy = false
		_draw_button.disabled = false
		return

	_hand_cards[first_free] = card
	_card_database.set_card_location(data.id, CardDatabase.LOC_HAND)
	card.set_resting_z_index(first_free)

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card, "global_position", _hand_slot_positions[first_free], 0.5)
	await tween.finished
	card.set_home(_hand_slot_positions[first_free])
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	_update_status("Deck: %d cards" % _deck_cards.size())
	_busy = false
	_draw_button.disabled = false


func _discard_card(data: CardData) -> void:
	var card := _active_card
	_active_card = null

	if _top_discard_card and is_instance_valid(_top_discard_card):
		_top_discard_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_discard_slot.set_occupied(true)
	_card_database.set_card_location(data.id, CardDatabase.LOC_DISCARD)

	card.z_index = _discard_stack_index
	var target := _discard_slot.global_position + Vector2(_discard_stack_index, _discard_stack_index)
	_discard_stack_index += 1

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card, "global_position", target, 0.5)
	await tween.finished
	card.set_home(card.global_position)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	_top_discard_card = card

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
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(card, "global_position", base_pos + Vector2(i * 2, i * 2), 0.3)
		card.z_index = i
	if not _deck_cards.is_empty():
		_deck_cards.back().mouse_filter = Control.MOUSE_FILTER_STOP


func _update_status(text: String) -> void:
	_status_label.text = text


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/test_menu.tscn")
