class_name CardVisual
extends "res://godot_ui_components/scenes/balatro/scripts/card.gd"

var _card_data: CardData
var home_position: Vector2 = Vector2.ZERO

var _render_pending := false
var _animation_pending := false
var _render_viewport: SubViewport
var _visuals_ready := false

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
	if _render_pending and _render_viewport and is_instance_valid(_render_viewport):
		var tex := _render_viewport.get_texture()
		if tex and tex.get_size() != Vector2.ZERO:
			var image := tex.get_image()
			_render_viewport.queue_free()
			_render_viewport = null
			_render_pending = false
			if image:
				card_texture.texture = ImageTexture.create_from_image(image)
			if _animation_pending:
				_animation_pending = false
				_start_draw_animation()

func _setup_visuals() -> void:
	var empty_style := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty_style)
	add_theme_stylebox_override("hover", empty_style)
	add_theme_stylebox_override("pressed", empty_style)
	add_theme_stylebox_override("disabled", empty_style)
	add_theme_stylebox_override("focus", empty_style)

	var fake_shader := load("res://godot_ui_components/scenes/shared/shaders/fake_3D.gdshader") as Shader
	var texture := load("res://resources/textures/card/Tiles_A_white.png") as Texture2D

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
	_render_pending = true
	_render_viewport = SubViewport.new()
	_render_viewport.size = Vector2(152, 207)
	_render_viewport.transparent_bg = true
	_render_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var card_face := Control.new()
	card_face.size = Vector2(152, 207)
	_render_viewport.add_child(card_face)
	CardRender._build_card_face(card_face, _card_data, Vector2(152, 207))
	add_child(_render_viewport)

func get_card_data() -> CardData:
	return _card_data

func get_card_rect() -> Rect2:
	return get_global_rect()

func _on_card_button_up() -> void:
	scale = Vector2.ONE
	rotation = 0.0
	if home_position != Vector2.ZERO:
		snap_to_home()
	card_released.emit(self)

func handle_shadow(delta: float) -> void:
	var center: Vector2 = get_viewport_rect().size / 2.0
	var distance: float = global_position.x - center.x
	shadow.position.x = lerp(0.0, sign(distance) * max_offset_shadow, abs(distance / center.x))

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
	if _render_pending:
		_animation_pending = true
		return
	_start_draw_animation()

func _start_draw_animation() -> void:
	global_position = Vector2(0, 800)
	modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", home_position, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
