extends CanvasLayer

@onready var time_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/TimeLabel
@onready var level_label: Label = $MarginContainer/VBoxContainer/HBoxContainer2/LevelLabel
@onready var exp_bar: ProgressBar = $MarginContainer/VBoxContainer/ExpBar
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
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
	health_bar.max_value = max_health
	health_bar.value = current_health

func _on_game_started():
	var player = GameManager.get_player()
	if player != null and player.has_method("get_health_info"):
		var health_info = player.get_health_info()
		health_bar.max_value = health_info.max_health
		health_bar.value = health_info.current_health
	update_ui()
