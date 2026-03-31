extends Node2D

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var enemy_spawner: Node = $EnemySpawner
@onready var game_ui: CanvasLayer = $GameUI
@onready var upgrade_ui: CanvasLayer = $UpgradeUI

var player_scene = preload("res://scenes/entities/player.tscn")
var player: CharacterBody2D = null

# 暂停菜单对话框
var pause_dialog: AcceptDialog

func _ready():
	GameManager.connect("level_up", _on_level_up)
	GameManager.connect("game_over", _on_game_over)
	# 预创建暂停菜单
	create_pause_dialog()
	# 设置 process_mode 为 ALWAYS，确保在场景树暂停时仍能响应输入
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_game()

func create_pause_dialog():
	# 创建暂停菜单对话框
	pause_dialog = AcceptDialog.new()
	# 设置 process_mode 为 ALWAYS，确保在场景树暂停时仍能响应
	pause_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_dialog.title = "游戏暂停"
	pause_dialog.min_size = Vector2(300, 200)
	
	# 清除默认的OK按钮
	for child in pause_dialog.get_children():
		if child is Button and child.text == "OK":
			child.queue_free()
	
	# 创建垂直容器
	var vbox = VBoxContainer.new()
	# 设置 process_mode 为 ALWAYS
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_theme_constant_override("margin_left", 20)
	vbox.add_theme_constant_override("margin_top", 20)
	vbox.add_theme_constant_override("margin_right", 20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	pause_dialog.add_child(vbox)
	
	# 继续游戏按钮
	var continue_button = Button.new()
	# 设置 process_mode 为 ALWAYS
	continue_button.process_mode = Node.PROCESS_MODE_ALWAYS
	continue_button.text = "继续游戏"
	continue_button.pressed.connect(func():
		# 恢复游戏
		GameManager.resume_game()
		pause_dialog.hide()
	)
	vbox.add_child(continue_button)
	
	# 重新开始按钮
	var restart_button = Button.new()
	# 设置 process_mode 为 ALWAYS
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.text = "重新开始"
	restart_button.pressed.connect(func():
		# 先恢复游戏，再切换场景
		GameManager.resume_game()
		pause_dialog.hide()
		# 跳转到角色选择界面
		get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
	)
	vbox.add_child(restart_button)
	
	# 退出按钮
	var exit_button = Button.new()
	# 设置 process_mode 为 ALWAYS
	exit_button.process_mode = Node.PROCESS_MODE_ALWAYS
	exit_button.text = "退出"
	exit_button.pressed.connect(func():
		# 先恢复游戏，再切换场景
		GameManager.resume_game()
		pause_dialog.hide()
		# 返回主菜单
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	vbox.add_child(exit_button)
	
	# 添加ESC键关闭功能
	pause_dialog.connect("close_requested", func():
		print("ESC键被按下，恢复游戏")
		GameManager.resume_game()
		pause_dialog.hide()
	)
	
	# 添加到根节点
	get_tree().root.add_child(pause_dialog)
	pause_dialog.hide()

func start_game():
	GameManager.start_game()
	
	# 计算视口中心位置
	var viewport_size = get_viewport().size
	var center_position = viewport_size / 2
	
	player = player_scene.instantiate()
	player.global_position = center_position
	add_child(player)
	
	game_ui.visible = true

func _on_level_up(_new_level: int):
	upgrade_ui.show_upgrades()

func _on_game_over():
	game_ui.visible = false
	
	var game_over_label = Label.new()
	game_over_label.text = "游戏结束！\n按 R 重新开始"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.add_theme_font_size_override("font_size", 48)
	game_over_label.anchors_preset = Control.PRESET_CENTER
	game_over_label.offset_left = -200
	game_over_label.offset_top = -50
	game_over_label.offset_right = 200
	game_over_label.offset_bottom = 50
	
	var canvas = CanvasLayer.new()
	canvas.add_child(game_over_label)
	add_child(canvas)

func _input(event: InputEvent):
	if event.is_action_pressed("ui_accept") and not GameManager.is_game_running:
		get_tree().reload_current_scene()
	
	if event.is_action_pressed("pause_menu") and GameManager.is_game_running and not GameManager.is_paused:  # 'r' key
		show_pause_menu()
	
	# 直接处理 ESC 键，确保在游戏暂停时能够恢复
	if event.is_action_pressed("ui_cancel") and GameManager.is_paused:
		print("ESC键被按下，恢复游戏")
		GameManager.resume_game()
		pause_dialog.hide()

func show_pause_menu():
	# 暂停游戏
	GameManager.pause_game()
	# 显示预创建的暂停菜单
	pause_dialog.show()
