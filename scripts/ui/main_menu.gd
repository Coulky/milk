extends Control

var character_select_scene = preload("res://scenes/ui/character_select.tscn")

# 常用分辨率选项
var resolutions = [
	Vector2(800, 600),
	Vector2(1024, 768),
	Vector2(1280, 720),  # HD
	Vector2(1920, 1080),  # FHD
	Vector2(2560, 1440),  # QHD
	Vector2(3840, 2160)  # 4K
]

func _ready():
	# 设置按钮文本
	if has_node("VBoxContainer/StartButton"):
		$VBoxContainer/StartButton.text = ConfigManager.get_language_text("main_menu.start_game", "开始游戏")
	if has_node("VBoxContainer/SettingsButton"):
		$VBoxContainer/SettingsButton.text = ConfigManager.get_language_text("main_menu.settings", "设置")
	if has_node("VBoxContainer/QuitButton"):
		$VBoxContainer/QuitButton.text = ConfigManager.get_language_text("main_menu.quit", "退出")

func _on_start_button_pressed():
	# 切换到角色选择场景
	get_tree().change_scene_to_packed(character_select_scene)

func _on_settings_button_pressed():
	# 创建灰色蒙版
	var overlay = ColorRect.new()
	overlay.name = "SettingsOverlay"
	overlay.anchors_preset = 15
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.grow_horizontal = 2
	overlay.grow_vertical = 2
	overlay.color = Color(0, 0, 0, 0.7)  # 半透明黑色蒙版
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # 阻止点击穿透
	add_child(overlay)
	
	# 创建设置对话框
	var dialog = AcceptDialog.new()
	dialog.title = ConfigManager.get_language_text("settings.title", "设置")
	dialog.min_size = Vector2(400, 300)
	
	# 移除默认的 OK 按钮
	dialog.get_ok_button().queue_free()
	
	# 隐藏右上角的关闭按钮 - 使用 Godot 4 正确的方法
	if dialog.has_node("close_button"):
		dialog.get_node("close_button").queue_free()
	
	# 创建垂直容器
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	vbox.add_theme_constant_override("margin_left", 20)
	vbox.add_theme_constant_override("margin_right", 20)
	vbox.add_theme_constant_override("margin_top", 20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	
	# 分辨率设置
	var resolution_hbox = HBoxContainer.new()
	vbox.add_child(resolution_hbox)
	
	var resolution_label = Label.new()
	resolution_label.text = ConfigManager.get_language_text("settings.resolution", "分辨率:")
	resolution_hbox.add_child(resolution_label)
	
	var resolution_option = OptionButton.new()
	for res in resolutions:
		resolution_option.add_item("%dx%d" % [res.x, res.y])
	# 默认选择当前分辨率
	var current_size = Vector2(get_viewport().size)
	for i in range(resolutions.size()):
		if resolutions[i] == current_size:
			resolution_option.selected = i
			break
	resolution_hbox.add_child(resolution_option)
	
	# 窗口模式设置
	var mode_hbox = HBoxContainer.new()
	vbox.add_child(mode_hbox)
	
	var mode_label = Label.new()
	mode_label.text = ConfigManager.get_language_text("settings.display_mode", "显示模式:")
	mode_hbox.add_child(mode_label)
	
	var mode_option = OptionButton.new()
	mode_option.add_item(ConfigManager.get_language_text("settings.windowed", "窗口模式"))
	mode_option.add_item(ConfigManager.get_language_text("settings.fullscreen", "全屏模式"))
	# 默认选择当前模式
	mode_option.selected = 1 if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else 0
	mode_hbox.add_child(mode_option)
	
	# 语言设置
	var language_hbox = HBoxContainer.new()
	vbox.add_child(language_hbox)
	
	var language_label = Label.new()
	language_label.text = ConfigManager.get_language_text("settings.language", "语言:")
	language_hbox.add_child(language_label)
	
	var language_option = OptionButton.new()
	language_option.add_item("简体中文")
	language_option.add_item("English")
	language_option.add_item("日本語")
	# 默认选择当前语言
	var current_locale = TranslationServer.get_locale()
	match current_locale:
		"zh_CN":
			language_option.selected = 0
		"en":
			language_option.selected = 1
		"ja":
			language_option.selected = 2
		_:
			language_option.selected = 0  # 默认简体中文
	language_hbox.add_child(language_option)
	
	# 应用按钮
	var apply_button = Button.new()
	apply_button.text = ConfigManager.get_language_text("settings.apply", "应用")
	apply_button.pressed.connect(func():
		# 应用分辨率
		var selected_res = resolutions[resolution_option.selected]
		DisplayServer.window_set_size(selected_res)
		
		# 应用显示模式
		var mode = DisplayServer.WINDOW_MODE_WINDOWED if mode_option.selected == 0 else DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(mode)
		
		# 应用语言设置
		var selected_language = language_option.selected
		var locale = "zh_CN"  # 默认简体中文
		match selected_language:
			0:
				locale = "zh_CN"
			1:
				locale = "en"
			2:
				locale = "ja"
		TranslationServer.set_locale(locale)
		
		# 刷新界面文本
		if has_node("VBoxContainer/StartButton"):
			$VBoxContainer/StartButton.text = ConfigManager.get_language_text("main_menu.start_game", "开始游戏")
		if has_node("VBoxContainer/SettingsButton"):
			$VBoxContainer/SettingsButton.text = ConfigManager.get_language_text("main_menu.settings", "设置")
		if has_node("VBoxContainer/QuitButton"):
			$VBoxContainer/QuitButton.text = ConfigManager.get_language_text("main_menu.quit", "退出")
		
		# 清理
		dialog.hide()
		dialog.queue_free()
		overlay.queue_free()
	)
	vbox.add_child(apply_button)
	
	# 关闭按钮
	var close_button = Button.new()
	close_button.text = ConfigManager.get_language_text("settings.close", "关闭")
	close_button.pressed.connect(func():
		dialog.hide()
		dialog.queue_free()
		overlay.queue_free()
	)
	vbox.add_child(close_button)
	
	# 处理对话框关闭事件
	dialog.close_requested.connect(func():
		dialog.hide()
		dialog.queue_free()
		overlay.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()  # 居中显示对话框

func _on_quit_button_pressed():
	get_tree().quit()
