class_name CombatResolver
extends RefCounted

const GladiatorDataScript := preload("res://scripts/models/gladiator_data.gd")

## DEFESA FIRME: reduz o dano recebido no turno seguinte. Cada ponto vale 5% de
## redução (o valor 6 = 30% de redução), com teto de 60%.
const DEFEND_GUARD_BONUS := 6
const GUARD_REDUCTION_PER_POINT := 0.05
const GUARD_REDUCTION_CAP := 0.6

## Precisão: cada ponto de ATT soma 1% de chance de acertar (base vem da ação).
const ACC_PER_ATT := 0.010
## Esquiva: cada ponto de AGI soma 1% de chance de anular o golpe (teto 45%).
const DODGE_PER_AGI := 0.010
const DODGE_CAP := 0.45
## Auto-defesa: cada ponto de DEF soma 1% de chance de aparar (teto 50%).
const BLOCK_PER_DEF := 0.010
const BLOCK_CAP := 0.50
## Fração do golpe aparado quando a auto-defesa dispara ("aparou X, entrou Y").
const BLOCK_FRACTION := 0.5
## REVIDAR (contra-ataque): quando o alvo APARA, há uma chance de contra-atacar e
## devolver parte do que aparou. PROPOSTA do item H §4: 50% de chance e 60% do
## valor aparado de volta ao atacante, consumindo armadura antes da vida. O dano
## do revidar é MENOR que o do golpe aparado, então aparar ainda compensa.
const COUNTER_CHANCE := 0.5
const COUNTER_DAMAGE_FRACTION := 0.6
## Mitigação direta por DEF já usada na curva de dano calibrada.
const DEF_MITIGATION := 0.55
const CRIT_MULTIPLIER := 1.55
## Crítico: base + SORTE (a antiga mecânica de luck, mantida e renomeada).
const CRIT_BASE := 0.06
const CRIT_PER_LUCK := 1.0 / 240.0

## DORMIR: cura uma fração da vida máxima e deixa vulnerável no turno seguinte
## (sem esquiva e com bônus de precisão para o inimigo).
const SLEEP_HEAL_FRACTION := 0.25
const SLEEP_VULNERABLE_ACCURACY := 0.30

## Taunt: chance base e pesos (a maioria empurra o alvo um passo para frente).
const TAUNT_BASE := 0.40
const TAUNT_CHA_WEIGHT := 0.02
const TAUNT_STR_WEIGHT := 0.01
const TAUNT_LUCK_WEIGHT := 0.005
const TAUNT_DEF_PENALTY := 0.012
const TAUNT_LUCK_RESIST := 0.015
const TAUNT_CHANCE_MIN := 0.05
const TAUNT_CHANCE_MAX := 0.95
## Resistência ao empurrão (SORTE): cada ponto = 2% (teto 60%).
const TAUNT_PUSH_RESIST_PER_LUCK := 0.02
const TAUNT_PUSH_RESIST_CAP := 0.6
## Tabela de efeitos do Taunt por peso (advance = maioria).
const TAUNT_EFFECTS := [
	{"id": "advance", "weight": 55, "label": "avança forçado"},
	{"id": "reckless", "weight": 25, "label": "ataca com precisão baixa"},
	{"id": "stumble", "weight": 20, "label": "tropeça e perde o turno"},
]

## Distância em "passos" entre os lutadores ao longo da arena (1–6, muralhas).
const ARENA_MIN_RANGE := 1
const ARENA_MAX_RANGE := 6
const ARENA_START_RANGE := 3
const ENEMY_REACH := 1
## Distância mínima em que um inimigo ranged tenta se manter.
const ENEMY_RANGED_RETREAT := 2

# --- Ações nomeadas por tipo de arma ---------------------------------------

## Corpo a corpo. `advance` = a INVESTIDA dá um passo antes de atacar.
static func melee_actions() -> Array[Dictionary]:
	return [
		{"id": "golpe", "label": "GOLPE", "multiplier": 1.0, "accuracy": 1.0, "penalty_scale": 1.0, "advance": false},
		{"id": "golpe_forte", "label": "GOLPE FORTE", "multiplier": 1.6, "accuracy": 0.62, "penalty_scale": 1.0, "advance": false},
		{"id": "investida", "label": "INVESTIDA", "multiplier": 1.15, "accuracy": 0.90, "penalty_scale": 1.0, "advance": true},
	]

