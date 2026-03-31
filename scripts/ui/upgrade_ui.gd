extends CanvasLayer

signal upgrade_selected(upgrade_data)

var available_upgrades: Array = []
var selected_upgrade: Dictionary = {}

@onready var upgrade_container: VBoxContainer = $PanelContainer/VBoxContainer

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_upgrades():
	available_upgrades = generate_upgrades()
	display_upgrades()
	visible = true
	get_tree().paused = true

func generate_upgrades() -> Array:
	var upgrades = []
	
	var all_weapons = ConfigManager.get_all_weapons()
	var all_passive_items = ConfigManager.get_all_passive_items()
	
	for weapon in all_weapons:
		upgrades.append({
			"type": "weapon",
			"id": weapon.get("id"),
			"name": weapon.get("name"),
			"description": weapon.get("description"),
			"symbol": weapon.get("symbol"),
			"color": weapon.get("symbol_color")
		})
	
	for item in all_passive_items:
		upgrades.append({
			"type": "passive",
			"id": item.get("id"),
			"name": item.get("name"),
			"description": item.get("description"),
			"symbol": item.get("symbol"),
			"color": item.get("symbol_color"),
			"effects": item.get("effects", {})
		})
	
	upgrades.shuffle()
	
	var choice_count = ConfigManager.game_settings.get("level_up_choices", 3)
	return upgrades.slice(0, min(choice_count, upgrades.size()))

func display_upgrades():
	for child in upgrade_container.get_children():
		child.queue_free()
	
	for upgrade in available_upgrades:
		var button = Button.new()
		button.text = "%s - %s" % [upgrade.get("symbol", "?"), upgrade.get("name", "Unknown")]
		button.tooltip_text = upgrade.get("description", "")
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(upgrade.get("color", "#ffffff"))
		style.bg_color.a = 0.3
		button.add_theme_stylebox_override("normal", style)
		
		button.pressed.connect(_on_upgrade_selected.bind(upgrade))
		upgrade_container.add_child(button)

func _on_upgrade_selected(upgrade: Dictionary):
	selected_upgrade = upgrade
	visible = false
	get_tree().paused = false
	emit_signal("upgrade_selected", upgrade)
	apply_upgrade(upgrade)

func apply_upgrade(upgrade: Dictionary):
	var player = GameManager.get_player()
	if player == null:
		return
	
	match upgrade.get("type"):
		"weapon":
			player.add_weapon(upgrade.get("id"))
		"passive":
			player.add_passive_item(upgrade.get("id"))
