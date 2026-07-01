class_name CardVisual
extends "res://godot_ui_components/scenes/balatro/scripts/card.gd"

var _card_data: CardData
var home_position: Vector2 = Vector2.ZERO

var _visuals_ready := false
var _is_hovered := false
var _resting_z_index: int = 0

signal card_released(card: CardVisual)

func _init() -> void:
	custom_minimum_size = Vector2(152, 207)
	size = Vector2(152, 207)
	pivot_offset = Vector2(76, 103.5)
	velocity_multiplier = 1.0

func _enter_tree() -> void:
	if not _visuals_ready:
		_setup_visuals()
		_visuals_ready = true

func _notification(what: int) -> void:
	if what in [NOTIFICATION_ENTER_TREE, NOTIFICATION_RESIZED, NOTIFICATION_THEME_CHANGED]:
		size = Vector2(152, 207)
		custom_minimum_size = Vector2(152, 207)

func _ready() -> void:
	super._ready()

	modulate.a = 0.0

	if _card_data:
		_render_face()

	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_up.connect(_on_card_button_up)

func _process(delta: float) -> void:
	super._process(delta)

func _setup_visuals() -> void:
	var empty_style := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty_style)
	add_theme_stylebox_override("hover", empty_style)
	add_theme_stylebox_override("pressed", empty_style)
	add_theme_stylebox_override("disabled", empty_style)
	add_theme_stylebox_override("focus", empty_style)

	var fake_shader := load("res://godot_ui_components/scenes/shared/shaders/fake_3D.gdshader") as Shader
	var texture := load("res://resources/cards/textures/card_back_encounter.png") as Texture2D

	var shadow_rect := TextureRect.new()
	shadow_rect.name = "Shadow"
	shadow_rect.show_behind_parent = true
	shadow_rect.anchor_right = 1.0
	shadow_rect.anchor_bottom = 1.0
	shadow_rect.offset_top = 24.0
	shadow_rect.offset_bottom = 24.0
	var shadow_image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	shadow_image.fill(Color.BLACK)
	shadow_rect.texture = ImageTexture.create_from_image(shadow_image)
	shadow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow_rect.self_modulate = Color(0, 0, 0, 0.25)
	shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow_rect)

	var card_tex := TextureRect.new()
	card_tex.name = "CardTexture"
	card_tex.anchor_right = 1.0
	card_tex.anchor_bottom = 1.0
	if texture:
		card_tex.texture = texture
	card_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if fake_shader:
		var fake_3d_material := ShaderMaterial.new()
		fake_3d_material.shader = fake_shader
		fake_3d_material.resource_local_to_scene = true
		fake_3d_material.set_shader_parameter("rect_size", Vector2(152, 207))
		fake_3d_material.set_shader_parameter("fov", 90.0)
		fake_3d_material.set_shader_parameter("cull_back", true)
		fake_3d_material.set_shader_parameter("y_rot", 0.0)
		fake_3d_material.set_shader_parameter("x_rot", 0.0)
		fake_3d_material.set_shader_parameter("inset", 0.0)
		card_tex.material = fake_3d_material

	add_child(card_tex)

	var destroy_area := Area2D.new()
	destroy_area.name = "DestroyArea"
	var collision_shape_node := CollisionShape2D.new()
	collision_shape_node.name = "CollisionShape2D"
	collision_shape_node.position = Vector2(75, 104.5)
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(130, 175)
	collision_shape_node.shape = rect_shape
	collision_shape_node.disabled = true
	destroy_area.add_child(collision_shape_node)
	add_child(destroy_area)

func setup(card: CardData) -> void:
	_card_data = card
	if is_inside_tree():
		_render_face()

func _render_face() -> void:
	if not _card_data or not is_inside_tree():
		return
	var tex_path: String = _card_data.texture
	if tex_path.is_empty() or not ResourceLoader.exists(tex_path):
		push_error("CardVisual: Missing texture for card '%s' at '%s'" % [_card_data.id, tex_path])
		return
	card_texture.texture = ResourceLoader.load(tex_path) as Texture2D

func set_back_texture(card_type: int) -> void:
	var path := "res://resources/cards/textures/card_back_encounter.png"
	if card_type == CardData.Type.TREASURE:
		path = "res://resources/cards/textures/card_back_treasure.png"
	card_texture.texture = ResourceLoader.load(path) as Texture2D

func flip_face(data: CardData) -> void:
	var old_filter := mouse_filter
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale:x", 0.0, 0.1)
	await tw.finished

	setup(data)

	var tw2 := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(self, "scale:x", 1.0, 0.1)
	await tw2.finished

	mouse_filter = old_filter

func get_card_data() -> CardData:
	return _card_data

func get_card_rect() -> Rect2:
	return get_global_rect()

func _on_card_button_up() -> void:
	scale = Vector2.ONE
	rotation = 0.0
	if home_position != Vector2.ZERO and global_position.distance_squared_to(home_position) > 4.0:
		snap_to_home()
	card_released.emit(self)

func set_resting_z_index(value: int) -> void:
	_resting_z_index = value
	if not _is_hovered:
		z_index = value

func _on_mouse_entered() -> void:
	_is_hovered = true
	z_index = 100
	super._on_mouse_entered()

func _on_mouse_exited() -> void:
	_is_hovered = false
	z_index = _resting_z_index
	super._on_mouse_exited()

func handle_shadow(delta: float) -> void:
	var center: Vector2 = get_viewport_rect().size / 2.0
	var distance: float = global_position.x - center.x
	var intensity: float = 1.0 if (_is_hovered or following_mouse) else 0.15
	shadow.position.x = lerp(0.0, sign(distance) * max_offset_shadow, abs(distance / center.x) * intensity)

func snap_to_home() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", home_position, 0.5)

func set_home(pos: Vector2) -> void:
	home_position = pos
	global_position = home_position

func set_home_animated(pos: Vector2) -> void:
	home_position = pos
	snap_to_home()

func play_draw_animation() -> void:
	_start_draw_animation()

func _start_draw_animation() -> void:
	global_position = Vector2(0, 800)
	modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", home_position, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
