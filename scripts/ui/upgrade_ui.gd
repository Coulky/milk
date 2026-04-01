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
		# 创建按钮作为容器
		var button = Button.new()
		button.custom_minimum_size = Vector2(150, 200)
		
		# 创建垂直布局容器
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		button.add_child(vbox)
		
		# 第一行：图标和名字
		var name_hbox = HBoxContainer.new()
		name_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(name_hbox)
		
		# 处理图标
		var icon_path = upgrade.get("path", "?")
		if icon_path.begins_with("res://"):
			# 如果是图片路径，使用 AssetManager 创建 TextureRect
			var asset_manager = preload("res://scripts/core/asset_manager.gd").new()
			var icon_texture = asset_manager.create_texture_rect(upgrade)
			if icon_texture.texture:
				# 创建一个容器节点来限制大小
				var container = HBoxContainer.new()
				var size = upgrade.get("size", [50, 50])
				container.custom_minimum_size = Vector2(size[0], size[1])
				container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				
				# 将 TextureRect 添加到容器中
				icon_texture.size_flags_horizontal = Control.SIZE_FILL
				icon_texture.size_flags_vertical = Control.SIZE_FILL
				container.add_child(icon_texture)
				
				# 将容器添加到 name_hbox
				name_hbox.add_child(container)
			else:
				# 如果加载失败，显示默认符号
				var icon_label = Label.new()
				icon_label.text = "?"
				icon_label.add_theme_font_size_override("font_size", 32)
				name_hbox.add_child(icon_label)
				continue
		else:
			# 如果是符号，显示为文本
			var icon_label = Label.new()
			icon_label.text = icon_path
			icon_label.add_theme_font_size_override("font_size", 32)
			name_hbox.add_child(icon_label)
		
		var name_label = Label.new()
		name_label.text = upgrade.get("name", "Unknown")
		name_label.add_theme_font_size_override("font_size", 18)
		name_hbox.add_child(name_label)
		
		# 第二行：描述
		var desc_label = Label.new()
		desc_label.text = upgrade.get("description", "")
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(desc_label)
		
		# 显示物品属性（只显示非零属性）
		if upgrade.get("type") == "item" and upgrade.has("stats"):
			var stats = upgrade.get("stats")
			var stats_vbox = VBoxContainer.new()
			vbox.add_child(stats_vbox)
			
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
						stat_label.add_theme_color_override("font_color", Color(0, 1, 0))  # 绿色
					else:
						stat_label.text = "%d%s %s" % [value, unit, attr_name]
						stat_label.add_theme_color_override("font_color", Color(1, 0, 0))  # 红色
					
					stats_vbox.add_child(stat_label)
		
		# 设置按钮样式
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		button.add_theme_stylebox_override("normal", style)
		
		button.pressed.connect(_on_upgrade_selected.bind(upgrade))
		upgrade_container.add_child(button)

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
							# 处理移动速度
							player.speed = player.speed * (1 + total_value / 100)
						"experience_gain":
							# 处理经验获取
							pass
						"pickup_range":
							# 处理拾取范围
							player.pickup_range += total_value
							if player.has_method("update_pickup_area"):
								player.update_pickup_area()
						"bounce_count":
							# 处理弹射次数
							pass
						"bounce_damage":
							# 处理弹射伤害
							pass
