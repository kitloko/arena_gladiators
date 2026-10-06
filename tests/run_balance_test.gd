extends SceneTree

## Teste de balanceamento (regras puras, sem interface).
##
## Executar com:
##   Godot --headless --path . -s res://tests/run_balance_test.gd
##
## Roda DEPOIS de run_systems_test.gd: aquele garante que as regras funcionam,
## este garante que elas estão calibradas. Se um número de balanceamento mudar
## e quebrar a curva de progressão, a suíte falha aqui — antes de virar surpresa
## no playtest.
##
## Modelo (simplificado de propósito, declarado para não enganar ninguém):
##  - luta = troca de golpes corpo a corpo, vida cheia dos dois lados, jogador ataca primeiro;
##  - não modela posicionamento/alcance, defender/avançar/recuar nem os especiais dos chefes;
##  - jogador recém-criado = distribuição dos pontos de criação (20 hoje) num build
##    comum: 25% vitalidade, 50% força, 20% defesa, resto em sorte;
##  - ganho de nível = 4 pontos por nível distribuídos 2 FOR / 1 VIT / 1 DEF (jogador "casual");
##  - "com loja" = equipa a espada e o peitoral Comum do próprio nível (a opção de base da loja).
## A armadura é um POOL separado (absorve antes da vida) e a DEF do alvo pode aparar
## (auto-defesa) — as duas entram na simulação porque resolve_attack as aplica.
## Com seed fixa, o resultado é reprodutível.

const CombatResolverScript := preload("res://scripts/systems/combat_resolver.gd")
const CrowdSystemScript := preload("res://scripts/systems/crowd_system.gd")
const GladiatorDataScript := preload("res://scripts/models/gladiator_data.gd")
const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")
const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")
const ItemGeneratorScript := preload("res://scripts/systems/item_generator.gd")

const SAMPLES := 4000
const SEED_VALUE := 20261006

var _failures: int = 0

func _initialize() -> void:
	seed(SEED_VALUE)
	var items := ContentRepositoryScript.load_items()
	var enemies := ContentRepositoryScript.load_enemies()

	_test_low_level_tier_is_safe(items)
	_test_first_fight_is_fair(items)
	_test_free_arena_curve(items)
	_test_player_always_favoured_early(items)
	_test_tournament_is_winnable(enemies)
	_test_crowd_gold_economy(items)

	if _failures == 0:
		print("PASS: balanceamento dentro das metas (curva de progressão e torneio).")
		quit(0)
	else:
		print("FAIL: %d verificação(ões) de balanceamento falharam." % _failures)
		quit(1)

# --- 1. Tier seguro nos primeiros níveis -----------------------------------

func _test_low_level_tier_is_safe(items: Array) -> void:
	print("")
	print("--- inimigo nos primeiros níveis ---")
	for level: int in [1, 2, 3]:
		var tiers := {1: 0, 2: 0, 3: 0}
		var hp_max := 0
		for i in 2000:
			var enemy: Dictionary = CombatResolverScript.generate_enemy(level, items)
			tiers[int(enemy.enemy_tier)] += 1
			hp_max = maxi(hp_max, GladiatorDataScript.HEALTH_BASE + int(enemy.base_vitality) * GladiatorDataScript.HEALTH_PER_VIT)
		print("  nível %d: tier 1/2/3 = %d%%/%d%%/%d%% | maior vida %d" % [
			level, int(round(tiers[1] / 20.0)), int(round(tiers[2] / 20.0)), int(round(tiers[3] / 20.0)), hp_max])
		if level <= 2:
			_check(tiers[3] == 0 and tiers[2] == 0, "nível %d nunca gera tier 2/3 (era 14%% de tier 3)" % level)
			_check(hp_max <= 70, "nível %d não gera inimigo com mais de 70 de vida (era 106)" % level)

# --- 2. Primeira luta ------------------------------------------------------

