extends CanvasLayer

signal upgrade_selected(upgrade_data)

var available_upgrades: Array = []
var selected_upgrade: Dictionary = {}

@onready var upgrade_container: HBoxContainer = $PanelContainer/VBoxContainer/UpgradesContainer

func _ready():
	if is_instance_valid(self):
		visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_upgrades():
	available_upgrades = generate_upgrades()
	display_upgrades()
	if is_instance_valid(self):
		visible = true
	get_tree().paused = true

func generate_upgrades() -> Array:
	var upgrades = []
	
	# 获取当前选择的角色ID
	var current_character_id = GameManager.selected_character
	
	# 只从 items 中获取物品
	var all_items = ConfigManager.get_all_items()
	
	for item in all_items:
		# 检查物品是否为该角色专属物品，或者是通用物品
		var item_type = item.get("item_type", "common")
		var item_class = item.get("class", "")
		if item_type == "common" or item_class == current_character_id:
			upgrades.append({
				"type": "item",
				"id": item.get("id"),
				"name": ConfigManager.get_item_name(item.get("id")),
				"description": ConfigManager.get_item_description(item.get("id")),
				"path": item.get("path", "I"),
				"size": item.get("size", [50, 50]),
				"color": "#ffffff",
				"stats": item.get("stats", {})
			})
	
	upgrades.shuffle()
	
	var choice_count = ConfigManager.get_game_setting("level_up_choices", 3)
	return upgrades.slice(0, min(choice_count, upgrades.size()))

func display_upgrades():
	for child in upgrade_container.get_children():
		child.queue_free()
	
	for upgrade in available_upgrades:
		# 创建物品卡片
		var card = create_item_card(upgrade)
		upgrade_container.add_child(card)

# 创建物品卡片 - 使用 item.png 作为背景，嵌入图标、名字和属性
# 
# 布局结构说明：
# - 背景：item.png 纹理
# - 图标位置：通过 ICON_OFFSET 调整，默认居中偏上
# - 名字位置：通过 NAME_OFFSET 调整，默认在图标下方
# - 属性位置：通过 STATS_OFFSET 调整，默认在名字下方
# - 所有位置都是相对于卡片中心的偏移
func create_item_card(upgrade: Dictionary) -> Control:
	# 创建按钮作为容器
	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 280)
	button.mouse_filter = Control.MOUSE_FILTER_STOP  # 确保按钮接收鼠标事件
	button.focus_mode = Control.FOCUS_NONE  # 禁用焦点模式
	
	# 创建背景容器 - 使用 Control 节点作为根容器
	var root_container = Control.new()
	root_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截鼠标事件
	button.add_child(root_container)
	
	# ========== 背景图片设置 ==========
	# 加载 item.png 作为背景
	var bg_texture = load("res://assets/images/items/item.png")
	var bg_rect = TextureRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.texture = bg_texture
	bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截鼠标事件
	root_container.add_child(bg_rect)
	
	# ========== 内容容器 ==========
	# 使用绝对定位来精确控制图标位置
	var content_container = Control.new()
	content_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截鼠标事件
	root_container.add_child(content_container)
	
	# ========== 图标位置调整 ==========
	# ICON_POSITION: 图标在卡片中的绝对位置
	# 相对于卡片左上角的坐标
	# 根据item.png中的黑色框框位置调整
	# 默认：Vector2(55, 45) - 图标放在黑色框框位置
	const ICON_POSITION = Vector2(55, 45)
	
	# 处理图标
	var icon_path = upgrade.get("path", "?")
	var icon_texture_rect: TextureRect = null
	
	if icon_path.begins_with("res://"):
		# 如果是图片路径，加载纹理
		var icon_texture = load(icon_path)
		if icon_texture:
			icon_texture_rect = TextureRect.new()
			icon_texture_rect.texture = icon_texture
			icon_texture_rect.custom_minimum_size = Vector2(80, 80)  # 增大图标大小以适配黑色框框
			icon_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截鼠标事件
			
			# 应用图标绝对位置
			icon_texture_rect.position = ICON_POSITION
			content_container.add_child(icon_texture_rect)
		else:
			# 如果加载失败，显示默认符号
			var icon_label = Label.new()
			icon_label.text = "?"
			icon_label.add_theme_font_size_override("font_size", 32)
			icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_label.custom_minimum_size = Vector2(80, 80)
			icon_label.position = ICON_POSITION
			icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截鼠标事件
			content_container.add_child(icon_label)
	else:
		# 如果是符号，显示为文本
		var icon_label = Label.new()
		icon_label.text = icon_path
		icon_label.add_theme_font_size_override("font_size", 32)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.custom_minimum_size = Vector2(80, 80)
		icon_label.position = ICON_POSITION
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截鼠标事件
		content_container.add_child(icon_label)
	
	# ========== 属性位置调整 ==========
	# STATS_POSITION: 属性列表在卡片中的绝对位置
	# 相对于卡片左上角的坐标
	# 默认：Vector2(20, 120) - 属性在名字下方（向下调整10像素）
	const STATS_POSITION = Vector2(20, 120)
	
	# 显示物品属性（只显示非零属性）
	if upgrade.get("type") == "item" and upgrade.has("stats"):
		var stats = upgrade.get("stats")
		var stats_vbox = VBoxContainer.new()
		stats_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		stats_vbox.custom_minimum_size = Vector2(160, 80)
		stats_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截鼠标事件
		
		# 应用属性绝对位置
		stats_vbox.position = STATS_POSITION
		content_container.add_child(stats_vbox)
		
		for stat_name in stats.keys():
			var value = stats[stat_name]
			if value != null and value != 0:
				var stat_label = Label.new()
				stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				stat_label.add_theme_font_size_override("font_size", 11)
				
				# 获取属性显示文本
				var attr_name = ConfigManager.get_attribute_name(stat_name)
				var unit = ConfigManager.get_attribute_unit(stat_name)
				
				if value > 0:
					stat_label.text = "+%d%s %s" % [value, unit, attr_name]
					stat_label.add_theme_color_override("font_color", Color(0, 0, 0))  # 暂时改为黑色
				else:
					stat_label.text = "%d%s %s" % [value, unit, attr_name]
					stat_label.add_theme_color_override("font_color", Color(0, 0, 0))  # 暂时改为黑色
				
				stat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截鼠标事件
				stats_vbox.add_child(stat_label)
	
	# ========== 名字位置调整 ==========
	# NAME_POSITION: 名字在卡片中的绝对位置
	# 相对于卡片左上角的坐标
	# 默认：Vector2(20, 235) - 名字在图标下方
	const NAME_POSITION = Vector2(20, 235)
	
	# 名字标签
	var name_label = Label.new()
	name_label.text = upgrade.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(160, 30)
	name_label.position = NAME_POSITION
	name_label.add_theme_color_override("font_color", Color(0, 0, 0))  # 暂时改为黑色
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不拦截鼠标事件
	content_container.add_child(name_label)

	# 设置按钮样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.0)  # 透明背景，因为使用图片
	button.add_theme_stylebox_override("normal", style)
	
	button.pressed.connect(_on_upgrade_selected.bind(upgrade))
	
	return button

