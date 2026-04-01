extends Area2D

var item_id: String = ""

func _ready():
	item_id = get_meta("item_id", "")
	add_to_group("consumables")
	# 连接碰撞检测信号
	if not is_connected("body_entered", _on_body_entered):
		body_entered.connect(_on_body_entered)
	# 添加自动消失计时器
	var timer = Timer.new()
	timer.wait_time = 20.0
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	
	# 确保碰撞设置正确
	collision_layer = 0
	collision_mask = 1

func _on_body_entered(body):
	if body and is_instance_valid(body):
		if body.is_in_group("player"):
			# 应用物品效果
			apply_item_effect(body)
			# 销毁物品
			queue_free()

func apply_item_effect(player):
	# 从存储的 drop_data 中获取效果信息
	var drop_data = get_meta("drop_data", {})
	if drop_data and drop_data.has("effect"):
		var effect = drop_data.get("effect")
		var effect_type = effect.get("type")
		
		match effect_type:
			"heal":
				# 恢复固定生命值
				var value = effect.get("value", 0)
				if player.has_method("heal"):
					player.heal(value)
			"heal_percent":
				# 恢复百分比生命值
				var percent = effect.get("health_percent", 0)
				if player.has_method("heal_percent"):
					player.heal_percent(percent)
			"buff":
				# 应用 buff
				var buff_stat = effect.get("stat", "")
				var buff_value = effect.get("value", 0)
				var duration = effect.get("duration", 10)
				if player.has_method("apply_buff"):
					player.apply_buff(buff_stat, buff_value, duration)
