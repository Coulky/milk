extends Node2D

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var enemy_spawner: Node = $EnemySpawner
@onready var game_ui: CanvasLayer = $GameUI
@onready var upgrade_ui: CanvasLayer = $UpgradeUI

var player_scene = preload("res://scenes/entities/player.tscn")
var player: CharacterBody2D = null

func _ready():
	GameManager.connect("level_up", _on_level_up)
	GameManager.connect("game_over", _on_game_over)
	start_game()

func start_game():
	GameManager.start_game()
	
	# 计算视口中心位置
	var viewport_size = get_viewport().size
	var center_position = viewport_size / 2
	
	player = player_scene.instantiate()
	player.global_position = center_position
	add_child(player)
	
	game_ui.visible = true

func _on_level_up(_new_level: int):
	upgrade_ui.show_upgrades()

func _on_game_over():
	game_ui.visible = false
	
	var game_over_label = Label.new()
	game_over_label.text = "游戏结束！\n按 R 重新开始"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.add_theme_font_size_override("font_size", 48)
	game_over_label.anchors_preset = Control.PRESET_CENTER
	game_over_label.offset_left = -200
	game_over_label.offset_top = -50
	game_over_label.offset_right = 200
	game_over_label.offset_bottom = 50
	
	var canvas = CanvasLayer.new()
	canvas.add_child(game_over_label)
	add_child(canvas)

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		if GameManager.is_paused:
			GameManager.resume_game()
		else:
			GameManager.pause_game()
	
	if event.is_action_pressed("ui_accept") and not GameManager.is_game_running:
		get_tree().reload_current_scene()
