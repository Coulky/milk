extends CanvasLayer

@onready var time_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/TimeLabel
@onready var level_label: Label = $MarginContainer/VBoxContainer/HBoxContainer2/LevelLabel
@onready var exp_bar: ProgressBar = $MarginContainer/VBoxContainer/ExpBar
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBarContainer/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthBarContainer/HealthLabel
@onready var kill_label: Label = $MarginContainer/VBoxContainer/HBoxContainer3/KillLabel

func _ready():
	GameManager.connect("experience_gained", _on_experience_gained)
	GameManager.connect("level_up", _on_level_up)
	GameManager.connect("health_changed", _on_health_changed)
	GameManager.connect("game_started", _on_game_started)
	
	update_ui()

func _process(_delta):
	if GameManager.is_game_running:
		time_label.text = GameManager.get_game_time_formatted()

func update_ui():
	var level_text = ConfigManager.get_language_text("ui.level_label", "等级: {0}")
	level_label.text = level_text.format([GameManager.current_level])
	
	var kill_text = ConfigManager.get_language_text("ui.kill_label", "击杀: {0}")
	kill_label.text = kill_text.format([GameManager.kill_count])
	
	var exp_percent = float(GameManager.total_experience) / float(GameManager.experience_to_next_level) * 100
	exp_bar.value = exp_percent

func _on_experience_gained(_amount: int):
	update_ui()

func _on_level_up(new_level: int):
	var level_text = ConfigManager.get_language_text("ui.level_label", "等级: {0}")
	level_label.text = level_text.format([new_level])
	exp_bar.value = 0

func _on_health_changed(current_health: int, max_health: int):
	# 直接使用实际生命值数值
	health_bar.max_value = float(max_health)
	health_bar.value = float(current_health)
	print("Health changed: " + str(current_health) + "/" + str(max_health))
	# 显示当前生命值和最大生命值
	health_label.text = "%d/%d" % [current_health, max_health]
	print("Health bar value: " + str(health_bar.value) + ", max: " + str(health_bar.max_value))

func _on_game_started():
	print("Game started, initializing health bar")
	var player = GameManager.get_player()
	print("Player reference: " + str(player))
	if player != null and player.has_method("get_health_info"):
		print("Player has get_health_info method")
		var health_info = player.get_health_info()
		# 直接使用实际生命值数值
		health_bar.max_value = float(health_info.max_health)
		health_bar.value = float(health_info.current_health)
		print("Health info: " + str(health_info))
		# 显示当前生命值和最大生命值
		health_label.text = "%d/%d" % [health_info.current_health, health_info.max_health]
		print("Health bar initialized: " + str(health_bar.value) + "/" + str(health_bar.max_value))
	else:
		print("Player not ready or missing get_health_info method")
	update_ui()
