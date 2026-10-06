class_name CrowdSystem
extends RefCounted

## Felicidade do público (item H do plano 2.0).
##
## A barra vai de 0 a 100% e fica no topo da tela de luta. Ela começa conforme o
## CARISMA dos dois lutadores e é movida por EVENTOS da luta (acertos, críticos,
## revidar, levar golpe, erro, defesa, recuo, dormir, exibição). No fim da luta a
## felicidade final vira um multiplicador de ouro (×1,0 a ×2,0) — mas luta
## definida em até 3 ações do jogador não multiplica ("o público nem viu a luta").
##
## TRAVAS ANTI-EXPLOIT (é regra, não detalhe — a barra multiplica dinheiro):
##  - teto de 100 com queda contínua: toda rodada normal custa 1 ponto de tédio,
##    então não existe "parado no máximo";
##  - repetição rende cada vez menos: EXIBIR cai de +8 a -5 e defender/recuar em
##    sequência somam uma penalidade crescente;
##  - luta fria (ninguém perde vida) gera vaias crescentes (-2, -4, -6...);
##  - o multiplicador vale UMA vez, no fim, e nunca passa de ×2,0.
##
## Estes números estão em docs/PLANO_2.0.md §8. O sistema é puro (sem interface e
## sem autoload) para os testes consumirem exatamente a mesma regra da arena.

const MIN_VALUE := 0
const MAX_VALUE := 100

## Início: 30 + (CHA do jogador + CHA do inimigo) × 1,5, com TETO de 70.
const START_BASE := 30
const START_CHA_WEIGHT := 1.5
const START_CAP := 70
## Luta contra chefe começa empolgada: PISO de 60.
const BOSS_FLOOR := 60

## ARENA MAIS LOTADA (item I, etapa 3): quanto maior o RANK, mais gente no
## estádio. O rank eleva o INÍCIO da barra (+3 por faixa acima de Areia) e o TETO
## do início (+4 por faixa) e o TETO do multiplicador de ouro (+0,05 por faixa).
## A conta fica AQUI (fonte única) — a UI só lê initial_happiness()/reward_multiplier().
const RANK_START_PER_TIER := 3
const RANK_START_CAP_PER_TIER := 4
const RANK_MULT_PER_TIER := 0.05
const RankSystemScript := preload("res://scripts/systems/rank_system.gd")

## Luta definida em até 3 ações do jogador não multiplica a recompensa.
const QUICK_FIGHT_ACTIONS := 3
const MULTIPLIER_MAX := 2.0

## Deltas fixos por evento (spec do item H §3).
const DELTA_HIT := 2
const DELTA_CRITICAL := 6
const DELTA_COUNTER := 5
const DELTA_TOOK_HIT := 3
const DELTA_DRAMA := 4
const DELTA_MISSED := -5
const DELTA_DEFEND := -3
const DELTA_RETREAT := -6
const DELTA_SLEEP := -4
const DELTA_POTION := -4
const DELTA_STALEMATE := -2
## Tédio por rodada "normal": garante que a barra não fique parada no teto.
const DELTA_ROUND_DECAY := -1
## Penalidade extra por repetir defesa/recuo na mesma sequência.
const STREAK_STEP := -2
## Vaias crescentes por rodada fria consecutiva (não há sangue na arena).
const COLD_EXTRA := -2
## EXIBIR: 1ª +8, 2ª +4, 3ª +2, da 4ª em diante -5 (o público se cansa).
const EXHIBIT_SEQUENCE := [8, 4, 2, -5]
## O ABERTO do EXIBIR: o inimigo ataca com +25% de precisão e a esquiva não vale.
const EXHIBIT_OPEN_ACCURACY := 0.25
## Vida abaixo desta fração e ainda atacando = drama (+4 no turno).
const DRAMA_HEALTH_FRACTION := 0.30

