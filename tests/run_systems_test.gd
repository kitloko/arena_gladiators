extends SceneTree

## Smoke test das regras puras (sem interface nem autoload).
## Executar com:
##   Godot --headless --path . -s res://tests/run_systems_test.gd

const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")
const CombatResolverScript := preload("res://scripts/systems/combat_resolver.gd")
const GladiatorDataScript := preload("res://scripts/models/gladiator_data.gd")
const ItemDataScript := preload("res://scripts/models/item_data.gd")
const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")
const SaveSystemScript := preload("res://scripts/systems/save_system.gd")
const ItemGeneratorScript := preload("res://scripts/systems/item_generator.gd")

var _failures: int = 0

func _initialize() -> void:
	_test_economy_rewards()
	_test_guard_bonus_constant()
	_test_enemy_action_shape()
	_test_resolve_attack_hit_and_miss()
	_test_accuracy_grows_with_att()
	_test_dodge_grows_with_agility()
	_test_auto_defense_reports_blocked_and_entered()
	_test_armour_absorbs_before_health()
	_test_critical_grows_with_luck()
	_test_taunt_distribution_and_resist()
	_test_sleep_heals_and_is_risky()
	_test_named_actions_melee()
	_test_level_points_distribution()
	_test_gladiator_progression()
	_test_movement_and_range()
	_test_equipment_and_inventory()
	_test_items_and_campaign_content()
	_test_attribute_definitions()
	_test_item_data_defaults()
	_test_archetypes_content()
	_test_save_roundtrip_and_migration()
	_test_procedural_shop_and_rest()
	_test_shop_names_follow_power()
	_test_experience_curve()
	_test_sell_rules()
	_test_streak_does_not_boost_experience()
	_test_bag_and_unequip()
	if _failures == 0:
		print("PASS: todos os testes de regras passaram.")
		quit(0)
	else:
		print("FAIL: %d verificacao(oes) falharam." % _failures)
		quit(1)

func _fighter(values: Dictionary):
	return GladiatorDataScript.new(values)

# --- Atributos: precisão (ATT), esquiva (AGI), auto-defesa (DEF) -----------

## Sem armadura, sem esquiva e sem auto-defesa, um acerto de 1.0 sempre acerta;
## um acerto de 0.0 com ATT 0 sempre erra.
func _test_resolve_attack_hit_and_miss() -> void:
	var attacker = _fighter({"id": "a", "base_strength": 12, "base_attack": 0, "base_agility": 0, "base_defence": 0, "base_vitality": 8})
	var defender = _fighter({"id": "d", "base_strength": 6, "base_attack": 0, "base_agility": 0, "base_defence": 0, "base_vitality": 10})
	var hp_before: int = defender.health
	var hit_result: Dictionary = CombatResolverScript.resolve_attack(attacker, defender, 1.0, 1.0, 0)
	_check(bool(hit_result.hit), "ataque com acerto 1.0 sempre acerta (ATT/esquiva/DEF zerados)")
	if bool(hit_result.hit):
		_check(int(hit_result.damage) >= 1, "dano minimo 1")
		_check(defender.health == maxi(0, hp_before - int(hit_result.health_damage)), "vida reduzida conforme o dano que entrou")
	var another = _fighter({"id": "d2", "base_strength": 6, "base_attack": 0, "base_agility": 0, "base_defence": 0, "base_vitality": 10})
	var hp_another: int = another.health
	var miss_result: Dictionary = CombatResolverScript.resolve_attack(attacker, another, 1.0, 0.0, 0)
	_check(not bool(miss_result.hit) and bool(miss_result.missed), "acerto 0.0 com ATT 0 sempre erra")
	_check(another.health == hp_another, "erro nao causa dano")

## Mais ATT = mais chance de acertar (precisão cresce com o atributo).
func _test_accuracy_grows_with_att() -> void:
	var defender = _fighter({"id": "d", "base_agility": 0, "base_defence": 0, "base_vitality": 20})
	var low = _fighter({"id": "low", "base_attack": 0, "base_strength": 5, "base_vitality": 20})
	var high = _fighter({"id": "high", "base_attack": 40, "base_strength": 5, "base_vitality": 20})
	var low_hits := 0
	var high_hits := 0
	for i in 3000:
		var d1 = _fighter({"id": "d", "base_agility": 0, "base_defence": 0, "base_vitality": 40})
		if bool(CombatResolverScript.resolve_attack(low, d1, 1.0, 0.5, 0).hit):
			low_hits += 1
		var d2 = _fighter({"id": "d", "base_agility": 0, "base_defence": 0, "base_vitality": 40})
		if bool(CombatResolverScript.resolve_attack(high, d2, 1.0, 0.5, 0).hit):
			high_hits += 1
	_check(high_hits > low_hits + 300, "precisão (ATT) aumenta os acertos (ATT 0: %d vs ATT 40: %d de 3000)" % [low_hits, high_hits])
	_check(CombatResolverScript.accuracy_for(high, 0.5) > CombatResolverScript.accuracy_for(low, 0.5), "accuracy_for cresce com ATT")

