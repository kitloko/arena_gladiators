class_name BossPool
extends RefCounted

## POOL DE BOSSES FINAIS POR TORNEIO (docs/PLANO_3.0.md §5.3).
##
## Cada torneio tem o SEU pool de 6 candidatos (18 no total), declarado no campo
## `boss_pool` de data/tournaments.json. A rodada FINAL sorteia UM boss do pool do
## PRÓPRIO tier — nunca de outro torneio — de forma testável e reproduzível por
## seed (`draw_final_boss`). A UI não sorteia nada: ela lê o boss que o GameState
## materializou a partir daqui.
##
## MEMÓRIA CURTA (anti-repetição): `draw_final_boss` recebe o id do último boss
## sorteado NAQUELE tier e o EXCLUI do sorteio. Quem guarda a memória é o
## GameState (`last_final_boss_by_tier`), mantendo esta camada pura e fácil de
## testar (tests/run_systems_test.gd).
##
## Regras puras: nenhuma dependência de UI; só lê o conteúdo.

const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")

## Ids do pool do torneio `tier_id` (na ordem declarada). Vazio se o tier não
## existir ou não declarar `boss_pool`.
static func pool_for(tier_id: String) -> Array[String]:
	var result: Array[String] = []
	if tier_id == "":
		return result
	for tier: Dictionary in ContentRepositoryScript.load_tournaments():
		if str(tier.get("id", "")) != tier_id:
			continue
		for entry: Variant in tier.get("boss_pool", []):
			var boss_id := str(entry)
			if boss_id != "" and not result.has(boss_id):
				result.append(boss_id)
		break
	return result

## Todos os ids de todos os pools (para validar unicidade entre torneios).
static func all_pool_ids() -> Array[String]:
	var result: Array[String] = []
	for tier: Dictionary in ContentRepositoryScript.load_tournaments():
		for entry: Variant in tier.get("boss_pool", []):
			var boss_id := str(entry)
			if boss_id != "" and not result.has(boss_id):
				result.append(boss_id)
	return result

## Sorteia o boss FINAL do torneio `tier_id`, excluindo `previous_id` (o último
## boss sorteado NAQUELE mesmo tier) para NÃO repetir dois iguais em sequência.
##
## `rng` é opcional: sem ele, usa o RNG global (o jogo); com ele, é reprodutível
## nos testes. Se o pool tiver só um candidato (ou o anterior não estiver no pool),
## o sorteio continua cobrindo o pool inteiro.
static func draw_final_boss(tier_id: String, rng: RandomNumberGenerator = null, previous_id: String = "") -> String:
	var pool := pool_for(tier_id)
	if pool.is_empty():
		return ""
	var candidates: Array[String] = []
	for boss_id: String in pool:
		if boss_id != previous_id:
			candidates.append(boss_id)
	if candidates.is_empty():
		candidates = pool
	var index := 0
	if rng != null:
		index = rng.randi_range(0, candidates.size() - 1)
	else:
		index = randi_range(0, candidates.size() - 1)
	return str(candidates[index])

## O pool é COMPLETO e COERENTE com os dados (todo id existe em enemies.json, é
## boss e declara grau 1 a 5). Usado pelos testes e pelo debug.
static func validate_pool(tier_id: String) -> Dictionary:
	var enemies := ContentRepositoryScript.load_enemies()
	var pool := pool_for(tier_id)
	var missing: Array[String] = []
	var not_boss: Array[String] = []
	var bad_grade: Array[String] = []
	for boss_id: String in pool:
		var template := ContentRepositoryScript.find_enemy(enemies, boss_id)
		if template.is_empty():
			missing.append(boss_id)
			continue
		if not bool(template.get("boss", false)):
			not_boss.append(boss_id)
		var grade := int(template.get("grade", 0))
		if grade < 1 or grade > 5:
			bad_grade.append(boss_id)
	return {
		"ok": pool.size() > 0 and missing.is_empty() and not_boss.is_empty() and bad_grade.is_empty(),
		"size": pool.size(),
		"missing": missing,
		"not_boss": not_boss,
		"bad_grade": bad_grade,
	}
