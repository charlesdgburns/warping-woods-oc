class_name CardRender
extends RefCounted

static func render_to_texture(parent: Node, card: CardData) -> Texture2D:
	var resolution := Vector2(152, 207)
	var viewport := SubViewport.new()
	viewport.size = resolution
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

	var card_face := Control.new()
	card_face.size = resolution
	viewport.add_child(card_face)

	_build_card_face(card_face, card, resolution)

	parent.add_child(viewport)
	RenderingServer.force_draw()
	var viewport_tex := viewport.get_texture()
	var image := viewport_tex.get_image()
	parent.remove_child(viewport)
	viewport.queue_free()

	if image:
		return ImageTexture.create_from_image(image)
	return null

static func _build_card_face(parent: Control, card: CardData, resolution: Vector2) -> void:
	var card_w := resolution.x
	var card_h := resolution.y

	var title_color: Color
	var art_color: Color
	match card.sub_type:
		CardData.SubType.HOSTILE:
			title_color = Color(0.55, 0.05, 0.05)
			art_color = Color(0.9, 0.6, 0.6)
		CardData.SubType.NEUTRAL:
			title_color = Color(0.1, 0.45, 0.1)
			art_color = Color(0.6, 0.85, 0.6)
		CardData.SubType.QUEST:
			title_color = Color(0.65, 0.5, 0.05)
			art_color = Color(0.9, 0.85, 0.6)
		CardData.SubType.ITEM:
			title_color = Color(0.1, 0.25, 0.6)
			art_color = Color(0.6, 0.7, 0.9)
		_:
			title_color = Color(0.3, 0.3, 0.3)
			art_color = Color(0.8, 0.8, 0.8)

	var border := ColorRect.new()
	border.size = resolution
	border.color = Color(0.12, 0.08, 0.04)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(border)

	var bg := ColorRect.new()
	bg.position = Vector2(2, 2)
	bg.size = resolution - Vector2(4, 4)
	bg.color = Color(0.93, 0.88, 0.78)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)

	var title_bar := ColorRect.new()
	title_bar.position = Vector2(2, 2)
	title_bar.size = Vector2(card_w - 4, 26)
	title_bar.color = title_color
	title_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(title_bar)

	var title := Label.new()
	title.position = Vector2(8, 4)
	title.size = Vector2(card_w - 16, 22)
	title.text = card.name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_constant_override("shadow_outline_size", 1)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(title)

	var art_border := ColorRect.new()
	art_border.position = Vector2(6, 31)
	art_border.size = Vector2(card_w - 12, 82)
	art_border.color = Color(0.12, 0.08, 0.04)
	art_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art_border)

	var art_rect := ColorRect.new()
	art_rect.position = Vector2(7, 32)
	art_rect.size = Vector2(card_w - 14, 80)
	art_rect.color = art_color
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art_rect)

	var art_label := Label.new()
	art_label.position = art_rect.position
	art_label.size = art_rect.size
	art_label.text = "[ ART ]"
	art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_label.add_theme_font_size_override("font_size", 11)
	art_label.add_theme_color_override("font_color", Color(0, 0, 0, 0.25))
	art_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art_label)

	var type_str := _type_string(card)
	var type_line := Label.new()
	type_line.position = Vector2(8, 117)
	type_line.size = Vector2(card_w - 16, 16)
	type_line.text = type_str
	type_line.add_theme_font_size_override("font_size", 9)
	type_line.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	type_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(type_line)

	var divider := ColorRect.new()
	divider.position = Vector2(6, 134)
	divider.size = Vector2(card_w - 12, 1)
	divider.color = Color(0.2, 0.15, 0.1, 0.3)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(divider)

	var text_bg := ColorRect.new()
	text_bg.position = Vector2(4, 137)
	text_bg.size = Vector2(card_w - 8, card_h - 141)
	text_bg.color = Color(0.98, 0.94, 0.86)
	text_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(text_bg)

	var desc := Label.new()
	desc.position = Vector2(8, 139)
	desc.size = Vector2(card_w - 16, card_h - 143)
	desc.text = card.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc.add_theme_font_size_override("font_size", 9)
	desc.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(desc)

static func _type_string(card: CardData) -> String:
	var type_str := "Encounter"
	if card.type == CardData.Type.TREASURE:
		type_str = "Treasure"
	var sub_type_str := ""
	match card.sub_type:
		CardData.SubType.HOSTILE:
			sub_type_str = "Hostile"
		CardData.SubType.NEUTRAL:
			sub_type_str = "Neutral"
		CardData.SubType.QUEST:
			sub_type_str = "Quest"
		CardData.SubType.ITEM:
			sub_type_str = "Item"
	return "%s — %s" % [type_str, sub_type_str]
