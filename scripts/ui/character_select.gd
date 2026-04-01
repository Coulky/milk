extends Control

var game_scene = preload("res://scenes/main.tscn")

func _ready():
	# 清除地图上的掉落物品
	clear_map_items()
	
	# 设置按钮文本
	if has_node("VBoxContainer/Title"):
		$VBoxContainer/Title.text = ConfigManager.get_language_text("character_select.title", "选择角色")
	if has_node("VBoxContainer/HBoxContainer/WarriorButton"):
		$VBoxContainer/HBoxContainer/WarriorButton.text = ConfigManager.get_language_text("character_select.warrior", "战士")
	if has_node("VBoxContainer/HBoxContainer/HunterButton"):
		$VBoxContainer/HBoxContainer/HunterButton.text = ConfigManager.get_language_text("character_select.hunter", "猎人")
	if has_node("VBoxContainer/HBoxContainer/MageButton"):
		$VBoxContainer/HBoxContainer/MageButton.text = ConfigManager.get_language_text("character_select.mage", "法师")
	if has_node("VBoxContainer/BackButton"):
		$VBoxContainer/BackButton.text = ConfigManager.get_language_text("character_select.back", "返回")

func clear_map_items():
	# 清除所有经验宝石和其他掉落物品
	for child in get_tree().root.get_children():
		if child.name == "ExperienceGem" or child.has_method("experience_value") or child.is_in_group("experience_gem"):
			if is_instance_valid(child):
				child.queue_free()
		# 也可以清除其他类型的掉落物品
		if child.is_in_group("items") or child.is_in_group("pickups") or child.has_method("pickup"):
			if is_instance_valid(child):
				child.queue_free()

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
