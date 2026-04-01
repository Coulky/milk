extends Node

# 资产管理器 - 统一处理素材尺寸和加载

# 获取素材的显示尺寸
func get_asset_display_size(asset_data: Dictionary) -> Vector2:
	# 从资产数据中获取尺寸配置
	if asset_data.has("size"):
		var size = asset_data.get("size")
		if size is Array and size.size() == 2:
			return Vector2(size[0], size[1])
	
	# 默认尺寸
	return Vector2(32, 32)

# 加载素材纹理
func load_asset_texture(path: String) -> Texture2D:
	if not path or not path.begins_with("res://"):
		return null
	
	# 检查文件是否存在
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("AssetManager: File not found: " + path)
		return null
	file.close()
	
	# 尝试加载纹理
	var texture = load(path)
	if texture and texture is Texture2D:
		return texture
	else:
		print("AssetManager: Failed to load texture: " + path)
		return null

# 创建纹理矩形节点
func create_texture_rect(asset_data: Dictionary) -> Control:
	# 创建一个容器节点来限制大小
	var container = Control.new()
	
	# 设置容器尺寸
	var size = get_asset_display_size(asset_data)
	container.custom_minimum_size = size
	container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# 加载纹理
	var path = asset_data.get("path", "")
	var texture = load_asset_texture(path)
	if texture:
		# 创建 Sprite2D 节点来显示图片
		var sprite = Sprite2D.new()
		sprite.texture = texture
		
		# 根据配置的 size 调整缩放
		var texture_size = texture.get_size()
		var scale_x = size.x / texture_size.x
		var scale_y = size.y / texture_size.y
		sprite.scale = Vector2(scale_x, scale_y)
		
		# 将 Sprite2D 添加到容器中
		container.add_child(sprite)
	
	return container
