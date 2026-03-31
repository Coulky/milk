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

@onready var sprite: Label = $Label

func _ready():
	add_to_group("projectiles")
	setup_visuals()

func setup_visuals():
	sprite.text = projectile_symbol
	sprite.add_theme_color_override("font_color", projectile_color)
	sprite.add_theme_font_size_override("font_size", 16)
	sprite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sprite.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func setup(dmg: int, spd: float, tgt, pierce: int, is_homing: bool):
	damage = dmg
	speed = spd
	piercing = pierce
	homing = is_homing
	
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
	rotation = direction.angle()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		if body in hit_enemies:
			return
		
		hit_enemies.append(body)
		body.take_damage(damage)
		
		if hit_enemies.size() >= piercing:
			queue_free()
