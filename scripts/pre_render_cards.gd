@tool
extends Node

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	var dir := DirAccess.open("res://")
	if not dir:
		push_error("pre_render: Cannot open res://")
		get_tree().quit()
		return

	if not await CardRender.render_card_back(self, "res://resources/cards/textures/card_back_encounter.png", false):
		push_error("pre_render: Failed to render encounter card back")
		get_tree().quit()
		return

	if not await CardRender.render_card_back(self, "res://resources/cards/textures/card_back_treasure.png", true):
		push_error("pre_render: Failed to render treasure card back")
		get_tree().quit()
		return

	await _process_category(dir, "resources/cards/encounters/")
	await _process_category(dir, "resources/cards/treasure/")

	print("pre_render: All card textures generated.")
	get_tree().quit()


func _process_category(dir: DirAccess, category_path: String) -> void:
	if not dir.dir_exists(category_path):
		return

	var cat_dir := DirAccess.open("res://" + category_path)
	if not cat_dir:
		return

	cat_dir.list_dir_begin()
	var fname := cat_dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			var file_path := "res://" + category_path.path_join(fname)
			await _render_card(file_path)
		fname = cat_dir.get_next()
	cat_dir.list_dir_end()


func _render_card(json_path: String) -> void:
	var file := FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("pre_render: Cannot open %s" % json_path)
		return

	var json: Variant = JSON.parse_string(file.get_as_text())
	if not (json is Dictionary):
		push_error("pre_render: Invalid JSON in %s" % json_path)
		return

	var card_id: String = json.get("id", "")
	if card_id.is_empty():
		push_error("pre_render: Card missing id in %s" % json_path)
		return

	var card: CardData = CardData.from_dict(json)
	var png_path := "res://resources/cards/textures/%s.png" % card_id

	if not await CardRender.save_card_png(card, self, png_path):
		push_error("pre_render: Failed to render %s" % card_id)
		return

	json["texture"] = png_path

	var out := FileAccess.open(json_path, FileAccess.WRITE)
	if not out:
		push_error("pre_render: Cannot write %s" % json_path)
		return

	out.store_string(JSON.stringify(json, "  ") + "\n")
	print("pre_render: %s -> %s" % [card.name, png_path])
