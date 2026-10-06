class_name BettingSystem
extends RefCounted

## APOSTAS NO PRÓPRIO COMBATE (item 5 do plano 2.0).
##
## Antes de entrar na arena o jogador aposta ouro em si mesmo. A ODD sai do
## Índice de Poder dos dois: quanto mais fraco você é em relação ao adversário,
## MAIOR a odd — e maior o prêmio se ganhar. Ganhar paga aposta × odd; perder
## queima a aposta.
##
## A conta da odd é honesta de propósito: o "livro" (a casa de apostas) fica com
## uma margem e a odd é oferecida em cima da probabilidade real de vitória,
## estimada pela diferença de poder. Assim o valor ESPERADO de uma aposta é
## sempre negativo para o jogador — não existe "imprimir dinheiro".
##
## TRAVAS ANTI-IMPRESSORA (é regra):
##  - teto de aposta por NÍVEL e por OURO (`max_bet`): nunca se aposta mais do que
##    se tem, nem mais do que `BET_BASE + nível×BET_PER_LEVEL`;
##  - odd MÁXIMA limitada (`MAX_ODD`) e mínima (`MIN_ODD`);
##  - a probabilidade estimada é limitada a [0,05, 0,90], então mesmo o favorito
##    recebe uma odd que paga menos do que a certeza (EV < 0 em toda a faixa);
##  - o ganho LÍQUIDO máximo por luta é `max_bet(nível) × (MAX_ODD − 1)`, medido em
##    teste contra a faixa de ouro por luta já aceita pelo balanceamento.
##
## Sistema puro (sem interface e sem autoload).

const MIN_ODD := 1.05
## Odd máxima presa também ao ORÇAMENTO da luta: com MAX_ODD = 2,00 o ganho
## líquido teórico máximo (max_bet × 1,00) nunca passa da recompensa-base da luta
## do mesmo nível — a aposta não rende mais que a própria luta (nem com o teto).
const MAX_ODD := 2.00
const BOOK_MARGIN := 0.90
## Cada ponto de Índice de Poder de vantagem move a probabilidade estimada.
const POWER_SLOPE := 0.004
const PROB_MIN := 0.05
const PROB_MAX := 0.90
## Teto de aposta: base + ganho por nível (limitado também pelo ouro do bolso).
const BET_BASE := 20
const BET_PER_LEVEL := 8

## Probabilidade estimada de vitória do jogador a partir dos Índices de Poder.
static func win_probability(player_power: int, enemy_power: int) -> float:
	return clampf(0.5 + float(player_power - enemy_power) * POWER_SLOPE, PROB_MIN, PROB_MAX)

## Odd oferecida: 1/probabilidade com a margem da casa, presa na faixa [MIN, MAX].
static func odd_for(player_power: int, enemy_power: int) -> float:
	var probability := win_probability(player_power, enemy_power)
	var odd := (1.0 / probability) * BOOK_MARGIN
	return clampf(odd, MIN_ODD, MAX_ODD)

## Teto de aposta deste lutador: por nível e por ouro (o menor dos dois).
static func max_bet(player) -> int:
	if player == null:
		return 0
	var by_level := BET_BASE + int(player.level) * BET_PER_LEVEL
	return maxi(0, mini(int(player.gold), by_level))

## Teto TEÓRICO (por nível, ignorando o ouro) do ganho LÍQUIDO de uma aposta —
## usado para provar que a aposta não vira impressora de dinheiro.
static func max_theoretical_net(level: int) -> int:
	var stake := BET_BASE + maxi(1, level) * BET_PER_LEVEL
	return int(round(float(stake) * (MAX_ODD - 1.0)))

## Pagamento bruto de uma aposta vencedora (já inclui a aposta de volta).
static func payout(stake: int, odd: float) -> int:
	return maxi(0, int(round(float(maxi(0, stake)) * maxf(MIN_ODD, odd))))

## Lucro líquido de uma aposta vencedora (pagamento − aposta).
static func net_win(stake: int, odd: float) -> int:
	return payout(stake, odd) - maxi(0, stake)

## Valor ESPERADO por ouro apostado, com a odd da probabilidade estimada.
## Negativo em toda a faixa — a prova de que a aposta não é impressora.
static func expected_value(player_power: int, enemy_power: int) -> float:
	var probability := win_probability(player_power, enemy_power)
	return probability * odd_for(player_power, enemy_power) - 1.0