## Mais AGI = mais esquiva (dano zero).
func _test_dodge_grows_with_agility() -> void:
	var attacker = _fighter({"id": "a", "base_attack": 0, "base_strength": 5, "base_vitality": 40})
	var low_dodges := 0
	var high_dodges := 0
	for i in 3000:
		var d1 = _fighter({"id": "d", "base_agility": 0, "base_defence": 0, "base_vitality": 40})
		if bool(CombatResolverScript.resolve_attack(attacker, d1, 1.0, 1.0, 0).dodged):
			low_dodges += 1
		var d2 = _fighter({"id": "d", "base_agility": 40, "base_defence": 0, "base_vitality": 40})
		if bool(CombatResolverScript.resolve_attack(attacker, d2, 1.0, 1.0, 0).dodged):
			high_dodges += 1
	_check(high_dodges > low_dodges + 300, "esquiva (AGI) cresce com o atributo (AGI 0: %d vs AGI 40: %d de 3000)" % [low_dodges, high_dodges])
	_check(CombatResolverScript.dodge_chance(_fighter({"base_agility": 40})) > CombatResolverScript.dodge_chance(_fighter({"base_agility": 0})), "dodge_chance cresce com AGI")

## Auto-defesa (DEF): quando apara, expõe 'aparou X, entrou Y' coerentes.
func _test_auto_defense_reports_blocked_and_entered() -> void:
	var attacker = _fighter({"id": "a", "base_attack": 0, "base_strength": 20, "base_vitality": 30})
	var blocked_seen := false
	var consistent := true
	for i in 400:
		var defender = _fighter({"id": "d", "base_agility": 0, "base_defence": 40, "base_vitality": 40})
		var result: Dictionary = CombatResolverScript.resolve_attack(attacker, defender, 1.0, 1.0, 0)
		if bool(result.blocked):
			blocked_seen = true
			if int(result.blocked_amount) <= 0 or int(result.entered) < 0:
				consistent = false
			# aparado + entrou = dano do golpe (o que a auto-defesa reparte).
			if int(result.blocked_amount) + int(result.entered) != int(result.damage):
				consistent = false
	_check(blocked_seen, "DEF alta faz a auto-defesa disparar (aparou)")
	_check(consistent, "quando apara, 'aparou X, entrou Y' com X>0 e X+Y = dano")

## A armadura é consumida ANTES da vida.
func _test_armour_absorbs_before_health() -> void:
	var attacker = _fighter({"id": "a", "base_attack": 0, "base_strength": 12, "base_vitality": 20})
	var defender = _fighter({"id": "d", "base_strength": 5, "base_attack": 0, "base_agility": 0, "base_defence": 0, "base_vitality": 10})
	defender.equip_item({"id": "test_armour", "display_name": "Teste", "slot": "armor", "armour": 40, "price": 10})
	_check(defender.max_armour == 40 and defender.armour == 40, "armadura equipada cria o pool (40)")
	var hp_full: int = defender.health
	var result: Dictionary = CombatResolverScript.resolve_attack(attacker, defender, 1.0, 1.0, 0)
	_check(int(result.armour_damage) > 0 and int(result.health_damage) == 0, "o dano consumiu armadura, não vida")
	_check(defender.health == hp_full and defender.armour == 40 - int(result.armour_damage), "vida intacta enquanto há armadura")
	# Drena a armadura até sobrar pouca e confirma que o excedente fere a vida.
	for i in 10:
		CombatResolverScript.resolve_attack(attacker, defender, 1.0, 1.0, 0)
	_check(defender.health < hp_full, "depois de esgotar a armadura, o dano passa para a vida")

## SORTE aumenta a chance de acerto crítico.
func _test_critical_grows_with_luck() -> void:
	_check(CombatResolverScript.critical_chance(_fighter({"base_luck": 50})) > CombatResolverScript.critical_chance(_fighter({"base_luck": 5})), "critical_chance cresce com SORTE")
	var attacker_low = _fighter({"id": "l", "base_attack": 0, "base_strength": 5, "base_luck": 0, "base_vitality": 30})
	var attacker_high = _fighter({"id": "h", "base_attack": 0, "base_strength": 5, "base_luck": 60, "base_vitality": 30})
	var low_crits := 0
	var high_crits := 0
	for i in 3000:
		var d1 = _fighter({"id": "d", "base_agility": 0, "base_defence": 0, "base_vitality": 300})
		if bool(CombatResolverScript.resolve_attack(attacker_low, d1, 1.0, 1.0, 0).critical):
			low_crits += 1
		var d2 = _fighter({"id": "d", "base_agility": 0, "base_defence": 0, "base_vitality": 300})
		if bool(CombatResolverScript.resolve_attack(attacker_high, d2, 1.0, 1.0, 0).critical):
			high_crits += 1
	_check(high_crits > low_crits + 200, "SORTE aumenta os críticos (SOR 0: %d vs SOR 60: %d de 3000)" % [low_crits, high_crits])

