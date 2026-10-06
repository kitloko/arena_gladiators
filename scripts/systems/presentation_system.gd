class_name PresentationSystem
extends RefCounted

## Apresentação do adversário (item F) + identidade dos inimigos (item G).
##
## Regras PURAS, sem interface: a tela de apresentação
## (scripts/ui/pre_fight_screen.gd) apenas desenha o que sai daqui, e os testes
## headless (tests/run_systems_test.gd) cobrem estas funções sem abrir o jogo.
##
## ÍNDICE DE PODER (fórmula documentada, item F):
##   poder = round( STR×2,0 + ATT×1,5 + DEF×1,5 + AGI×1,5 + VIT×1,0
##                  + CAR×0,5 + SOR×1,0 + NÍVEL×5,0 )
## STR, ATT, DEF e AGI têm os maiores pesos (definem dano, precisão, defesa e
## esquiva); VIT, CAR e SOR pesam menos (são atributos de suporte). O NÍVEL entra
## com peso 5 para que a experiência acumulada conte. Todos os pesos são POSITIVOS:
## mais atributo e mais nível = mais poder, sem exceção — é o que o teste verifica.
##
## PROVOCAÇÕES: cada template em data/enemies.json pode ter uma lista "taunts"; o
## sorteio é uniforme sobre a lista. Sem lista própria (inimigos procedurais da
## Arena Livre), cai na reserva genérica. O jogador também provoca (reserva dele).

const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")

## Pesos do Índice de Poder (ver cabeçalho).
const POWER_STR := 2.0
const POWER_ATT := 1.5
const POWER_DEF := 1.5
const POWER_AGI := 1.5
const POWER_VIT := 1.0
const POWER_CHA := 0.5
const POWER_LUK := 1.0
const POWER_LEVEL := 5.0

## Ordem canônica dos 7 atributos exibidos na comparação (id, sigla, título).
const ATTRIBUTES := [
	{"id": "strength", "short": "STR", "label": "Força"},
	{"id": "attack", "short": "ATT", "label": "Ataque"},
	{"id": "defence", "short": "DEF", "label": "Defesa"},
	{"id": "agility", "short": "AGI", "label": "Agilidade"},
	{"id": "vitality", "short": "VIT", "label": "Vitalidade"},
	{"id": "charisma", "short": "CAR", "label": "Carisma"},
	{"id": "luck", "short": "SOR", "label": "Sorte"},
]

## Reserva para inimigos SEM identidade própria (procedurais da Arena Livre).
const GENERIC_ENEMY_NICKNAME := "O Desafiante"
const GENERIC_ENEMY_DESCRIPTION := "Um lutador anônimo da arena, sem biografia conhecida."
const GENERIC_ENEMY_WEAKNESS := "Nenhum ponto fraco declarado."

## Provocações de reserva do JOGADOR (o jogador também provoca, item F).
const PLAYER_TAUNTS := [
	"Vou te usar de saco de treino!",
	"Guarde as desculpas para depois da luta.",
	"A arena vai comer você — e eu vou aplaudir.",
	"Segura a pose: é a última que você faz de pé.",
	"Cheguei; o espetáculo pode começar.",
]

## Provocações de reserva para inimigos SEM lista própria (item G).
const GENERIC_ENEMY_TAUNTS := [
	"Sua fama não passa de fumaça.",
	"A areia vai beber o seu sangue hoje.",
	"Você é só mais um nome na minha lista.",
	"Costumo terminar o que o público começa.",
	"Vamos ver se a sua coragem durou a viagem.",
]

## Índice de Poder de um lutador (soma ponderada dos 7 atributos + nível).
static func power_index(fighter) -> int:
	if fighter == null:
		return 0
	var total := 0.0
	total += float(fighter.strength) * POWER_STR
	total += float(fighter.attack) * POWER_ATT
	total += float(fighter.defence) * POWER_DEF
	total += float(fighter.agility) * POWER_AGI
	total += float(fighter.vitality) * POWER_VIT
	total += float(fighter.charisma) * POWER_CHA
	total += float(fighter.luck) * POWER_LUK
	total += float(fighter.level) * POWER_LEVEL
	return maxi(0, roundi(total))

## Valor de um atributo pelo id ("strength".."luck"); 0 para lutador nulo.
static func attribute_value(fighter, attribute_id: String) -> int:
	if fighter == null:
		return 0
	return int(fighter.get(attribute_id))

## Sorteia UMA fala de uma lista (uniforme). Lista vazia devolve "".
static func random_line(lines: Array, rng: RandomNumberGenerator = null) -> String:
	if lines.is_empty():
		return ""
	var index := 0
	if rng != null:
		index = rng.randi_range(0, lines.size() - 1)
	else:
		index = randi() % lines.size()
	return str(lines[index]).strip_edges()

## Provocação do jogador (reserva, sorteada).
static func player_taunt(rng: RandomNumberGenerator = null) -> String:
	return random_line(PLAYER_TAUNTS, rng)

## Identidade do inimigo: resolve o template pelo id e devolve
## {nickname, description, weakness, taunts}. Sem template (inimigo procedural),
## devolve a reserva genérica.
static func enemy_identity(enemy) -> Dictionary:
	var template := {}
	if enemy != null:
		template = ContentRepositoryScript.find_enemy(ContentRepositoryScript.load_enemies(), str(enemy.id))
	return identity_from_template(template)

## Identidade a partir de um template de data/enemies.json (ou {} para a reserva).
static func identity_from_template(template: Dictionary) -> Dictionary:
	var taunts: Array = _string_list(template.get("taunts", []))
	if taunts.is_empty():
		taunts = GENERIC_ENEMY_TAUNTS.duplicate()
	return {
		"nickname": str(template.get("nickname", GENERIC_ENEMY_NICKNAME)),
		"description": str(template.get("description", GENERIC_ENEMY_DESCRIPTION)),
		"weakness": str(template.get("weakness", GENERIC_ENEMY_WEAKNESS)),
		"taunts": taunts,
	}

## Provocação do inimigo: sorteia entre as falas próprias dele ou na reserva.
static func enemy_taunt(enemy, rng: RandomNumberGenerator = null) -> String:
	var identity: Dictionary = enemy_identity(enemy)
	return random_line(identity.get("taunts", []), rng)

## Lista de strings não vazias (valida as falas do JSON).
static func _string_list(source) -> Array:
	var result: Array = []
	if source is Array:
		for entry: Variant in source:
			var text := str(entry).strip_edges()
			if text != "":
				result.append(text)
	return result
