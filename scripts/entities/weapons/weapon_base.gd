extends Node2D
class_name WeaponBase

var weapon_config: Dictionary = {}
var owner_player: Node2D = null

var weapon_id: String = ""
var weapon_name: String = ""
var weapon_type: String = "melee"
var base_damage: int = 10
var current_damage: int = 10
var attack_speed: float = 1.0
var attack_range: float = 80.0
var projectile_count: int = 1
var projectile_speed: float = 400.0
var piercing: int = 1
var homing: bool = false

var attack_timer: float = 0.0
var cooldown: float = 1.0
var cooldown_reduction: float = 0.0
var area_bonus: float = 0.0

var weapon_level: int = 1

var weapon_symbol: String = ""
var weapon_color: Color = Color.WHITE

signal attack_performed

func setup(config: Dictionary, player: Node2D):
	weapon_config = config
	owner_player = player
	
	weapon_id = config.get("id", "")
	weapon_name = config.get("name", "")
	weapon_type = config.get("type", "melee")
	base_damage = config.get("damage", 10)
	current_damage = base_damage
	attack_speed = config.get("attack_speed", 1.0)
	attack_range = config.get("range", 80.0)
	projectile_count = config.get("projectile_count", 1)
	projectile_speed = config.get("projectile_speed", 400.0)
	piercing = config.get("piercing", 1)
	homing = config.get("homing", false)
	
	cooldown = attack_speed
	
	setup_weapon_visuals()

func setup_weapon_visuals():
	weapon_symbol = weapon_config.get("symbol", "?")
	weapon_color = Color(weapon_config.get("symbol_color", "#ffffff"))
	
	var sprite: Label
	if has_node("WeaponSprite"):
		sprite = $WeaponSprite
	else:
		sprite = Label.new()
		sprite.name = "WeaponSprite"
		sprite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sprite.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sprite.z_index = 1
		add_child(sprite)
	
	sprite.text = weapon_symbol
	sprite.add_theme_color_override("font_color", weapon_color)
	sprite.add_theme_font_size_override("font_size", 24)

func _process(delta):
	if not GameManager.is_game_running or GameManager.is_paused:
		return
	
	attack_timer += delta
	
	var actual_cooldown = cooldown * (1.0 - cooldown_reduction)
	if attack_timer >= actual_cooldown:
		attack_timer = 0.0
		perform_attack()

func perform_attack():
	match weapon_type:
		"melee":
			melee_attack()
		"projectile":
			projectile_attack()
		"area":
			area_attack()
		"instant":
			instant_attack()
	
	emit_signal("attack_performed")

func melee_attack():
	var actual_range = attack_range * (1.0 + area_bonus)
	var enemies = GameManager.get_enemies_in_range(owner_player.global_position, actual_range)
	
	var hit_count = 0
	for enemy in enemies:
		if hit_count >= piercing:
			break
		enemy.take_damage(current_damage + owner_player.get_attack_damage())
		hit_count += 1

func projectile_attack():
	for i in range(projectile_count):
		var target = GameManager.get_nearest_enemy(owner_player.global_position, attack_range * (1.0 + area_bonus))
		if target == null:
			continue
		
		var projectile = create_projectile()
		projectile.global_position = owner_player.global_position
		projectile.projectile_symbol = weapon_symbol
		projectile.projectile_color = weapon_color
		projectile.setup(
			current_damage + owner_player.get_attack_damage(),
			projectile_speed,
			target.global_position if not homing else target,
			piercing,
			homing
		)
		get_tree().current_scene.add_child(projectile)

func area_attack():
	var actual_range = attack_range * (1.0 + area_bonus)
	var enemies = GameManager.get_enemies_in_range(owner_player.global_position, actual_range)
	
	for enemy in enemies:
		enemy.take_damage(current_damage + owner_player.get_attack_damage())

func instant_attack():
	var enemies = GameManager.get_enemies()
	var target_enemies = []
	
	for enemy in enemies:
		if enemy.global_position.distance_to(owner_player.global_position) <= attack_range * (1.0 + area_bonus):
			target_enemies.append(enemy)
	
	target_enemies.shuffle()
	
	for i in range(min(projectile_count, target_enemies.size())):
		var enemy = target_enemies[i]
		enemy.take_damage(current_damage + owner_player.get_attack_damage())
		create_lightning_effect(enemy.global_position)

func create_projectile() -> Node2D:
	var projectile_scene = preload("res://scenes/entities/player_projectile.tscn")
	return projectile_scene.instantiate()

func create_lightning_effect(_pos: Vector2):
	pass

func apply_cooldown_reduction(value: float):
	cooldown_reduction = min(0.75, cooldown_reduction + value)

func apply_area_bonus(value: float):
	area_bonus += value

func level_up():
	weapon_level += 1
	current_damage = int(base_damage * (1.0 + weapon_level * 0.2))
	if weapon_level % 2 == 0:
		projectile_count += 1
