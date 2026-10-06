class_name UniqueItems
extends RefCounted

## As 8 VARIAÇÕES ÚNICAS de torneio (docs/PLANO_3.0.md §5.2).
##
## Um conjunto por torneio (Menor/Maior/Grande) — subir de torneio NÃO é "o
## mesmo prêmio mais forte": cada tier tem as SUAS variações. Cada uma é
## um-de-um-tipo, com NOME PRÓPRIO e um EFEITO EXCLUSIVO ligado à mecânica (não
## é texto decorativo): o efeito mora no item (campo "unique_effect" em
## data/items.json) e GladiatorData.unique_effects() expõe o que está equipado.
##
## Regras (todas com teste em tests/run_systems_test.gd):
##  - NÃO aparecem na loja (o estoque é procedural e nunca lê os ids únicos);
##  - NÃO são vendáveis (os itens têm "unique": true — EconomySystem.is_sellable);
##  - só caem de BOSS (BossDropTable sorteia o conjunto do tier na queda).

const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")

## Conjunto de cada torneio (id -> lista de ids únicos). 2 + 3 + 3 = 8.
const TIER_SETS := {
	"t1": ["adaga_da_viuva", "manto_do_publico"],
	"t2": ["elmo_do_imperador", "botas_do_mensageiro", "luvas_do_carrasco"],
	"t3": ["gladius_magnus", "pingente_do_sortudo", "coracao_de_bronze"],
}

## Catálogo FECHADO dos efeitos exclusivos (id -> metadados). É a fonte da
## verdade que as consultas de combate/arena usam via os predicados abaixo.
const EFFECTS := {
	"always_counter": {
		"label": "Vingança da Viúva",
		"description": "sempre que você APARA, REVIDA — sem depender da sorte.",
	},
	"exhibit_master": {
		"label": "Favor do Público",
		"description": "EXIBIR rende +50% e NÃO deixa você aberto ao contra-ataque.",
	},
	"taunt_immune": {
		"label": "Coroa de Ferro",
		"description": "IMUNE a Taunt: provocações não te deslocam nem te expõem.",
	},
	"wind_dodge": {
		"label": "Passo do Vento",
		"description": "+0,15 de esquiva e a esquiva NÃO tem teto.",
	},
	"crit_master": {
		"label": "Golpe do Carrasco",
		"description": "+15% de chance de acerto crítico.",
	},
	"champion_fury": {
		"label": "Fúria do Campeão",
		"description": "+20% de dano corpo a corpo.",
	},
	"lucky_gold": {
		"label": "Bolsa do Sortudo",
		"description": "+25% de ouro em cada vitória.",
	},
	"second_wind": {
		"label": "Segundo Sopro",
		"description": "sobrevive ao primeiro golpe fatal de cada luta (volta com 1 de vida).",
	},
}

const WIND_DODGE_BONUS := 0.15
const DODGE_CAP_RAISED := 0.75
const CRIT_MASTER_BONUS := 0.15
const CHAMPION_FURY_BONUS := 0.20
const LUCKY_GOLD_MULTIPLIER := 1.25

## Todos os ids únicos (8 no total, na ordem dos tiers).
static func all_ids() -> Array[String]:
	var result: Array[String] = []
	for tier_id: String in ["t1", "t2", "t3"]:
		for item_id: Variant in TIER_SETS.get(tier_id, []):
			result.append(str(item_id))
	return result

## Tier (t1/t2/t3) de um id único; "" se o id não for de variação única.
static func tier_of(item_id: String) -> String:
	for tier_id: String in TIER_SETS.keys():
		if (TIER_SETS[tier_id] as Array).has(item_id):
			return tier_id
	return ""

## Ids únicos de um torneio (cópia).
static func tier_set(tier_id: String) -> Array[String]:
	var result: Array[String] = []
	for item_id: Variant in TIER_SETS.get(tier_id, []):
		result.append(str(item_id))
	return result

## O item de conteúdo (data/items.json) de uma variação única.
static func find(item_id: String) -> Dictionary:
	return ContentRepositoryScript.find_item(ContentRepositoryScript.load_items(), item_id)

## Próxima variação única a cair do tier, SEM REPETIR enquanto o jogador não
## tiver todas (anti-farm: nada de duplicata inútil). Devolve "" quando o
## conjunto inteiro já é do jogador.
static func pick_unique(tier_id: String, owned_ids: Array) -> String:
	for item_id: String in tier_set(tier_id):
		if not owned_ids.has(item_id):
			return item_id
	return ""

## Metadados de um efeito ({} se o id não existir).
static func effect_definition(effect_id: String) -> Dictionary:
	return EFFECTS.get(effect_id, {})

## Descrição legível do efeito (para a ficha do item).
static func effect_text(effect_id: String) -> String:
	var defn: Dictionary = effect_definition(effect_id)
	return str(defn.get("description", ""))

# --- Consultas de mecânica (o que cada efeito EQUIPADO faz de verdade) -------

static func _equipped(fighter, effect_id: String) -> bool:
	if fighter == null:
		return false
	if not ("unique_effects" in fighter):
		return false
	return (fighter.unique_effects as Array).has(effect_id)

## Adaga da Viúva: revida SEMPRE que apara (contra-ataque garantido).
static func always_counter(fighter) -> bool:
	return _equipped(fighter, "always_counter")

## Manto do Público: EXIBIR rende +50% e não deixa aberto.
static func exhibit_boost(fighter) -> bool:
	return _equipped(fighter, "exhibit_master")

## Elmo do Imperador: imune a Taunt.
static func taunt_immune(fighter) -> bool:
	return _equipped(fighter, "taunt_immune")

## Botas do Mensageiro: +0,15 de esquiva e sem teto de esquiva.
static func wind_dodge(fighter) -> bool:
	return _equipped(fighter, "wind_dodge")

static func dodge_bonus(fighter) -> float:
	return WIND_DODGE_BONUS if wind_dodge(fighter) else 0.0

static func ignores_dodge_cap(fighter) -> bool:
	return wind_dodge(fighter)

## Luvas do Carrasco: +15% de crítico.
static func crit_bonus(fighter) -> float:
	return CRIT_MASTER_BONUS if _equipped(fighter, "crit_master") else 0.0

## Gládio do Grande Gladiador: +20% de dano corpo a corpo.
static func melee_damage_bonus(fighter) -> float:
	return CHAMPION_FURY_BONUS if _equipped(fighter, "champion_fury") else 0.0

## Pingente do Sortudo: +25% de ouro em cada vitória.
static func gold_multiplier(fighter) -> float:
	return LUCKY_GOLD_MULTIPLIER if _equipped(fighter, "lucky_gold") else 1.0

## Coração de Bronze: sobrevive ao primeiro golpe fatal de cada luta.
static func second_wind(fighter) -> bool:
	return _equipped(fighter, "second_wind")
