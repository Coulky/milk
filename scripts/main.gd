extends Node2D

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var enemy_spawner: Node = $EnemySpawner
@onready var game_ui: CanvasLayer = get_node_or_null("GameUI")
@onready var upgrade_ui: CanvasLayer = get_node_or_null("UpgradeUI")

var player_scene = preload("res://scenes/entities/player.tscn")
var player: CharacterBody2D = null

# 暂停菜单对话框
var pause_dialog: Window
# 死亡菜单对话框
var death_dialog: Window

func _ready():
	GameManager.connect("level_up", _on_level_up)
	GameManager.connect("game_over", _on_game_over)
	# 预创建暂停菜单
	create_pause_dialog()
	# 预创建死亡菜单
	create_death_dialog()
	start_game()

func create_pause_dialog():
	# 创建暂停菜单对话框
	pause_dialog = Window.new()
	# 设置 process_mode 为 ALWAYS，确保在场景树暂停时仍能响应
	pause_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_dialog.title = ConfigManager.get_language_text("pause_menu.title", "游戏暂停")
	pause_dialog.min_size = Vector2(600, 400)
	# 确保对话框居中
	pause_dialog.unresizable = true
	pause_dialog.size = Vector2(600, 400)  # 增加宽度
	
	# 创建水平容器
	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.process_mode = Node.PROCESS_MODE_ALWAYS
	hbox.add_theme_constant_override("margin_left", 20)
	hbox.add_theme_constant_override("margin_top", 20)
	hbox.add_theme_constant_override("margin_right", 20)
	hbox.add_theme_constant_override("margin_bottom", 20)
	hbox.add_theme_constant_override("separation", 40)
	hbox.size = Vector2(560, 360)  # 增加宽度和高度
	pause_dialog.add_child(hbox)
	
	# 左侧：按钮区域
	var left_vbox = VBoxContainer.new()
	left_vbox.name = "LeftVBox"
	left_vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	left_vbox.size_flags_horizontal = 0  # 禁用水平方向的自动调整
	left_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# 设置左侧按钮区域的固定宽度
	left_vbox.size = Vector2(250, 360)  # 设置固定宽度为150
	hbox.add_child(left_vbox)
	
	# 继续游戏按钮
	var continue_button = Button.new()
	continue_button.process_mode = Node.PROCESS_MODE_ALWAYS
	continue_button.text = ConfigManager.get_language_text("pause_menu.continue", "继续游戏")
	continue_button.pressed.connect(func():
		GameManager.resume_game()
		pause_dialog.hide()
	)
	left_vbox.add_child(continue_button)
	
	# 重新开始按钮
	var restart_button = Button.new()
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.text = ConfigManager.get_language_text("pause_menu.restart", "重新开始")
	restart_button.pressed.connect(func():
		GameManager.resume_game()
		GameManager.reset_game()
		pause_dialog.hide()
		get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
	)
	left_vbox.add_child(restart_button)
	
	# 退出按钮
	var exit_button = Button.new()
	exit_button.process_mode = Node.PROCESS_MODE_ALWAYS
	exit_button.text = ConfigManager.get_language_text("pause_menu.exit", "退出")
	exit_button.pressed.connect(func():
		GameManager.resume_game()
		GameManager.reset_game()
		pause_dialog.hide()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	left_vbox.add_child(exit_button)
	
	# 右侧：角色属性区域
	var right_vbox = VBoxContainer.new()
	right_vbox.name = "RightVBox"
	right_vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(right_vbox)
	
	# 角色属性标题
	var title_label = Label.new()
	title_label.process_mode = Node.PROCESS_MODE_ALWAYS
	title_label.text = ConfigManager.get_language_text("pause_menu.character_stats", "角色属性")
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_constant_override("margin_bottom", 5)
	right_vbox.add_child(title_label)
	
	# 属性显示容器（使用 ScrollContainer 以防属性过多）
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.process_mode = Node.PROCESS_MODE_ALWAYS
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_theme_constant_override("margin_left", 2)
	scroll.add_theme_constant_override("margin_top", 2)
	scroll.add_theme_constant_override("margin_right", 2)
	scroll.add_theme_constant_override("margin_bottom", 2)
	right_vbox.add_child(scroll)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.name = "StatsVBox"
	stats_vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL  # 确保垂直扩展
	stats_vbox.add_theme_constant_override("separation", 2)  # 进一步减少属性之间的间距
	# 添加蓝色背景
	var stats_bg = ColorRect.new()
	stats_bg.name = "Background"
	stats_bg.color = Color(0, 0, 1, 0.2)  # 半透明蓝色背景
	stats_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_bg.z_index = -1  # 确保背景在最底层
	stats_vbox.add_child(stats_bg)
	scroll.add_child(stats_vbox)
	
	# 添加ESC键关闭功能
	pause_dialog.connect("close_requested", func():
		GameManager.resume_game()
		pause_dialog.hide()
	)
	
	# 添加到根节点
	get_tree().root.add_child(pause_dialog)
	pause_dialog.hide()

func create_death_dialog():
	# 创建死亡菜单对话框
	death_dialog = Window.new()
	# 设置 process_mode 为 ALWAYS，确保在场景树暂停时仍能响应
	death_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	death_dialog.title = ConfigManager.get_language_text("death_menu.title", "你已经死亡")
	death_dialog.min_size = Vector2(300, 150)
	# 确保对话框居中
	death_dialog.unresizable = true
	
	# 创建垂直容器
	var vbox = VBoxContainer.new()
	# 设置 process_mode 为 ALWAYS
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_theme_constant_override("margin_left", 20)
	vbox.add_theme_constant_override("margin_top", 20)
	vbox.add_theme_constant_override("margin_right", 20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	death_dialog.add_child(vbox)
	
	# 重新开始按钮
	var restart_button = Button.new()
	# 设置 process_mode 为 ALWAYS
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.text = ConfigManager.get_language_text("death_menu.restart", "重新开始")
	restart_button.pressed.connect(func():
		# 先恢复游戏，再切换场景
		GameManager.resume_game()
		GameManager.reset_game()
		death_dialog.hide()
		# 跳转到角色选择界面
		get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
	)
	vbox.add_child(restart_button)
	
	# 退出按钮
	var exit_button = Button.new()
	# 设置 process_mode 为 ALWAYS
	exit_button.process_mode = Node.PROCESS_MODE_ALWAYS
	exit_button.text = ConfigManager.get_language_text("death_menu.exit", "退出")
	exit_button.pressed.connect(func():
		# 先恢复游戏，再切换场景
		GameManager.resume_game()
		GameManager.reset_game()
		death_dialog.hide()
		# 返回主菜单
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	vbox.add_child(exit_button)
	
	# 添加ESC键关闭功能
	death_dialog.connect("close_requested", func():
		GameManager.resume_game()
		GameManager.reset_game()
		death_dialog.hide()
		# 返回主菜单
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	
	# 添加到根节点
	get_tree().root.add_child(death_dialog)
	death_dialog.hide()

func _process(_delta):
	if player and is_instance_valid(player):
		if has_node("Camera2D"):
			var camera = $Camera2D
			
			# 获取地图尺寸
			var map_size = ConfigManager.get_map_size()
			var map_width = map_size.get("width", 2000)
			var map_height = map_size.get("height", 2000)
			
			# 获取视口大小
			var viewport_size = get_viewport_rect().size
			
			# 计算相机的最小和最大位置
			var min_camera_x = viewport_size.x / 2
			var max_camera_x = map_width - viewport_size.x / 2
			var min_camera_y = viewport_size.y / 2
			var max_camera_y = map_height - viewport_size.y / 2
			
			# 计算目标相机位置，并限制在边界内
			var target_camera_x = clamp(player.global_position.x, min_camera_x, max_camera_x)
			var target_camera_y = clamp(player.global_position.y, min_camera_y, max_camera_y)
			
			# 设置相机位置
			camera.global_position = Vector2(target_camera_x, target_camera_y)

func start_game():
	# 清空地图
	clear_map()
	
	GameManager.start_game()
	
	# 计算地图中心位置（2000x2000的正方形）
	var map_center = Vector2(1000, 1000)
	
	# 创建地图边框标记
	create_map_border()
	
	player = player_scene.instantiate()
	player.global_position = map_center
	add_child(player)
	
	# 设置相机跟随玩家
	if has_node("Camera2D"):
		var camera = $Camera2D
		camera.global_position = player.global_position
		# 设为当前相机
		camera.make_current()
	
	if game_ui and is_instance_valid(game_ui):
		game_ui.visible = true

func clear_map():
	# 删除旧的玩家
	if player and is_instance_valid(player):
		player.queue_free()
		player = null
	
	# 删除所有敌人
	for enemy in GameManager.get_enemies():
		if enemy and is_instance_valid(enemy):
			enemy.queue_free()
	
	# 重置敌人生成器
	if enemy_spawner and is_instance_valid(enemy_spawner):
		enemy_spawner.reset()
	
	# 删除所有经验宝石
	for child in get_tree().root.get_children():
		if child.name == "ExperienceGem" or child.has_method("experience_value") or child.is_in_group("experience_gem"):
			if is_instance_valid(child):
				child.queue_free()
		# 也可以清除其他类型的掉落物品
		if child.is_in_group("items") or child.is_in_group("pickups") or child.has_method("pickup"):
			if is_instance_valid(child):
				child.queue_free()
		# 清除敌人投射物
		if child.is_in_group("enemy_projectiles") or child.name == "EnemyProjectile" or child.name == "EnemyProjectileSplit":
			if is_instance_valid(child):
				child.queue_free()
	var map_border = get_node_or_null("MapBorder")
	if map_border and is_instance_valid(map_border):
		map_border.queue_free()
	
	# 删除其他可能的子节点（除了UI和EnemySpawner）
	for child in get_children():
		if child.name != "GameUI" and child.name != "UpgradeUI" and child.name != "EnemySpawner" and child.name != "Camera2D" and child.name != "PlayerSpawn" and child.name != "MapBorder":
			if is_instance_valid(child):
				child.queue_free()

func create_map_border():
	var map_size = ConfigManager.get_map_size()
	var map_width = map_size.get("width", 2000)
	var map_height = map_size.get("height", 2000)
	
	# 创建 Line2D 来绘制边框
	var border_line = Line2D.new()
	border_line.name = "MapBorder"
	border_line.width = 4.0
	border_line.default_color = Color.GRAY
	border_line.closed = true
	
	# 添加四个角的点
	border_line.add_point(Vector2(0, 0))
	border_line.add_point(Vector2(map_width, 0))
	border_line.add_point(Vector2(map_width, map_height))
	border_line.add_point(Vector2(0, map_height))
	
	add_child(border_line)

func _on_level_up(_new_level: int):
	if upgrade_ui and is_instance_valid(upgrade_ui):
		upgrade_ui.show_upgrades()

func _on_game_over():
	if game_ui and is_instance_valid(game_ui):
		game_ui.visible = false
	# 显示死亡菜单
	show_death_menu()

func _input(event: InputEvent):
	if event.is_action_pressed("pause_menu") and GameManager.is_game_running and not GameManager.is_paused:  # 'r' key
		show_pause_menu()
	
	# 直接处理 ESC 键，确保在游戏暂停时能够恢复
	if event.is_action_pressed("ui_cancel") and GameManager.is_paused:
		GameManager.resume_game()
		if pause_dialog and is_instance_valid(pause_dialog):
			pause_dialog.hide()
		if death_dialog and is_instance_valid(death_dialog):
			death_dialog.hide()

func show_pause_menu():
	# 暂停游戏
	GameManager.pause_game()
	# 更新角色属性显示
	update_pause_menu_stats()
	# 确保对话框居中
	var viewport_size = Vector2(get_viewport_rect().size)
	var dialog_size = Vector2(pause_dialog.min_size)
	pause_dialog.position = (viewport_size - dialog_size) / 2
	# 显示预创建的暂停菜单
	pause_dialog.show()

func update_pause_menu_stats():
	# 获取属性显示容器
	var scroll = pause_dialog.get_node_or_null("HBoxContainer/RightVBox/ScrollContainer")
	if not scroll:
		# 打印所有子节点来调试
		print("Pause dialog children:", pause_dialog.get_children())
		return
	
	var stats_vbox = scroll.get_node_or_null("StatsVBox")
	if not stats_vbox:
		# 打印滚动容器的子节点
		print("Scroll container children:", scroll.get_children())
		return
	
	# 清除旧的属性显示
	for child in stats_vbox.get_children():
		child.queue_free()
	
	# 获取玩家
	var current_player = GameManager.get_player()
	if not current_player:
		return
	
	# 获取玩家的缓存属性
	var cached_stats = current_player.get("cached_stats")
	if not cached_stats:
		return
	
	# 定义属性显示顺序
	var stat_order = [
		"max_health",
		"health_regen",
		"life_steal",
		"damage",
		"melee_damage",
		"ranged_damage",
		"elemental_damage",
		"attack_speed",
		"crit_chance",
		"range",
		"armor",
		"evasion",
		"speed",
		"experience_gain",
		"pickup_range",
		"bounce_count",
		"multiple_attack"
	]
	
	# 显示每个属性
	for stat_name in stat_order:
		if cached_stats.has(stat_name):
			var value = cached_stats[stat_name]
			# 跳过null值的属性
			if value == null:
				continue
			
			var stat_label = Label.new()
			stat_label.process_mode = Node.PROCESS_MODE_ALWAYS
			stat_label.add_theme_font_size_override("font_size", 14)  # 增加字体大小
			stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # 确保标签能够水平扩展
			stat_label.clip_text = false  # 禁用文本裁剪
			
			# 获取属性名称的本地化文本
			var stat_text = ConfigManager.get_language_text("item_attributes." + stat_name, stat_name)
			stat_text = stat_text.replace("{value}", str(value))
			
			stat_label.text = stat_text
			stats_vbox.add_child(stat_label)

func show_death_menu():
	# 暂停游戏
	GameManager.pause_game()
	# 确保对话框居中
	var viewport_size = Vector2(get_viewport_rect().size)
	var dialog_size = Vector2(death_dialog.min_size)
	death_dialog.position = (viewport_size - dialog_size) / 2
	# 显示预创建的死亡菜单
	death_dialog.show()
