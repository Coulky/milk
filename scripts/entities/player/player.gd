extends CharacterBody2D

# 从 GameManager 获取选中的角色
var character_id: String = ""

var character_config: Dictionary = {}
var max_health: int = 100
var current_health: int = 100
var speed: float = 200.0
var base_attack: float = 10.0
var defense: float = 5.0
var pickup_range: float = 50.0

# 攻击属性
var attack_type: String = "melee"
var attack_range: float = 80.0
var attack_speed: float = 1.0
var attack_timer: float = 0.0
var projectile_speed: float = 400.0
var piercing: int = 1
var homing: bool = false
var projectile_texture: String = ""

var passive_items: Dictionary = {}
var item_counts: Dictionary = {}

var is_invincible: bool = false
var invincibility_duration: float = 1.0

var sprite_2d_ref: Sprite2D = null

signal health_changed(current_health, max_health)
signal player_died

@onready var sprite: Label = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var pickup_area: Area2D = $PickupArea
@onready var invincibility_timer: Timer = $InvincibilityTimer

func _ready():
	# 从 GameManager 获取选中的角色
	character_id = GameManager.selected_character
	load_character_config()
	setup_character()
	GameManager.register_player(self)
	# 初始化时更新血条
	GameManager.update_player_health(current_health, max_health)

func load_character_config():
	character_config = ConfigManager.get_character(character_id)
	if character_config.is_empty():
		push_error("无法加载角色配置: " + character_id)
		return

func setup_character():
	max_health = character_config.get("max_health", 100)
	current_health = max_health
	speed = character_config.get("speed", 200)
	base_attack = character_config.get("attack", 10)
	defense = character_config.get("defense", 5)
	
	# 加载攻击属性
	attack_type = character_config.get("attack_type", "melee")
	attack_range = character_config.get("attack_range", 80.0)
	attack_speed = character_config.get("attack_speed", 1.0)
	projectile_speed = character_config.get("projectile_speed", 400.0)
	piercing = character_config.get("piercing", 1)
	homing = character_config.get("homing", false)
	projectile_texture = character_config.get("projectile_texture", "")
	
	var model_path = character_config.get("path", "")
	var size = character_config.get("size", [0, 0])
	var model_width = size[0]
	var model_height = size[1]
	var symbol = character_config.get("symbol", "@")
	var color = Color(character_config.get("symbol_color", "#00ff00"))
	
	var sprite_2d: Sprite2D = null
	
	if model_path and model_path != "":
		# 如果有模型路径，创建 Sprite2D 节点
		if has_node("Sprite2D"):
			sprite_2d = $Sprite2D
		else:
			sprite_2d = Sprite2D.new()
			sprite_2d.name = "Sprite2D"
			add_child(sprite_2d)
		
		# 保存 Sprite2D 的引用
		sprite_2d_ref = sprite_2d
		
		# 加载图片
		var texture = load(model_path)
		if texture:
			sprite_2d.texture = texture
			# 应用尺寸设置
			if model_width > 0 and model_height > 0:
				# 计算缩放比例
				var original_size = texture.get_size()
				var scale_x = model_width / original_size.x
				var scale_y = model_height / original_size.y
				sprite_2d.scale = Vector2(scale_x, scale_y)
			# 隐藏原有的 Label 节点
			if sprite:
				sprite.hide()
		else:
			# 如果图片加载失败，显示符号
			if sprite:
				sprite.text = symbol
				sprite.add_theme_color_override("font_color", color)
				sprite.add_theme_font_size_override("font_size", 32)
				sprite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				sprite.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				sprite.show()
			# 隐藏 Sprite2D 节点
			if sprite_2d:
				sprite_2d.hide()
	else:
		# 如果没有模型路径，显示符号
		if sprite:
			sprite.text = symbol
			sprite.add_theme_color_override("font_color", color)
			sprite.add_theme_font_size_override("font_size", 32)
			sprite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sprite.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sprite.show()
		# 隐藏可能存在的 Sprite2D 节点
		if has_node("Sprite2D"):
			$Sprite2D.hide()



func add_passive_item(item_id: String):
	var item_config = ConfigManager.get_item(item_id)
	if item_config.is_empty():
		return
	
	if passive_items.has(item_id):
		if passive_items[item_id] < item_config.get("max_level", 5):
			passive_items[item_id] += 1
			apply_passive_item_effects(item_config, passive_items[item_id])
	else:
		passive_items[item_id] = 1
		apply_passive_item_effects(item_config, 1)

func apply_passive_item_effects(item_config: Dictionary, level: int):
	var effects = item_config.get("effects", {})
	
	for effect_key in effects:
		var value = effects[effect_key] * level
		match effect_key:
			"defense":
				defense += value
			"max_health":
				max_health += value
				current_health += value
			"pickup_range":
				pickup_range += value
				update_pickup_area()
			"cooldown_reduction":
				# 减少攻击间隔
				attack_speed *= (1.0 - value)
			"area_bonus":
				# 增加攻击范围
				attack_range *= (1.0 + value)

