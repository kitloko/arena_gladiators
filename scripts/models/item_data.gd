class_name ItemData
extends RefCounted

var id: String
var display_name: String
var slot: String
var price: int
var attack_bonus: int
var defense_bonus: int

func _init(values: Dictionary = {}) -> void:
	id = str(values.get("id", "unnamed_item"))
	display_name = str(values.get("display_name", "Item"))
	slot = str(values.get("slot", "weapon"))
	price = int(values.get("price", 0))
	attack_bonus = int(values.get("attack_bonus", 0))
	defense_bonus = int(values.get("defense_bonus", 0))
