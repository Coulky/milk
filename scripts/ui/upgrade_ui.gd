extends CanvasLayer

signal upgrade_selected(upgrade_data)

var available_upgrades: Array = []
var selected_upgrade: Dictionary = {}

@onready var upgrade_container: VBoxContainer = $PanelContainer/VBoxContainer

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
				"symbol": item.get("icon", "I"),
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
		var button = Button.new()
		button.text = "%s - %s" % [upgrade.get("symbol", "?"), upgrade.get("name", "Unknown")]
		
		# 构建 tooltip 文本
		var tooltip = upgrade.get("description", "")
		
		# 显示物品属性（只显示非零属性）
		if upgrade.get("type") == "item" and upgrade.has("stats"):
			var stats = upgrade.get("stats")
			var non_zero_stats = []
			
			for stat_name in stats.keys():
				var value = stats[stat_name]
				if value != 0:
					non_zero_stats.append(ConfigManager.get_item_attribute_text(stat_name, value))
			
			if non_zero_stats.size() > 0:
				tooltip += "\n\n属性："
				for stat_text in non_zero_stats:
					tooltip += "\n- " + stat_text
		
		button.tooltip_text = tooltip
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(upgrade.get("color", "#ffffff"))
		style.bg_color.a = 0.3
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
				if value != 0:
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