func update_pickup_area():
	if pickup_area:
		var collision_shape = pickup_area.get_node_or_null("CollisionShape2D")
		if collision_shape and collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = pickup_range

func _physics_process(delta):
	if not GameManager.is_game_running or GameManager.is_paused:
		return
	
	var input_direction = get_input_direction()
	velocity = input_direction * speed
	move_and_slide()
	
	# 根据移动方向反转角色
	if input_direction.x > 0:
		if sprite:
			sprite.scale.x = -1.0
		if sprite_2d_ref:
			sprite_2d_ref.scale.x = -abs(sprite_2d_ref.scale.x)
	elif input_direction.x < 0:
		if sprite:
			sprite.scale.x = 1.0
		if sprite_2d_ref:
			sprite_2d_ref.scale.x = abs(sprite_2d_ref.scale.x)
	
	# 处理攻击
	attack_timer += delta
	if attack_timer >= attack_speed:
		attack_timer = 0.0
		perform_attack()
	
	# 限制玩家在地图边界内
	var map_size = ConfigManager.get_map_size()
	var map_width = map_size.get("width", 2000)
	var map_height = map_size.get("height", 2000)
	
	# 确保玩家不会走出地图
	global_position.x = clamp(global_position.x, 16, map_width - 16)
	global_position.y = clamp(global_position.y, 16, map_height - 16)

func get_input_direction() -> Vector2:
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	return direction.normalized()

func perform_attack():
	match attack_type:
		"melee":
			melee_attack()
		"projectile":
			projectile_attack()

func melee_attack():
	var enemies = GameManager.get_enemies_in_range(global_position, attack_range)
	var hit_count = 0
	for enemy in enemies:
		if hit_count >= piercing:
			break
		enemy.take_damage(int(base_attack))
		hit_count += 1

func projectile_attack():
	var target = GameManager.get_nearest_enemy(global_position, attack_range)
	if target == null:
		return
	
	var projectile = create_projectile()
	projectile.global_position = global_position
	projectile.setup(
		int(base_attack),
		projectile_speed,
		target.global_position if not homing else target,
		piercing,
		homing,
		projectile_texture
	)
	get_tree().current_scene.add_child(projectile)

func create_projectile() -> Node2D:
	var projectile_scene = preload("res://scenes/entities/player_projectile.tscn")
	return projectile_scene.instantiate()

func take_damage(amount: int):
	if is_invincible:
		return
	
	var actual_damage = max(1, int(amount - defense))
	current_health -= actual_damage
	emit_signal("health_changed", current_health, max_health)
	GameManager.update_player_health(current_health, max_health)
	
	if current_health <= 0:
		die()
	else:
		start_invincibility()

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	emit_signal("health_changed", current_health, max_health)
	GameManager.update_player_health(current_health, max_health)

func heal_percent(percent: float):
	# 计算恢复的生命值
	var heal_amount = int(round(max_health * (percent / 100.0)))
	# 应用恢复
	current_health = min(max_health, current_health + heal_amount)
	emit_signal("health_changed", current_health, max_health)
	GameManager.update_player_health(current_health, max_health)

func apply_buff(stat: String, value: float, _duration: float):
	# 暂时直接应用效果，不处理持续时间
	match stat:
		"speed":
			speed *= (1.0 + value)
		"defense":
			defense *= (1.0 + value)
		"attack":
			base_attack *= (1.0 + value)
		"attack_speed":
			# 暂时不处理攻击速度
			pass
		"crit_chance":
			# 暂时不处理暴击率
			pass
		"mana_regen":
			# 暂时不处理魔法恢复
			pass
		"skill_damage":
			# 暂时不处理技能伤害
			pass
		"cooldown_reduction":
			# 暂时不处理冷却减少
			pass

func start_invincibility():
	is_invincible = true
	if sprite:
		sprite.modulate.a = 0.5
	if invincibility_timer:
		invincibility_timer.start(invincibility_duration)

func _on_invincibility_timer_timeout():
	is_invincible = false
	if sprite:
		sprite.modulate.a = 1.0

func die():
	emit_signal("player_died")
	GameManager.end_game()

func get_attack_damage() -> int:
	return int(base_attack)

func get_health_info() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health
	}

func _on_pickup_area_body_entered(body):
	if body.is_in_group("experience_gem"):
		body.collect(self)

func _on_hitbox_body_entered(body):
	if body and is_instance_valid(body):
		# 检查是否是敌人投射物
		if body.has_method("is_in_group") and body.is_in_group("enemy_projectiles"):
			if "damage" in body:
				take_damage(body.damage)
		# 检查是否是敌人（近战攻击）
		elif body.has_method("is_in_group") and body.is_in_group("enemies"):
			if "damage" in body:
				take_damage(body.damage)
