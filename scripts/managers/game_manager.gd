extends Node

signal game_started
signal game_paused
signal game_resumed
signal game_over
signal enemy_killed(enemy)
signal experience_gained(amount)
signal level_up(new_level)
signal health_changed(current_health, max_health)

var is_game_running: bool = false
var is_paused: bool = false
var game_time: float = 0.0
var kill_count: int = 0
var total_experience: int = 0
var current_level: int = 1
var experience_to_next_level: int = 10

var player: Node2D = null
var enemies: Array = []
var experience_gems: Array = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	if is_game_running and not is_paused:
		game_time += delta

func start_game():
	is_game_running = true
	is_paused = false
	game_time = 0.0
	kill_count = 0
	total_experience = 0
	current_level = 1
	experience_to_next_level = ConfigManager.get_game_setting("level_up_base_exp", 10)
	emit_signal("game_started")

func pause_game():
	if is_game_running:
		is_paused = true
		get_tree().paused = true
		emit_signal("game_paused")

func resume_game():
	if is_game_running and is_paused:
		is_paused = false
		get_tree().paused = false
		emit_signal("game_resumed")

func end_game():
	is_game_running = false
	emit_signal("game_over")

func register_player(p: Node2D):
	player = p

func register_enemy(enemy: Node2D):
	enemies.append(enemy)

func unregister_enemy(enemy: Node2D):
	enemies.erase(enemy)

func get_enemies() -> Array:
	return enemies

func add_kill(enemy: Node2D):
	kill_count += 1
	emit_signal("enemy_killed", enemy)

func add_experience(amount: int):
	total_experience += amount
	emit_signal("experience_gained", amount)
	
	while total_experience >= experience_to_next_level:
		total_experience -= experience_to_next_level
		current_level += 1
		var multiplier = ConfigManager.get_game_setting("level_up_exp_multiplier", 1.5)
		experience_to_next_level = int(experience_to_next_level * multiplier)
		emit_signal("level_up", current_level)

func get_game_time_formatted() -> String:
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	return "%02d:%02d" % [minutes, seconds]

func get_player() -> Node2D:
	return player

func get_nearest_enemy(pos: Vector2, max_range: float = -1) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = INF
	
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		var dist = pos.distance_to(enemy.global_position)
		if dist < nearest_dist:
			if max_range < 0 or dist <= max_range:
				nearest = enemy
				nearest_dist = dist
	
	return nearest

func get_enemies_in_range(pos: Vector2, range_val: float) -> Array:
	var result = []
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if pos.distance_to(enemy.global_position) <= range_val:
			result.append(enemy)
	return result
