extends Area2D

var experience_value: int = 1

func _ready():
	add_to_group("experience_gem")
	
	# 添加自动消失计时器
	var timer = Timer.new()
	timer.wait_time = 40.0
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	
	# 从配置中获取经验宝石信息
	var drop_data = ConfigManager.get_drop("experience_gem")
	var icon = drop_data.get("path", "★")
	
	if icon.begins_with("res://"):
		# 创建 TextureRect 节点来显示图片
		var texture_rect = TextureRect.new()
		
		# 加载纹理
		var texture = load(icon)
		if texture:
			texture_rect.texture = texture
			
			# 根据配置的 size 调整大小
			if drop_data.has("size"):
				var size = drop_data.get("size")
				if size is Array and size.size() == 2:
					texture_rect.custom_minimum_size = Vector2(size[0], size[1])
			
			# 设置拉伸模式和透明度
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			
			# 居中显示
			texture_rect.position = Vector2(-texture_rect.custom_minimum_size.x / 2, -texture_rect.custom_minimum_size.y / 2)
		
		add_child(texture_rect)
	else:
		# 如果是符号，创建Label
		var label = Label.new()
		label.text = icon
		label.add_theme_color_override("font_color", Color.YELLOW)
		label.add_theme_font_size_override("font_size", 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(label)

func _on_body_entered(body):
	if body and is_instance_valid(body):
		if body.is_in_group("player"):
			GameManager.add_experience(experience_value)
			queue_free()
