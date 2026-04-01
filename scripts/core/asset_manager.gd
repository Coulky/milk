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
func create_texture_rect(asset_data: Dictionary) -> TextureRect:
	var texture_rect = TextureRect.new()
	
	# 设置尺寸
	var size = get_asset_display_size(asset_data)
	texture_rect.custom_minimum_size = size
	print("AssetManager: Creating texture rect with size: " + str(size))
	
	# 设置拉伸模式
	texture_rect.stretch_mode = 2 # STRETCH_KEEP_ASPECT_CENTERED
	
	# 加载纹理
	var path = asset_data.get("path", "")
	var texture = load_asset_texture(path)
	if texture:
		texture_rect.texture = texture
	
	return texture_rect
