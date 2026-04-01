extends Area2D

var experience_value: int = 1

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	add_to_group("experience_gem")
	if sprite:
		sprite.hide()

func collect(player: Node2D):
	GameManager.add_experience(experience_value)
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect(body)
