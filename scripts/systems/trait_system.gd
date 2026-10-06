class_name TraitSystem
extends RefCounted

## CATÁLOGO DE TRAÇOS DE COMBATE (docs/IDEIAS.md, item 8 — a metade que faltava).
##
## A fraqueza declarada de cada template de data/enemies.json era SÓ TEXTO. Este
## sistema liga o texto à mecânica: cada inimigo recebe o campo `trait` com um id
## DESTE catálogo fechado, e o texto de `weakness` passa a DESCREVER exatamente o
## efeito. O CombatResolver aplica o efeito na conta de verdade e a arena mostra no
## log quando o traço morde.
##
## REGRAS DE ESCOPO:
##  - catálogo FECHADO de 6 traços (4 a 6 pedidos na spec);
##  - o JOGADOR não tem traço (fora do escopo): o traço é campo de INIMIGO e só
##    existe quando o template o declara. Inimigo procedural da Arena Livre nasce
##    SEM traço — o balanceamento da arena livre não muda;
##  - cada efeito é um número explícito abaixo (nada implícito);
##  - `power_weight` é o peso PEQUENO e DOCUMENTADO do traço no Índice de Poder e,
##    por tabela, na odd da aposta (BettingSystem usa o Índice de Poder). O sinal
##    segue a força real: traço que enfraquece o inimigo pesa negativo, o que o
##    fortalece pesa positivo; a magnitude foi calibrada como "alguns pontos de
##    atributo" (o peso de 1 STR no índice é 2,0).
##
## EFEITOS (documentados e medidos em tests/run_systems_test.gd):
##  - frail    (Frágil)     : +25% de dano RECEBIDO de golpes pesados.
##  - slow     (Lento)      : −0,15 de esquiva própria e −10% de precisão própria.
##  - dodgy    (Ágil)       : +0,10 de esquiva própria.
##  - armoured (Couraçado)  : −20% de dano melee RECEBIDO, mas −0,10 de esquiva.
##  - glass    (Vidro)      : +15% de dano recebido de QUALQUER tipo e +10% causado.
##  - beast    (Fera)       : +10% de dano CAUSADO. (Escolhida a variante de dano,
##                            NÃO a de ação extra: o resolver é por ataque e a
##                            arena dirige os turnos; +10% de dano é honesto,
##                            local e testável. Documentado aqui.)

## Ações consideradas "golpes pesados" para o traço `frail`.
const HEAVY_ACTIONS := ["golpe_forte", "investida", "bombardeio"]

## Catálogo FECHADO: id -> efeito exato. Nenhum outro id é válido.
const CATALOG := {
	"frail": {
		"id": "frail",
		"label": "Frágil",
		"description": "Leva +25% de dano de golpes pesados.",
		"heavy_damage_taken": 0.25,
		"power_weight": -6,
	},
	"slow": {
		"id": "slow",
		"label": "Lento",
		"description": "−0,15 de esquiva e −10% de precisão própria.",
		"dodge_penalty": 0.15,
		"accuracy_multiplier": 0.90,
		"power_weight": -8,
	},
	"dodgy": {
		"id": "dodgy",
		"label": "Ágil",
		"description": "+0,10 de esquiva própria.",
		"dodge_bonus": 0.10,
		"power_weight": 6,
	},
	"armoured": {
		"id": "armoured",
		"label": "Couraçado",
		"description": "−20% de dano melee sofrido, mas −0,10 de esquiva.",
		"melee_damage_taken": -0.20,
		"dodge_penalty": 0.10,
		"power_weight": 6,
	},
	"glass": {
		"id": "glass",
		"label": "Vidro",
		"description": "+15% de dano recebido de qualquer tipo e +10% de dano causado.",
		"damage_taken": 0.15,
		"damage_dealt": 0.10,
		"power_weight": 2,
	},
	"beast": {
		"id": "beast",
		"label": "Fera",
		"description": "+10% de dano causado.",
		"damage_dealt": 0.10,
		"power_weight": 8,
	},
}

## Um traço é "golpe pesado" quando a ação está em HEAVY_ACTIONS.
static func is_heavy_attack(attack_id: String) -> bool:
	return HEAVY_ACTIONS.has(attack_id)

## Id do traço de um lutador ("" quando não tem). Aceita qualquer objeto com o
## campo `trait_id`; nunca explode com lutador nulo.
static func trait_id_of(fighter) -> String:
	if fighter == null:
		return ""
	if not ("trait_id" in fighter):
		return ""
	return str(fighter.trait_id)

