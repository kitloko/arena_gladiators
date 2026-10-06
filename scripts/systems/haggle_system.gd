class_name HaggleSystem
extends RefCounted

## PECHINCHA (item 4 do plano 2.0).
##
## Antes de comprar, o jogador pode tentar PECHINCHAR um item. Usa CARISMA (o
## atributo da barganha) e SORTE (o empurrãozinho de última hora):
##
##   chance de sucesso = clamp(0.40 + CHA×0,012 + SOR×0,006, 0,05, 0,95)
##   desconto pedido   = clamp(CHA×0,010 + SOR×0,005, 0, 0,35)
##
## REGRAS ANTI-ABUSO (é regra, não detalhe):
##  - cada item só pode ser pechinchado UMA vez (o registro vive no lutador e vai
##    para o save: não existe "tentar de novo até dar certo");
##  - FALHAR TRAVA o item: o comerciante percebe a choradeira e aquele item só
##    pode ser comprado pelo preço normal — nunca mais aceita pechincha;
##  - o desconto do item NUNCA passa de MAX_DISCOUNT (0,35), somando a pechincha
##    com o pequeno desconto de mercado que já existia (EconomySystem.shop_discount,
##    ≤ 0,15). Quem barganha bem vê a barganha valer de verdade: o teto de 0,35 é
##    do TOTAL, não do mercado.
##
## Sistema puro; o estado por item fica em GladiatorData.haggle_marks.

const MAX_DISCOUNT := 0.35
const SUCCESS_BASE := 0.40
const SUCCESS_CHA_WEIGHT := 0.012
const SUCCESS_SOR_WEIGHT := 0.006
const SUCCESS_MIN := 0.05
const SUCCESS_MAX := 0.95
## Desconto EXTRA conquistado pela pechincha (a fórmula pedida, presa no teto).
const BONUS_CHA_WEIGHT := 0.010
const BONUS_SOR_WEIGHT := 0.005
const BONUS_MAX := 0.35

## Desconto total que o jogador pode exibir (mercado + pechincha cheia), no teto.
static func potential_discount(player) -> float:
	if player == null:
		return 0.0
	return clampf(float(EconomySystem.shop_discount(player)) + bonus_max(player), 0.0, MAX_DISCOUNT)

## Desconto passivo de mercado já existente (CHA/SOR), para exibição.
static func market_discount(player) -> float:
	if player == null:
		return 0.0
	return clampf(float(EconomySystem.shop_discount(player)), 0.0, MAX_DISCOUNT)

## Teto do desconto extra da pechincha com este lutador.
static func bonus_max(player) -> float:
	if player == null:
		return 0.0
	return clampf(float(player.charisma) * BONUS_CHA_WEIGHT + float(player.luck) * BONUS_SOR_WEIGHT, 0.0, BONUS_MAX)

## Chance de a pechincha dar certo (exibida na tela antes de tentar).
static func success_chance(player) -> float:
	if player == null:
		return 0.0
	var chance := SUCCESS_BASE + float(player.charisma) * SUCCESS_CHA_WEIGHT + float(player.luck) * SUCCESS_SOR_WEIGHT
	return clampf(chance, SUCCESS_MIN, SUCCESS_MAX)

## Registro da pechincha de um item no lutador: {result, discount} ou {}.
static func mark_for(player, item_id: String) -> Dictionary:
	if player == null or item_id == "" or not ("haggle_marks" in player):
		return {}
	return player.haggle_marks.get(item_id, {})

static func attempted(player, item_id: String) -> bool:
	return not mark_for(player, item_id).is_empty()

static func succeeded(player, item_id: String) -> bool:
	return str(mark_for(player, item_id).get("result", "")) == "won"

## Desconto EXTRA já conquistado neste item (0,0 se não barganhou ou falhou).
static func discount_for_item(player, item_id: String) -> float:
	var mark := mark_for(player, item_id)
	if str(mark.get("result", "")) != "won":
		return 0.0
	return clampf(float(mark.get("discount", 0.0)), 0.0, BONUS_MAX)

## Tenta pechinchar um item. Marca o resultado no lutador mesmo em caso de falha
## (a falha TRAVA o item). Devolve {ok, success, discount, locked, chance, reason}.
static func attempt(player, item_id: String) -> Dictionary:
	if player == null:
		return {"ok": false, "success": false, "discount": 0.0, "locked": false, "reason": "sem lutador"}
	if item_id == "":
		return {"ok": false, "success": false, "discount": 0.0, "locked": false, "reason": "item inválido"}
	if attempted(player, item_id):
		return {"ok": false, "success": false, "discount": 0.0, "locked": false, "reason": "este item já foi pechinchado"}
	var chance := success_chance(player)
	var success := randf() < chance
	var discount := bonus_max(player) if success else 0.0
	player.haggle_marks[item_id] = {"result": "won" if success else "lost", "discount": discount}
	return {"ok": true, "success": success, "discount": discount, "locked": not success, "chance": chance, "reason": ""}

## Desconto TOTAL (mercado + pechincha conquistada) de um item, já no teto.
static func total_discount(player, item_id: String) -> float:
	return clampf(market_discount(player) + discount_for_item(player, item_id), 0.0, MAX_DISCOUNT)
