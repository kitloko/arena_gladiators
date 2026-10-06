class_name FightResult
extends RefCounted

## Resumo de uma luta, preenchido pela arena e exibido na tela de resultado.
## Apenas guarda dados — não contém regras nem interface.

var victory: bool = false
var rounds: int = 1
var hits: int = 0
var criticals: int = 0
var damage_dealt: int = 0
var damage_taken: int = 0
var gold: int = 0
var experience: int = 0
var leveled_up: bool = false
var opponent_name: String = ""
var boss: bool = false
var campaign_cleared: bool = false
var campaign_lost: bool = false
var penalty: int = 0
var tournament: bool = false
var prize: int = 0

func _init(p_victory: bool = false, p_rounds: int = 1) -> void:
	victory = p_victory
	rounds = p_rounds
