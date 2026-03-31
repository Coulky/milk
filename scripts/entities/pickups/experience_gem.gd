extends Area2D

var experience_value: int = 1
var move_speed: float = 300.0
var is_being_collected: bool = false
var target: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	add_to_group("experience_gem")

func collect(player: Node2D):
	if is_being_collected:
		return
	
	is_being_collected = true
	target = player

func _physics_process(delta):
	if is_being_collected and target:
		var direction = (target.global_position - global_position).normalized()
		position += direction * move_speed * delta
		
		if global_position.distance_to(target.global_position) < 10:
			GameManager.add_experience(experience_value)
			queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect(body)
