class_name GladiatorData
extends RefCounted

const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")

## Fonte única de dados de um lutador.
##
## SETE atributos permanentes (criação + pontos de nível + equipamento):
##  - strength  (STR): dano corpo a corpo; também pesa na força do Taunt.
##  - attack    (ATT): precisão — chance de acertar o golpe.
##  - defence   (DEF): auto-defesa — chance de aparar, reduzindo o dano que entra.
##  - agility   (AGI): esquiva — chance de anular o golpe (dano zero).
##  - vitality  (VIT): vida máxima (max_health = HEALTH_BASE + vitality * HEALTH_PER_VIT).
##  - charisma  (CHA): desconto na loja, felicidade do público (etapa futura) e
##                     eficácia de exibição/Taunt.
##  - luck      (SOR): chance de acerto crítico (dano x1.55), resistência a efeitos
##                     aleatórios (reduz o Taunt do inimigo e o empurrão) e
##                     pechincha na loja (leitura pronta; sem UI nova nesta etapa).
## STA (stamina) e MAG (magicka) NÃO existem nesta versão.
##
## A ARMADURA é um POOL separado da vida: o dano consome armadura primeiro e só o
## excedente fere a vida. Vem das peças de proteção (campo 'armour' do item) e é
## restaurada junto com a vida no descanso e ao entrar num torneio.

const SLOT_ORDER := ["weapon", "armor", "helmet", "gloves", "boots", "belt"]
const ATTRS_VERSION := 2
const HEALTH_BASE := 10
const HEALTH_PER_VIT := 6

var id: String
var display_name: String
var archetype_id: String = ""
var level: int = 1
var experience: int = 0
var gold: int = 0
## Pontos de atributo pendentes para distribuir (4 por nível ganho).
var pending_points: int = 0
## Felicidade do público (etapa futura): campo e leitura prontos, ainda não usado.
var crowd_happiness: int = 0

var base_strength: int = 8
var base_attack: int = 8
var base_defence: int = 3
var base_agility: int = 5
var base_vitality: int = 6
var base_charisma: int = 5
var base_luck: int = 5

## Derivados (recalculados por recompute_derived()).
var strength: int = 8
var attack: int = 8
var defence: int = 3
var agility: int = 5
var vitality: int = 6
var charisma: int = 5
var luck: int = 5
var max_health: int = 46
var max_armour: int = 0
var health: int = 46
var armour: int = 0

## equipado: slot -> id do item; _bonus: slot -> {str,att,def,agi,vit,cha,luck,armour}.
var equipped: Dictionary = {}
var owned_item_ids: Array = []
var _bonus: Dictionary = {}
## Catálogo id -> dicionário completo do item (itens processuais guardam
## nome/raridade/nível aqui, já que não estão em data/items.json).
var _catalog: Dictionary = {}

## Estado transitório de combate (não é salvo): DORMIR deixa o lutador
## vulnerável no turno seguinte (sem esquiva e mais fácil de acertar).
var vulnerable: bool = false

## Metadados de inimigos gerados proceduralmente (não usados pelo jogador).
var enemy_kind: String = "melee"
var enemy_reach: int = 1
var enemy_tier: int = 1
var reward_multiplier: float = 1.0
var weapon_label: String = ""
## Chefe (data/enemies.json "boss": true): usado pela felicidade do público, que
## começa empolgada (piso 60) contra chefes.
var boss: bool = false

