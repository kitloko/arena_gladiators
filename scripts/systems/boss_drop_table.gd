class_name BossDropTable
extends RefCounted

## TABELA DE DROP POR GRAU DE DIFICULDADE do boss (docs/PLANO_3.0.md §5.3).
##
## Cada boss tem um grau de dificuldade (1 a 5 ⭐). O grau define a TABELA base
## (abaixo, exatamente como no plano). O TIER do torneio empurra a tabela para
## cima e o RANK do jogador tem peso pequeno (para não virar farm de lendário no
## torneio pequeno). A chance de variação única (Lendário) é LIMITADA por
## torneio (anti-farm).
##
## Funções puras e determináveis por seed: os testes medem as proporções reais e
## comparam com o plano (tests/run_systems_test.gd).
##
##   | Grau | Comum | Incomum | Raro | Épico | Lendário |
##   |  1   |  55%  |   25%   | 12%  |   6%  |    2%    |
##   |  2   |  40%  |   28%   | 18%  |  10%  |    4%    |
##   |  3   |  28%  |   30%   | 24%  |  13%  |    5%    |
##   |  4   |  15%  |   28%   | 30%  |  19%  |    8%    |
##   |  5   |  10%  |   22%   | 32%  |  26%  |   10%    |

const RARITY_ORDER: Array[String] = ["comum", "incomum", "raro", "epico", "lendario"]
const MIN_GRADE := 1
const MAX_GRADE := 5

## A tabela do plano, linha a linha: grau -> {raridade: %}. Soma 100 em cada linha.
const GRADE_ROWS := {
	1: {"comum": 55, "incomum": 25, "raro": 12, "epico": 6, "lendario": 2},
	2: {"comum": 40, "incomum": 28, "raro": 18, "epico": 10, "lendario": 4},
	3: {"comum": 28, "incomum": 30, "raro": 24, "epico": 13, "lendario": 5},
	4: {"comum": 15, "incomum": 28, "raro": 30, "epico": 19, "lendario": 8},
	5: {"comum": 10, "incomum": 22, "raro": 32, "epico": 26, "lendario": 10},
}

## Empurrão do TIER do torneio (índice 0 = Menor, 1 = Maior, 2 = Grande): pontos
## retirados do Comum e distribuídos para raro/épico/lendário. O Menor não
## empurra (é a régua do plano).
const TIER_PUSH := [0, 8, 16]
## Peso PEQUENO do rank do jogador no empurrão (por faixa de rank, com teto).
const RANK_PUSH_PER_TIER := 1
const RANK_PUSH_MAX := 4
## Teto de LENDÁRIO (variação única) por torneio — anti-farm. O excesso vira Épico.
const UNIQUE_CAP_BY_TIER := [4, 7, 10]
## Piso do Comum (o empurrão nunca apaga a raridade básica).
const COMMON_FLOOR := 5

## Rótulo e cor de cada raridade (inclui a variação única).
const RARITY_LABELS := {
	"comum": "Comum", "incomum": "Incomum", "raro": "Raro", "epico": "Épico", "lendario": "Lendário",
}
const RARITY_COLORS := {
	"comum": "b9b0be", "incomum": "79cf7b", "raro": "70b9e8", "epico": "c06ee0", "lendario": "f5c451",
}

static func clamp_grade(grade: int) -> int:
	return clampi(grade, MIN_GRADE, MAX_GRADE)

## A linha EXATA do plano para um grau (sem empurrão de tier nem de rank).
static func weights_for_grade(grade: int) -> Dictionary:
	return (GRADE_ROWS[clamp_grade(grade)] as Dictionary).duplicate()

## Teto de lendário de um torneio pelo índice do tier.
static func unique_cap(tier_index: int) -> int:
	return int(UNIQUE_CAP_BY_TIER[clampi(tier_index, 0, UNIQUE_CAP_BY_TIER.size() - 1)])