## Taunt: a maioria dos efeitos empurra para frente; SORTE resiste (chance e empurrão).
func _test_taunt_distribution_and_resist() -> void:
	var counts := {}
	for i in 1000:
		var effect: Dictionary = CombatResolverScript.roll_taunt_effect()
		var key := str(effect.get("id", ""))
		counts[key] = int(counts.get(key, 0)) + 1
	var advance: int = int(counts.get("advance", 0))
	_check(advance > 450, "Taunt: a MAIORIA empurra para frente (%d de 1000 avançam)" % advance)
	_check(advance > int(counts.get("reckless", 0)) and advance > int(counts.get("stumble", 0)), "Taunt: avançar é o efeito mais comum")
	var defender = _fighter({"id": "d", "base_charisma": 5, "base_defence": 3, "base_luck": 5, "base_vitality": 20, "base_strength": 8})
	var weak = _fighter({"id": "w", "base_charisma": 5, "base_strength": 8, "base_luck": 5, "base_vitality": 20})
	var strong = _fighter({"id": "s", "base_charisma": 40, "base_strength": 40, "base_luck": 20, "base_vitality": 20})
	_check(CombatResolverScript.taunt_chance(strong, defender) > CombatResolverScript.taunt_chance(weak, defender), "Taunt: CHA/STR do provocador aumentam a chance")
	var lucky = _fighter({"id": "l", "base_charisma": 5, "base_defence": 3, "base_luck": 60, "base_vitality": 20})
	_check(CombatResolverScript.taunt_chance(strong, lucky) < CombatResolverScript.taunt_chance(strong, defender), "Taunt: SORTE do alvo reduz a chance (resistência)")
	var unlucky_resists := 0
	var lucky_resists := 0
	for i in 3000:
		if CombatResolverScript.taunt_push_resisted(defender):
			unlucky_resists += 1
		var lucky_defender = _fighter({"id": "l", "base_luck": 60, "base_vitality": 20})
		if CombatResolverScript.taunt_push_resisted(lucky_defender):
			lucky_resists += 1
	_check(lucky_resists > unlucky_resists + 300, "Taunt: SORTE resiste ao empurrão (SOR 5: %d vs SOR 60: %d de 3000)" % [unlucky_resists, lucky_resists])

## DORMIR cura 25% da vida máxima, deixa vulnerável e NÃO é melhor que atacar.
func _test_sleep_heals_and_is_risky() -> void:
	var sleeper = _fighter({"id": "s", "base_vitality": 20, "base_defence": 3})
	sleeper.health = 10
	var heal := int(round(float(sleeper.max_health) * CombatResolverScript.SLEEP_HEAL_FRACTION))
	sleeper.health = mini(sleeper.max_health, sleeper.health + heal)
	_check(heal == int(round(sleeper.max_health * 0.25)) and sleeper.health == 10 + heal, "DORMIR cura 25%% da vida máxima (+%d)" % heal)
	# Simulação: quem só dorme nunca fere o inimigo e acaba caindo.
	var sleeps_won := 0
	var attacks_won := 0
	for trial in 200:
		var p = _fighter({"id": "p", "base_strength": 40, "base_attack": 0, "base_agility": 0, "base_defence": 3, "base_vitality": 20})
		var f1 = _fighter({"id": "f", "base_strength": 40, "base_attack": 0, "base_agility": 0, "base_defence": 0, "base_vitality": 6})
		if _simulate(p, f1, true):
			sleeps_won += 1
		var p2 = _fighter({"id": "p", "base_strength": 40, "base_attack": 0, "base_agility": 0, "base_defence": 3, "base_vitality": 20})
		var f2 = _fighter({"id": "f", "base_strength": 40, "base_attack": 0, "base_agility": 0, "base_defence": 0, "base_vitality": 6})
		if _simulate(p2, f2, false):
			attacks_won += 1
	_check(sleeps_won == 0, "DORMIR não é melhor que lutar: quem só dorme nunca vence (%d/200)" % sleeps_won)
	_check(attacks_won > 150, "atacar vence a maioria das vezes (%d/200)" % attacks_won)

## `only_sleep` = o jogador só dorme; senão só ataca. Vitória = inimigo cai.
func _simulate(player, foe, only_sleep: bool) -> bool:
	var guard := 0
	while guard < 200:
		guard += 1
		if only_sleep:
			var heal := int(round(float(player.max_health) * CombatResolverScript.SLEEP_HEAL_FRACTION))
			player.health = mini(player.max_health, player.health + heal)
			player.vulnerable = true
		else:
			CombatResolverScript.resolve_attack(player, foe, 1.0, 1.0, 0)
			if foe.is_defeated():
				return true
		CombatResolverScript.resolve_attack(foe, player, 1.0, 1.0, 0)
		player.vulnerable = false
		if player.is_defeated():
			return false
	return false

