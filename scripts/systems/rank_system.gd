class_name RankSystem
extends RefCounted

## RANK e KD do gladiador (item I do plano 2.0) — SEPARADO do nível.
##
## FÓRMULA EXATA (documentada aqui; é a régua que os testes reproduzem):
##
## 1) Avaliação de um adversário ("rating"): o inimigo não carrega pontos de rank,
##    então o rating dele é derivado do NÍVEL, do TIER e de ser (ou não) chefe:
##        rating(oponente) = nível × RANK_PER_LEVEL
##                         + (tier − 1) × RANK_PER_TIER
##                         + (300 se for chefe)
##    com RANK_PER_LEVEL = 250 e RANK_PER_TIER = 120.
##
## 2) Ganho/perda por luta (Elo com escala reduzida para a luta curta):

##        esperado = 1 / (1 + 10^((rating_oponente − pontos_do_jogador) / SCALE))
##        vitória  → ganho    = round(K × (1 − esperado))          (piso 0)
##        derrota  → perda    = max(LOSS_MIN, round(K × esperado))  (sempre ≥ LOSS_MIN)
##    com SCALE = 250, K = 60 e LOSS_MIN = 5.
##
##    Consequências (é o que a spec pede):
##     - vencer alguém mais FORTE (rating acima) rende muito (perto de K = 60);
##     - vencer alguém MUITO mais fraco rende ~0 (o ganho arredonda para 0 e o
##       ranking para de subir — é o que mata o farm);
##     - perder SEMPRE tira pontos (piso LOSS_MIN), e perder para alguém de rank
##       bem MENOR dói mais (esperado ≈ 1 → perda ≈ K = 60).
##
## 3) Os PONTOS nunca ficam negativos (piso 0). Quem cai abaixo do piso de uma
##    faixa REBAIXA de título (resolvido por tier_index; `demoted`).
##
## 4) Faixas e requisitos de acesso e modificadores de arena vivem em
##    data/ranks.json (fora da UI) e são lidos aqui.

const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")

## Parâmetros da régua (ver cabeçalho).
const RANK_PER_LEVEL := 250
const RANK_PER_TIER := 120
const BOSS_BONUS := 300
const SCALE := 250.0
const K_FACTOR := 60.0
const LOSS_MIN := 5

## Faixas padrão (só usadas se data/ranks.json não carregar): mesmas do JSON.
const FALLBACK_TIERS := [
	{"id": "areia", "title": "Areia", "min": 0},
	{"id": "pedra", "title": "Pedra", "min": 200},
	{"id": "ferro", "title": "Ferro", "min": 500},
	{"id": "aco", "title": "Aço", "min": 900},
	{"id": "prata", "title": "Prata", "min": 1500},
	{"id": "ouro", "title": "Ouro", "min": 2300},
	{"id": "campeao", "title": "Campeão", "min": 3500},
	{"id": "lenda", "title": "Lenda", "min": 5000},
]

static var _ranks: Dictionary = {}

static func _data() -> Dictionary:
	if _ranks.is_empty():
		_ranks = ContentRepositoryScript.load_ranks()
		if _ranks.is_empty():
			_ranks = {"tiers": FALLBACK_TIERS, "access": [], "arena_bands": []}
	return _ranks

# --- Faixas e títulos -------------------------------------------------------

static func tiers() -> Array:
	return _data().get("tiers", FALLBACK_TIERS)

## Índice da faixa para uma quantidade de pontos (0 = Areia, a mais baixa).
static func tier_index_for(points: int) -> int:
	var index := 0
	var list: Array = tiers()
	for i in list.size():
		if points >= int(dict_of(list[i]).get("min", 0)):
			index = i
		else:
			break
	return index

## Dicionário da faixa em que o jogador está.
static func tier_for(points: int) -> Dictionary:
	var list: Array = tiers()
	return dict_of(list[tier_index_for(points)])

static func title_for(points: int) -> String:
	return str(tier_for(points).get("title", "Areia"))

## Próxima faixa ({} se já está na última).
static func next_tier(points: int) -> Dictionary:
	var list: Array = tiers()
	var index := tier_index_for(points)
	if index + 1 >= list.size():
		return {}
	return dict_of(list[index + 1])

## Pontos que faltam para a próxima faixa (0 se já está na última).
static func points_to_next(points: int) -> int:
	var next := next_tier(points)
	if next.is_empty():
		return 0
	return maxi(0, int(next.get("min", 0)) - points)

# --- Avaliação do adversário e ganho/perda ---------------------------------

