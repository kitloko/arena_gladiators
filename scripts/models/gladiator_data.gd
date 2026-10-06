class_name GladiatorData
extends RefCounted

const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")

## Fonte única de dados de um lutador.
## - base_* são as estatísticas permanentes (criação + escolhas de nível).
## - attack/defense/luck/max_health são derivados (base + soma do equipamento).
## Equipamento é genérico por slot (arma, armadura, capacete, luvas, botas, cinto).

const SLOT_ORDER := ["weapon", "armor", "helmet", "gloves", "boots", "belt"]

var id: String
var display_name: String
var archetype_id: String = ""  # mantido por compatibilidade (sem uso na UI)
var level: int = 1
var experience: int = 0
var gold: int = 0
var pending_level_ups: int = 0

var base_max_health: int = 1
var base_attack: int = 1
var base_defense: int = 0
var base_luck: int = 0

## Derivados (recalculados por recompute_derived()).
var max_health: int = 1
var attack: int = 1
var defense: int = 0
var luck: int = 0
var health: int = 1

## equipado: slot -> id do item; _bonus: slot -> {atk, def, luck, hp}.
var equipped: Dictionary = {}
var owned_item_ids: Array = []
var _bonus: Dictionary = {}
## Catálogo id -> dicionário completo do item (itens processuais guardam
## nome/raridade/nível aqui, já que não estão em data/items.json).
var _catalog: Dictionary = {}

## Metadados de inimigos gerados proceduralmente (não usados pelo jogador).
var enemy_kind: String = "melee"
var enemy_reach: int = 1
var enemy_tier: int = 1
var reward_multiplier: float = 1.0
var weapon_label: String = ""

func _init(values: Dictionary = {}) -> void:
	id = str(values.get("id", "unnamed"))
	display_name = str(values.get("display_name", "Gladiador"))
	archetype_id = str(values.get("archetype_id", ""))
	level = int(values.get("level", 1))
	experience = int(values.get("experience", 0))
	gold = int(values.get("gold", 0))
	pending_level_ups = int(values.get("pending_level_ups", 0))
	# Aceita base_* (jogador) ou os nomes antigos (inimigos/templates).
	base_max_health = int(values.get("base_max_health", int(values.get("max_health", 50))))
	base_attack = int(values.get("base_attack", int(values.get("attack", 10))))
	base_defense = int(values.get("base_defense", int(values.get("defense", 4))))
	base_luck = int(values.get("base_luck", int(values.get("luck", 5))))
	equipped = _to_string_dict(values.get("equipped", {}))
	# Compatibilidade com saves antigos (apenas arma/armadura).
	if not equipped.has("weapon"):
		equipped["weapon"] = str(values.get("equipped_weapon_id", ""))
	if not equipped.has("armor"):
		equipped["armor"] = str(values.get("equipped_armor_id", ""))
	_bonus = _load_bonus(values.get("_bonus", {}))
	# Bônus legados de arma/armadura.
	if not _bonus.has("weapon"):
		_bonus["weapon"] = {"atk": int(values.get("weapon_atk", 0)), "def": int(values.get("weapon_def", 0)), "luck": 0, "hp": 0}
	if not _bonus.has("armor"):
		_bonus["armor"] = {"atk": int(values.get("armor_atk", 0)), "def": int(values.get("armor_def", 0)), "luck": 0, "hp": 0}
	owned_item_ids = _to_string_array(values.get("owned_item_ids", []))
	_catalog = _load_catalog(values.get("_catalog", {}))
	enemy_kind = str(values.get("enemy_kind", "melee"))
	enemy_reach = int(values.get("enemy_reach", 1))
	enemy_tier = int(values.get("enemy_tier", 1))
	reward_multiplier = float(values.get("reward_multiplier", 1.0))
	weapon_label = str(values.get("weapon_label", ""))
	recompute_derived()
	var requested_health := int(values.get("health", -1))
	health = clampi(requested_health if requested_health >= 0 else max_health, 0, max_health)

## Guarda o dicionário completo de um item (id -> item) no catálogo do lutador,
## para exibir nome/raridade/nível mesmo de itens processuais fora do JSON.
func remember_item(item: Dictionary) -> void:
	if item.is_empty():
		return
	var item_id := str(item.get("id", ""))
	if item_id == "":
		return
	_catalog[item_id] = item.duplicate(true)
	_register_owned(item_id)

## Devolve o item conhecido (catálogo) pelo id, ou {} se não houver.
func catalog_item(item_id: String) -> Dictionary:
	return _catalog.get(item_id, {}) if _catalog.has(item_id) else {}

func has_catalog_item(item_id: String) -> bool:
	return _catalog.has(item_id)

func _load_catalog(source) -> Dictionary:
	var result := {}
	if source is Dictionary:
		for key: Variant in source.keys():
			var entry: Variant = source[key]
			if entry is Dictionary:
				result[str(key)] = entry.duplicate(true)
	return result

func recompute_derived() -> void:
	max_health = base_max_health
	attack = base_attack
	defense = base_defense
	luck = base_luck
	for slot: Variant in _bonus.keys():
		var bonus: Dictionary = _bonus[slot]
		max_health += int(bonus.get("hp", 0))
		attack += int(bonus.get("atk", 0))
		defense += int(bonus.get("def", 0))
		luck += int(bonus.get("luck", 0))
	health = mini(health, max_health)