## Golpes nomeados: GOLPE FORTE acerta menos e bate mais que GOLPE.
func _test_named_actions_melee() -> void:
	var actions := CombatResolverScript.melee_actions()
	var golpe := CombatResolverScript.find_action(actions, "golpe")
	var forte := CombatResolverScript.find_action(actions, "golpe_forte")
	var investida := CombatResolverScript.find_action(actions, "investida")
	_check(not golpe.is_empty() and not forte.is_empty() and not investida.is_empty(), "melee tem GOLPE, GOLPE FORTE e INVESTIDA")
	_check(float(forte.multiplier) > float(golpe.multiplier) and float(forte.accuracy) < float(golpe.accuracy), "GOLPE FORTE: dano maior, precisão menor")
	_check(bool(investida.advance), "INVESTIDA avança antes de atacar")
	var ranged := CombatResolverScript.ranged_actions()
	_check(not CombatResolverScript.find_action(ranged, "tiro").is_empty() and not CombatResolverScript.find_action(ranged, "tiro_certeiro").is_empty() and not CombatResolverScript.find_action(ranged, "bombardeio").is_empty(), "ranged tem TIRO, TIRO CERTEIRO e BOMBARDEIO")

## Subir de nível dá 4 pontos para distribuir entre os 7 atributos.
func _test_level_points_distribution() -> void:
	var fighter = _fighter({"id": "pts", "base_vitality": 10})
	var needed: int = EconomySystemScript.required_experience(1)
	fighter.grant_experience(needed)
	_check(fighter.pending_points == EconomySystemScript.attribute_points_per_level(), "nível dá %d pontos de atributo" % EconomySystemScript.attribute_points_per_level())
	var before: int = fighter.base_strength
	_check(fighter.spend_attribute_point("strength") and fighter.base_strength == before + 1, "gastar ponto soma no atributo escolhido")
	_check(fighter.pending_points == 3, "cada ponto consumido reduz o saldo")
	for definition: Dictionary in EconomySystemScript.attribute_definitions():
		while fighter.pending_points > 0:
			fighter.spend_attribute_point(str(definition.get("id", "")))
	_check(fighter.pending_points == 0 and not fighter.spend_attribute_point("luck"), "sem pontos, gastar é recusado")

func _test_procedural_shop_and_rest() -> void:
	var stock: Dictionary = ItemGeneratorScript.generate_shop_stock(3)
	var categories: Array[Dictionary] = ItemGeneratorScript.top_categories()
	var subtypes := 0
	var per_type_ok := true
	var has_baseline := true
	var distinct_ok := true
	for category: Dictionary in categories:
		for sub: Dictionary in category.get("subtypes", []):
			subtypes += 1
			var items: Array = stock.get(str(sub.get("id", "")), [])
			if items.is_empty() or items.size() > ItemGeneratorScript.PER_TYPE:
				per_type_ok = false
			var found_baseline := false
			for a: Dictionary in items:
				if int(a.get("price", 0)) <= 0:
					per_type_ok = false
				if str(a.get("rarity", "")) == "Comum":
					found_baseline = true
				for b: Dictionary in items:
					if a == b:
						continue
					var same := str(a.get("rarity", "")) == str(b.get("rarity", ""))
					same = same and int(a.get("level", 0)) == int(b.get("level", 0))
					same = same and int(a.get("strength_bonus", 0)) == int(b.get("strength_bonus", 0))
					same = same and int(a.get("attack_bonus", 0)) == int(b.get("attack_bonus", 0))
					same = same and int(a.get("defence_bonus", 0)) == int(b.get("defence_bonus", 0))
					same = same and int(a.get("agility_bonus", 0)) == int(b.get("agility_bonus", 0))
					same = same and int(a.get("vitality_bonus", 0)) == int(b.get("vitality_bonus", 0))
					same = same and int(a.get("charisma_bonus", 0)) == int(b.get("charisma_bonus", 0))
					same = same and int(a.get("luck_bonus", 0)) == int(b.get("luck_bonus", 0))
					same = same and int(a.get("armour", 0)) == int(b.get("armour", 0))
					same = same and int(a.get("price", 0)) == int(b.get("price", 0))
					if same:
						distinct_ok = false
			if not found_baseline:
				has_baseline = false
	_check(subtypes == 12 and per_type_ok, "loja procedural: 12 tipos com 1 a 3 itens de preço > 0")
	_check(has_baseline, "cada tipo traz ao menos um item Comum (base acessível)")
	_check(distinct_ok, "itens do mesmo tipo nunca são idênticos (nome diferente = status diferente)")
	# Descanso cobre vida + armadura faltantes.
	var fighter = _fighter({"id": "r", "level": 5, "base_vitality": 5})
	fighter.health = 20
	fighter.equip_item({"id": "rest_armour", "display_name": "Teste", "slot": "armor", "armour": 10, "price": 5})
	fighter.armour = 4
	var hp_price := EconomySystemScript.rest_hp_price(5)
	_check(hp_price >= 1 and EconomySystemScript.full_rest_cost(fighter) == (fighter.max_health - 20 + 6) * hp_price, "descanso: custo = (vida faltante + armadura faltante) × preço por ponto")
	_check(EconomySystemScript.shop_reroll_cost(5) >= 20, "reroll da loja custa ouro")
	# Sequência de vitórias: +12% por vitória, sem bônus com 0.
	_check(EconomySystemScript.streak_reward_multiplier(0) == 1.0 and EconomySystemScript.streak_bonus_percent(0) == 0, "sequência 0 = recompensa normal")
	_check(EconomySystemScript.streak_bonus_percent(5) == 60, "sequência 5 = +60%")
	_check(EconomySystemScript.streak_bonus_percent(10) == 120, "sequência 10 = +120%")
	_check(EconomySystemScript.streak_reward_multiplier(20) <= EconomySystemScript.streak_reward_multiplier(15), "bônus da sequência é limitado")

