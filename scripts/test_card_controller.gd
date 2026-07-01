extends Node2D

var slots: Array[CardSlot] = []
var _cards: Array[CardVisual] = []

func _ready() -> void:
	for child in $UI/Slots.get_children():
		if child is CardSlot:
			slots.append(child)

	var dir := DirAccess.open("res://resources/cards/encounters/")
	if dir == null:
		return

	dir.list_dir_begin()
	var fname := dir.get_next()
	var idx := 0
	while fname != "" and idx < slots.size():
		if fname.ends_with(".json"):
			var file := FileAccess.open("res://resources/cards/encounters/" + fname, FileAccess.READ)
			if file:
				var json: Variant = JSON.parse_string(file.get_as_text())
				if json is Dictionary:
					var data := CardData.from_dict(json)
					_spawn_card(data, idx)
					idx += 1
		fname = dir.get_next()
	dir.list_dir_end()

func _spawn_card(data: CardData, slot_index: int) -> void:
	var card := CardVisual.new()
	card.setup(data)
	card.card_released.connect(_on_card_released)
	add_child(card)
	_cards.append(card)
	card.set_home(slots[slot_index].global_position)
	card.play_draw_animation()

func _on_card_released(_card: CardVisual) -> void:
	var card_rect: Rect2 = _card.get_card_rect()
	var card_center: Vector2 = card_rect.get_center()
	for i in range(slots.size()):
		if slots[i].get_global_rect().has_point(card_center):
			_card.set_home(slots[i].global_position)
			return
	_card.snap_to_home()
