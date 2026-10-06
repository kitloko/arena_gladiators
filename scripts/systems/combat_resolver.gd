class_name CombatResolver
extends RefCounted

const GladiatorDataScript := preload("res://scripts/models/gladiator_data.gd")
const DEFEND_GUARD_BONUS := 6

## Distância em "passos" entre os lutadores ao longo da arena (1–6, muralhas).
const ARENA_MIN_RANGE := 1
const ARENA_MAX_RANGE := 6
const ARENA_START_RANGE := 3
const ENEMY_REACH := 1
## Distância mínima em que um inimigo ranged tenta se manter.
const ENEMY_RANGED_RETREAT := 2

## Gera um inimigo procedural com nível, atributos, tier, tipo de ataque
## (melee reach 1–2 ou ranged) e um conjunto de equipamento exibível baseado no
## nível do jogador. Os status finais seguem a faixa calibrada de dificuldade;
## o equipamento aparece na inspeção (o comportamento usa enemy_kind/reach).
## Se `items` (pool de data/items.json) for vazio, o inimigo sai sem itens.
static func generate_enemy(player_level: int, items: Array = []) -> Dictionary:
	# Nos primeiros níveis o inimigo é sempre tier 1: um tier 3 no nível 1 saía com
	# 106 de vida contra os ~58 do jogador recém-criado (derrota praticamente garantida).
	var tier := 1
	if player_level > 2:
		var roll := randf()
		if roll < 0.15:
			tier = 3
		elif roll < 0.45:
			tier = 2
	var level := maxi(1, player_level + randi_range(-1, 0) + (tier - 1))
	var kind := "ranged" if randf() < 0.35 else "melee"
	var reach := 1
	if kind == "melee" and randf() < 0.35:
		reach = 2
	# --- equipamento (exibido na inspeção; status já incluem o poder) --------
	var equipped := {}
	if not items.is_empty():
		var wishlist := {"weapon": _enemy_weapon_id(kind, reach, tier)}
		for slot: String in ["armor", "helmet", "gloves", "boots", "belt"]:
			if randf() <= _gear_fullness(tier):
				wishlist[slot] = _enemy_gear_id(slot, tier)
		for slot: String in wishlist.keys():
			var item := _find_item_by_id(items, wishlist[slot])
			if not item.is_empty():
				equipped[slot] = str(item.get("id", ""))
	# --- atributos na faixa calibrada de dificuldade --------------------------
	# Escala calibrada por tests/run_balance_test.gd: o inimigo cresce, mas mais devagar
	# que a escolha de treino do jogador (+4 de ataque ou +14 de vida por nível).
	var hp := maxi(20, 24 + level * 7 + tier * 8 + randi_range(-5, 6))
	var atk := maxi(4, 6 + int(round(float(level) * 1.6)) + tier * 2 + randi_range(-2, 2))
	var defense := maxi(1, 2 + level + tier + randi_range(0, 2))
	var luck := maxi(1, 3 + randi_range(0, 2 + tier * 2))
	var mult := 1.0 + float(tier - 1) * 0.7 + randf() * 0.15
	var weapon_label := "machado velho"
	if kind == "ranged":
		weapon_label = "arco de guerra" if randf() < 0.5 else "besta"
	elif reach > 1:
		weapon_label = "lança longa"
	var name := "Lutador da arena"
	var name_pool := [["Brutos", "O Chifre"], ["Nérvia", "a Sombra"], ["Cássio", "o Escudo"], ["Vale", "o Flecha"], ["Rufus", "o Martelo"], ["Míria", "a Raposa"]]
	var pick: Array = name_pool[randi() % name_pool.size()]
	name = "%s, %s" % [str(pick[0]), str(pick[1])]
	return {
		"id": "generated_%d" % (randi() % 100000),
		"display_name": name,
		"level": level,
		"base_max_health": hp,
		"max_health": hp,
		"base_attack": atk,
		"base_defense": defense,
		"base_luck": luck,
		"equipped": equipped,
		"enemy_kind": kind,
		"enemy_reach": reach,
		"enemy_tier": tier,
		"reward_multiplier": round(mult * 100.0) / 100.0,
		"weapon_label": weapon_label,
	}

## Arma do inimigo conforme tipo/alcance/tier (ids de data/items.json).
static func _enemy_weapon_id(kind: String, reach: int, tier: int) -> String:
	if kind == "ranged":
		match tier:
			3:
				return "crossbow"
			2:
				return "short_bow"
			_:
				return "short_bow" if randf() < 0.5 else "throwing_knives"
	if reach > 1:
		return "spear"
	match tier:
		3:
			return "battle_axe" if randf() < 0.6 else "hand_axe"
		2:
			return "hand_axe" if randf() < 0.6 else "dagger"
		_:
			return "short_sword" if randf() < 0.5 else "dagger"

