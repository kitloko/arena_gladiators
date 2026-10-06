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
## Felicidade do público no fim da luta e o multiplicador de ouro resultante
## (item H): ×1,0 a ×2,0. `quick_fight` = luta definida em até 3 ações (o
## multiplicador é 1,0: "o público nem viu a luta"). A tela de resultado exibe.
var crowd_happiness: int = 0
var crowd_multiplier: float = 1.0
var quick_fight: bool = false
## Itens ganhos na luta (prêmio de rodada de torneio e/ou item único do campeão).
var loot: Array[Dictionary] = []
## RANK/KD (item I): variação de rank desta luta, preenchida pela arena.
var rank_delta: int = 0
var rank_points: int = 0
var rank_title: String = ""
var rank_promoted: bool = false
var rank_demoted: bool = false
var rank_change_known: bool = false
## Faixa de arena usada nesta luta (ideia 9): id + título.
var arena_band_id: String = ""
var arena_band_title: String = ""

func _init(p_victory: bool = false, p_rounds: int = 1) -> void:
	victory = p_victory
	rounds = p_rounds