## Dicionário do traço ({} quando o id é vazio ou desconhecido = catálogo fechado).
static func trait_definition(trait_id: String) -> Dictionary:
	if trait_id == "" or not CATALOG.has(trait_id):
		return {}
	return CATALOG[trait_id]

static func has_trait(trait_id: String) -> bool:
	return CATALOG.has(trait_id)

## Rótulo legível ("Frágil") ou "" sem traço.
static func label_for(trait_id: String) -> String:
	return str(trait_definition(trait_id).get("label", ""))

## Descrição do efeito ("Leva +25% de dano de golpes pesados.") ou "".
static func description_for(trait_id: String) -> String:
	return str(trait_definition(trait_id).get("description", ""))

## Todos os ids do catálogo (ordem estável).
static func trait_ids() -> Array:
	return CATALOG.keys()

# --- Efeitos: dano recebido / causado ---------------------------------------

## Multiplicador de dano RECEBIDO pelo alvo (1,0 = sem traço).
## `is_melee`/`is_heavy` descrevem o ATAQUE que chegou.
static func damage_taken_multiplier(defender, is_melee: bool, is_heavy: bool) -> float:
	var trait_id := trait_id_of(defender)
	if trait_id == "":
		return 1.0
	match trait_id:
		"frail":
			if is_heavy:
				return 1.25
		"armoured":
			if is_melee:
				return 0.80
		"glass":
			return 1.15
	return 1.0

## Multiplicador de dano CAUSADO pelo atacante (1,0 = sem traço).
static func damage_dealt_multiplier(attacker) -> float:
	var trait_id := trait_id_of(attacker)
	match trait_id:
		"glass":
			return 1.10
		"beast":
			return 1.10
	return 1.0

# --- Efeitos: esquiva e precisão --------------------------------------------

## Soma (positiva ou negativa) à chance de esquiva do lutador.
static func dodge_modifier(fighter) -> float:
	var trait_id := trait_id_of(fighter)
	match trait_id:
		"slow":
			return -0.15
		"armoured":
			return -0.10
		"dodgy":
			return 0.10
	return 0.0

## Multiplicador de precisão do atacante (1,0 = sem traço).
static func accuracy_multiplier(fighter) -> float:
	var trait_id := trait_id_of(fighter)
	if trait_id == "slow":
		return 0.90
	return 1.0

# --- Peso no Índice de Poder / aposta ---------------------------------------

## Peso do traço no Índice de Poder (0 sem traço).
static func power_weight(fighter) -> int:
	var defn := trait_definition(trait_id_of(fighter))
	if defn.is_empty():
		return 0
	return int(defn.get("power_weight", 0))

# --- Avisos de log (o traço tem de APARECER na luta) ------------------------

## Aviso quando o atacante teve o dano CAUSADO ampliado pelo próprio traço.
static func dealt_note(attacker) -> String:
	var defn := trait_definition(trait_id_of(attacker))
	if defn.is_empty():
		return ""
	if not defn.has("damage_dealt"):
		return ""
	return "%s: +%d%% de dano" % [str(defn.label), int(round(float(defn.damage_dealt) * 100.0))]

## Aviso quando o ALVO teve o dano recebido alterado pelo traço.
static func taken_note(defender, is_melee: bool, is_heavy: bool) -> String:
	var trait_id := trait_id_of(defender)
	var defn := trait_definition(trait_id)
	if defn.is_empty():
		return ""
	match trait_id:
		"frail":
			if is_heavy:
				return "Frágil: +%d%% de dano" % int(round(float(defn.heavy_damage_taken) * 100.0))
		"armoured":
			if is_melee:
				return "Couraçado: aparou parte do golpe (−%d%% corpo a corpo)" % int(round(absf(float(defn.melee_damage_taken)) * 100.0))
		"glass":
			return "Vidro: +%d%% de dano recebido" % int(round(float(defn.damage_taken) * 100.0))
	return ""

## Aviso quando o alvo esquivou (destaque para o bônus de Ágil).
static func dodge_note(defender) -> String:
	if trait_id_of(defender) == "dodgy":
		return "Ágil: esquivou com facilidade"
	return ""

## Aviso quando um alvo Lento é acertado (não conseguiu esquivar).
static func dodge_fail_note(defender) -> String:
	if trait_id_of(defender) == "slow":
		return "Lento: não conseguiu esquivar"
	return ""

## Aviso quando um atacante Lento erra por causa da precisão reduzida.
static func accuracy_miss_note(attacker) -> String:
	if trait_id_of(attacker) == "slow":
		return "Lento: −10% de precisão"
	return ""