static func opponent_rating(level: int, tier: int, is_boss: bool = false) -> int:
	var rating := maxi(0, level) * RANK_PER_LEVEL + maxi(0, tier - 1) * RANK_PER_TIER
	if is_boss:
		rating += BOSS_BONUS
	return rating

## Rating de um lutador (usa level/enemy_tier/boss do GladiatorData do inimigo).
static func opponent_rating_for(enemy) -> int:
	if enemy == null:
		return 0
	return opponent_rating(int(enemy.level), int(enemy.enemy_tier), bool(enemy.boss))

static func expected_score(points: int, opponent_rating_value: int) -> float:
	return 1.0 / (1.0 + pow(10.0, float(opponent_rating_value - points) / SCALE))

## Pontos ganhos ao VENCER (piso 0 — vencer muito mais fraco rende ~0).
static func win_gain(points: int, opponent_rating_value: int) -> int:
	var expected := expected_score(points, opponent_rating_value)
	return maxi(0, roundi(K_FACTOR * (1.0 - expected)))

## Pontos PERDIDOS ao ser derrotado (sempre ≥ LOSS_MIN; perder para rank menor dói mais).
static func loss_penalty(points: int, opponent_rating_value: int) -> int:
	var expected := expected_score(points, opponent_rating_value)
	return maxi(LOSS_MIN, roundi(K_FACTOR * expected))

## Resolve o efeito de UMA luta sem mutar nada.
## Devolve {delta, points, old_title, new_title, old_tier, new_tier, promoted, demoted}.
static func resolve_result(points: int, opponent_rating_value: int, victory: bool) -> Dictionary:
	var old_tier := tier_index_for(points)
	var delta := win_gain(points, opponent_rating_value) if victory else -loss_penalty(points, opponent_rating_value)
	var new_points := maxi(0, points + delta)
	var new_tier := tier_index_for(new_points)
	return {
		"delta": new_points - points,
		"points": new_points,
		"old_title": title_for(points),
		"new_title": title_for(new_points),
		"old_tier": old_tier,
		"new_tier": new_tier,
		"promoted": new_tier > old_tier,
		"demoted": new_tier < old_tier,
	}

## Aplica o resultado de UMA luta a um GladiatorData (rank/KD) e devolve o
## antes/depois. Só mexe em pontos/vitórias/derrotas; nada de UI ou economia.
static func apply_to(gladiator, opponent_rating_value: int, victory: bool) -> Dictionary:
	if gladiator == null:
		return {}
	var info: Dictionary = resolve_result(int(gladiator.rank_points), opponent_rating_value, victory)
	gladiator.rank_points = int(info.get("points", gladiator.rank_points))
	if victory:
		gladiator.wins += 1
	else:
		gladiator.losses += 1
	return info

# --- Acesso por rank (torneios) --------------------------------------------

static func access_requirements() -> Array:
	return _data().get("access", [])

## Pontos mínimos exigidos por um destino (id do destino; 0 = livre).
static func requirement_for(dest_id: String) -> int:
	for entry: Variant in access_requirements():
		var info := dict_of(entry)
		if str(info.get("id", "")) == dest_id:
			return int(info.get("min", 0))
	return 0

static func meets(points: int, dest_id: String) -> bool:
	return points >= requirement_for(dest_id)

## Motivo do bloqueio ("" se liberado): "Precisa de rank Aço — você está em Ferro".
static func lock_reason(points: int, dest_id: String) -> String:
	var required := requirement_for(dest_id)
	if points >= required:
		return ""
	return "Precisa de rank %s — você está em %s" % [title_for(required), title_for(points)]

# --- Arenas por faixa (ideia 9) --------------------------------------------

static func arena_bands() -> Array:
	return _data().get("arena_bands", [])

static func arena_band_for(points: int) -> Dictionary:
	var chosen: Dictionary = {}
	var list: Array = arena_bands()
	if list.is_empty():
		return {"id": "areia", "title": "Arenas de Areia", "min": 0, "gold_multiplier": 1.0, "enemy_level_bonus": 0, "tint": "ffffff", "texture": "arena_background"}
	for entry: Variant in list:
		var info := dict_of(entry)
		if points >= int(info.get("min", 0)):
			chosen = info
		else:
			break
	if chosen.is_empty():
		chosen = dict_of(list[0])
	return chosen

# --- Utilidades -------------------------------------------------------------

## Aceita Dictionary ou não; evita cast arriscado em conteúdo do JSON.
static func dict_of(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}