func equipped_id(slot: String) -> String:
	return str(equipped.get(slot, ""))

func equipped_bonus(slot: String) -> Dictionary:
	return _bonus.get(slot, {})

func equip_item(item: Dictionary) -> void:
	var slot := str(item.get("slot", "weapon"))
	if not SLOT_ORDER.has(slot):
		return
	remember_item(item)
	var was_full := health >= max_health
	var item_id := str(item.get("id", ""))
	equipped[slot] = item_id
	_bonus[slot] = {
		"atk": int(item.get("attack_bonus", 0)),
		"def": int(item.get("defense_bonus", 0)),
		"luck": int(item.get("luck_bonus", 0)),
		"hp": int(item.get("health_bonus", 0)),
	}
	_register_owned(item_id)
	recompute_derived()
	if was_full:
		health = max_health

## Compatibilidade: equipa forçando o slot da arma/armadura.
func equip_weapon(item: Dictionary) -> void:
	var copy := item.duplicate()
	copy["slot"] = "weapon"
	equip_item(copy)

func equip_armor(item: Dictionary) -> void:
	var copy := item.duplicate()
	copy["slot"] = "armor"
	equip_item(copy)

func _register_owned(item_id: String) -> void:
	if item_id == "" or owned_item_ids.has(item_id):
		return
	owned_item_ids.append(item_id)

## Desequipa um slot: o item volta para a bolsa (continua em owned_item_ids).
func unequip(slot: String) -> bool:
	if not SLOT_ORDER.has(slot) or equipped_id(slot) == "":
		return false
	equipped[slot] = ""
	_bonus[slot] = {"atk": 0, "def": 0, "luck": 0, "hp": 0}
	recompute_derived()
	return true

## Tira um item da bolsa (venda). Recusa item equipado: desequipe antes.
func remove_owned(item_id: String) -> bool:
	if item_id == "" or not owned_item_ids.has(item_id) or _is_equipped(item_id):
		return false
	owned_item_ids.erase(item_id)
	_catalog.erase(item_id)
	return true

func _is_equipped(item_id: String) -> bool:
	for slot: String in SLOT_ORDER:
		if equipped_id(slot) == item_id:
			return true
	return false

func is_equipped(item_id: String) -> bool:
	return _is_equipped(item_id)

## Itens da bolsa (comprados ou ganhos e NÃO equipados), na ordem de aquisição.
func bag_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Variant in owned_item_ids:
		var item_id := str(entry)
		if item_id == "" or _is_equipped(item_id):
			continue
		var item := catalog_item(item_id)
		if not item.is_empty():
			result.append(item)
	return result

func owns_item(item_id: String) -> bool:
	return owned_item_ids.has(item_id)

func is_defeated() -> bool:
	return health <= 0

func heal_full() -> void:
	health = max_health

func receive_damage(amount: int) -> int:
	var applied_damage: int = maxi(0, amount)
	health = maxi(0, health - applied_damage)
	return applied_damage

func required_experience() -> int:
	return EconomySystemScript.required_experience(level)

## Acumula XP e marca níveis pendentes; o jogador escolhe o treino na tela de
## resultado (apply_level_up). Retorna true se algum nível foi ganho.
func grant_experience(amount: int) -> bool:
	experience += maxi(0, amount)
	var leveled_up := false
	while experience >= required_experience():
		experience -= required_experience()
		level += 1
		pending_level_ups += 1
		leveled_up = true
	return leveled_up

## Aplica uma escolha de treino (definida em EconomySystem.level_up_options).
func apply_level_up(option: Dictionary) -> bool:
	if pending_level_ups <= 0:
		return false
	var stat := str(option.get("stat", ""))
	if stat != "base_max_health" and stat != "base_attack" and stat != "base_defense" and stat != "base_luck":
		return false
	set(stat, int(get(stat)) + int(option.get("amount", 0)))
	pending_level_ups -= 1
	recompute_derived()
	if bool(option.get("heal", false)):
		heal_full()
	return true

func to_save_data() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"archetype_id": archetype_id,
		"level": level,
		"experience": experience,
		"gold": gold,
		"pending_level_ups": pending_level_ups,
		"base_max_health": base_max_health,
		"base_attack": base_attack,
		"base_defense": base_defense,
		"base_luck": base_luck,
		"health": health,
		"equipped": equipped.duplicate(true),
		"_bonus": _bonus.duplicate(true),
		"owned_item_ids": owned_item_ids.duplicate(),
		"_catalog": _catalog.duplicate(true),
	}

func _to_string_array(source) -> Array:
	var result: Array = []
	if source is Array:
		for entry: Variant in source:
			result.append(str(entry))
	return result

func _to_string_dict(source) -> Dictionary:
	var result := {}
	if source is Dictionary:
		for key: Variant in source.keys():
			result[str(key)] = str(source[key])
	return result

func _load_bonus(source) -> Dictionary:
	var result := {}
	if source is Dictionary:
		for key: Variant in source.keys():
			var entry: Variant = source[key]
			if entry is Dictionary:
				result[str(key)] = {
					"atk": int(entry.get("atk", int(entry.get("attack_bonus", 0)))),
					"def": int(entry.get("def", int(entry.get("defense_bonus", 0)))),
					"luck": int(entry.get("luck", int(entry.get("luck_bonus", 0)))),
					"hp": int(entry.get("hp", int(entry.get("health_bonus", 0)))),
				}
	return result