func _test_economy_rewards() -> void:
	var level1: Dictionary = EconomySystemScript.fight_rewards(1)
	_check(int(level1.gold) == 24, "recompensa nivel 1 ouro == 24")
	_check(int(level1.experience) == 20, "recompensa nivel 1 xp == 20")
	var level5: Dictionary = EconomySystemScript.fight_rewards(5)
	_check(int(level5.gold) == 56, "recompensa nivel 5 ouro == 56")
	_check(int(level5.experience) == 52, "recompensa nivel 5 xp == 52")

func _test_guard_bonus_constant() -> void:
	_check(CombatResolverScript.DEFEND_GUARD_BONUS == 6, "DEFEND_GUARD_BONUS == 6 (DEFESA FIRME reduz 30% do dano)")

func _test_enemy_action_shape() -> void:
	var invalid := 0
	var consistent := true
	var kinds := {}
	for i in 200:
		var action: Dictionary = CombatResolverScript.choose_enemy_action()
		if not (action.has("kind") and action.has("multiplier") and action.has("accuracy")):
			invalid += 1
			continue
		var kind := str(action.kind)
		kinds[kind] = true
		if kind == "brutal":
			if not (float(action.multiplier) == 1.35 and float(action.accuracy) == 0.82):
				consistent = false
		elif kind == "normal":
			if not (float(action.multiplier) == 1.0 and float(action.accuracy) == 1.0):
				consistent = false
		else:
			invalid += 1
	_check(invalid == 0, "escolha do inimigo tem shape valido nas 200 amostras")
	_check(consistent, "multiplier/accuracy coerentes com o kind")
	_check(kinds.size() == 2, "as duas acoes inimigas ocorrem em 200 amostras")

func _test_gladiator_progression() -> void:
	var fighter = _fighter({"id": "prog", "level": 1, "base_vitality": 7})
	_check(fighter.max_health == GladiatorDataScript.HEALTH_BASE + 7 * GladiatorDataScript.HEALTH_PER_VIT, "vida máxima = base + VIT × 6")
	fighter.receive_damage(200)
	_check(fighter.health == 0 and fighter.is_defeated(), "dano excessivo leva a 0 e derrota")
	fighter.heal_full()
	_check(fighter.health == fighter.max_health, "heal_full restaura a vida")
	var needed: int = EconomySystemScript.required_experience(1)
	var leveled: bool = fighter.grant_experience(needed)
	_check(leveled and fighter.level == 2, "%d xp no nivel 1 sobe para nivel 2" % needed)
	_check(fighter.pending_points == 4, "nivel ganho fica pendente de distribuição")
	var att_before: int = fighter.attack
	_check(not fighter.spend_attribute_point("nao_existe") and fighter.pending_points == 4, "atributo inexistente não consome ponto")
	fighter.spend_attribute_point("attack")
	_check(fighter.base_attack == att_before + 1 and fighter.attack == att_before + 1, "ponto em ATT aumenta a precisão")

func _test_equipment_and_inventory() -> void:
	var items := ContentRepositoryScript.load_items()
	var fighter = _fighter({"id": "p2", "base_strength": 10, "base_attack": 8, "base_defence": 4, "base_agility": 4, "base_vitality": 8, "base_charisma": 6, "base_luck": 6})
	fighter.equip_weapon(ContentRepositoryScript.find_item(items, "dagger"))
	_check(fighter.strength == 12 and fighter.agility == 5 and fighter.luck == 7, "equipar arma soma os bônus (STR/AGI/SOR) nos derivados")
	_check(fighter.owns_item("dagger"), "equipar registra item no inventario")
	fighter.equip_armor(ContentRepositoryScript.find_item(items, "leather_armor"))
	_check(fighter.max_armour == 14 and fighter.armour == 14, "equipar armadura soma o pool de armadura (14)")
	_check(fighter.vitality == 9, "armadura com VIT soma vitalidade")
	fighter.equip_weapon(ContentRepositoryScript.find_item(items, "short_sword"))
	_check(fighter.strength == 12 and fighter.owns_item("dagger") and fighter.owns_item("short_sword"), "trocar arma recalcula e mantém o inventário")
	var helm = ContentRepositoryScript.find_item(items, "iron_helm")
	fighter.equip_item(helm)
	_check(fighter.equipped_id("helmet") == "iron_helm" and fighter.max_armour == 24, "capacete equipa no slot correto e soma armadura")
	var belt = ContentRepositoryScript.find_item(items, "rope_belt")
	fighter.equip_item(belt)
	_check(fighter.max_armour == 28 and fighter.vitality == 10 and fighter.owns_item("rope_belt"), "cinto soma armadura e vitalidade")

