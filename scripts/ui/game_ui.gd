extends CanvasLayer

@onready var time_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/TimeLabel
@onready var level_label: Label = $MarginContainer/VBoxContainer/HBoxContainer2/LevelLabel
@onready var exp_bar: ProgressBar = $MarginContainer/VBoxContainer/ExpBar
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBarContainer/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthBarContainer/HealthLabel
@onready var kill_label: Label = $MarginContainer/VBoxContainer/HBoxContainer3/KillLabel
@onready var items_container: HBoxContainer = $Inventory/ItemsContainer

# 存储当前显示的物品
var displayed_items: Dictionary = {}

func _ready():
	GameManager.connect("experience_gained", _on_experience_gained)
	GameManager.connect("level_up", _on_level_up)
	GameManager.connect("health_changed", _on_health_changed)
	GameManager.connect("game_started", _on_game_started)
	
	update_ui()

func _process(_delta):
	if GameManager.is_game_running:
		time_label.text = GameManager.get_game_time_formatted()

func update_ui():
	var level_text = ConfigManager.get_language_text("ui.level_label", "等级: {0}")
	level_label.text = level_text.format([GameManager.current_level])
	
	var kill_text = ConfigManager.get_language_text("ui.kill_label", "击杀: {0}")
	kill_label.text = kill_text.format([GameManager.kill_count])
	
	var exp_percent = float(GameManager.total_experience) / float(GameManager.experience_to_next_level) * 100
	exp_bar.value = exp_percent

func _on_experience_gained(_amount: int):
	update_ui()

func _on_level_up(new_level: int):
	var level_text = ConfigManager.get_language_text("ui.level_label", "等级: {0}")
	level_label.text = level_text.format([new_level])
	exp_bar.value = 0

func _on_health_changed(current_health: int, max_health: int):
	# 血条长度固定为 100，不随最大生命值增长而变长
	health_bar.max_value = 100.0
	# 计算生命值百分比
	var health_percent = float(current_health) / float(max_health) * 100.0
	health_bar.value = health_percent
	# 显示当前生命值和最大生命值
	health_label.text = "%d/%d" % [current_health, max_health]

func _on_game_started():
	var player = GameManager.get_player()
	if player != null and player.has_method("get_health_info"):
		var health_info = player.get_health_info()
		# 血条长度固定为 100，不随最大生命值增长而变长
		health_bar.max_value = 100.0
		# 计算生命值百分比
		var health_percent = float(health_info.current_health) / float(health_info.max_health) * 100.0
		health_bar.value = health_percent
		# 显示当前生命值和最大生命值
		health_label.text = "%d/%d" % [health_info.current_health, health_info.max_health]
		# 初始化物品栏
		update_inventory(player.item_counts)
	update_ui()

func update_inventory(item_counts: Dictionary):
	# 清除旧的显示
	for child in items_container.get_children():
		child.queue_free()
	displayed_items.clear()
	
	# 显示每个物品
	for item_id in item_counts.keys():
		var count = item_counts[item_id]
		var item = ConfigManager.get_item(item_id)
		
		# 获取物品图标
		var icon = item.get("path", "?")
		
		if icon.begins_with("res://"):
			# 如果是图片路径，创建一个水平容器来放置图片和计数
			var item_container = HBoxContainer.new()
			item_container.alignment = BoxContainer.ALIGNMENT_CENTER
			
			# 使用 AssetManager 创建 TextureRect
			var asset_manager = preload("res://scripts/core/asset_manager.gd").new()
			var icon_container = asset_manager.create_texture_rect(item)
			# 检查容器中是否有纹理
			var texture_rect = icon_container.get_child(0)
			if texture_rect and texture_rect.texture:
				# 直接添加容器到物品容器
				item_container.add_child(icon_container)
			else:
				# 如果加载失败，显示默认符号
				var fallback_label = Label.new()
				fallback_label.text = "?"
				fallback_label.add_theme_font_size_override("font_size", 24)
				item_container.add_child(fallback_label)
				items_container.add_child(item_container)
				displayed_items[item_id] = item_container
				continue
			
			# 如果数量大于1，显示计数
			if count > 1:
				var count_label = Label.new()
				count_label.text = "*%d" % count
				count_label.add_theme_font_size_override("font_size", 16)
				item_container.add_child(count_label)
			
			items_container.add_child(item_container)
			displayed_items[item_id] = item_container
		else:
			# 如果是符号，显示为文本
			var item_label = Label.new()
			item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			
			# 如果数量大于1，显示 "图标*x"
			if count > 1:
				item_label.text = "%s*%d" % [icon, count]
			else:
				item_label.text = icon
			
			# 设置字体大小
			item_label.add_theme_font_size_override("font_size", 24)
			
			items_container.add_child(item_label)
			displayed_items[item_id] = item_label
