class_name InjurySystem
extends RefCounted

## FERIMENTOS PERSISTENTES (item 2 do plano 2.0).
##
## Perder uma luta (e/ou levar um crítico forte) pode deixar uma SEQUELA que
## sobrevive ao combate: um ferimento com nome e uma penalidade real num atributo
## (ex.: "Braço quebrado −3 STR"). O ferimento conta de verdade no próximo combate
## (GladiatorData.recompute_derived aplica a penalidade) e NÃO soma sozinho: só o
## MÉDICO (ou uma poção de ferimento) cura.
##
## REGRAS FECHADAS (documentadas no relatório):
##  - no máximo 2 ferimentos ativos ao mesmo tempo (MAX_ACTIVE) — mais que isso
##    vira invalidez permanente e o jogo deixa de ser jogável;
##  - o mesmo ferimento não empilha (não existe "dois braços quebrados");
##  - nenhum ferimento pode zerar um atributo: a penalidade aplicada é cortada
##    para que o atributo fique no mínimo em MIN_ATTRIBUTE (1).
##
## Sistema puro (sem interface nem autoload) para os testes consumirem a MESMA
## regra que o jogo usa.

const MAX_ACTIVE := 2
## Chance de ferimento ao PERDER na Arena Livre. Perder a luta sempre dói, mas nem
## toda derrota aleija — senão o jogo vira uma espiral de sequelas.
const DEFEAT_INJURY_CHANCE := 0.75
## Bônus de chance quando, além de perder, o jogador levou um CRÍTICO forte.
const DEFEAT_CRIT_BONUS := 0.15
## Chance de ferimento ao vencer tomando um crítico forte (raro).
const VICTORY_CRIT_INJURY_CHANCE := 0.10
## Nenhum atributo pode ser reduzido abaixo disto por um ferimento.
const MIN_ATTRIBUTE := 1

const TEMPLATES := [
	{"id": "broken_arm", "label": "Braço quebrado", "attr": "strength", "short": "STR", "penalty": 3},
	{"id": "cracked_ribs", "label": "Costela rachada", "attr": "vitality", "short": "VIT", "penalty": 4},
	{"id": "swollen_eye", "label": "Olho inchado", "attr": "attack", "short": "ATT", "penalty": 3},
	{"id": "sprained_ankle", "label": "Tornozelo torcido", "attr": "agility", "short": "AGI", "penalty": 3},
	{"id": "hurt_shoulder", "label": "Ombro machucado", "attr": "defence", "short": "DEF", "penalty": 3},
	{"id": "bad_luck", "label": "Má sorte no ringue", "attr": "luck", "short": "SOR", "penalty": 4},
	{"id": "dented_face", "label": "Rosto desfigurado", "attr": "charisma", "short": "CHA", "penalty": 3},
]

static func max_active() -> int:
	return MAX_ACTIVE

static func templates() -> Array:
	return TEMPLATES

static func find_template(template_id: String) -> Dictionary:
	for entry: Dictionary in TEMPLATES:
		if str(entry.get("id", "")) == template_id:
			return entry
	return {}

## Campo derivado (sem o prefixo base_) de um atributo: usado para ler o valor
## "cru" do atributo antes de aplicar a penalidade.
static func field_for(attribute_id: String) -> String:
	match attribute_id:
		"strength", "base_strength":
			return "strength"
		"attack", "base_attack":
			return "attack"
		"defence", "defense", "base_defence":
			return "defence"
		"agility", "base_agility":
			return "agility"
		"vitality", "base_vitality":
			return "vitality"
		"charisma", "base_charisma":
			return "charisma"
		"luck", "base_luck":
			return "luck"
	return ""

## Ferimentos ativos do lutador (lista de dicionários). Vazia se não houver.
static func active(player) -> Array:
	if player == null or not ("injuries" in player):
		return []
	return player.injuries

static func count(player) -> int:
	return active(player).size()

static func has_injury(player, injury_id: String) -> bool:
	for injury: Variant in active(player):
		if injury is Dictionary and str((injury as Dictionary).get("id", "")) == injury_id:
			return true
	return false

## Soma das penalidades já APLICADAS a um atributo (o valor guardado, já cortado
## para não zerar).
static func penalty_total(player, attribute_id: String) -> int:
	var total := 0
	for injury: Variant in active(player):
		if injury is Dictionary and str((injury as Dictionary).get("attr", "")) == attribute_id:
			total += int((injury as Dictionary).get("penalty", 0))
	return total

## Penalidades por atributo derivado, no formato usado por GladiatorData.
static func penalty_map(player) -> Dictionary:
	var result := {}
	for injury: Variant in active(player):
		if not injury is Dictionary:
			continue
		var entry: Dictionary = injury
		var attr := str(entry.get("attr", ""))
		if attr == "":
			continue
		result[attr] = int(result.get(attr, 0)) + int(entry.get("penalty", 0))
	return result