var happiness: int = 0
## Ações do jogador nesta luta (usado pelo corte de luta rápida).
var actions: int = 0
var boss: bool = false
## Pontos de rank do jogador nesta luta (arena mais lotada quanto maior o rank).
var rank_points: int = 0
## O jogador se exibiu: o inimigo ataca com bônus e a esquiva não vale.
var exposed: bool = false

var _exhibit_count: int = 0
var _defend_streak: int = 0
var _retreat_streak: int = 0
var _cold_streak: int = 0
var _events: Array[Dictionary] = []

func _init(player = null, enemy = null, is_boss: bool = false, p_rank_points: int = 0) -> void:
	boss = is_boss
	rank_points = p_rank_points
	happiness = initial_happiness(player, enemy, is_boss, p_rank_points)

## Valor inicial: clamp(30 + (CHA jogador + CHA inimigo) × 1,5, 0, 70); em luta
## contra chefe o início tem PISO de 60. O RANK eleva o início e o teto (arena
## mais lotada, item I): +3 de início e +4 de teto por faixa acima de Areia.
static func initial_happiness(player, enemy, is_boss: bool = false, rank_points: int = 0) -> int:
	var cha := 0
	if player != null:
		cha += int(player.charisma)
	if enemy != null:
		cha += int(enemy.charisma)
	var rank_tier := RankSystemScript.tier_index_for(rank_points)
	var value := int(round(START_BASE + float(cha) * START_CHA_WEIGHT)) + rank_tier * RANK_START_PER_TIER
	var cap := START_CAP + rank_tier * RANK_START_CAP_PER_TIER
	value = clampi(value, MIN_VALUE, cap)
	if is_boss:
		value = maxi(value, BOSS_FLOOR)
	return clampi(value, MIN_VALUE, MAX_VALUE)

func value() -> int:
	return happiness

## Registra UMA ação do jogador (o corte de luta rápida conta ações, não rodadas).
func register_action() -> void:
	actions += 1

func is_quick_fight() -> bool:
	return actions <= QUICK_FIGHT_ACTIONS

## Multiplicador de ouro da vitória: ×1,0 + felicidade/100, limitado a ×2,0.
## Luta definida em até 3 ações não multiplica (retorna 1,0). O RANK eleva o TETO
## (+0,05 por faixa acima de Areia): com rank alto a mesma felicidade paga mais.
func reward_multiplier(p_rank_points: int = 0) -> float:
	if is_quick_fight():
		return 1.0
	var rank_tier := rank_points_or(p_rank_points)
	var bonus := RANK_MULT_PER_TIER * float(rank_tier)
	var cap := MULTIPLIER_MAX + bonus
	return clampf(1.0 + float(happiness) / 100.0 + bonus, 1.0, cap)

## Usa o rank passado por argumento; se 0, cai para o rank guardado no sistema.
func rank_points_or(p_rank_points: int) -> int:
	if p_rank_points > 0:
		return RankSystemScript.tier_index_for(p_rank_points)
	return RankSystemScript.tier_index_for(rank_points)

## BÔNUS de item único (etapa 9, Manto do Público): soma felicidade extra ao
## evento (limitado ao teto) e registra como evento logável.
func apply_bonus(event_id: String, delta: int) -> Dictionary:
	return _commit(event_id, delta)

func clear_exposed() -> void:
	exposed = false

## Zera as sequências de defesa/recuo (o jogador fez outra coisa).
func reset_action_streaks() -> void:
	_defend_streak = 0
	_retreat_streak = 0