func _test_first_fight_is_fair(items: Array) -> void:
	var losses_geared := 0
	var losses_bare := 0
	for i in SAMPLES:
		var foe_geared = GladiatorDataScript.new(CombatResolverScript.generate_enemy(1, items))
		var foe_bare = GladiatorDataScript.new(CombatResolverScript.generate_enemy(1, items))
		if not _fight(_make_player(1, true), foe_geared):
			losses_geared += 1
		if not _fight(_make_player(1, false), foe_bare):
			losses_bare += 1
	var geared_rate := 100.0 * losses_geared / SAMPLES
	var bare_rate := 100.0 * losses_bare / SAMPLES
	print("")
	print("--- primeira luta de um personagem novo (nível 1) ---")
	print("  derrota sem loja: %.1f%%   com ouro gasto na loja: %.1f%%" % [bare_rate, geared_rate])
	_check(geared_rate <= 5.0, "derrota na 1ª luta com loja <= 5%% (medido %.1f%%)" % geared_rate)
	_check(bare_rate <= 12.0, "derrota na 1ª luta sem loja <= 12%% (medido %.1f%%)" % bare_rate)

# --- 3. Curva da Arena Livre ----------------------------------------------

func _test_free_arena_curve(items: Array) -> void:
	var results := {}
	print("")
	print("--- Arena Livre: vitória por nível (vida/STR/DEF do jogador) ---")
	for level: int in [1, 3, 5, 8, 10, 12, 15]:
		var bare_wins := 0
		var geared_wins := 0
		var sample_geared = _make_player(level, true)
		for i in SAMPLES:
			var foe_bare = GladiatorDataScript.new(CombatResolverScript.generate_enemy(level, items))
			var foe_geared = GladiatorDataScript.new(CombatResolverScript.generate_enemy(level, items))
			if _fight(_make_player(level, false), foe_bare):
				bare_wins += 1
			if _fight(_make_player(level, true), foe_geared):
				geared_wins += 1
		var bare := 100.0 * bare_wins / SAMPLES
		var geared := 100.0 * geared_wins / SAMPLES
		results[level] = {"bare": bare, "geared": geared}
		print("  nível %2d | %3d/%3d/%3d | sem loja %3d%% | com loja %3d%%" % [
			level, sample_geared.max_health, sample_geared.strength, sample_geared.defence,
			int(round(bare)), int(round(geared))])
	_check(results[1].bare >= 92.0, "nível 1 sem loja >= 92%% (medido %d%%)" % int(round(results[1].bare)))
	_check(results[10].bare >= 68.0, "nível 10 sem loja >= 68%% (medido %d%%)" % int(round(results[10].bare)))
	_check(results[15].bare >= 55.0, "nível 15 sem loja >= 55%% (medido %d%%)" % int(round(results[15].bare)))
	_check(results[1].geared >= 88.0, "nível 1 com loja >= 88%% (medido %d%%)" % int(round(results[1].geared)))
	_check(results[15].geared >= 70.0, "nível 15 com loja >= 70%% (medido %d%%)" % int(round(results[15].geared)))
	# A curva não pode desabar conforme o jogador sobe (tolerância de 3 pontos para a
	# oscilação da amostragem: 89% contra 89% não é regressão de balanceamento).
	_check(results[8].bare >= results[5].bare - 3.0, "curva sem loja não cai mais de 3 pontos entre os níveis 5 e 8")
	_check(results[15].bare >= results[10].bare - 3.0, "curva sem loja não cai mais de 3 pontos entre os níveis 10 e 15")

# --- 4. Golpes para matar (o que o jogador sente) -------------------------

func _test_player_always_favoured_early(items: Array) -> void:
	print("")
	print("--- golpes para matar (inimigo médio) ---")
	var favourable := true
	for level: int in [1, 3, 5, 8, 10, 12, 15]:
		var player = _make_player(level, false)
		var foe = _mean_foe(level, items)
		var player_hits: int = int(ceil(float(foe.max_health) / float(maxi(1, int(round(float(player.strength) - float(foe.defence) * 0.55))))))
		var foe_hits: int = int(ceil(float(player.max_health) / float(maxi(1, int(round(float(foe.strength) - float(player.defence) * 0.55))))))
		print("  nível %2d | você mata em %d golpes | ele te mata em %d | inimigo típico: %d vida, %d STR, %d DEF" % [
			level, player_hits, foe_hits, foe.max_health, foe.strength, foe.defence])
		if level <= 8 and player_hits > foe_hits:
			favourable = false
	_check(favourable, "até o nível 8 o jogador mata em menos golpes do que morre (a curva virava no nível 4)")

