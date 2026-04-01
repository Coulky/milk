extends Area2D

var experience_value: int = 1

func _ready():
	add_to_group("experience_gem")
	
	# 从配置中获取经验宝石信息
	var drop_data = ConfigManager.get_drop("experience_gem")
	var icon = drop_data.get("path", "★")
	
	if icon.begins_with("res://"):
		# 创建 Sprite2D 节点来显示图片
		var sprite = Sprite2D.new()
		
		# 加载纹理
		var texture = load(icon)
		if texture:
			sprite.texture = texture
			
			# 根据配置的 size 调整缩放
			if drop_data.has("size"):
				var size = drop_data.get("size")
				if size is Array and size.size() == 2:
					# 计算缩放比例
					var texture_size = texture.get_size()
					var scale_x = size[0] / texture_size.x
					var scale_y = size[1] / texture_size.y
					sprite.scale = Vector2(scale_x, scale_y)
		
		add_child(sprite)
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
