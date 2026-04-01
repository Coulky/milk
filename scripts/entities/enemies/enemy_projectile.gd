extends Area2D

var damage: int = 10
var speed: float = 300.0
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 5.0
var start_position: Vector2 = Vector2.ZERO

var projectile_type: String = "normal"
var split_distance: float = 150.0
var split_count: int = 3
var has_split: bool = false

var projectile_symbol: String = "•"
var projectile_color: Color = Color.RED

var sprite: Label

func _ready():
	add_to_group("enemy_projectiles")
	start_position = global_position
	
	# 查找 Label 子节点
	for child in get_children():
		if child is Label:
			sprite = child
			break
	
	setup_visuals()
	
	# 设置生命周期计时器
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(queue_free)

func setup_visuals():
	if is_instance_valid(sprite):
		sprite.text = projectile_symbol
		sprite.add_theme_color_override("font_color", projectile_color)
		sprite.add_theme_font_size_override("font_size", 16)
		sprite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _physics_process(delta):
	position += direction * speed * delta
	rotation = direction.angle()
	
	# 检查是否需要分裂
	if projectile_type == "split" and not has_split:
		var distance_traveled = global_position.distance_to(start_position)
		if distance_traveled >= split_distance:
			has_split = true
			split_projectile()

func split_projectile():
	# 计算分裂后的角度
	var base_angle = direction.angle()
	var angle_step = deg_to_rad(30)
	
	for i in range(split_count):
		var offset_angle = (i - (split_count - 1) / 2) * angle_step
		var new_angle = base_angle + offset_angle
		var new_direction = Vector2(cos(new_angle), sin(new_angle))
		
		create_child_projectile(new_direction)
	
	# 销毁原投射物
	queue_free()

func create_child_projectile(new_direction: Vector2):
	var projectile = Area2D.new()
	projectile.name = "EnemyProjectileSplit"
	projectile.collision_layer = 8
	projectile.collision_mask = 1
	
	# 创建碰撞形状
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 6.0
	collision_shape.shape = circle_shape
	projectile.add_child(collision_shape)
	
	# 创建标签用于显示
	var label = Label.new()
	label.text = "•"
	label.add_theme_color_override("font_color", Color.MAGENTA)
	label.add_theme_font_size_override("font_size", 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.offset_left = -6.0
	label.offset_top = -6.0
	label.offset_right = 6.0
	label.offset_bottom = 6.0
	projectile.add_child(label)
	
	# 添加脚本
	var projectile_script = preload("res://scripts/entities/enemies/enemy_projectile.gd")
	projectile.set_script(projectile_script)
	
	# 设置属性
	projectile.global_position = global_position
	projectile.damage = damage / 2
	projectile.speed = speed * 1.2
	projectile.direction = new_direction
	projectile.projectile_type = "normal"
	projectile.projectile_color = Color.MAGENTA
	projectile.lifetime = 3.0
	
	# 添加到场景
	get_parent().add_child(projectile)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