# --- 5. Torneio ------------------------------------------------------------

func _test_tournament_is_winnable(enemies: Array) -> void:
	print("")
	print("--- torneio: conclusão das 4 lutas ---")
	var tiers := ContentRepositoryScript.load_tournaments()
	var levels: Array[int] = [1, 3, 5, 8, 12, 15]
	var measured := {}
	for tier_index in tiers.size():
		var tier: Dictionary = tiers[tier_index]
		var rounds: Array = tier.get("rounds", [])
		measured[tier_index] = {}
		for level: int in levels:
			var cleared_bare := 0
			var cleared_geared := 0
			var cleared_equipped := 0
			for attempt in 600:
				if _tournament(_make_player(level, false), rounds, enemies, level, tier_index):
					cleared_bare += 1
				if _tournament(_make_player(level, true), rounds, enemies, level, tier_index):
					cleared_geared += 1
				if _tournament(_make_player_equipped(level), rounds, enemies, level, tier_index):
					cleared_equipped += 1
			var bare := 100.0 * cleared_bare / 600.0
			var geared := 100.0 * cleared_geared / 600.0
			var equipped := 100.0 * cleared_equipped / 600.0
			measured[tier_index][level] = equipped
			print("  %s nível %2d | conclui: sem loja %3d%% | 2 peças %3d%% | 6 slots %3d%%" % [
				str(tier.get("name", "?")), level, int(round(bare)), int(round(geared)), int(round(equipped))])
	# O torneio NÃO é para ser vencível de cara: ele é a escada de fim de jogo, e
	# o jogador precisa subir de nível e comprar equipamento para chegar lá. As
	# metas abaixo são o nível em que cada torneio passa a valer a pena.
	# (Sem equipamento o torneio é ruim de propósito: é o desafio de quem investiu.)
	var targets := {0: [5, 60.0], 1: [8, 50.0], 2: [12, 50.0]}
	for tier_index: int in targets:
		var target_level: int = int(targets[tier_index][0])
		var goal := float(targets[tier_index][1])
		var tier_name := str(tiers[tier_index].get("name", "?"))
		var got := float(measured[tier_index][target_level])
		_check(got >= goal, "%s: concluível por um jogador equipado no nível %d, meta %d%% (medido %d%%)" % [
			tier_name, target_level, int(goal), int(round(got))])
	# Escada de verdade: no nível 5 o Menor é mais fácil que o Maior, e o Maior mais
	# fácil que o Grande. Se esta ordem quebrar, um torneio "maior" ficou trivial.
	if tiers.size() >= 3:
		var menor := float(measured[0][5])
		var maior := float(measured[1][5])
		var grande := float(measured[2][5])
		_check(menor > maior and maior >= grande, "os torneios formam uma escada de dificuldade no nível 5 (menor %.0f%% > maior %.0f%% >= grande %.0f%%)" % [menor, maior, grande])
	# Nenhum torneio pode ser impossível para quem se equipou: algum nível fecha.
	for tier_index in tiers.size():
		var best := 0.0
		for level: int in levels:
			best = maxf(best, float(measured[tier_index][level]))
		_check(best >= 50.0, "%s é concluível por um jogador equipado (melhor taxa medida: %d%%)" % [
			str(tiers[tier_index].get("name", "?")), int(round(best))])

# --- regras / utilidades ---------------------------------------------------

func _tournament(player, rounds: Array, enemies: Array, level: int, tier_index: int) -> bool:
	# Mesma fórmula de GameState.enemy_level_for_current_stage():
	# nível do inimigo = nível do jogador + índice do tier × 2 + rodada.
	for round_index in rounds.size():
		var template := ContentRepositoryScript.find_enemy(enemies, str(rounds[round_index]))
		var foe = CombatResolverScript.enemy_for_level(level + tier_index * 2 + round_index, template)
		if _fight(player, foe):
			player.heal_full()
		else:
			return false
	return true

