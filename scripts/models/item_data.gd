class_name ItemData
extends RefCounted

## Item de conteúdo. Bônus conforme a peça: atributos STR/ATT/DEF/AGI/VIT/CHA/SOR
## e/ou 'armour' (peças de proteção: pool de armadura separado da vida).

var id: String
var display_name: String
var slot: String
var price: int
var strength_bonus: int
var attack_bonus: int
var defence_bonus: int
var agility_bonus: int
var vitality_bonus: int
var charisma_bonus: int
var luck_bonus: int
var armour: int

func _init(values: Dictionary = {}) -> void:
	id = str(values.get("id", "unnamed_item"))
	display_name = str(values.get("display_name", "Item"))
	slot = str(values.get("slot", "weapon"))
	price = int(values.get("price", 0))
	strength_bonus = int(values.get("strength_bonus", 0))
	attack_bonus = int(values.get("attack_bonus", 0))
	defence_bonus = int(values.get("defence_bonus", 0))
	agility_bonus = int(values.get("agility_bonus", 0))
	vitality_bonus = int(values.get("vitality_bonus", 0))
	charisma_bonus = int(values.get("charisma_bonus", 0))
	luck_bonus = int(values.get("luck_bonus", 0))
	armour = int(values.get("armour", 0))
