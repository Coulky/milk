extends Control

var game_scene = preload("res://scenes/main.tscn")

func _ready():
	pass

func _on_warrior_button_pressed():
	# 选择战士角色
	GameManager.selected_character = "warrior"
	start_game()

func _on_hunter_button_pressed():
	# 选择猎人角色
	GameManager.selected_character = "hunter"
	start_game()

func _on_mage_button_pressed():
	# 选择法师角色
	GameManager.selected_character = "mage"
	start_game()

func _on_back_button_pressed():
	# 返回主菜单
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func start_game():
	# 切换到游戏场景
	get_tree().change_scene_to_packed(game_scene)