## Inimigo típico de um nível: média de 400 gerações (número redondo para a tabela).
func _mean_foe(level: int, items: Array) -> GladiatorData:
	var vit_sum := 0
	var str_sum := 0
	var def_sum := 0
	for i in 400:
		var enemy: Dictionary = CombatResolverScript.generate_enemy(level, items)
		vit_sum += int(enemy.base_vitality)
		str_sum += int(enemy.base_strength)
		def_sum += int(enemy.base_defence)
	return GladiatorDataScript.new({
		"id": "media", "level": level,
		"base_vitality": int(round(vit_sum / 400.0)),
		"base_strength": int(round(str_sum / 400.0)),
		"base_defence": int(round(def_sum / 400.0)),
	})

## Personagem com a criação neutra do jogo, distribuindo os 20 pontos num build de
## jogador comum: um pouco mais de força que o resto.
## `geared` = comprou a espada e o peitoral Comum do próprio nível.
func _make_player(level: int, geared: bool) -> GladiatorData:
	var points: int = EconomySystemScript.creation_points()
	# 25% em vitalidade, 50% em força, 20% em defesa, o resto em sorte (total = pontos).
	var vitality_points := int(round(float(points) * 0.25))
	var strength_points := int(round(float(points) * 0.5))
	var defence_points := int(round(float(points) * 0.2))
	var luck_points: int = maxi(0, points - vitality_points - strength_points - defence_points)
	var player = GladiatorDataScript.new({
		"id": "player", "display_name": "Teste", "level": 1,
		"base_vitality": EconomySystemScript.neutral_total("vitality", {"vitality": vitality_points}),
		"base_strength": EconomySystemScript.neutral_total("strength", {"strength": strength_points}),
		"base_defence": EconomySystemScript.neutral_total("defence", {"defence": defence_points}),
		"base_luck": EconomySystemScript.neutral_total("luck", {"luck": luck_points}),
	})
	# Um nível = 4 pontos, distribuídos 2 FOR / 1 VIT / 1 DEF (jogador "casual").
	for i in (maxi(0, level - 1)):
		player.grant_experience(player.required_experience())
		player.spend_attribute_point("strength")
		player.spend_attribute_point("strength")
		player.spend_attribute_point("vitality")
		player.spend_attribute_point("defence")
	if geared:
		var stock: Dictionary = ItemGeneratorScript.generate_shop_stock(level)
		for subtype: String in ["espada", "peitoral"]:
			var list: Array = stock.get(subtype, [])
			if not list.is_empty():
				player.equip_item(list[0])
	player.level = level
	player.health = player.max_health
	player.armour = player.max_armour
	return player

## Jogador "equipado": os 6 slots com o melhor item do tipo disponível para o
## nível na loja procedural. É o perfil de quem entra num torneio depois de
## gastar o ouro — e é o único que mede o torneio de forma justa.
func _make_player_equipped(level: int) -> GladiatorData:
	var player = _make_player(level, false)
	var stock: Dictionary = ItemGeneratorScript.generate_shop_stock(level)
	var subtypes_by_slot := {
		"weapon": ["espada", "machado", "lanca"],
		"armor": ["peitoral"],
		"helmet": ["capacete"],
		"gloves": ["luvas"],
		"boots": ["botas"],
		"belt": ["cinto"],
	}
	for slot: String in subtypes_by_slot:
		var best: Dictionary = {}
		for subtype: String in subtypes_by_slot[slot]:
			var list: Array = stock.get(subtype, [])
			for item: Dictionary in list:
				if best.is_empty() or int(item.get("price", 0)) > int(best.get("price", 0)):
					best = item
		if not best.is_empty():
			player.equip_item(best)
	player.level = level
	player.health = player.max_health
	player.armour = player.max_armour
	return player

## Troca de golpes até alguém cair (vida cheia nos dois lados). Vitória = o
## inimigo cai primeiro.
func _fight(player, foe) -> bool:
	var guard := 0
	while guard < 400:
		guard += 1
		CombatResolverScript.resolve_attack(player, foe, 1.0, 1.0, 0)
		if foe.is_defeated():
			return true
		CombatResolverScript.resolve_attack(foe, player, 1.0, 1.0, 0)
		if player.is_defeated():
			return false
	return false

# --- 6. Ouro por luta com o multiplicador do público (item H) ---------------

