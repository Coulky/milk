extends CharacterBody2D

@export var character_id: String = "warrior"

var character_config: Dictionary = {}
var max_health: int = 100
var current_health: int = 100
var speed: float = 200.0
var base_attack: int = 10
var defense: int = 5
var pickup_range: float = 50.0

var weapons: Array = []
var passive_items: Dictionary = {}

var is_invincible: bool = false
var invincibility_duration: float = 1.0

signal health_changed(current_health, max_health)
signal player_died

@onready var sprite: Label = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var pickup_area: Area2D = $PickupArea
@onready var invincibility_timer: Timer = $InvincibilityTimer

func _ready():
	load_character_config()
	setup_character()
	add_starting_weapons()
	GameManager.register_player(self)

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
	
	var symbol = character_config.get("symbol", "@")
	var color = Color(character_config.get("symbol_color", "#00ff00"))
	
	if sprite:
		sprite.text = symbol
		sprite.add_theme_color_override("font_color", color)
		sprite.add_theme_font_size_override("font_size", 32)
		sprite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sprite.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func add_starting_weapons():
	var starting_weapons = character_config.get("starting_weapons", [])
	for weapon_id in starting_weapons:
		add_weapon(weapon_id)

func add_weapon(weapon_id: String):
	var weapon_config = ConfigManager.get_weapon(weapon_id)
	if weapon_config.is_empty():
		push_error("无法加载武器配置: " + weapon_id)
		return
	
	var weapon_scene = preload("res://scripts/entities/weapons/weapon_base.gd")
	var weapon = weapon_scene.new()
	weapon.setup(weapon_config, self)
	weapons.append(weapon)
	add_child(weapon)

func add_passive_item(item_id: String):
	var item_config = ConfigManager.get_passive_item(item_id)
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
				for weapon in weapons:
					weapon.apply_cooldown_reduction(value)
			"area_bonus":
				for weapon in weapons:
					weapon.apply_area_bonus(value)

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

func get_input_direction() -> Vector2:
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	return direction.normalized()

func take_damage(amount: int):
	if is_invincible:
		return
	
	var actual_damage = max(1, amount - defense)
	current_health -= actual_damage
	emit_signal("health_changed", current_health, max_health)
	GameManager.emit_signal("health_changed", current_health, max_health)
	
	if current_health <= 0:
		die()
	else:
		start_invincibility()

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	emit_signal("health_changed", current_health, max_health)
	GameManager.emit_signal("health_changed", current_health, max_health)

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
	return base_attack

func _on_pickup_area_body_entered(body):
	if body.is_in_group("experience_gem"):
		body.collect(self)
