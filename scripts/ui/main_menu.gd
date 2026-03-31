extends Control

var game_scene = preload("res://scenes/main.tscn")

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
	pass

func _on_start_button_pressed():
	# 使用推荐的场景切换方式，确保场景正确清理
	get_tree().change_scene_to_packed(game_scene)

func _on_settings_button_pressed():
	# 创建设置对话框
	var dialog = AcceptDialog.new()
	dialog.title = "设置"
	dialog.min_size = Vector2(400, 300)
	
	# 创建垂直容器
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	# 分辨率设置
	var resolution_hbox = HBoxContainer.new()
	vbox.add_child(resolution_hbox)
	
	var resolution_label = Label.new()
	resolution_label.text = "分辨率:"
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
	mode_label.text = "显示模式:"
	mode_hbox.add_child(mode_label)
	
	var mode_option = OptionButton.new()
	mode_option.add_item("窗口模式")
	mode_option.add_item("全屏模式")
	# 默认选择当前模式
	mode_option.selected = 1 if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else 0
	mode_hbox.add_child(mode_option)
	
	# 应用按钮
	var apply_button = Button.new()
	apply_button.text = "应用"
	apply_button.pressed.connect(func():
		# 应用分辨率
		var selected_res = resolutions[resolution_option.selected]
		DisplayServer.window_set_size(selected_res)
		
		# 应用显示模式
		var mode = DisplayServer.WINDOW_MODE_WINDOWED if mode_option.selected == 0 else DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(mode)
		
		dialog.hide()
		dialog.queue_free()
	)
	vbox.add_child(apply_button)
	
	add_child(dialog)
	dialog.show()

func _on_quit_button_pressed():
	get_tree().quit()
