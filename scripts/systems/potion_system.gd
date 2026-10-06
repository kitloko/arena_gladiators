class_name PotionSystem
extends RefCounted

## POÇÕES DE USO EM COMBATE (item 6 do plano 2.0).
##
## Consumíveis comprados na loja e guardados na bolsa. Cada poção é usada DURANTE
## a luta como UMA AÇÃO: gasta o turno (o inimigo age depois) e CONSOME o item.
## Fora da luta não há botão de poção — a poção é remédio de ringue, não cura
## grátis no meio da cidade (a cidade tem o médico pago para isso).
##
## Tipos (o campo `effect` do item manda):
##  - heal:       recupera vida;
##  - armour:     recupera armadura;
##  - buff_str:   +STR por N turnos;
##  - buff_agi:   +AGI por N turnos;
##  - cure_injury: cura UM ferimento.
##
## Limite de mochila: no máximo MAX_POTIONS consumíveis na bolsa (comprar além
## disso é recusado — a bolsa tem espaço, mas a mochila de combate não é infinita).

const MAX_POTIONS := 5

const InjurySystemScript := preload("res://scripts/systems/injury_system.gd")

const EFFECTS := ["heal", "armour", "buff_str", "buff_agi", "cure_injury"]

static func max_potions() -> int:
	return MAX_POTIONS

static func is_consumable(item: Dictionary) -> bool:
	return str(item.get("slot", "")) == "consumable"

static func effect_of(item: Dictionary) -> String:
	return str(item.get("effect", ""))

## Quantas poções o lutador carrega (consumíveis na bolsa).
static func count(player) -> int:
	if player == null or not player.has_method("bag_items"):
		return 0
	var total := 0
	for item: Dictionary in player.bag_items():
		if is_consumable(item):
			total += 1
	return total

## Ainda cabe esta poção na mochila?
static func can_carry(player, item: Dictionary) -> bool:
	if player == null:
		return false
	if not is_consumable(item):
		return false
	return count(player) < MAX_POTIONS

## Poções da bolsa do lutador (só consumíveis).
static func potions(player) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if player == null or not player.has_method("bag_items"):
		return result
	for item: Dictionary in player.bag_items():
		if is_consumable(item):
			result.append(item)
	return result

## Usa uma poção: APLICA o efeito no lutador e devolve {ok, effect, amount,
## turns, message}. NÃO remove o item — quem remove é o GameState (dono da
## bolsa), para não haver duas versões da mesma regra.
static func use(player, item: Dictionary) -> Dictionary:
	if player == null or item.is_empty():
		return {"ok": false, "reason": "poção inválida"}
	if not is_consumable(item):
		return {"ok": false, "reason": "item não é poção"}
	var effect := effect_of(item)
	var amount := int(item.get("amount", 0))
	var turns := int(item.get("turns", 0))
	var message := ""
	match effect:
		"heal":
			var before := int(player.health)
			player.health = mini(int(player.max_health), int(player.health) + amount)
			var gained := int(player.health) - before
			message = "recupera %d de vida" % gained
		"armour":
			var before_armour := int(player.armour)
			player.armour = mini(int(player.max_armour), int(player.armour) + amount)
			message = "recupera %d de armadura" % (int(player.armour) - before_armour)
		"buff_str":
			player.add_buff("strength", amount, turns)
			message = "+%d FOR por %d turnos" % [amount, turns]
		"buff_agi":
			player.add_buff("agility", amount, turns)
			message = "+%d AGI por %d turnos" % [amount, turns]
		"cure_injury":
			var cured: Dictionary = InjurySystemScript.cure_one(player)
			if not bool(cured.get("ok", false)):
				return {"ok": false, "reason": "não há ferimento para curar"}
			message = "cura %s" % InjurySystemScript.describe(cured.get("cured", {}))
		_:
			return {"ok": false, "reason": "efeito desconhecido"}
	return {"ok": true, "effect": effect, "amount": amount, "turns": turns, "message": message}

## Rótulo curto do efeito, usado na lista da mochila em combate.
static func effect_label(item: Dictionary) -> String:
	match effect_of(item):
		"heal":
			return "cura %d de vida" % int(item.get("amount", 0))
		"armour":
			return "recupera %d de armadura" % int(item.get("amount", 0))
		"buff_str":
			return "+%d FOR por %d turnos" % [int(item.get("amount", 0)), int(item.get("turns", 0))]
		"buff_agi":
			return "+%d AGI por %d turnos" % [int(item.get("amount", 0)), int(item.get("turns", 0))]
		"cure_injury":
			return "cura 1 ferimento"
	return "efeito"