func _init(values: Dictionary = {}) -> void:
	id = str(values.get("id", "unnamed"))
	display_name = str(values.get("display_name", "Gladiador"))
	archetype_id = str(values.get("archetype_id", ""))
	level = int(values.get("level", 1))
	experience = int(values.get("experience", 0))
	gold = int(values.get("gold", 0))
	# Aceita pending_points (novo) ou pending_level_ups (save antigo: converte em pontos).
	pending_points = int(values.get("pending_points", int(values.get("pending_level_ups", 0)) * EconomySystemScript.attribute_points_per_level()))
	crowd_happiness = int(values.get("crowd_happiness", 0))
	# Formato novo (7 atributos) quando traz qualquer chave nova; senão migra o
	# formato antigo (health/attack/defense/luck) sem zerar nada.
	var new_format: bool = int(values.get("attrs_version", 0)) >= ATTRS_VERSION or values.has("base_strength") or values.has("base_defence") or values.has("base_agility") or values.has("base_vitality") or values.has("base_charisma")
	if new_format:
		base_strength = int(values.get("base_strength", 8))
		base_attack = int(values.get("base_attack", 8))
		base_defence = int(values.get("base_defence", 3))
		base_agility = int(values.get("base_agility", 5))
		base_vitality = int(values.get("base_vitality", 6))
		base_charisma = int(values.get("base_charisma", 5))
		base_luck = int(values.get("base_luck", 5))
	else:
		# Migração do save/formato antigo: health->vitality, attack->strength,
		# defense->defence, luck->luck (SOR). Nada é descartado.
		var old_hp := int(values.get("base_max_health", int(values.get("max_health", 46))))
		base_vitality = maxi(1, roundi((float(old_hp) - float(HEALTH_BASE)) / float(HEALTH_PER_VIT)))
		base_strength = int(values.get("base_attack", 8))
		base_attack = 8
		base_defence = int(values.get("base_defense", 3))
		base_agility = 5
		base_charisma = int(values.get("base_luck", 5))
		base_luck = int(values.get("base_luck", 5))
	equipped = _to_string_dict(values.get("equipped", {}))
	# Compatibilidade com saves antigos (apenas arma/armadura).
	if not equipped.has("weapon"):
		equipped["weapon"] = str(values.get("equipped_weapon_id", ""))
	if not equipped.has("armor"):
		equipped["armor"] = str(values.get("equipped_armor_id", ""))
	_bonus = _load_bonus(values.get("_bonus", {}))
	# Bônus legados de arma/armadura (campos weapon_atk/armor_atk etc.).
	if not _bonus.has("weapon"):
		_bonus["weapon"] = _legacy_bonus(int(values.get("weapon_atk", 0)), int(values.get("weapon_def", 0)), 0, 0)
	if not _bonus.has("armor"):
		_bonus["armor"] = _legacy_bonus(int(values.get("armor_atk", 0)), int(values.get("armor_def", 0)), 0, 0)
	owned_item_ids = _to_string_array(values.get("owned_item_ids", []))
	_catalog = _load_catalog(values.get("_catalog", {}))
	enemy_kind = str(values.get("enemy_kind", "melee"))
	enemy_reach = int(values.get("enemy_reach", 1))
	enemy_tier = int(values.get("enemy_tier", 1))
	reward_multiplier = float(values.get("reward_multiplier", 1.0))
	weapon_label = str(values.get("weapon_label", ""))
	boss = bool(values.get("boss", false))
	recompute_derived()
	var requested_health := int(values.get("health", -1))
	health = clampi(requested_health if requested_health >= 0 else max_health, 0, max_health)
	var requested_armour := int(values.get("armour", -1))
	armour = clampi(requested_armour if requested_armour >= 0 else max_armour, 0, max_armour)

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
	strength = base_strength
	attack = base_attack
	defence = base_defence
	agility = base_agility
	vitality = base_vitality
	charisma = base_charisma
	luck = base_luck
	var armour_sum := 0
	for slot: Variant in _bonus.keys():
		var bonus: Dictionary = _bonus[slot]
		strength += int(bonus.get("str", 0))
		attack += int(bonus.get("att", 0))
		defence += int(bonus.get("def", 0))
		agility += int(bonus.get("agi", 0))
		vitality += int(bonus.get("vit", 0))
		charisma += int(bonus.get("cha", 0))
		luck += int(bonus.get("luck", 0))
		armour_sum += int(bonus.get("armour", 0))
	max_health = HEALTH_BASE + vitality * HEALTH_PER_VIT
	max_armour = armour_sum
	health = mini(health, max_health)
	armour = mini(armour, max_armour)

func equipped_id(slot: String) -> String:
	return str(equipped.get(slot, ""))

func equipped_bonus(slot: String) -> Dictionary:
	return _bonus.get(slot, {})

func equip_item(item: Dictionary) -> void:
	var slot := str(item.get("slot", "weapon"))
	if not SLOT_ORDER.has(slot):
		return
	remember_item(item)
	var was_health_full := health >= max_health
	var was_armour_full := armour >= max_armour
	var item_id := str(item.get("id", ""))
	equipped[slot] = item_id
	_bonus[slot] = {
		"str": int(item.get("strength_bonus", 0)),
		"att": int(item.get("attack_bonus", 0)),
		"def": int(item.get("defence_bonus", 0)),
		"agi": int(item.get("agility_bonus", 0)),
		"vit": int(item.get("vitality_bonus", 0)),
		"cha": int(item.get("charisma_bonus", 0)),
		"luck": int(item.get("luck_bonus", 0)),
		"armour": int(item.get("armour", 0)),
	}
	_register_owned(item_id)
	recompute_derived()
	if was_health_full:
		health = max_health
	if was_armour_full:
		armour = max_armour

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
	var was_health_full := health >= max_health
	var was_armour_full := armour >= max_armour
	equipped[slot] = ""
	_bonus[slot] = _empty_bonus()
	recompute_derived()
	if was_health_full:
		health = max_health
	if was_armour_full:
		armour = max_armour
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
	armour = max_armour
	vulnerable = false

## Total a recuperar (vida faltante + armadura faltante) — usado pelo descanso.
func missing_pool() -> int:
	return maxi(0, max_health - health) + maxi(0, max_armour - armour)