func _on_upgrade_selected(upgrade: Dictionary):
	selected_upgrade = upgrade
	if is_instance_valid(self):
		visible = false
	get_tree().paused = false
	emit_signal("upgrade_selected", upgrade)
	apply_upgrade(upgrade)

func apply_upgrade(upgrade: Dictionary):
	var player = GameManager.get_player()
	if player == null:
		return
	
	# 只处理物品类型的升级
	if upgrade.get("type") == "item":
		# 处理物品，这里可以根据物品类型执行不同的操作
		# 例如，添加到物品栏或者直接使用
		var item_id = upgrade.get("id")
		var item = ConfigManager.get_item(item_id)
		
		# 增加物品计数
		if player.item_counts.has(item_id):
			player.item_counts[item_id] += 1
		else:
			player.item_counts[item_id] = 1
		
		# 通知游戏UI更新物品栏显示
		var game_ui = get_node_or_null("/root/Main/GameUI")
		if game_ui and game_ui.has_method("update_inventory"):
			game_ui.update_inventory(player.item_counts)
		
		# 应用物品效果（根据计数叠加）
		if item.has("effect"):
			# 处理物品效果
			var effect = item.get("effect")
			var _count = player.item_counts[item_id]
			match effect.get("type"):
				"heal":
					# 消耗品效果，每次使用都生效
					player.heal(effect.get("value", 0))
				"mana":
					# 暂时不处理魔法值，因为玩家脚本中没有相关属性
					pass
				"heal_mana":
					# 消耗品效果，每次使用都生效
					player.heal(effect.get("health_value", 0))
					# 暂时不处理魔法值，因为玩家脚本中没有相关属性
					pass
				"buff":
					# 处理 buff 效果
					var stats = effect.get("stats", {})
					if stats.size() > 0:
						# 应用 buff 效果（可以根据计数叠加）
						pass
		
		# 应用物品属性（根据计数叠加）
		if item.has("stats"):
			var stats = item.get("stats")
			var count = player.item_counts[item_id]
			
			# 应用属性效果
			for stat_name in stats.keys():
				var value = stats[stat_name]
				if value != null and value != 0:
					# 根据计数叠加属性
					var total_value = value * count
					# 应用属性到玩家
					match stat_name:
						"max_health":
							# 增加最大生命值
							player.max_health += total_value
							# 同时增加当前生命值
							player.current_health += total_value
							# 更新血条
							player.emit_signal("health_changed", player.current_health, player.max_health)
							GameManager.update_player_health(player.current_health, player.max_health)
						"health_regen":
							# 处理生命再生
							pass
						"life_steal":
							# 处理生命吸取
							pass
						"damage":
							# 处理伤害增加
							player.base_attack = int(player.base_attack * (1 + total_value / 100))
						"melee_damage":
							# 处理近战伤害
							pass
						"ranged_damage":
							# 处理远程伤害
							pass
						"elemental_damage":
							# 处理元素伤害
							pass
						"attack_speed":
							# 处理攻击速度
							pass
						"crit_chance":
							# 处理暴击率
							pass
						"range":
							# 处理攻击范围
							pass
						"armor":
							# 处理护甲
							player.defense += total_value
						"evasion":
							# 处理闪避
							pass
						"speed":
							# 处理速度
							pass
						"experience_gain":
							# 处理经验获取
							pass
						"pickup_range":
							# 处理拾取范围
							pass
						"bounce_count":
							# 处理弹射次数
							pass
						"bounce_damage":
							# 处理弹射伤害
							pass
