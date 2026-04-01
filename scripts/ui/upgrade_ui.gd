extends CanvasLayer

signal upgrade_selected(upgrade_data)

var available_upgrades: Array = []
var selected_upgrade: Dictionary = {}

@onready var upgrade_container: VBoxContainer = $PanelContainer/VBoxContainer

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_upgrades():
	available_upgrades = generate_upgrades()
	display_upgrades()
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
				"symbol": "I",
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
		if item.has("effect"):
			# 处理物品效果
			var effect = item.get("effect")
			match effect.get("type"):
				"heal":
					player.heal(effect.get("value", 0))
				"mana":
					# 暂时不处理魔法值，因为玩家脚本中没有相关属性
					pass
				"heal_mana":
					player.heal(effect.get("health_value", 0))
					# 暂时不处理魔法值，因为玩家脚本中没有相关属性
					pass