func _test_items_and_campaign_content() -> void:
	var items := ContentRepositoryScript.load_items()
	_check(items.size() >= 6, "items.json tem pelo menos 6 itens")
	var slots := {}
	for item: Dictionary in items:
		slots[str(item.get("slot", ""))] = true
	_check(slots.has("weapon") and slots.has("armor"), "itens cobrem arma e armadura")
	var enemies := ContentRepositoryScript.load_enemies()
	_check(enemies.size() == 6, "enemies.json tem 6 inimigos (inclui chefes)")
	var imperator := ContentRepositoryScript.find_enemy(enemies, "imperator")
	var grande := ContentRepositoryScript.find_enemy(enemies, "grande_gladiador")
	_check(not imperator.get("special", {}).is_empty() and not grande.get("special", {}).is_empty(), "chefes têm habilidade exclusiva")
	var campaign := ContentRepositoryScript.load_campaign()
	_check(campaign.size() == 5, "campanha tem 5 arenas")
	var boss_count := 0
	var ids := {}
	for stage: Dictionary in campaign:
		if bool(stage.get("boss", false)):
			boss_count += 1
		ids[str(stage.get("id", ""))] = true
	_check(boss_count == 1, "campanha tem um chefe final")
	_check(ids.size() == campaign.size(), "arenas da campanha tem ids unicos")
	# Loja: nenhum item de valor zerado (itens básicos são comprados, não grátis).
	for item: Dictionary in items:
		_check(int(item.get("price", 0)) > 0, "item %s tem preço > 0" % str(item.get("id", "?")))
	# Gerador procedural de inimigos: aleatório com tier/tipo válidos e recompensa crescente.
	var tiers_ok := true
	var kinds := {}
	for i in 40:
		var e: Dictionary = CombatResolverScript.generate_enemy(5)
		var tier := int(e.get("enemy_tier", 0))
		if tier < 1 or tier > 3 or float(e.get("reward_multiplier", 0.0)) < 1.0:
			tiers_ok = false
		kinds[str(e.get("enemy_kind", ""))] = true
		if int(e.get("base_vitality", 0)) <= 0 or int(e.get("base_strength", 0)) <= 0:
			tiers_ok = false
	_check(tiers_ok, "gerador cria inimigos com tier 1-3, recompensa >= 1 e VIT/STR válidos")
	_check(kinds.has("melee") and kinds.has("ranged"), "gerador cria inimigos melee e ranged")
	# Gerador com itens (jogo real passa a pool): sai sempre com arma equipada.
	var geared := true
	for i in 20:
		var e: Dictionary = CombatResolverScript.generate_enemy(5, items)
		var eq: Dictionary = e.get("equipped", {})
		var weapon_id := str(eq.get("weapon", ""))
		if weapon_id == "":
			geared = false
		if not eq.is_empty():
			var fighter = _fighter(e)
			if fighter.strength <= 0 or fighter.max_health <= 0:
				geared = false
	_check(geared, "gerador com itens equipa sempre uma arma e mantém status válidos")

func _test_attribute_definitions() -> void:
	var definitions := EconomySystemScript.attribute_definitions()
	_check(definitions.size() == 7, "existem SETE atributos (STR/ATT/DEF/AGI/VIT/CHA/SOR)")
	var ids := {}
	for definition: Dictionary in definitions:
		var attribute_id := str(definition.get("id", ""))
		ids[attribute_id] = true
		_check(definition.has("label") and definition.has("short"), "atributo %s tem label e sigla" % attribute_id)
	_check(ids.has("strength") and ids.has("attack") and ids.has("defence") and ids.has("agility") and ids.has("vitality") and ids.has("charisma") and ids.has("luck"), "os 7 ids são STR/ATT/DEF/AGI/VIT/CHA/SOR (luck = SOR)")
	_check(not ids.has("stamina") and not ids.has("magicka"), "STA e MAG não existem nesta versão")

