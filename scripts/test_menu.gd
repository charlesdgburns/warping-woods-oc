extends Control

func _on_main_game_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_card_test_pressed():
	get_tree().change_scene_to_file("res://scenes/test_card_scene.tscn")

func _on_hand_test_pressed():
	pass

func _on_card_piles_pressed():
	get_tree().change_scene_to_file("res://scenes/test_card_piles.tscn")
