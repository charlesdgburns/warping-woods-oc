extends GutTest

func test_script_can_load_directly() -> void:
	var script_res = load("res://scripts/card_visual.gd")
	assert_not_null(script_res, "CardVisual script resource should load")
	if script_res:
		assert_true(script_res is Script, "Loaded resource should be a Script")
		assert_eq(script_res.resource_path, "res://scripts/card_visual.gd")

func test_scene_script_is_attached() -> void:
	var scene = load("res://scenes/card_visual.tscn")
	assert_not_null(scene, "Scene should load")
	var node: Control = scene.instantiate()
	assert_not_null(node, "Scene should instantiate")
	assert_eq(node.get_class(), "CardVisual", "Node class should be CardVisual (class_name attached)")
	assert_not_null(node.get_script(), "Node should have script attached after instantiate")
	if node.get_script():
		assert_eq(node.get_script().resource_path, "res://scripts/card_visual.gd")

func test_card_visual_new_works() -> void:
	var card_visual := CardVisual.new()
	assert_not_null(card_visual, "CardVisual should be instantiatable directly")
	assert_true(card_visual is CardVisual, "Direct instance should be CardVisual")
	assert_true(card_visual is Control, "CardVisual should extend Control")

func test_balatro_submodule_resources_exist() -> void:
	assert_true(ResourceLoader.exists("res://godot_ui_components/scenes/balatro/scripts/card.gd"), "Balatro card script should exist")
	assert_true(ResourceLoader.exists("res://godot_ui_components/scenes/balatro/visuals/Tiles_A_white.png"), "Balatro card texture should exist")
	assert_true(ResourceLoader.exists("res://godot_ui_components/scenes/shared/shaders/fake_3D.gdshader"), "fake_3D shader should exist")
	assert_true(ResourceLoader.exists("res://godot_ui_components/scenes/shared/shaders/dissolve.gdshader"), "dissolve shader should exist")
