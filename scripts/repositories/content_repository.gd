class_name ContentRepository
extends RefCounted

const ENEMIES_PATH := "res://data/enemies.json"
const ITEMS_PATH := "res://data/items.json"
const ARCHETYPES_PATH := "res://data/archetypes.json"
const CAMPAIGN_PATH := "res://data/campaign.json"
const TOURNAMENTS_PATH := "res://data/tournaments.json"

static func load_enemies() -> Array[Dictionary]:
	return _load_array(ENEMIES_PATH)

static func load_items() -> Array[Dictionary]:
	return _load_array(ITEMS_PATH)

static func load_archetypes() -> Array[Dictionary]:
	return _load_array(ARCHETYPES_PATH)

static func load_campaign() -> Array[Dictionary]:
	return _load_array(CAMPAIGN_PATH)

static func load_tournaments() -> Array[Dictionary]:
	return _load_array(TOURNAMENTS_PATH)

static func find_item(items: Array[Dictionary], item_id: String) -> Dictionary:
	for entry: Dictionary in items:
		if str(entry.get("id", "")) == item_id:
			return entry
	return {}

static func find_enemy(enemies: Array[Dictionary], enemy_id: String) -> Dictionary:
	for entry: Dictionary in enemies:
		if str(entry.get("id", "")) == enemy_id:
			return entry
	return {}

static func _load_array(path: String) -> Array[Dictionary]:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Conteúdo não encontrado: %s" % path)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		push_error("Conteúdo inválido: %s" % path)
		return []
	var result: Array[Dictionary] = []
	for entry: Variant in parsed:
		if entry is Dictionary:
			result.append(entry)
	return result
