extends CharacterBody2D

@export var enemy_id: String = "zombie"

var enemy_config: Dictionary = {}
var max_health: int = 20
var current_health: int = 20
var speed: float = 80.0
var damage: int = 5
var experience_value: int = 1
var attack_type: String = "melee"
var attack_range: float = 50.0
var attack_speed: float = 1.0
var attack_timer: float = 0.0
var projectile_type: String = "normal"
var projectile_symbol: String = "•"
var projectile_color: Color = Color.RED
var split_distance: float = 150.0
var split_count: int = 3

var target: Node2D = null

signal died(enemy)

@onready var sprite: Label = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox

func _ready():
	load_enemy_config()
	setup_enemy()
	add_to_group("enemies")
	GameManager.register_enemy(self)

func load_enemy_config():
	enemy_config = ConfigManager.get_enemy(enemy_id)
	if enemy_config.is_empty():
		push_error("无法加载敌人配置: " + enemy_id)
		return

func setup_enemy():
	# 计算增强系数 - 每3分钟增强一次
	var game_time_minutes = GameManager.game_time / 60.0
	var enhancement_multiplier = 1.0 + (game_time_minutes / 3.0) * 0.2
	
	max_health = int(enemy_config.get("max_health", 20) * enhancement_multiplier)
	current_health = max_health
	speed = enemy_config.get("speed", 80) * (1.0 + (game_time_minutes / 3.0) * 0.1)
	damage = int(enemy_config.get("damage", 5) * enhancement_multiplier)
	experience_value = int(enemy_config.get("experience", 1) * enhancement_multiplier)
	attack_type = enemy_config.get("attack_type", "melee")
	attack_range = enemy_config.get("attack_range", 50.0)
	attack_speed = enemy_config.get("attack_speed", 1.0)
	attack_timer = 0.0
	projectile_type = enemy_config.get("projectile_type", "normal")
	projectile_symbol = enemy_config.get("projectile_symbol", "•")
	var proj_color_str = enemy_config.get("projectile_color", "#ff0000")
	projectile_color = Color(proj_color_str)
	split_distance = enemy_config.get("split_distance", 150.0)
	split_count = enemy_config.get("split_count", 3)
	
	var symbol = enemy_config.get("symbol", "Z")
	var color = Color(enemy_config.get("symbol_color", "#00ff00"))
	
	if sprite:
		sprite.text = symbol
		sprite.add_theme_color_override("font_color", color)
		sprite.add_theme_font_size_override("font_size", 28)
		sprite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sprite.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _physics_process(_delta):
	if not GameManager.is_game_running or GameManager.is_paused:
		return
	
	update_target()
	move_and_attack(_delta)

func update_target():
	if target == null or not is_instance_valid(target):
		target = GameManager.get_player()

func move_and_attack(delta):
	if target == null:
		return
	
	var distance_to_target = global_position.distance_to(target.global_position)
	
	if attack_type == "melee":
		move_towards_target()
	else:
		if distance_to_target > attack_range:
			move_towards_target()
		else:
			velocity = Vector2.ZERO
			move_and_slide()
	
	attack_timer += delta
	if attack_timer >= attack_speed:
		attack_timer = 0.0
		perform_attack()

func move_towards_target():
	if target == null:
		return
	
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func perform_attack():
	if target == null:
		return
	
	if attack_type == "melee":
		# 近战攻击：检查是否在攻击范围内
		var distance_to_target = global_position.distance_to(target.global_position)
		if distance_to_target <= attack_range + 20:
			if target.has_method("take_damage"):
				target.take_damage(damage)
	else:
		shoot_projectile()