## Aplica UM evento nomeado e devolve {event, delta, applied, value, label}.
func apply_event(event_id: String) -> Dictionary:
	var delta := 0
	match event_id:
		"hit":
			delta = DELTA_HIT
			reset_action_streaks()
		"critical":
			delta = DELTA_CRITICAL
			reset_action_streaks()
		"counter":
			delta = DELTA_COUNTER
		"took_hit":
			delta = DELTA_TOOK_HIT
		"drama":
			delta = DELTA_DRAMA
		"missed":
			delta = DELTA_MISSED
			reset_action_streaks()
		"defend":
			# Defender e recuar são ações PASSIVAS: a sequência saturada cresce a
			# cada uma (mesmo alternando as duas), até outra ação zerar.
			_defend_streak += 1
			delta = DELTA_DEFEND + (_defend_streak - 1) * STREAK_STEP
		"retreat":
			_retreat_streak += 1
			delta = DELTA_RETREAT + (_retreat_streak - 1) * STREAK_STEP
		"sleep":
			delta = DELTA_SLEEP
			reset_action_streaks()
		"potion":
			# Tomar poção no meio da luta esfria a plateia: é remédio, não show.
			delta = DELTA_POTION
			reset_action_streaks()
		"exhibit":
			delta = _next_exhibit_delta()
			exposed = true
			reset_action_streaks()
		_:
			delta = 0
	return _commit(event_id, delta)

## Deriva os eventos de público de UM resultado de combate (mesma regra para a
## arena e para os testes, para não haver duas versões). Só o jogador gera
## acerto/crítico/erro; levar golpe vale para os dois lados (quem levou pode ser o
## jogador); revidar (contra-ataque) vale para os dois lados. Devolve as entries.
func apply_combat_result(result: Dictionary, player_is_attacker: bool) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if bool(result.get("dodged", false)) or not bool(result.get("hit", false)):
		# O jogador errou o ataque (esquiva do alvo, erro de precisão ou fora de
		# alcance): o público vaia.
		if player_is_attacker:
			entries.append(apply_event("missed"))
		return entries
	if player_is_attacker:
		entries.append(apply_event("critical" if bool(result.get("critical", false)) else "hit"))
	else:
		# Quem levou o golpe foi o jogador.
		entries.append(apply_event("took_hit"))
	if bool(result.get("countered", false)):
		entries.append(apply_event("counter"))
	return entries

## Fecha a rodada. Rodada FRIA (ninguém perdeu vida) gera vaias crescentes;
## rodada normal custa 1 ponto de tédio (a barra nunca fica parada no teto).
func end_round(cold_round: bool) -> Dictionary:
	if cold_round:
		_cold_streak += 1
		return _commit("cold", DELTA_STALEMATE + (_cold_streak - 1) * COLD_EXTRA)
	_cold_streak = 0
	return _commit("decay", DELTA_ROUND_DECAY)

## Texto de log da variação: "Público +6 (crítico) → 72%".
static func log_line(entry: Dictionary) -> String:
	var delta := int(entry.get("delta", 0))
	var sign_text := "+%d" % delta if delta >= 0 else "%d" % delta
	return "Público %s (%s) → %d%%" % [sign_text, str(entry.get("label", "")), int(entry.get("value", 0))]

static func label_for(event_id: String) -> String:
	match event_id:
		"hit":
			return "acerto"
		"critical":
			return "crítico"
		"counter":
			return "revidou"
		"took_hit":
			return "levou golpe"
		"drama":
			return "drama"
		"missed":
			return "errou"
		"defend":
			return "defesa firme"
		"retreat":
			return "recuou"
		"sleep":
			return "dormiu"
		"potion":
			return "bebeu poção"
		"exhibit":
			return "exibição"
		"exhibit_bonus":
			return "Manto do Público"
		"cold":
			return "arena fria"
		"decay":
			return "tédio"
	return event_id

func _next_exhibit_delta() -> int:
	var index: int = mini(_exhibit_count, EXHIBIT_SEQUENCE.size() - 1)
	_exhibit_count += 1
	return int(EXHIBIT_SEQUENCE[index])

func _commit(event_id: String, delta: int) -> Dictionary:
	var before := happiness
	happiness = clampi(happiness + delta, MIN_VALUE, MAX_VALUE)
	var entry := {
		"event": event_id,
		"delta": delta,
		"applied": happiness - before,
		"value": happiness,
		"label": label_for(event_id),
	}
	_events.append(entry)
	return entry