## Peça (não arma) do inimigo conforme slot/tier.
static func _enemy_gear_id(slot: String, tier: int) -> String:
	match slot:
		"armor":
			match tier:
				3:
					return "plate_armor" if randf() < 0.6 else "chain_mail"
				2:
					return "chain_mail" if randf() < 0.5 else "leather_armor"
				_:
					return "leather_armor" if randf() < 0.5 else "cloth_tunic"
		"helmet":
			match tier:
				3:
					return "great_helm" if randf() < 0.5 else "iron_helm"
				2:
					return "iron_helm"
				_:
					return "cloth_hood"
		"gloves":
			match tier:
				3:
					return "iron_gauntlets" if randf() < 0.6 else "leather_gloves"
				2:
					return "leather_gloves" if randf() < 0.6 else "cloth_wraps"
				_:
					return "cloth_wraps"
		"boots":
			match tier:
				3:
					return "greaves" if randf() < 0.6 else "leather_boots"
				2:
					return "leather_boots" if randf() < 0.6 else "sandals"
				_:
					return "sandals"
		"belt":
			match tier:
				3:
					return "champion_belt" if randf() < 0.5 else "leather_belt"
				2:
					return "leather_belt" if randf() < 0.5 else "rope_belt"
				_:
					return "rope_belt"
	return ""

## Chance de um inimigo vir com cada slot extra de equipamento.
static func _gear_fullness(tier: int) -> float:
	match tier:
		3:
			return 0.85
		2:
			return 0.6
		_:
			return 0.4

static func _find_item_by_id(items: Array, item_id: String) -> Dictionary:
	for item: Dictionary in items:
		if str(item.get("id", "")) == item_id:
			return item
	return {}

## Regras puras de combate: sem interface, cenas ou acesso ao estado global.
## Isto permite testar e ajustar o balanceamento isoladamente.
static func resolve_attack(attacker, defender, multiplier: float = 1.0, accuracy: float = 1.0, guard_bonus: int = 0) -> Dictionary:
	var hit: bool = randf() <= accuracy
	if not hit:
		return {"hit": false, "critical": false, "damage": 0}
	var critical_chance: float = 0.06 + float(attacker.luck) / 240.0
	var critical: bool = randf() < critical_chance
	var raw_damage: float = float(attacker.attack) * multiplier + float(randi_range(-3, 4)) - (float(defender.defense + guard_bonus) * 0.55)
	var damage: int = maxi(1, roundi(raw_damage * (1.55 if critical else 1.0)))
	defender.receive_damage(damage)
	return {"hit": true, "critical": critical, "damage": damage}

static func enemy_for_level(level: int, template: Dictionary):
	# Escala do torneio: mais suave que a Arena Livre porque o torneio soma
	# `nível do jogador + índice do tier × 2 + rodada` (GameState). Com +12 de vida
	# por nível, o chefe ficava matematicamente imbatível em todos os níveis.
	var safe_level: int = maxi(1, level)
	return GladiatorDataScript.new({"id": str(template.get("id", "enemy")), "display_name": str(template.get("display_name", "Desafiante")), "level": safe_level, "max_health": int(template.get("base_health", 42)) + (safe_level - 1) * 8, "health": int(template.get("base_health", 42)) + (safe_level - 1) * 8, "attack": int(template.get("base_attack", 8)) + (safe_level - 1) * 2, "defense": int(template.get("base_defense", 3)) + (safe_level - 1), "luck": int(template.get("base_luck", 4)) + (safe_level - 1) * 2})

## Decisão simples do inimigo: 22% de chance de golpe arriscado, senão ataque normal.
## Centralizado aqui para a interface não conter regras de comportamento.
static func choose_enemy_action() -> Dictionary:
	if randf() < 0.22:
		return {"kind": "brutal", "multiplier": 1.35, "accuracy": 0.82}
	return {"kind": "normal", "multiplier": 1.0, "accuracy": 1.0}

# --- Movimento e alcance -------------------------------------------------

## Tipo de arma: "melee" (padrão) ou "ranged".
static func weapon_kind(weapon: Dictionary) -> String:
	return str(weapon.get("kind", "melee"))

## Alcance (passos) de uma arma melee; ranged ataca de qualquer distância.
static func weapon_reach(weapon: Dictionary) -> int:
	return maxi(1, int(weapon.get("reach", 1)))

static func can_attack_at(distance: int, weapon: Dictionary) -> bool:
	if weapon_kind(weapon) == "ranged":
		return distance >= ARENA_MIN_RANGE
	return distance <= weapon_reach(weapon)

static func move_toward(distance: int) -> int:
	return maxi(ARENA_MIN_RANGE, distance - 1)

static func move_away(distance: int) -> int:
	return mini(ARENA_MAX_RANGE, distance + 1)

## Precisão de projétil cai com a distância além do mínimo.
static func ranged_accuracy(accuracy: float, distance: int) -> float:
	var penalty := float(maxi(0, distance - ARENA_MIN_RANGE)) * 0.07
	return clampf(accuracy - penalty, 0.0, 1.0)

## Ataque que respeita alcance e distância. Melee fora do alcance não acerta;
## ranged aplica a penalidade de distância na precisão.
static func resolve_positional_attack(attacker, defender, weapon: Dictionary, distance: int, multiplier: float = 1.0, accuracy: float = 1.0, guard_bonus: int = 0) -> Dictionary:
	if not can_attack_at(distance, weapon):
		return {"hit": false, "critical": false, "damage": 0, "out_of_range": true}
	var effective_accuracy := accuracy
	if weapon_kind(weapon) == "ranged":
		effective_accuracy = ranged_accuracy(accuracy, distance)
	return resolve_attack(attacker, defender, multiplier, effective_accuracy, guard_bonus)
