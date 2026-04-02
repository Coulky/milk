extends Area2D

var damage: int = 10
var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT
var target: Node2D = null
var piercing: int = 1
var homing: bool = false
var lifetime: float = 5.0

var hit_enemies: Array = []

var projectile_symbol: String = "•"
var projectile_color: Color = Color.WHITE
var projectile_texture: String = ""

var sprite: Sprite2D

func _ready():
	add_to_group("projectiles")
	setup_visuals()

func setup_visuals():
	# 创建 Sprite2D 节点
	sprite = Sprite2D.new()
	
	# 使用传入的素材路径
	var texture_path = projectile_texture
	if texture_path == "":
		texture_path = "res://assets/images/projectiles/player_arrow.png"
	
	# 加载素材
	var texture = load(texture_path)
	if texture:
		sprite.texture = texture
		# 等比例缩放，保持宽高比，设置高度为20像素
		var target_height = 20.0
		var scale_factor = target_height / texture.get_height()
		sprite.scale = Vector2(scale_factor, scale_factor)
	
	add_child(sprite)

func setup(dmg: int, spd: float, tgt, pierce: int, is_homing: bool, projectile_texture_param: String = ""):
	damage = dmg
	speed = spd
	piercing = pierce
	homing = is_homing
	projectile_texture = projectile_texture_param
	
	if tgt is Vector2:
		direction = (tgt - global_position).normalized()
	elif tgt is Node2D:
		target = tgt
		direction = (target.global_position - global_position).normalized()
	
	setup_visuals()
	
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(queue_free)

func _physics_process(delta):
	if homing and target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	
	position += direction * speed * delta
	# 素材是直立状态（箭头朝下），所以需要减 PI/2 来让箭头指向飞行方向
	rotation = direction.angle() - PI / 2

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		if body in hit_enemies:
			return
		
		hit_enemies.append(body)
		body.take_damage(damage)
		
		if hit_enemies.size() >= piercing:
			# 使用 call_deferred 来避免在物理查询刷新期间修改场景树
			call_deferred("queue_free")