func _test_item_data_defaults() -> void:
	var item = ItemDataScript.new({"id": "tempered_blade", "display_name": "Lamina temperada", "slot": "weapon", "price": 45, "strength_bonus": 2, "attack_bonus": 1, "armour": 3})
	_check(item.slot == "weapon", "ItemData le slot do JSON")
	_check(int(item.price) == 45, "ItemData le preco do JSON")
	_check(int(item.strength_bonus) == 2 and int(item.attack_bonus) == 1 and int(item.armour) == 3, "ItemData le os bonus novos do JSON")

## O nome do item tem que acompanhar o preço dentro do tipo: em cada estoque gerado,
## um item mais caro nunca pode ter substantivo mais fraco na ordem canônica do
## data/*.json.
func _test_shop_names_follow_power() -> void:
	var samples := 0
	var wrong := 0
	var example := ""
	for category: Dictionary in ItemGeneratorScript.top_categories():
		for sub: Dictionary in category.get("subtypes", []):
			var canonical: Array = sub.get("nouns", [])
			for attempt in 30:
				var items: Array = ItemGeneratorScript.generate_shop_stock(3).get(str(sub.get("id", "")), [])
				samples += 1
				for a: Dictionary in items:
					for b: Dictionary in items:
						if int(a.get("price", 0)) >= int(b.get("price", 0)):
							continue
						var index_a: int = canonical.find(str(a.get("display_name", "")))
						var index_b: int = canonical.find(str(b.get("display_name", "")))
						if index_a > index_b:
							wrong += 1
							if example == "":
								example = "%s: %s (%d ouro) mais caro que %s (%d ouro)" % [
									str(sub.get("label", "?")), str(a.get("display_name", "?")), int(a.get("price", 0)),
									str(b.get("display_name", "?")), int(b.get("price", 0))]
	_check(wrong == 0, "nome do item acompanha o preco no mesmo tipo (%d estoques%s)" % [
		samples, "" if wrong == 0 else " - %d pares fora de ordem, ex: %s" % [wrong, example]])

func _test_experience_curve() -> void:
	var best := 999.0
	var worst := 0.0
	for level in range(1, 16):
		var xp: int = int(EconomySystemScript.fight_rewards(level).experience)
		var needed: int = EconomySystemScript.required_experience(level)
		var fights := float(needed) / float(maxi(1, xp))
		best = minf(best, fights)
		worst = maxf(worst, fights)
		_check(xp < needed, "nível %d: uma luta não dá um nível (XP %d de %d exigidos)" % [level, xp, needed])
	_check(best >= 3.0, "mínimo de 3 lutas por nível na fase mais rápida (medido %.1f)" % best)
	_check(worst <= 5.5, "máximo de 5,5 lutas por nível na fase mais lenta (medido %.1f)" % worst)

func _test_streak_does_not_boost_experience() -> void:
	var best_case := 0
	for level in range(1, 16):
		var base: int = int(EconomySystemScript.fight_rewards(level).experience)
		var per_fight := int(round(float(base) * EconomySystemScript.tier_experience_multiplier(3)))
		best_case = per_fight
		var fights := int(ceil(float(EconomySystemScript.required_experience(level)) / float(maxi(1, per_fight))))
		_check(fights >= 3, "nível %d: mesmo no melhor caso são %d lutas para subir (mínimo 3)" % [level, fights])
	_check(EconomySystemScript.streak_reward_multiplier(10) > 1.0, "a sequência continua premiando o ouro")
	_check(best_case > 0, "o cálculo do XP por luta é positivo")

func _test_sell_rules() -> void:
	_check(EconomySystemScript.sell_price({"id": "teste", "price": 100}) == 40, "venda devolve 40 por cento do preço")
	var trophy := {"id": "gladius_magnus", "display_name": "Gládio", "price": 250, "unique": true}
	_check(EconomySystemScript.sell_price(trophy) == 0, "item único não tem preço de venda")
	_check(not EconomySystemScript.is_sellable(trophy), "item único não é vendável")
	_check(EconomySystemScript.sell_price({}) == 0, "item vazio não tem preço de venda")

func _test_bag_and_unequip() -> void:
	var player = _fighter({"id": "p", "base_strength": 10, "base_vitality": 8})
	var sword := {"id": "sw1", "display_name": "Espada", "slot": "weapon", "price": 100, "strength_bonus": 4}
	player.remember_item(sword)
	_check(player.bag_items().size() == 1, "item lembrado aparece na bolsa")
	player.equip_item(sword)
	_check(player.equipped_id("weapon") == "sw1" and player.bag_items().is_empty(), "equipar tira o item da bolsa")
	_check(player.strength == 14, "equipar aplica o bônus")
	_check(not player.remove_owned("sw1"), "item equipado não pode ser removido da bolsa")
	_check(player.unequip("weapon") and player.equipped_id("weapon") == "", "desequipar limpa o slot")
	_check(player.strength == 10, "desequipar devolve o atributo")
	_check(player.bag_items().size() == 1, "item desequipado volta para a bolsa")
	_check(player.remove_owned("sw1") and player.bag_items().is_empty(), "item desequipado pode ser removido")

