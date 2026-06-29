class_name BoardTile
extends Area2D

signal tile_clicked(grid_position: Vector2i)

var grid_position: Vector2i
var tile_type: String = "walkable"
var walkable: bool = true

var _sprite: Sprite2D
var _highlight: Sprite2D

const TILE_SIZE := 40


func _ready() -> void:
	_generate_nodes()
	_set_color()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)


func _generate_nodes() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = false
	add_child(_sprite)

	_highlight = Sprite2D.new()
	_highlight.centered = false
	_highlight.visible = false
	_highlight.self_modulate = Color(1, 1, 0, 0.35)
	add_child(_highlight)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	shape.shape = rect
	add_child(shape)

	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	_sprite.texture = tex
	_highlight.texture = tex


func setup(pos: Vector2i, type: String) -> void:
	grid_position = pos
	tile_type = type
	walkable = (type != "unwalkable")
	_set_color()


func _set_color() -> void:
	if not _sprite:
		return
	match tile_type:
		"unwalkable":
			_sprite.self_modulate = Color("#8B4513")
		"encounter":
			_sprite.self_modulate = Color("#228B22")
		_:
			_sprite.self_modulate = Color("#87CEEB")


func set_highlight(active: bool) -> void:
	if _highlight:
		_highlight.visible = active


func _on_mouse_entered() -> void:
	if walkable and _sprite:
		_sprite.self_modulate = _sprite.self_modulate.lightened(0.15)


func _on_mouse_exited() -> void:
	_set_color()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tile_clicked.emit(grid_position)
