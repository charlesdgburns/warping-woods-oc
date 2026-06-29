class_name ActionCard
extends GridContainer

signal action_selected(action_name: String)

var _options: Dictionary = {}


func _ready() -> void:
	columns = 2
	_setup_options()


func _setup_options() -> void:
	var actions := [
		["move", "Move", true],
		["attack_opt", "Attack", false],
		["escape_opt", "Escape", false],
		["trade_opt", "Trade", false],
		["item_opt", "Item", false],
		["rest_opt", "Rest", true],
	]

	for a in actions:
		var opt := ActionOption.new()
		opt.setup(a[0], a[1], a[2])
		opt.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
		opt.option_clicked.connect(_on_option_clicked)
		_options[a[0]] = opt
		add_child(opt)


func _on_option_clicked(action_name: String) -> void:
	action_selected.emit(action_name)


func set_option_available(action_name: String, available: bool) -> void:
	if _options.has(action_name):
		_options[action_name].set_available(available)


func reset_turn() -> void:
	set_option_available("move", true)
	set_option_available("rest_opt", true)
