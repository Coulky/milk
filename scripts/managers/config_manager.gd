extends Node

var characters_config = {}
var monsters_config = {}
var items_config = {}
var drops_config = {}
var game_settings = {}
var languages_config = {}

func _ready():
	load_all_configs()

func load_all_configs():
	characters_config = load_json("res://configs/characters.json")
	monsters_config = load_json("res://configs/monsters.json")
	items_config = load_json("res://configs/items.json")
	drops_config = load_json("res://configs/drops.json")
	game_settings = load_json("res://configs/game_settings.json")
	languages_config = load_json("res://configs/languages.json")

func load_json(path):
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

func get_character(id):
	for character in characters_config.get("characters", []):
		if character.get("id") == id:
			return character
	return {}

func get_all_characters():
	return characters_config.get("characters", [])

func get_monster(id):
	for monster in monsters_config.get("monsters", []):
		if monster.get("id") == id:
			return monster
	return {}

func get_all_monsters():
	return monsters_config.get("monsters", [])



func get_game_setting(key, default = null):
	return game_settings.get("game_settings", {}).get(key, default)

func set_game_setting(key, value):
	if not game_settings.has("game_settings"):
		game_settings["game_settings"] = {}
	game_settings["game_settings"][key] = value

func get_wave_data():
	return game_settings.get("waves", [])

func get_map_size():
	return game_settings.get("map_size", {"width": 4000, "height": 4000})

func get_item(id):
	return items_config.get("items", {}).get(id, {})

func get_all_items():
	var all_items = []
	for item_name in items_config.get("items", {}).keys():
		var item = items_config.get("items", {}).get(item_name, {})
		item["id"] = item_name
		all_items.append(item)
	return all_items

func get_common_items():
	var common_items = []
	for item_name in items_config.get("items", {}).keys():
		var item = items_config.get("items", {}).get(item_name, {})
		if item.get("item_type") == "common":
			item["id"] = item_name
			common_items.append(item)
	return common_items

func get_class_items(class_name_param):
	var class_items = []
	for item_name in items_config.get("items", {}).keys():
		var item = items_config.get("items", {}).get(item_name, {})
		if item.get("item_type") == "class" and item.get("class") == class_name_param:
			item["id"] = item_name
			class_items.append(item)
	return class_items

func get_language_text(key, default = ""):
	var locale = TranslationServer.get_locale()
	if locale == "en_US":
		locale = "en"
	var language_data = languages_config.get("languages", {}).get(locale, {})
	if language_data.is_empty():
		language_data = languages_config.get("languages", {}).get("zh_CN", {})
	var keys = key.split(".")
	var current_data = language_data
	for k in keys:
		if not current_data.has(k):
			return default
		current_data = current_data[k]
	return current_data if typeof(current_data) == TYPE_STRING else default

func get_item_name(item_id):
	var item = get_item(item_id)
	var locale = TranslationServer.get_locale()
	if locale == "en_US":
		locale = "en"
	if item.has("name") and typeof(item["name"]) == TYPE_DICTIONARY:
		if item["name"].has(locale):
			var item_name = item["name"][locale]
			if typeof(item_name) == TYPE_STRING and item_name != "":
				return item_name
		if item["name"].has("zh_CN"):
			var item_name = item["name"]["zh_CN"]
			if typeof(item_name) == TYPE_STRING and item_name != "":
				return item_name
	return item_id

func get_item_description(item_id, variables = {}):
	var item = get_item(item_id)
	var locale = TranslationServer.get_locale()
	if locale == "en_US":
		locale = "en"
	var description = ""
	if item.has("description") and typeof(item["description"]) == TYPE_DICTIONARY:
		if item["description"].has(locale):
			var desc = item["description"][locale]
			if typeof(desc) == TYPE_STRING and desc != "":
				description = desc
		elif item["description"].has("zh_CN"):
			var desc = item["description"]["zh_CN"]
			if typeof(desc) == TYPE_STRING and desc != "":
				description = desc
	for key in variables.keys():
		var placeholder = "{" + key + "}"
		if description.find(placeholder) != -1:
			description = description.replace(placeholder, str(variables[key]))
	return description

func get_attribute_name(attribute):
	var locale = TranslationServer.get_locale()
	if locale == "en_US":
		locale = "en"
	
	var en_attribute_names = {
		"max_health": "Max Health",
		"health_regen": "Health Regen",
		"life_steal": "Life Steal",
		"damage": "Damage",
		"melee_damage": "Melee Damage",
		"ranged_damage": "Ranged Damage",
		"elemental_damage": "Elemental Damage",
		"attack_speed": "Attack Speed",
		"crit_chance": "Crit Chance",
		"range": "Range",
		"armor": "Armor",
		"evasion": "Evasion",
		"speed": "Speed",
		"experience_gain": "Experience Gain",
		"pickup_range": "Pickup Range",
		"bounce_count": "Bounce Count",
		"bounce_damage": "Bounce Damage"
	}
	
	var ja_attribute_names = {
		"max_health": "最大HP",
		"health_regen": "HP回復",
		"life_steal": "ライフスティール",
		"damage": "ダメージ",
		"melee_damage": "近接ダメージ",
		"ranged_damage": "遠隔ダメージ",
		"elemental_damage": "元素ダメージ",
		"attack_speed": "攻撃速度",
		"crit_chance": "クリティカル率",
		"range": "範囲",
		"armor": "防御力",
		"evasion": "回避率",
		"speed": "速度",
		"experience_gain": "経験値獲得",
		"pickup_range": "拾得範囲",
		"bounce_count": "跳ね返り回数",
		"bounce_damage": "跳ね返りダメージ"
	}
	
	if locale == "en":
		return en_attribute_names.get(attribute, attribute)
	elif locale == "ja":
		return ja_attribute_names.get(attribute, attribute)
	else:
		return attribute

func get_attribute_unit(attribute):
	var units = {
		"life_steal": "%",
		"damage": "%",
		"attack_speed": "%",
		"crit_chance": "%",
		"evasion": "%",
		"speed": "%",
		"experience_gain": "%"
	}
	return units.get(attribute, "")

func get_item_attribute_text(attribute, value):
	var key = "item_attributes." + attribute
	var text = get_language_text(key, attribute)
	return text.replace("{value}", str(value))

func get_drop(id):
	return drops_config.get("drops", {}).get(id, {})

func get_all_drops():
	var all_drops = []
	for drop_id in drops_config.get("drops", {}).keys():
		var drop = drops_config.get("drops", {}).get(drop_id, {})
		drop["id"] = drop_id
		all_drops.append(drop)
	return all_drops

func get_consumable_drops():
	var consumable_drops = []
	for drop_id in drops_config.get("drops", {}).keys():
		var drop = drops_config.get("drops", {}).get(drop_id, {})
		if drop.get("type") == "consumable":
			drop["id"] = drop_id
			consumable_drops.append(drop)
	return consumable_drops

func get_experience_drops():
	var experience_drops = []
	for drop_id in drops_config.get("drops", {}).keys():
		var drop = drops_config.get("drops", {}).get(drop_id, {})
		if drop.get("type") == "experience":
			drop["id"] = drop_id
			experience_drops.append(drop)
	return experience_drops