## Tabela EFETIVA do jogo: linha do grau + empurrão do tier + peso pequeno do
## rank + teto de lendário por torneio. Sempre soma 100.
static func effective_weights(grade: int, tier_index: int = 0, rank_tier: int = 0) -> Dictionary:
	var w := weights_for_grade(grade)
	var push: int = int(TIER_PUSH[clampi(tier_index, 0, TIER_PUSH.size() - 1)])
	push += clampi(rank_tier * RANK_PUSH_PER_TIER, 0, RANK_PUSH_MAX)
	if push > 0:
		var moved := mini(push, maxi(0, int(w["comum"]) - COMMON_FLOOR))
		w["comum"] = int(w["comum"]) - moved
		w["raro"] = int(w["raro"]) + int(round(float(moved) * 0.45))
		w["epico"] = int(w["epico"]) + int(round(float(moved) * 0.35))
		w["lendario"] = int(w["lendario"]) + int(round(float(moved) * 0.20))
	# Anti-farm: teto de variação única por torneio (o excesso vira Épico).
	var cap := unique_cap(tier_index)
	if int(w["lendario"]) > cap:
		var excess := int(w["lendario"]) - cap
		w["lendario"] = cap
		w["epico"] = int(w["epico"]) + excess
	# Renormaliza para exatamente 100 (arredondamentos).
	var total := 0
	for rarity_id: String in RARITY_ORDER:
		total += int(w[rarity_id])
	w["comum"] = int(w["comum"]) + (100 - total)
	return w

## Sorteia UMA raridade pela linha EXATA do plano (sem tier/rank/teto). É a régua
## que os testes medem contra a tabela do §5.3.
static func sample_base_rarity(grade: int, rng: RandomNumberGenerator = null) -> String:
	return _sample(weights_for_grade(grade), rng)

## Sorteia UMA raridade pela tabela EFETIVA do jogo (tier + rank + teto).
static func sample_drop_rarity(grade: int, tier_index: int = 0, rank_tier: int = 0, rng: RandomNumberGenerator = null) -> String:
	return _sample(effective_weights(grade, tier_index, rank_tier), rng)

static func _sample(weights: Dictionary, rng: RandomNumberGenerator = null) -> String:
	var roll := 0
	if rng != null:
		roll = rng.randi_range(1, 100)
	else:
		roll = randi_range(1, 100)
	var accumulated := 0
	for rarity_id: String in RARITY_ORDER:
		accumulated += int(weights.get(rarity_id, 0))
		if roll <= accumulated:
			return rarity_id
	return RARITY_ORDER[RARITY_ORDER.size() - 1]

## Probabilidade (%) de uma raridade na linha exata do plano.
static func probability_for(grade: int, rarity_id: String) -> float:
	return float(weights_for_grade(grade).get(rarity_id, 0))

## Soma de raro + épico + lendário de um grau (monotônica: grau maior = melhor).
static func high_rarity_share(grade: int) -> int:
	var w := weights_for_grade(grade)
	return int(w["raro"]) + int(w["epico"]) + int(w["lendario"])

## Grau como estrelas cheias/vazias (1 a 5) para exibir na apresentação/arena.
## ATENÇÃO: usar "★"/"☆" (U+2605/U+2606) e NUNCA "⭐" (emoji) — a fonte padrão do
## Godot não tem o emoji e ele sai como retângulo vazio. Medido com qa/qa_glyphs.tscn.
static func stars(grade: int) -> String:
	var filled := clamp_grade(grade)
	var text := ""
	for i in MAX_GRADE:
		text += "★" if i < filled else "☆"
	return text

static func rarity_label(rarity_id: String) -> String:
	return str(RARITY_LABELS.get(rarity_id, "Comum"))

static func rarity_color(rarity_id: String) -> String:
	return str(RARITY_COLORS.get(rarity_id, "b9b0be"))

## Índice da raridade na ordem comum..lendário (para pisos de raridade).
static func rarity_index(rarity_id: String) -> int:
	return RARITY_ORDER.find(rarity_id)
