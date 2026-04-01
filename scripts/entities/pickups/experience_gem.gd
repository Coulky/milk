extends Area2D

var experience_value: int = 1

@onready var label: Label = $Label

func _ready():
	add_to_group("experience_gem")
	if label:
		label.text = "★"
		label.add_theme_color_override("font_color", Color.YELLOW)
		label.add_theme_font_size_override("font_size", 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _on_body_entered(body):
	if body and is_instance_valid(body):
		if body.is_in_group("player"):
			GameManager.add_experience(experience_value)
			queue_free()