## À distância. TIRO CERTEIRO tem precisão alta (sofre menos com a distância) e
## dano menor; BOMBARDEIO bate mais forte mas acerta menos.
static func ranged_actions() -> Array[Dictionary]:
	return [
		{"id": "tiro", "label": "TIRO", "multiplier": 1.0, "accuracy": 1.0, "penalty_scale": 1.0, "advance": false},
		{"id": "tiro_certeiro", "label": "TIRO CERTEIRO", "multiplier": 0.8, "accuracy": 1.0, "penalty_scale": 0.35, "advance": false},
		{"id": "bombardeio", "label": "BOMBARDEIO", "multiplier": 1.7, "accuracy": 0.60, "penalty_scale": 1.35, "advance": false},
	]

static func attack_actions_for(weapon: Dictionary) -> Array[Dictionary]:
	if weapon_kind(weapon) == "ranged":
		return ranged_actions()
	return melee_actions()

static func find_action(actions: Array, action_id: String) -> Dictionary:
	for action: Dictionary in actions:
		if str(action.get("id", "")) == action_id:
			return action
	return {}

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
	# que os pontos de atributo do jogador (4 por nível).
	var hp := maxi(20, 25 + level * 7 + tier * 8 + randi_range(-5, 6))
	var vit := maxi(2, roundi((float(hp) - float(GladiatorDataScript.HEALTH_BASE)) / float(GladiatorDataScript.HEALTH_PER_VIT)))
	var strg := maxi(4, 7 + int(round(float(level) * 1.75)) + tier * 2 + randi_range(-2, 2))
	var defense := maxi(1, 2 + int(round(float(level) * 1.05)) + tier * 2 + randi_range(0, 2))
	var attack := maxi(4, 5 + int(round(float(level) * 0.5)) + tier)
	var agility := maxi(1, 2 + tier + randi_range(0, 2))
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
		"attrs_version": GladiatorDataScript.ATTRS_VERSION,
		"id": "generated_%d" % (randi() % 100000),
		"display_name": name,
		"level": level,
		"base_vitality": vit,
		"base_strength": strg,
		"base_defence": defense,
		"base_attack": attack,
		"base_agility": agility,
		"base_charisma": luck,
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

# --- Fórmulas de combate ---------------------------------------------------

## Chance de acertar (antes da esquiva): precisão da ação + ATT do atacante.
static func accuracy_for(attacker, base_accuracy: float) -> float:
	if attacker == null:
		return clampf(base_accuracy, 0.0, 1.0)
	return clampf(base_accuracy + float(attacker.attack) * ACC_PER_ATT, 0.0, 1.0)

## Chance de ESQUIVA do alvo (AGI).
static func dodge_chance(defender) -> float:
	if defender == null:
		return 0.0
	return clampf(float(defender.agility) * DODGE_PER_AGI, 0.0, DODGE_CAP)

## Chance de AUTO-DEFESA do alvo (DEF): aparta parte do golpe.
static func block_chance(defender) -> float:
	if defender == null:
		return 0.0
	return clampf(float(defender.defence) * BLOCK_PER_DEF, 0.0, BLOCK_CAP)

## Chance de ACERTO CRÍTICO do atacante (base + SORTE).
static func critical_chance(attacker) -> float:
	if attacker == null:
		return CRIT_BASE
	return clampf(CRIT_BASE + float(attacker.luck) * CRIT_PER_LUCK, 0.0, 1.0)