## Adiciona um ferimento ao lutador respeitando as três regras (teto, duplicata,
## não zerar). Devolve {ok, injury, reason}. A penalidade aplicada pode ser MENOR
## que a do template quando o atributo está no chão — e isso é registrado no
## próprio ferimento, para a cura devolver exatamente o que foi tirado.
static func add_injury(player, template: Dictionary) -> Dictionary:
	if player == null:
		return {"ok": false, "reason": "sem lutador", "injury": {}}
	if template.is_empty():
		return {"ok": false, "reason": "ferimento inválido", "injury": {}}
	var injury_id := str(template.get("id", ""))
	if injury_id == "":
		return {"ok": false, "reason": "ferimento sem id", "injury": {}}
	if has_injury(player, injury_id):
		return {"ok": false, "reason": "já tem esse ferimento", "injury": {}}
	if count(player) >= MAX_ACTIVE:
		return {"ok": false, "reason": "ferimentos demais (%d)" % MAX_ACTIVE, "injury": {}}
	var attr := str(template.get("attr", ""))
	var field := field_for(attr)
	if field == "":
		return {"ok": false, "reason": "atributo inválido", "injury": {}}
	var current := int(player.get(field))
	var room := current - MIN_ATTRIBUTE
	if room <= 0:
		return {"ok": false, "reason": "%s já está no mínimo" % attr, "injury": {}}
	var applied := mini(int(template.get("penalty", 0)), room)
	var injury := {
		"id": injury_id,
		"label": str(template.get("label", "Ferimento")),
		"attr": attr,
		"short": str(template.get("short", "")),
		"penalty": applied,
	}
	player.injuries.append(injury)
	player.recompute_derived()
	return {"ok": true, "injury": injury, "reason": ""}

## Sorteia um ferimento ainda não ativo (para o resultado da luta).
static func add_random_injury(player) -> Dictionary:
	var pool: Array = []
	for entry: Dictionary in TEMPLATES:
		if not has_injury(player, str(entry.get("id", ""))):
			pool.append(entry)
	if pool.is_empty():
		return {"ok": false, "reason": "todos os ferimentos já ativos", "injury": {}}
	pool.shuffle()
	var last := {"ok": false, "reason": "não foi possível aplicar", "injury": {}}
	for entry: Dictionary in pool:
		last = add_injury(player, entry)
		if bool(last.get("ok", false)):
			return last
	return last

## Regra única do fim de luta: decide se esta luta deixou um ferimento novo.
## Devolve {injured, injury, reason}. `victory` = o jogador venceu;
## `took_critical` = levou um crítico forte.
static func after_fight(player, victory: bool, took_critical: bool) -> Dictionary:
	if player == null:
		return {"injured": false, "injury": {}, "reason": "sem lutador"}
	var chance := 0.0
	if not victory:
		chance = DEFEAT_INJURY_CHANCE
		if took_critical:
			chance = minf(0.95, chance + DEFEAT_CRIT_BONUS)
	elif took_critical:
		chance = VICTORY_CRIT_INJURY_CHANCE
	if chance <= 0.0 or randf() > chance:
		return {"injured": false, "injury": {}, "reason": ""}
	var info: Dictionary = add_random_injury(player)
	if bool(info.get("ok", false)):
		return {"injured": true, "injury": info.get("injury", {}), "reason": ""}
	return {"injured": false, "injury": {}, "reason": str(info.get("reason", ""))}

## Cura TODOS os ferimentos (só o médico/poção de ferimento chama isto). Devolve
## quantos foram curados.
static func cure_all(player) -> int:
	if player == null or not ("injuries" in player):
		return 0
	var total: int = player.injuries.size()
	player.injuries.clear()
	player.recompute_derived()
	return total

## Cura UM ferimento: por id, ou o mais recente quando injury_id == "".
static func cure_one(player, injury_id: String = "") -> Dictionary:
	if player == null or not ("injuries" in player):
		return {"ok": false, "cured": {}}
	var injuries: Array = player.injuries
	if injuries.is_empty():
		return {"ok": false, "cured": {}}
	var index := injuries.size() - 1
	if injury_id != "":
		index = -1
		for i in injuries.size():
			if str((injuries[i] as Dictionary).get("id", "")) == injury_id:
				index = i
				break
		if index < 0:
			return {"ok": false, "cured": {}}
	var cured: Dictionary = injuries[index]
	injuries.remove_at(index)
	player.recompute_derived()
	return {"ok": true, "cured": cured}

## Texto de um ferimento: "Braço quebrado (−3 STR)".
static func describe(injury: Dictionary) -> String:
	if injury.is_empty():
		return ""
	var short := str(injury.get("short", ""))
	if short == "":
		short = field_for(str(injury.get("attr", ""))).to_upper()
	return "%s (−%d %s)" % [str(injury.get("label", "Ferimento")), int(injury.get("penalty", 0)), short]

## Uma linha com todos os ferimentos ativos, para HUD/log.
static func summary(player) -> String:
	var parts: Array[String] = []
	for injury: Variant in active(player):
		if injury is Dictionary:
			parts.append(describe(injury))
	if parts.is_empty():
		return "sem ferimentos"
	return ", ".join(parts)