func shoot_projectile():
	if target == null:
		return
	
	var direction = (target.global_position - global_position).normalized()
	
	# 直接在代码中创建投射物，不使用预加载场景
	var projectile = Area2D.new()
	projectile.name = "EnemyProjectile"
	projectile.collision_layer = 8
	projectile.collision_mask = 1
	
	# 创建碰撞形状
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 12.0
	collision_shape.shape = circle_shape
	projectile.add_child(collision_shape)
	
	# 创建标签用于显示
	var label = Label.new()
	label.text = projectile_symbol
	label.add_theme_color_override("font_color", projectile_color)
	label.add_theme_font_size_override("font_size", 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.offset_left = -12.0
	label.offset_top = -12.0
	label.offset_right = 12.0
	label.offset_bottom = 12.0
	projectile.add_child(label)
	
	# 添加脚本
	var projectile_script = preload("res://scripts/entities/enemies/enemy_projectile.gd")
	projectile.set_script(projectile_script)
	
	# 设置属性
	projectile.global_position = global_position
	projectile.damage = damage
	projectile.speed = 250.0
	projectile.direction = direction
	projectile.projectile_type = projectile_type
	projectile.split_distance = split_distance
	projectile.split_count = split_count
	projectile.projectile_symbol = projectile_symbol
	projectile.projectile_color = projectile_color
	
	# 添加到场景
	get_parent().add_child(projectile)

func take_damage(amount: int):
	current_health -= amount
	
	if current_health <= 0:
		die()

func die():
	emit_signal("died", self)
	GameManager.add_kill(self)
	GameManager.unregister_enemy(self)
	spawn_experience_gem()
	spawn_pickup()
	queue_free()

func spawn_experience_gem():
	var saved_position = global_position
	var saved_experience = experience_value
	call_deferred("_spawn_experience_gem_deferred", saved_position, saved_experience)

func _spawn_experience_gem_deferred(pos: Vector2, exp_value: int):
	var gem_scene = preload("res://scenes/entities/experience_gem.tscn")
	var gem = gem_scene.instantiate()
	gem.global_position = pos
	gem.experience_value = exp_value
	get_tree().root.add_child(gem)

func spawn_pickup():
	# 从配置中获取消耗品掉落信息
	var consumable_drops = ConfigManager.get_consumable_drops()
	
	# 尝试掉落物品
	for drop in consumable_drops:
		var probability = drop.get("drop_probability", 0)
		if randf() < probability:
			# 使用 call_deferred 延迟创建物品，避免物理查询冲突
			call_deferred("_spawn_pickup_deferred", drop, global_position)
			break  # 只掉落一个物品

func _spawn_pickup_deferred(drop, pos):
	# 生成物品（直接创建，不通过 ConfigManager）
	var pickup = Area2D.new()
	pickup.name = drop.id
	
	# 创建碰撞形状
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 15.0
	collision_shape.shape = circle_shape
	pickup.add_child(collision_shape)
	
	# 创建标签或纹理用于显示
	if drop.path.begins_with("res://"):
		# 创建 Sprite2D 节点来显示图片
		var drop_sprite = Sprite2D.new()
		
		# 加载纹理
		var texture = load(drop.path)
		if texture:
			drop_sprite.texture = texture
			
			# 根据配置的 size 调整缩放
			if drop.has("size"):
				var size = drop.get("size")
				if size is Array and size.size() == 2:
					# 计算缩放比例
					var texture_size = texture.get_size()
					var scale_x = size[0] / texture_size.x
					var scale_y = size[1] / texture_size.y
					drop_sprite.scale = Vector2(scale_x, scale_y)
		
		pickup.add_child(drop_sprite)
	else:
		# 如果是符号，显示为文本
		var label = Label.new()
		label.text = drop.path
		label.add_theme_font_size_override("font_size", 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.offset_left = -15.0
		label.offset_top = -15.0
		label.offset_right = 15.0
		label.offset_bottom = 15.0
		pickup.add_child(label)
	
	# 添加脚本
	var pickup_script = preload("res://scripts/entities/pickups/consumable_pickup.gd")
	pickup.set_script(pickup_script)
	
	# 设置属性
	pickup.global_position = pos
	pickup.set_meta("item_id", drop.id)
	pickup.set_meta("drop_data", drop)  # 存储完整的掉落数据
	
	# 添加到场景
	get_tree().root.add_child(pickup)

func _on_hitbox_body_entered(body):
	if body and is_instance_valid(body):
		if body.is_in_group("player") and attack_type == "melee":
			if body.has_method("take_damage"):
				body.take_damage(damage)
