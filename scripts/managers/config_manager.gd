extends Node

var characters_config: Dictionary = {}
var enemies_config: Dictionary = {}
var weapons_config: Dictionary = {}
var game_settings: Dictionary = {}
var languages_config: Dictionary = {}

func _ready():
	load_all_configs()

func load_all_configs():
	characters_config = load_json("res://configs/characters.json")
	enemies_config = load_json("res://configs/enemies.json")
	weapons_config = load_json("res://configs/weapons.json")
	game_settings = load_json("res://configs/game_settings.json")
	languages_config = load_json("res://configs/languages.json")

func load_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("无法加载配置文件: " + path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("JSON 解析错误: " + json.get_error_message())
		return {}
	
	return json.data

func get_character(id: String) -> Dictionary:
	for character in characters_config.get("characters", []):
		if character.get("id") == id:
			return character
	return {}

func get_all_characters() -> Array:
	return characters_config.get("characters", [])

func get_enemy(id: String) -> Dictionary:
	for enemy in enemies_config.get("enemies", []):
		if enemy.get("id") == id:
			return enemy
	return {}

func get_all_enemies() -> Array:
	return enemies_config.get("enemies", [])

func get_weapon(id: String) -> Dictionary:
	for weapon in weapons_config.get("weapons", []):
		if weapon.get("id") == id:
			return weapon
	return {}

func get_all_weapons() -> Array:
	return weapons_config.get("weapons", [])

func get_passive_item(id: String) -> Dictionary:
	for item in weapons_config.get("passive_items", []):
		if item.get("id") == id:
			return item
	return {}

func get_all_passive_items() -> Array:
	return weapons_config.get("passive_items", [])

func get_game_setting(key: String, default = null):
	return game_settings.get("game_settings", {}).get(key, default)

func get_wave_data() -> Array:
	return game_settings.get("waves", [])

func get_map_size() -> Dictionary:
	return game_settings.get("map_size", {"width": 4000, "height": 4000})

func get_language_text(key: String, default: String = "") -> String:
	var locale = TranslationServer.get_locale()
	# 确保语言代码格式正确
	if locale == "en_US":
		locale = "en"
	
	# 获取对应语言的配置
	var language_data = languages_config.get("languages", {}).get(locale, {})
	
	# 如果没有对应语言的配置，使用默认语言（简体中文）
	if language_data.is_empty():
		language_data = languages_config.get("languages", {}).get("zh_CN", {})
	
	# 解析键路径，支持点号分隔的路径
	var keys = key.split(".")
	var current_data = language_data
	
	for k in keys:
		if not current_data.has(k):
			return default
		current_data = current_data[k]
	
	return current_data if typeof(current_data) == TYPE_STRING else default