## Resolve UM ataque com o feedback pedido, campo por campo:
##  {hit, missed, dodged, blocked, blocked_amount, damage, entered,
##   armour_damage, health_damage, critical, out_of_range}
## Ordem: (1) precisão pelo ATT; (2) esquiva pela AGI; (3) dano por STR vs DEF
## (crítico pela SORTE); (4) auto-defesa pela DEF ("aparou X, entrou Y");
## (5) DEFESA FIRME (guard_bonus) reduz o que entra; (6) a armadura absorve antes
## da vida.
static func resolve_attack(attacker, defender, multiplier: float = 1.0, accuracy: float = 1.0, guard_bonus: int = 0) -> Dictionary:
	var result := {
		"hit": false, "missed": false, "dodged": false, "blocked": false,
		"blocked_amount": 0, "damage": 0, "entered": 0, "armour_damage": 0,
		"health_damage": 0, "critical": false, "out_of_range": false,
		"countered": false, "counter_damage": 0, "counter_armour_damage": 0,
		"counter_health_damage": 0,
	}
	if attacker == null or defender == null:
		return result
	# (1) Precisão: o ATT do atacante define se o golpe acerta de saída.
	if randf() > accuracy_for(attacker, accuracy):
		result["missed"] = true
		return result
	# (2) Esquiva: a AGI do alvo pode anular o golpe. Quem dormiu (vulnerável) não esquiva.
	var vulnerable := bool(defender.vulnerable)
	if not vulnerable and randf() < dodge_chance(defender):
		result["dodged"] = true
		return result
	# (3) Dano: STR x multiplicador - mitigação direta da DEF; crítico pela SORTE.
	var critical := randf() < critical_chance(attacker)
	var raw_damage: float = float(attacker.strength) * multiplier + float(randi_range(-3, 4)) - (float(defender.defence) * DEF_MITIGATION)
	if critical:
		raw_damage *= CRIT_MULTIPLIER
	var damage := maxi(1, roundi(raw_damage))
	# (4) DEFESA FIRME do turno anterior reduz o dano que chega a entrar.
	if guard_bonus > 0:
		var reduction: float = minf(GUARD_REDUCTION_CAP, float(guard_bonus) * GUARD_REDUCTION_PER_POINT)
		damage = maxi(1, roundi(float(damage) * (1.0 - reduction)))
	# (5) Auto-defesa: a DEF do alvo apara parte do golpe ("aparou X, entrou Y").
	var blocked_amount := 0
	var countered := false
	if randf() < block_chance(defender):
		blocked_amount = maxi(0, roundi(float(damage) * BLOCK_FRACTION))
	var entered := maxi(0, damage - blocked_amount)
	# (6) A armadura absorve ANTES da vida.
	var split: Dictionary = defender.absorb_damage(entered)
	result["hit"] = true
	result["critical"] = critical
	result["blocked"] = blocked_amount > 0
	result["blocked_amount"] = blocked_amount
	result["damage"] = damage
	result["entered"] = entered
	result["armour_damage"] = int(split.get("armour", 0))
	result["health_damage"] = int(split.get("health", 0))
	# (7) REVIDAR: quem aparou pode contra-atacar devolvendo parte do aparado ao
	# atacante (o contra-golpe é MENOR que o golpe original). Isso alimenta o
	# evento +5 da felicidade do público.
	if blocked_amount > 0 and randf() < COUNTER_CHANCE:
		countered = true
		var counter_damage := maxi(1, roundi(float(blocked_amount) * COUNTER_DAMAGE_FRACTION))
		var counter_split: Dictionary = attacker.absorb_damage(counter_damage)
		result["countered"] = true
		result["counter_damage"] = counter_damage
		result["counter_armour_damage"] = int(counter_split.get("armour", 0))
		result["counter_health_damage"] = int(counter_split.get("health", 0))
	return result

static func enemy_for_level(level: int, template: Dictionary):
	# Escala do torneio: mais suave que a Arena Livre porque o torneio soma
	# `nível do jogador + índice do tier × 2 + rodada` (GameState).
	var safe_level: int = maxi(1, level)
	var hp: int = int(template.get("base_health", 42)) + (safe_level - 1) * 8
	var vit: int = maxi(2, roundi((float(hp) - float(GladiatorDataScript.HEALTH_BASE)) / float(GladiatorDataScript.HEALTH_PER_VIT)))
	return GladiatorDataScript.new({
		"attrs_version": GladiatorDataScript.ATTRS_VERSION,
		"id": str(template.get("id", "enemy")),
		"display_name": str(template.get("display_name", "Desafiante")),
		"level": safe_level,
		"base_vitality": vit,
		"base_strength": int(template.get("base_attack", 8)) + (safe_level - 1) * 2,
		"base_defence": int(template.get("base_defense", 3)) + (safe_level - 1),
		"base_attack": 8 + int(round(float(safe_level - 1) * 0.6)),
		"base_agility": 4 + int(round(float(safe_level - 1) * 0.4)),
		"base_charisma": int(template.get("base_luck", 4)) + (safe_level - 1) * 2,
		"base_luck": int(template.get("base_luck", 4)) + (safe_level - 1) * 2,
		"boss": bool(template.get("boss", false)),
	})