func _test_archetypes_content() -> void:
	var archetypes: Array[Dictionary] = ContentRepositoryScript.load_archetypes()
	_check(archetypes.size() == 3, "archetypes.json tem 3 arquétipos")
	var ids := {}
	for entry: Dictionary in archetypes:
		var arch_id := str(entry.get("id", ""))
		_check(arch_id != "" and str(entry.get("display_name", "")) != "", "arquétipo %s tem id e nome" % arch_id)
		_check(int(entry.get("base_health", 0)) > 0 and int(entry.get("base_attack", 0)) > 0 and int(entry.get("base_defense", 0)) >= 0, "arquétipo %s tem atributos" % arch_id)
		var skill: Dictionary = entry.get("skill", {})
		_check(float(skill.get("multiplier", 0.0)) > 0.0 and float(skill.get("accuracy", 0.0)) > 0.0, "arquétipo %s tem habilidade com números" % arch_id)
		ids[arch_id] = true
	_check(ids.size() == archetypes.size(), "ids de arquétipos únicos")
	var duelist = _fighter({"id": "p", "archetype_id": "duelist", "base_vitality": 10})
	_check(duelist.archetype_id == "duelist", "GladiatorData guarda archetype_id")

## O save novo preserva os 7 atributos; o save ANTIGO (4 stats) migra sem zerar.
func _test_save_roundtrip_and_migration() -> void:
	var test_path := "user://tests_save.json"
	var fighter = _fighter({"id": "p", "display_name": "Tester", "level": 3, "gold": 99, "base_strength": 10, "base_attack": 8, "base_defence": 4, "base_agility": 6, "base_vitality": 9, "base_charisma": 7, "base_luck": 6, "pending_points": 3})
	fighter.equip_weapon(ContentRepositoryScript.find_item(ContentRepositoryScript.load_items(), "dagger"))
	_check(SaveSystemScript.save_game({"version": 2, "stage_index": 2, "player": fighter.to_save_data()}, test_path), "save_game grava o arquivo")
	_check(SaveSystemScript.has_save(test_path), "has_save detecta o arquivo")
	var data := SaveSystemScript.load_game(test_path)
	var loaded = _fighter(data.get("player", {}))
	_check(loaded.level == 3 and loaded.gold == 99 and loaded.strength == 12, "load recupera nivel/ouro/atributos/equipamento")
	_check(loaded.luck == 7 and loaded.pending_points == 3 and int(data.get("stage_index", -1)) == 2, "load recupera SOR, pontos pendentes e progresso")
	SaveSystemScript.delete_save(test_path)
	_check(not SaveSystemScript.has_save(test_path), "delete_save remove o arquivo")
	# Migração do formato antigo (health/attack/defense/luck).
	var old = _fighter({"id": "old", "base_max_health": 60, "base_attack": 10, "base_defense": 4, "base_luck": 6, "health": 60})
	_check(old.strength == 10 and old.defence == 4 and old.luck == 6, "save antigo migra attack→STR, defense→DEF, luck→SOR")
	_check(old.max_health > 0 and old.base_vitality > 0, "save antigo migra health→VIT sem zerar")

func _test_movement_and_range() -> void:
	_check(CombatResolverScript.move_toward(3) == 2 and CombatResolverScript.move_toward(1) == 1, "avancar reduz a distancia respeitando o minimo")
	_check(CombatResolverScript.move_away(3) == 4 and CombatResolverScript.move_away(6) == 6, "recuar aumenta a distancia respeitando o maximo")
	var melee := {"kind": "melee", "reach": 1}
	var ranged := {"kind": "ranged"}
	_check(CombatResolverScript.can_attack_at(1, melee) and not CombatResolverScript.can_attack_at(2, melee), "melee so acerta dentro do alcance")
	_check(CombatResolverScript.can_attack_at(6, ranged), "ranged ataca de qualquer distancia")
	_check(CombatResolverScript.ranged_accuracy(1.0, 3) < CombatResolverScript.ranged_accuracy(1.0, 1), "ranged erra mais quanto maior a distancia")
	var attacker = _fighter({"id": "a", "base_attack": 0, "base_strength": 12, "base_agility": 0, "base_defence": 0, "base_vitality": 20})
	var defender = _fighter({"id": "d", "base_attack": 0, "base_strength": 6, "base_agility": 0, "base_defence": 0, "base_vitality": 20})
	var out_range: Dictionary = CombatResolverScript.resolve_positional_attack(attacker, defender, melee, 3, 1.0, 1.0, 0)
	_check(bool(out_range.get("out_of_range", false)) and not bool(out_range.hit), "melee fora de alcance nao acerta")
	var hp_before: int = defender.health
	CombatResolverScript.resolve_positional_attack(attacker, defender, melee, 1, 1.0, 1.0, 0)
	_check(defender.health < hp_before or defender.armour < defender.max_armour, "melee em alcance causa dano")

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok - %s" % label)
	else:
		_failures += 1
		printerr("  FALHOU - %s" % label)
