extends Node

@export var spawn_radius: float = 800.0
@export var min_spawn_distance: float = 300.0

var spawn_timer: float = 0.0
var current_spawn_rate: float = 2.0
var current_wave_index: int = 0

var enemy_scene = preload("res://scenes/entities/enemy.tscn")

func _ready():
	current_spawn_rate = ConfigManager.get_game_setting("base_spawn_rate", 2.0)

func _process(delta):
	if not GameManager.is_game_running or GameManager.is_paused:
		return
	
	update_wave()
	spawn_enemies(delta)

func update_wave():
	var waves = ConfigManager.get_wave_data()
	
	for i in range(waves.size() - 1, current_wave_index, -1):
		if GameManager.game_time >= waves[i].get("time", 0):
			current_wave_index = i
			current_spawn_rate = ConfigManager.get_game_setting("base_spawn_rate", 2.0)
			var multiplier = waves[i].get("spawn_multiplier", 1.0)
			current_spawn_rate /= multiplier
			break

func spawn_enemies(delta):
	spawn_timer += delta
	
	if spawn_timer >= current_spawn_rate:
		spawn_timer = 0.0
		spawn_enemy()

func spawn_enemy():
	var player = GameManager.get_player()
	if player == null:
		return
	
	var max_enemies = ConfigManager.get_game_setting("max_enemies_on_screen", 500)
	if GameManager.get_enemies().size() >= max_enemies:
		return
	
	var enemy_type = get_random_enemy_type()
	var spawn_position = get_spawn_position(player.global_position)
	
	var enemy = enemy_scene.instantiate()
	enemy.enemy_id = enemy_type
	enemy.global_position = spawn_position
	get_parent().add_child(enemy)

func get_random_enemy_type() -> String:
	var waves = ConfigManager.get_wave_data()
	var current_wave: Dictionary = {}
	
	for wave in waves:
		if GameManager.game_time >= wave.get("time", 0):
			current_wave = wave
	
	var enemy_types = current_wave.get("enemy_types", ["zombie"])
	
	var enemies_config = ConfigManager.get_all_enemies()
	var weighted_enemies = []
	
	for enemy_type in enemy_types:
		for enemy_config in enemies_config:
			if enemy_config.get("id") == enemy_type:
				var weight = enemy_config.get("spawn_weight", 1)
				for i in range(weight):
					weighted_enemies.append(enemy_type)
	
	if weighted_enemies.is_empty():
		return "zombie"
	
	return weighted_enemies[randi() % weighted_enemies.size()]

func get_spawn_position(player_pos: Vector2) -> Vector2:
	var angle = randf() * TAU
	var distance = randf_range(min_spawn_distance, spawn_radius)
	
	var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance
	
	var map_size = ConfigManager.get_map_size()
	spawn_pos.x = clamp(spawn_pos.x, 0, map_size.get("width", 4000))
	spawn_pos.y = clamp(spawn_pos.y, 0, map_size.get("height", 4000))
	
	return spawn_pos

func reset():
	spawn_timer = 0.0
	current_spawn_rate = ConfigManager.get_game_setting("base_spawn_rate", 2.0)
	current_wave_index = 0