## Aplica o dano consumindo a ARMADURA primeiro e só o excedente fere a vida.
## Devolve {armour, health, total} com o que cada reserva absorveu.
func absorb_damage(amount: int) -> Dictionary:
	var remaining := maxi(0, amount)
	var armour_used := mini(armour, remaining)
	armour -= armour_used
	remaining -= armour_used
	var health_used := mini(health, remaining)
	health -= health_used
	return {"armour": armour_used, "health": health_used, "total": armour_used + health_used}

## Compatibilidade: devolve o dano total aplicado (armadura + vida).
func receive_damage(amount: int) -> int:
	return int(absorb_damage(amount).get("total", 0))

func required_experience() -> int:
	return EconomySystemScript.required_experience(level)

## Acumula XP e marca pontos de atributo pendentes; o jogador distribui os
## pontos na tela de Personagem (spend_attribute_point). Retorna true se subiu.
func grant_experience(amount: int) -> bool:
	experience += maxi(0, amount)
	var leveled_up := false
	while experience >= required_experience():
		experience -= required_experience()
		level += 1
		pending_points += EconomySystemScript.attribute_points_per_level()
		leveled_up = true
	return leveled_up

## Gasta UM ponto pendente num atributo (id em EconomySystem.attribute_definitions).
func spend_attribute_point(attribute_id: String) -> bool:
	if pending_points <= 0:
		return false
	var field := _base_field_for(attribute_id)
	if field == "":
		return false
	set(field, int(get(field)) + 1)
	pending_points -= 1
	var was_health_full := health >= max_health
	var was_armour_full := armour >= max_armour
	recompute_derived()
	if was_health_full:
		health = max_health
	if was_armour_full:
		armour = max_armour
	return true

## Campo base_* de um atributo; aceita o id curto ("strength") ou o campo.
func _base_field_for(attribute_id: String) -> String:
	match attribute_id:
		"strength", "base_strength":
			return "base_strength"
		"attack", "base_attack":
			return "base_attack"
		"defence", "defense", "base_defence":
			return "base_defence"
		"agility", "base_agility":
			return "base_agility"
		"vitality", "base_vitality":
			return "base_vitality"
		"charisma", "base_charisma":
			return "base_charisma"
		"luck", "base_luck":
			return "base_luck"
	return ""

## Leitura pronta da felicidade do público (etapa futura).
func audience_favour() -> int:
	return crowd_happiness

func to_save_data() -> Dictionary:
	return {
		"attrs_version": ATTRS_VERSION,
		"id": id,
		"display_name": display_name,
		"archetype_id": archetype_id,
		"level": level,
		"experience": experience,
		"gold": gold,
		"pending_points": pending_points,
		"crowd_happiness": crowd_happiness,
		"base_strength": base_strength,
		"base_attack": base_attack,
		"base_defence": base_defence,
		"base_agility": base_agility,
		"base_vitality": base_vitality,
		"base_charisma": base_charisma,
		"base_luck": base_luck,
		"health": health,
		"armour": armour,
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

func _empty_bonus() -> Dictionary:
	return {"str": 0, "att": 0, "def": 0, "agi": 0, "vit": 0, "cha": 0, "luck": 0, "armour": 0}

## Normaliza um bônus de item, aceitando o vocabulário novo e o antigo
## (atk/def/luck/hp) para não quebrar saves existentes.
func _normalize_bonus(entry: Dictionary) -> Dictionary:
	var hp_legacy := int(entry.get("hp", 0))
	var vit := int(entry.get("vit", int(entry.get("vitality_bonus", 0))))
	if vit == 0 and hp_legacy != 0:
		vit = int(round(float(hp_legacy) / float(HEALTH_PER_VIT)))
	return {
		"str": int(entry.get("str", int(entry.get("strength_bonus", 0)))),
		"att": int(entry.get("att", int(entry.get("attack_bonus", 0)))),
		"def": int(entry.get("def", int(entry.get("defence_bonus", 0)))),
		"agi": int(entry.get("agi", int(entry.get("agility_bonus", 0)))),
		"vit": vit,
		"cha": int(entry.get("cha", int(entry.get("charisma_bonus", 0)))),
		"luck": int(entry.get("luck", int(entry.get("luck_bonus", 0)))),
		"armour": int(entry.get("armour", 0)),
	}

func _legacy_bonus(atk: int, def: int, luck: int, hp: int) -> Dictionary:
	return {
		"str": atk, "att": 0, "def": def, "agi": 0,
		"vit": int(round(float(hp) / float(HEALTH_PER_VIT))), "cha": 0,
		"luck": luck, "armour": 0,
	}

func _load_bonus(source) -> Dictionary:
	var result := {}
	if source is Dictionary:
		for key: Variant in source.keys():
			var entry: Variant = source[key]
			if entry is Dictionary:
				var normalized := _normalize_bonus(entry)
				# Compatibilidade com o antigo "_bonus" {atk,def,luck,hp}: o ataque
				# antigo era dano (vira força) e o hp vira vitalidade.
				if entry.has("atk") and not entry.has("str"):
					normalized["str"] = int(entry.get("atk", 0))
				result[str(key)] = normalized
	return result