## Decisão simples do inimigo: 22% de chance de golpe arriscado, senão ataque normal.
static func choose_enemy_action() -> Dictionary:
	if randf() < 0.22:
		return {"kind": "brutal", "multiplier": 1.35, "accuracy": 0.82}
	return {"kind": "normal", "multiplier": 1.0, "accuracy": 1.0}

# --- Taunt ------------------------------------------------------------------

## Chance de sucesso do Taunt: CHA do provocador contra CHA/DEF/SOR do alvo,
## com peso do STR do provocador e um pequeno peso da SORTE do próprio.
static func taunt_chance(attacker, defender) -> float:
	if attacker == null or defender == null:
		return 0.0
	var chance := TAUNT_BASE
	chance += (float(attacker.charisma) - float(defender.charisma)) * TAUNT_CHA_WEIGHT
	chance += float(attacker.strength) * TAUNT_STR_WEIGHT
	chance += float(attacker.luck) * TAUNT_LUCK_WEIGHT
	chance -= float(defender.defence) * TAUNT_DEF_PENALTY
	chance -= float(defender.luck) * TAUNT_LUCK_RESIST
	return clampf(chance, TAUNT_CHANCE_MIN, TAUNT_CHANCE_MAX)

## Resistência ao EMPURRÃO para frente (SORTE): quem tem mais SORTE resiste mais.
static func taunt_push_resisted(defender) -> bool:
	if defender == null:
		return false
	var resist := clampf(float(defender.luck) * TAUNT_PUSH_RESIST_PER_LUCK, 0.0, TAUNT_PUSH_RESIST_CAP)
	return randf() < resist

## Sorteia o efeito do Taunt (advance é o de maior peso = maioria).
static func roll_taunt_effect() -> Dictionary:
	var total := 0
	for effect: Dictionary in TAUNT_EFFECTS:
		total += int(effect.get("weight", 0))
	var roll := randi_range(1, maxi(1, total))
	var accumulated := 0
	for effect: Dictionary in TAUNT_EFFECTS:
		accumulated += int(effect.get("weight", 0))
		if roll <= accumulated:
			return effect
	return TAUNT_EFFECTS[0]

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

## Precisão de projétil cai com a distância além do mínimo (escala ajustável
## pelas ações: TIRO CERTEIRO sofre menos, BOMBARDEIO sofre mais).
static func ranged_accuracy_scaled(accuracy: float, distance: int, penalty_scale: float) -> float:
	var penalty := float(maxi(0, distance - ARENA_MIN_RANGE)) * 0.07 * penalty_scale
	return clampf(accuracy - penalty, 0.0, 1.0)

static func ranged_accuracy(accuracy: float, distance: int) -> float:
	return ranged_accuracy_scaled(accuracy, distance, 1.0)

## Ataque que respeita alcance e distância. Melee fora do alcance não acerta;
## ranged aplica a penalidade de distância na precisão.
static func resolve_positional_attack(attacker, defender, weapon: Dictionary, distance: int, multiplier: float = 1.0, accuracy: float = 1.0, guard_bonus: int = 0, penalty_scale: float = 1.0) -> Dictionary:
	if not can_attack_at(distance, weapon):
		return {"hit": false, "missed": false, "dodged": false, "blocked": false, "blocked_amount": 0, "damage": 0, "entered": 0, "armour_damage": 0, "health_damage": 0, "critical": false, "out_of_range": true, "countered": false, "counter_damage": 0, "counter_armour_damage": 0, "counter_health_damage": 0}
	var effective_accuracy := accuracy
	if weapon_kind(weapon) == "ranged":
		effective_accuracy = ranged_accuracy_scaled(accuracy, distance, penalty_scale)
	return resolve_attack(attacker, defender, multiplier, effective_accuracy, guard_bonus)