## Mede o OURO por luta já com o multiplicador da felicidade do público (×1,0 a
## ×2,0). A barra muda a economia: reporta o número por nível e trava o teto.
func _test_crowd_gold_economy(items: Array) -> void:
	print("")
	print("--- felicidade do público: ouro por luta com o multiplicador médio ---")
	var levels: Array[int] = [1, 3, 5, 8, 10, 15]
	var samples := 1000
	var min_avg := 9.0
	var max_avg := 0.0
	var min_gold := 999999.0
	var max_gold := 0.0
	for level: int in levels:
		var total_mult := 0.0
		var bare_gold := 0.0
		var geared_gold := 0.0
		for i in samples:
			var foe = GladiatorDataScript.new(CombatResolverScript.generate_enemy(level, items))
			var outcome: Dictionary = _crowd_fight(_make_player(level, false), foe)
			total_mult += float(outcome.multiplier)
			if bool(outcome.won):
				bare_gold += float(EconomySystemScript.fight_rewards(level).gold) * float(foe.reward_multiplier) * float(outcome.multiplier)
			var foe_g = GladiatorDataScript.new(CombatResolverScript.generate_enemy(level, items))
			var outcome_g: Dictionary = _crowd_fight(_make_player(level, true), foe_g)
			if bool(outcome_g.won):
				geared_gold += float(EconomySystemScript.fight_rewards(level).gold) * float(foe_g.reward_multiplier) * float(outcome_g.multiplier)
		var avg_mult := total_mult / float(samples)
		var bare_per_fight := bare_gold / float(samples)
		var geared_per_fight := geared_gold / float(samples)
		min_avg = minf(min_avg, avg_mult)
		max_avg = maxf(max_avg, avg_mult)
		min_gold = minf(min_gold, bare_per_fight)
		max_gold = maxf(max_gold, geared_per_fight)
		print("  nível %2d | multiplicador médio ×%.2f | ouro/luta sem loja %.1f | com 2 peças %.1f" % [level, avg_mult, bare_per_fight, geared_per_fight])
	print("  faixa do multiplicador médio: ×%.2f a ×%.2f | ouro/luta: %.1f a %.1f" % [min_avg, max_avg, min_gold, max_gold])
	_check(min_avg >= 1.0, "o multiplicador médio do público nunca cai abaixo de ×1,0 (menor medido ×%.2f)" % min_avg)
	_check(max_avg <= CrowdSystemScript.MULTIPLIER_MAX, "o multiplicador médio respeita o teto ×2,0 (maior medido ×%.2f)" % max_avg)
	_check(max_avg > 1.05, "lutas reais rendem multiplicador de público acima de ×1,0 (maior médio ×%.2f)" % max_avg)
	_check(min_gold > 0.0, "a arena livre paga ouro em todos os níveis mesmo sem loja (menor %.1f/luta)" % min_gold)

## Troca de golpes com a barra de público (item H) movida pelos eventos reais.
func _crowd_fight(player, foe) -> Dictionary:
	var crowd = CrowdSystemScript.new(player, foe, false)
	var guard := 0
	while guard < 400:
		guard += 1
		var cold := true
		crowd.register_action()
		var hit: Dictionary = CombatResolverScript.resolve_attack(player, foe, 1.0, 1.0, 0)
		crowd.apply_combat_result(hit, true)
		if int(hit.get("health_damage", 0)) > 0 or int(hit.get("counter_health_damage", 0)) > 0:
			cold = false
		if foe.is_defeated():
			return {"won": true, "multiplier": crowd.reward_multiplier()}
		var enemy_hit: Dictionary = CombatResolverScript.resolve_attack(foe, player, 1.0, 1.0, 0)
		crowd.apply_combat_result(enemy_hit, false)
		if int(enemy_hit.get("health_damage", 0)) > 0 or int(enemy_hit.get("counter_health_damage", 0)) > 0:
			cold = false
		crowd.end_round(cold)
		if player.is_defeated():
			return {"won": false, "multiplier": 0.0}
	return {"won": false, "multiplier": 0.0}

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok - %s" % label)
	else:
		_failures += 1
		printerr("  FALHOU - %s" % label)
