extends CharacterBody2D

@export var enemy_id: String = "zombie"

var enemy_config: Dictionary = {}
var max_health: int = 20
var current_health: int = 20
var speed: float = 80.0
var damage: int = 5
var experience_value: int = 1

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
	max_health = enemy_config.get("max_health", 20)
	current_health = max_health
	speed = enemy_config.get("speed", 80)
	damage = enemy_config.get("damage", 5)
	experience_value = enemy_config.get("experience", 1)
	
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
	move_towards_target()

func update_target():
	if target == null or not is_instance_valid(target):
		target = GameManager.get_player()

func move_towards_target():
	if target == null:
		return
	
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func take_damage(amount: int):
	current_health -= amount
	
	if current_health <= 0:
		die()

func die():
	emit_signal("died", self)
	GameManager.add_kill(self)
	GameManager.unregister_enemy(self)
	spawn_experience_gem()
	queue_free()

func spawn_experience_gem():
	var gem_scene = preload("res://scenes/entities/experience_gem.tscn")
	var gem = gem_scene.instantiate()
	gem.global_position = global_position
	gem.experience_value = experience_value
	get_parent().add_child(gem)

func _on_hitbox_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
