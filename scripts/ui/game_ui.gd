extends CanvasLayer

@onready var time_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/TimeLabel
@onready var level_label: Label = $MarginContainer/VBoxContainer/HBoxContainer2/LevelLabel
@onready var exp_bar: ProgressBar = $MarginContainer/VBoxContainer/ExpBar
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBarContainer/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthBarContainer/HealthLabel
@onready var kill_label: Label = $MarginContainer/VBoxContainer/HBoxContainer3/KillLabel
@onready var damage_numbers_checkbox: CheckBox = $MarginContainer/VBoxContainer/HBoxContainer4/DamageNumbersCheckBox
@onready var items_container: HBoxContainer = $Inventory/PanelContainer/ItemsContainer

# 存储当前显示的物品
var displayed_items: Dictionary = {}

func _ready():
	GameManager.connect("experience_gained", _on_experience_gained)
	GameManager.connect("level_up", _on_level_up)
	GameManager.connect("health_changed", _on_health_changed)
	GameManager.connect("game_started", _on_game_started)
	
	# 连接伤害数值显示复选框
	damage_numbers_checkbox.toggled.connect(_on_damage_numbers_toggled)
	
	# 初始化复选框状态
	damage_numbers_checkbox.button_pressed = ConfigManager.get_game_setting("show_damage_numbers", true)
	
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
	
	# 加载item_child.png作为背景
	var item_child_texture = load("res://assets/images/items/item_child.png")
	
	# 显示每个物品
	for item_id in item_counts.keys():
		var count = item_counts[item_id]
		var item = ConfigManager.get_item(item_id)
		
		# 创建物品容器
		var item_container = Control.new()
		item_container.custom_minimum_size = Vector2(60, 60)  # 设置固定大小
		item_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# 添加item_child背景
		if item_child_texture:
			var bg_rect = TextureRect.new()
			bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg_rect.texture = item_child_texture
			bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			item_container.add_child(bg_rect)
		
		# 处理图标
		var icon_path = item.get("path", "?")
		
		if icon_path.begins_with("res://"):
			# 如果是图片路径，加载纹理
			var icon_texture = load(icon_path)
			if icon_texture:
				var icon_rect = TextureRect.new()
				icon_rect.texture = icon_texture
				
				# 计算图标尺寸，保持比例
				var original_size = icon_texture.get_size()
				var max_side = max(original_size.x, original_size.y)
				var icon_scale = 40.0 / max_side  # 图标最大尺寸40
				var scaled_size = original_size * icon_scale
				
				icon_rect.custom_minimum_size = scaled_size
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				
				# 居中放置图标并调整位置
				icon_rect.set_anchors_preset(Control.PRESET_CENTER)
				icon_rect.offset_left = -20  # 向左移动20像素
				icon_rect.offset_top = -20  # 向上移动20像素
				item_container.add_child(icon_rect)
			else:
				# 如果加载失败，显示默认符号
				var fallback_label = Label.new()
				fallback_label.text = "?"
				fallback_label.add_theme_font_size_override("font_size", 20)
				fallback_label.set_anchors_preset(Control.PRESET_CENTER)
				fallback_label.offset_left = -20  # 向左移动20像素
				fallback_label.offset_top = -20  # 向上移动20像素
				fallback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
				item_container.add_child(fallback_label)
		else:
			# 如果是符号，显示为文本
			var icon_label = Label.new()
			icon_label.text = icon_path
			icon_label.add_theme_font_size_override("font_size", 20)
			icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_label.offset_left = -20  # 向左移动20像素
			icon_label.offset_top = -20  # 向上移动20像素
			icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			item_container.add_child(icon_label)
		
		# 如果数量大于1，在右下角显示计数
		if count > 1:
			var count_label = Label.new()
			count_label.text = str(count)
			count_label.add_theme_font_size_override("font_size", 14)
			count_label.add_theme_color_override("font_color", Color(0, 0, 0))  # 黑色文本
			count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			count_label.set_anchors_preset(Control.PRESET_FULL_RECT)
			count_label.offset_left = 5
			count_label.offset_top = 5
			count_label.offset_right = -5
			count_label.offset_bottom = -5
			count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			item_container.add_child(count_label)
		
		# 添加到物品容器
		items_container.add_child(item_container)
		displayed_items[item_id] = item_container

func _on_damage_numbers_toggled(button_pressed: bool):
	ConfigManager.set_game_setting("show_damage_numbers", button_pressed)
