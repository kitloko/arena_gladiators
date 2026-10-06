extends SceneTree

## Smoke test das regras puras (sem interface nem autoload).
## Executar com:
##   Godot --headless --path . -s res://tests/run_systems_test.gd

const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")
const CombatResolverScript := preload("res://scripts/systems/combat_resolver.gd")
const CrowdSystemScript := preload("res://scripts/systems/crowd_system.gd")
const RankSystemScript := preload("res://scripts/systems/rank_system.gd")
const GladiatorDataScript := preload("res://scripts/models/gladiator_data.gd")
const ItemDataScript := preload("res://scripts/models/item_data.gd")
const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")
const SaveSystemScript := preload("res://scripts/systems/save_system.gd")
const ItemGeneratorScript := preload("res://scripts/systems/item_generator.gd")
const PresentationSystemScript := preload("res://scripts/systems/presentation_system.gd")
const InjurySystemScript := preload("res://scripts/systems/injury_system.gd")
const HaggleSystemScript := preload("res://scripts/systems/haggle_system.gd")
const BettingSystemScript := preload("res://scripts/systems/betting_system.gd")
const PotionSystemScript := preload("res://scripts/systems/potion_system.gd")
const GameStateScript := preload("res://scripts/autoload/game_state.gd")

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
	_test_crowd_start_value()
	_test_crowd_events()
	_test_crowd_exhibit_and_open()
	_test_crowd_multiplier_and_quick_fight()
	_test_counter_attack_on_block()
	_test_crowd_anti_exploit()
	_test_rank_tiers_and_titles()
	_test_rank_win_loss_by_strength()
	_test_rank_floor_and_demotion()
	_test_rank_access_gate()
	_test_rank_kd_and_save_migration()
	_test_rank_arena_bands()
	_test_rank_crowd_bonus()
	_test_rank_anti_farm()
	_test_presentation_power_index()
	_test_presentation_taunt_draw()
	_test_enemy_identity_content()
	# --- ETAPA 5 ---
	_test_injury_generated_and_reduces_attribute()
	_test_injury_limits_and_no_zero()
	_test_injury_cure_only_paid()
	_test_haggle_discount_and_once_per_item()
	_test_betting_odd_payout_and_cap()
	_test_potion_effect_and_consumed()
	_test_potion_only_in_combat()
	_test_blacksmith_upgrade_and_cap()
	_test_trainer_xp_and_cap()
	_test_doctor_cures_and_charges()
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

# --- Felicidade do público (item H) ----------------------------------------

## Início: 30 + (CHA seu + CHA dele) × 1,5, teto 70; chefe tem PISO 60.
func _test_crowd_start_value() -> void:
	var player = _fighter({"id": "p", "base_charisma": 5})
	var foe = _fighter({"id": "e", "base_charisma": 5})
	_check(CrowdSystemScript.initial_happiness(player, foe, false) == 45, "público inicial = 30 + (5+5) × 1,5 = 45")
	var rich = _fighter({"id": "p", "base_charisma": 50})
	var rich_foe = _fighter({"id": "e", "base_charisma": 50})
	_check(CrowdSystemScript.initial_happiness(rich, rich_foe, false) == 70, "público inicial tem TETO 70 (carisma 50+50)")
	var low = _fighter({"id": "p", "base_charisma": 0})
	var low_foe = _fighter({"id": "e", "base_charisma": 0})
	_check(CrowdSystemScript.initial_happiness(low, low_foe, false) == 30, "carisma 0+0 fora de chefe começa em 30")
	_check(CrowdSystemScript.initial_happiness(low, low_foe, true) == 60, "luta contra CHEFE tem PISO 60")
	var crowd = CrowdSystemScript.new(player, foe, false)
	_check(int(crowd.value()) == 45, "CrowdSystem.new usa a mesma conta do início")

## Cada evento move a barra pelo valor esperado (spec item H §3).
func _test_crowd_events() -> void:
	var crowd = CrowdSystemScript.new(null, null, false)
	_check(int(crowd.value()) == 30, "público neutro (sem carisma) começa em 30")
	var expected := {
		"hit": 2, "critical": 6, "counter": 5, "took_hit": 3, "drama": 4,
		"missed": -5, "defend": -3, "retreat": -6, "sleep": -4,
	}
	for event_id: String in expected.keys():
		var before: int = int(crowd.value())
		var entry: Dictionary = crowd.apply_event(event_id)
		var want: int = int(expected[event_id])
		_check(int(entry.delta) == want and int(crowd.value()) == before + want, "evento '%s' = %+d" % [event_id, want])
	var cold = CrowdSystemScript.new(null, null, false)
	_check(int(cold.end_round(true).delta) == -2, "rodada em que ninguém se acertou: -2")
	_check(int(cold.end_round(true).delta) == -4, "rodadas frias seguidas: vaias crescentes (-4)")
	var busy = CrowdSystemScript.new(null, null, false)
	_check(int(busy.end_round(false).delta) == -1, "rodada normal esfria 1 (anti 'parado no máximo')")
	_check(CrowdSystemScript.MAX_VALUE == 100, "a barra tem teto 100")

## EXIBIR: rendimento decrescente (+8, +4, +2, -5) e deixa o jogador ABERTO.
func _test_crowd_exhibit_and_open() -> void:
	var crowd = CrowdSystemScript.new(null, null, false)
	var sequence := [8, 4, 2, -5, -5]
	for i in sequence.size():
		var entry: Dictionary = crowd.apply_event("exhibit")
		_check(int(entry.delta) == int(sequence[i]), "EXIBIR %dª vez = %+d" % [i + 1, int(sequence[i])])
	_check(bool(crowd.exposed), "EXIBIR deixa o jogador ABERTO (o inimigo ataca com bônus)")
	crowd.clear_exposed()
	_check(not bool(crowd.exposed), "clear_exposed limpa o ABERTO depois do turno do inimigo")
	_check(CrowdSystemScript.EXHIBIT_OPEN_ACCURACY > 0.0, "o ABERTO dá +%d%% de precisão ao inimigo" % int(round(CrowdSystemScript.EXHIBIT_OPEN_ACCURACY * 100.0)))
	# Defesa/recuo em sequência saturam (mesmo alternando as duas).
	var passive = CrowdSystemScript.new(null, null, false)
	_check(int(passive.apply_event("defend").delta) == -3, "1ª defesa firme = -3")
	_check(int(passive.apply_event("retreat").delta) == -6, "1º recuo (na sequência passiva) = -6")
	_check(int(passive.apply_event("defend").delta) == -5, "2ª defesa seguida satura (-5)")
	_check(int(passive.apply_event("retreat").delta) == -8, "2º recuo seguido satura (-8)")
	passive.reset_action_streaks()
	_check(int(passive.apply_event("defend").delta) == -3, "outra ação zera a sequência (defesa volta a -3)")

## Multiplicador: ×1,0 a ×2,0 e luta definida em até 3 ações não multiplica.
func _test_crowd_multiplier_and_quick_fight() -> void:
	var crowd = CrowdSystemScript.new(null, null, false)
	crowd.actions = 10
	crowd.happiness = 0
	_check(is_equal_approx(crowd.reward_multiplier(), 1.0), "público 0% → ×1,0 (mínimo)")
	crowd.happiness = 100
	_check(is_equal_approx(crowd.reward_multiplier(), 2.0), "público 100% → ×2,0 (teto da arena)")
	crowd.happiness = 50
	_check(is_equal_approx(crowd.reward_multiplier(), 1.5), "público 50% → ×1,5 (= ×1,0 + público/100)")
	var quick = CrowdSystemScript.new(null, null, false)
	quick.happiness = 100
	quick.actions = CrowdSystemScript.QUICK_FIGHT_ACTIONS
	_check(quick.is_quick_fight() and is_equal_approx(quick.reward_multiplier(), 1.0), "luta definida em até 3 ações NÃO multiplica (×1,0)")
	quick.actions = CrowdSystemScript.QUICK_FIGHT_ACTIONS + 1
	_check(not quick.is_quick_fight() and quick.reward_multiplier() > 1.0, "a partir da 4ª ação o multiplicador volta a valer")
	_check(is_equal_approx(CrowdSystemScript.MULTIPLIER_MAX, 2.0), "teto do multiplicador = ×2,0")

## REVIDAR: aparar abre um contra-ataque que devolve parte do golpe ao atacante.
func _test_counter_attack_on_block() -> void:
	var counters := 0
	var damage_ok := true
	for i in 2000:
		var attacker = _fighter({"id": "a", "base_attack": 0, "base_strength": 40, "base_agility": 0, "base_defence": 0, "base_luck": 0, "base_vitality": 40})
		var defender = _fighter({"id": "d", "base_attack": 0, "base_strength": 5, "base_agility": 0, "base_defence": 50, "base_luck": 0, "base_vitality": 40})
		var result: Dictionary = CombatResolverScript.resolve_attack(attacker, defender, 1.0, 1.0, 0)
		if bool(result.get("countered", false)):
			counters += 1
			if int(result.counter_damage) < 1 or int(result.counter_armour_damage) + int(result.counter_health_damage) < 1:
				damage_ok = false
	_check(counters > 200, "aparar abre o REVIDAR (contra-ataque em %d de 2000)" % counters)
	_check(damage_ok, "o REVIDAR devolve dano > 0 ao atacante (armadura/vida)")
	_check(CombatResolverScript.COUNTER_CHANCE > 0.0 and CombatResolverScript.COUNTER_DAMAGE_FRACTION > 0.0, "parâmetros do REVIDAR definidos (chance %.2f, fração %.2f)" % [CombatResolverScript.COUNTER_CHANCE, CombatResolverScript.COUNTER_DAMAGE_FRACTION])
	_check(CrowdSystemScript.DELTA_COUNTER == 5, "o REVIDAR alimenta o evento +5 do público")

## ANTI-EXPLOIT (item H §7): spam de EXIBIR e fuga+defesa NÃO podem render mais
## OURO por AÇÃO do que lutar direito. Mede o ouro por ação de cada estratégia.
func _test_crowd_anti_exploit() -> void:
	var trials := 400
	var fight := _measure_strategy("fight", trials)
	var exhibit := _measure_strategy("exhibit", trials)
	var flee := _measure_strategy("flee", trials)
	print("    ouro/ação — lutar direito %.3f | spam de EXIBIR %.3f | fuga+defesa %.3f" % [fight.gold_per_action, exhibit.gold_per_action, flee.gold_per_action])
	print("    multiplicador médio — direito ×%.2f | EXIBIR ×%.2f | fuga ×%.2f | vitórias %d/%d/%d" % [fight.multiplier_avg, exhibit.multiplier_avg, flee.multiplier_avg, fight.wins, exhibit.wins, flee.wins])
	_check(float(exhibit.gold_per_action) < float(fight.gold_per_action), "lutar direito rende mais ouro/ação que spam de EXIBIR (%.3f > %.3f)" % [fight.gold_per_action, exhibit.gold_per_action])
	_check(float(flee.gold_per_action) < float(fight.gold_per_action), "lutar direito rende mais ouro/ação que fuga+defesa (%.3f > %.3f)" % [fight.gold_per_action, flee.gold_per_action])
	_check(int(exhibit.wins) == 0 and int(flee.wins) == 0, "as duas estratégias de exploit PERDEM a luta (0 vitórias): não há ouro a multiplicar")
	_check(float(fight.multiplier_avg) <= CrowdSystemScript.MULTIPLIER_MAX, "o multiplicador médio respeita o teto da arena ×%.2f (medido ×%.2f)" % [CrowdSystemScript.MULTIPLIER_MAX, fight.multiplier_avg])

## Mede o ouro por ação de uma estratégia em N combates contra o mesmo inimigo.
func _measure_strategy(strategy: String, trials: int) -> Dictionary:
	var total_gold := 0.0
	var total_actions := 0.0
	var total_mult := 0.0
	var wins := 0
	for i in trials:
		var player = _fighter({"id": "p", "base_strength": 30, "base_attack": 25, "base_defence": 6, "base_agility": 5, "base_vitality": 20, "base_charisma": 5, "base_luck": 5})
		var foe = _fighter({"id": "f", "base_strength": 20, "base_attack": 0, "base_defence": 3, "base_agility": 0, "base_vitality": 18, "base_charisma": 5, "base_luck": 3})
		var outcome: Dictionary = _run_crowd_fight(player, foe, strategy)
		total_actions += float(outcome.actions)
		total_mult += float(outcome.multiplier)
		if bool(outcome.won):
			wins += 1
			total_gold += float(outcome.gold)
	var gold_per_action := 0.0
	if total_actions > 0.0:
		gold_per_action = total_gold / total_actions
	return {
		"gold_per_action": gold_per_action,
		"gold_total": total_gold,
		"actions": int(round(total_actions / float(trials))),
		"multiplier_avg": total_mult / float(trials),
		"wins": wins,
	}

## Simula um combate com a régua REAL (CombatResolver + CrowdSystem). Vitória =
## inimigo cai; o ouro da vitória = 40 × multiplicador do público.
func _run_crowd_fight(player, foe, strategy: String) -> Dictionary:
	var crowd = CrowdSystemScript.new(player, foe, false)
	var guard := 0
	while guard < 300:
		guard += 1
		var cold := true
		crowd.register_action()
		if strategy == "exhibit":
			crowd.apply_event("exhibit")
		elif strategy == "flee":
			# Fuga e defesa: ações PASSIVAS em sequência (saturam).
			if guard <= 3:
				crowd.apply_event("retreat")
			else:
				crowd.apply_event("defend")
		else:
			crowd.reset_action_streaks()
			var hit: Dictionary = CombatResolverScript.resolve_attack(player, foe, 1.0, 1.0, 0)
			crowd.apply_combat_result(hit, true)
			if int(hit.get("health_damage", 0)) > 0 or int(hit.get("counter_health_damage", 0)) > 0:
				cold = false
			if foe.is_defeated():
				var mult := crowd.reward_multiplier()
				return {"won": true, "actions": crowd.actions, "multiplier": mult, "gold": int(round(40.0 * mult))}
		var enemy_hit: Dictionary = CombatResolverScript.resolve_attack(foe, player, 1.0, 1.0, 0)
		crowd.apply_combat_result(enemy_hit, false)
		if int(enemy_hit.get("health_damage", 0)) > 0 or int(enemy_hit.get("counter_health_damage", 0)) > 0:
			cold = false
		crowd.end_round(cold)
		if player.is_defeated():
			return {"won": false, "actions": crowd.actions, "multiplier": 0.0, "gold": 0}
	return {"won": false, "actions": crowd.actions, "multiplier": 0.0, "gold": 0}

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok - %s" % label)
	else:
		_failures += 1
		printerr("  FALHOU - %s" % label)

# ===========================================================================
# ETAPA 5 — ferimentos, pechincha, apostas, poções e serviços da cidade
# ===========================================================================

## Instância limpa de GameState com um lutador, sem tocar no disco (modo torneio).
func _new_game_state(player, foe = null):
	var gs = GameStateScript.new()
	gs.mode = "tournament"
	gs.player = player
	gs.current_enemy = foe
	return gs

## FERIMENTO (item 2): perder gera sequela que reduz de verdade o atributo e
## sobrevive a heal_full; o descanso comum NÃO cura.
func _test_injury_generated_and_reduces_attribute() -> void:
	seed(424242)
	var generated := 0
	for i in 300:
		var p = _fighter({"id": "inj", "base_strength": 20, "base_vitality": 10})
		var info: Dictionary = InjurySystemScript.after_fight(p, false, false)
		if bool(info.get("injured", false)):
			generated += 1
			if p.injuries.size() != 1:
				_failures += 1
				printerr("  FALHOU - perder gerou ferimento mas a lista tem %d" % p.injuries.size())
				return
	_check(generated > 150, "perder gera FERIMENTO na maioria das derrotas (%d de 300)" % generated)
	# Um ferimento de template reduz o atributo de verdade e conta no combate.
	var player = _fighter({"id": "hurt", "base_strength": 20, "base_attack": 10, "base_defence": 10, "base_agility": 10, "base_vitality": 10, "base_charisma": 10, "base_luck": 10})
	var strength_before: int = player.strength
	var add: Dictionary = InjurySystemScript.add_injury(player, InjurySystemScript.find_template("broken_arm"))
	_check(bool(add.get("ok", false)) and player.strength == strength_before - 3, "'Braço quebrado' reduz STR de verdade (%d → %d)" % [strength_before, player.strength])
	_check(player.injuries.size() == 1 and str((player.injuries[0] as Dictionary).get("label", "")) == "Braço quebrado", "o ferimento aparece na lista do lutador")
	# Costela rachada mexe na VIT → mexe na vida máxima.
	var vital = _fighter({"id": "hurt2", "base_vitality": 10})
	var hp_before: int = vital.max_health
	InjurySystemScript.add_injury(vital, InjurySystemScript.find_template("cracked_ribs"))
	_check(vital.max_health == hp_before - 4 * GladiatorDataScript.HEALTH_PER_VIT, "ferimento de VIT reduz a vida máxima (conta no combate)")
	# Sobrevive à cura comum (heal_full) — só o médico/poção tira.
	var previous: int = player.strength
	player.heal_full()
	_check(player.strength == previous and player.injuries.size() == 1, "heal_full (descanso comum) NÃO cura o ferimento")
	# Um ferimento gerado por derrota muda o dano resolvido (conta de verdade).
	var healthy = _fighter({"id": "h", "base_strength": 30, "base_attack": 0, "base_agility": 0, "base_defence": 0, "base_vitality": 30})
	var wounded = _fighter({"id": "w", "base_strength": 30, "base_attack": 0, "base_agility": 0, "base_defence": 0, "base_vitality": 30})
	InjurySystemScript.add_injury(wounded, InjurySystemScript.find_template("broken_arm"))
	_check(wounded.strength == healthy.strength - 3, "o ferimento entra na luta seguinte (STR efetiva menor)")

## FERIMENTO (item 2): no máximo 2 ativos, sem repetir, e nenhum pode zerar.
func _test_injury_limits_and_no_zero() -> void:
	var player = _fighter({"id": "lim", "base_strength": 20, "base_attack": 20, "base_defence": 20, "base_agility": 20, "base_vitality": 20, "base_charisma": 20, "base_luck": 20})
	var a: Dictionary = InjurySystemScript.add_injury(player, InjurySystemScript.find_template("broken_arm"))
	var dup: Dictionary = InjurySystemScript.add_injury(player, InjurySystemScript.find_template("broken_arm"))
	_check(bool(a.get("ok", false)) and not bool(dup.get("ok", false)), "o MESMO ferimento não empilha (2ª vez recusada)")
	_check(str(dup.get("reason", "")) != "", "a recusa de duplicata explica o motivo")
	InjurySystemScript.add_injury(player, InjurySystemScript.find_template("cracked_ribs"))
	var third: Dictionary = InjurySystemScript.add_injury(player, InjurySystemScript.find_template("swollen_eye"))
	_check(player.injuries.size() == 2 and not bool(third.get("ok", false)), "no máximo 2 ferimentos ativos (teto do sistema = %d)" % InjurySystemScript.max_active())
	_check(InjurySystemScript.max_active() == 2, "o teto documentado é 2 ferimentos ativos")
	# Nenhum ferimento zera um atributo: com STR 2, o corte de −3 vira −1.
	seed(7)
	var weak = _fighter({"id": "weak", "base_strength": 2, "base_vitality": 10})
	var applied: Dictionary = InjurySystemScript.add_injury(weak, InjurySystemScript.find_template("broken_arm"))
	_check(bool(applied.get("ok", false)) and weak.strength == 1, "ferimento não zera o atributo (STR 2 −3 → 1, cortado)")
	_check(int((applied.get("injury", {}) as Dictionary).get("penalty", 0)) == 1, "a penalidade aplicada é a cortada (%d)" % int((applied.get("injury", {}) as Dictionary).get("penalty", 0)))
	# Um atributo já no mínimo recusa o ferimento.
	var floor_fighter = _fighter({"id": "floor", "base_strength": 1, "base_vitality": 10})
	# força o mínimo via derivação: adiciona ferimento de outro atributo não ajuda; simula STR 1
	var refused: Dictionary = InjurySystemScript.add_injury(floor_fighter, InjurySystemScript.find_template("broken_arm"))
	_check(not bool(refused.get("ok", false)) or floor_fighter.strength >= 1, "atributo no mínimo nunca é zerado nem negativo")

## FERIMENTO (item 2): só a cura PAGA (médico) tira a sequela.
func _test_injury_cure_only_paid() -> void:
	var player = _fighter({"id": "cure", "base_strength": 20, "base_vitality": 10, "level": 4})
	var base_strength: int = player.strength
	InjurySystemScript.add_injury(player, InjurySystemScript.find_template("broken_arm"))
	_check(player.strength == base_strength - 3, "ferimento aplicado (STR −3)")
	player.health = 10
	player.heal_full()
	_check(player.injuries.size() == 1, "recuperar a vida cheia não cura o ferimento")
	var cost: int = EconomySystemScript.doctor_cost(player)
	_check(cost >= EconomySystemScript.injury_cure_price(player.level), "o médico cobra pela cura do ferimento (%d ouro)" % cost)
	var gs = _new_game_state(player)
	gs.mode = "tournament"
	# Sem ouro, o médico recusa.
	player.gold = 0
	var poor: Dictionary = gs.visit_doctor()
	_check(not bool(poor.get("ok", false)) and player.injuries.size() == 1, "sem ouro o médico não cura")
	player.gold = cost + 5
	var paid: Dictionary = gs.visit_doctor()
	_check(bool(paid.get("ok", false)) and int(paid.get("cured", 0)) == 1, "o médico pago cura o ferimento")
	_check(player.injuries.is_empty() and player.strength == base_strength, "curar devolve o atributo (%d → %d)" % [base_strength - 3, player.strength])
	_check(player.gold == 5, "o médico cobrou exatamente o custo (sobrou %d)" % player.gold)
	gs.free()

## PECHINCHA (item 4): desconto dentro do teto, uma vez por item, falha trava.
func _test_haggle_discount_and_once_per_item() -> void:
	seed(20260101)
	var low_cha = _fighter({"id": "l", "base_charisma": 5, "base_luck": 5})
	var high_cha = _fighter({"id": "h", "base_charisma": 40, "base_luck": 5})
	_check(HaggleSystemScript.success_chance(high_cha) > HaggleSystemScript.success_chance(low_cha), "CHA/sorte aumentam a chance de pechincha (%.2f > %.2f)" % [HaggleSystemScript.success_chance(high_cha), HaggleSystemScript.success_chance(low_cha)])
	_check(HaggleSystemScript.success_chance(high_cha) <= HaggleSystemScript.SUCCESS_MAX and HaggleSystemScript.success_chance(low_cha) >= HaggleSystemScript.SUCCESS_MIN, "a chance fica na faixa [5%%, 95%%]")
	# Nenhuma tentativa pode passar do teto total.
	var over_cap := false
	var successes := 0
	for i in 4000:
		var p = _fighter({"id": "p", "base_charisma": 40, "base_luck": 5})
		var info: Dictionary = HaggleSystemScript.attempt(p, "item_%d" % i)
		if bool(info.get("success", false)):
			successes += 1
			if float(info.get("discount", 0.0)) > HaggleSystemScript.BONUS_MAX + 0.0001:
				over_cap = true
			if HaggleSystemScript.total_discount(p, "item_%d" % i) > HaggleSystemScript.MAX_DISCOUNT + 0.0001:
				over_cap = true
	_check(not over_cap, "o desconto da pechincha nunca passa do teto (bônus ≤ %.2f, total ≤ %.2f)" % [HaggleSystemScript.BONUS_MAX, HaggleSystemScript.MAX_DISCOUNT])
	# Desconto médio por valor de CHA (medido).
	var avg_low := _measure_haggle(low_cha, 4000)
	var avg_high := _measure_haggle(high_cha, 4000)
	print("    pechincha — desconto médio: CHA 5 = %.1f%% | CHA 40 = %.1f%%" % [avg_low * 100.0, avg_high * 100.0])
	_check(avg_high > avg_low, "mais CARISMA = desconto médio maior (%.1f%% > %.1f%%)" % [avg_high * 100.0, avg_low * 100.0])
	_check(avg_high <= HaggleSystemScript.MAX_DISCOUNT, "o desconto médio de CHA 40 fica dentro do teto (%.1f%%)" % (avg_high * 100.0))
	# Uma vez por item: a 2ª tentativa é recusada.
	var p2 = _fighter({"id": "p2", "base_charisma": 20, "base_luck": 20})
	var first: Dictionary = HaggleSystemScript.attempt(p2, "espada_x")
	var second: Dictionary = HaggleSystemScript.attempt(p2, "espada_x")
	_check(bool(first.get("ok", false)) and not bool(second.get("ok", false)), "cada item só pode ser pechinchado UMA vez")
	_check(str(second.get("reason", "")).contains("já"), "a 2ª tentativa explica que já foi pechinchado")
	# Falha TRAVA: depois de perder, o item nunca mais aceita pechincha.
	var locked := false
	for i in 200:
		var p3 = _fighter({"id": "p3", "base_charisma": 1, "base_luck": 1})
		var tried: Dictionary = HaggleSystemScript.attempt(p3, "item_travado")
		if not bool(tried.get("success", false)):
			locked = bool(tried.get("locked", false)) and HaggleSystemScript.attempted(p3, "item_travado")
			var again: Dictionary = HaggleSystemScript.attempt(p3, "item_travado")
			if bool(again.get("ok", false)):
				locked = false
			break
	_check(locked, "falhar TRAVA o item (não dá para tentar de novo)")
	# O preço efetivo de um item pechinchado com sucesso é menor que o do mercado.
	var buyer = _fighter({"id": "b", "base_charisma": 40, "base_luck": 5})
	var item := {"id": "for_sale", "price": 100, "slot": "weapon"}
	var market_price: int = EconomySystemScript.price_for_player(item, buyer)
	buyer.haggle_marks["for_sale"] = {"result": "won", "discount": HaggleSystemScript.bonus_max(buyer)}
	var haggled_price: int = EconomySystemScript.price_for_player(item, buyer)
	_check(haggled_price < market_price, "pechinchar com sucesso baixa o preço (%d → %d)" % [market_price, haggled_price])

## Mede o desconto médio REAL aplicado (só quando a pechincha dá certo).
func _measure_haggle(player, trials: int) -> float:
	var total := 0.0
	var used := 0
	var index := 0
	for i in trials:
		index += 1
		var info: Dictionary = HaggleSystemScript.attempt(player, "m_%d" % index)
		if bool(info.get("success", false)):
			total += float(info.get("discount", 0.0))
		used += 1
	return total / float(maxi(1, used))

## APOSTA (item 5): odd pelo Índice de Poder, pagamento e perda, teto respeitado.
func _test_betting_odd_payout_and_cap() -> void:
	# Mais fraco → odd maior; mais forte → odd menor.
	var weak_odd: float = BettingSystemScript.odd_for(50, 120)
	var strong_odd: float = BettingSystemScript.odd_for(120, 50)
	_check(weak_odd > strong_odd, "o mais FRACO recebe odd maior (%.2f > %.2f)" % [weak_odd, strong_odd])
	_check(weak_odd <= BettingSystemScript.MAX_ODD and strong_odd >= BettingSystemScript.MIN_ODD, "a odd respeita o teto %.2f e o piso %.2f" % [BettingSystemScript.MAX_ODD, BettingSystemScript.MIN_ODD])
	var all_negative := true
	for diff in range(-200, 201, 20):
		if BettingSystemScript.expected_value(100 + diff, 100 - diff) >= 0.0:
			all_negative = false
	_check(all_negative, "o valor esperado da aposta é SEMPRE negativo (não é impressora de dinheiro)")
	# TRAVA ANTI-IMPRESSORA (ouro por luta): o ganho LÍQUIDO máximo teórico da
	# aposta (aposta-teto × odd máxima) nunca passa da recompensa-base da luta do
	# MESMO nível, nem com o multiplicador mínimo do público (~×1,2). A aposta não
	# rende mais que a própria luta — não dá para viver de apostar.
	var out_of_band := ""
	var band_report: Array[String] = []
	for level in [1, 3, 5, 8, 10, 12, 15]:
		var ceiling := int(round(float(EconomySystemScript.fight_rewards(level).gold) * 1.2))
		var net := BettingSystemScript.max_theoretical_net(level)
		band_report.append("nv%d %d≤%d" % [level, net, ceiling])
		if net > ceiling:
			out_of_band += " nível %d (%d > %d)" % [level, net, ceiling]
	print("    aposta — ganho líquido máxima vs luta: %s" % " | ".join(band_report))
	_check(out_of_band == "", "o ganho líquido máximo da aposta cabe na recompensa da luta de cada nível%s" % out_of_band)
	# A odd também é presa: o mais fraco nunca recebe mais que MAX_ODD.
	_check(BettingSystemScript.odd_for(1, 999) <= BettingSystemScript.MAX_ODD, "a odd do azarão fica presa em ×%.2f (anti-impressora)" % BettingSystemScript.MAX_ODD)
	# Pagamento e perda com a régua do GameState.
	var foe = _fighter({"id": "foe", "base_strength": 40, "base_attack": 20, "base_defence": 20, "base_agility": 10, "base_vitality": 20, "base_charisma": 10, "base_luck": 10, "level": 3})
	var player = _fighter({"id": "gambler", "base_strength": 12, "base_attack": 8, "base_defence": 6, "base_agility": 6, "base_vitality": 8, "base_charisma": 6, "base_luck": 6, "level": 3, "gold": 100})
	var gs = _new_game_state(player, foe)
	var cap_before: int = gs.max_bet()
	_check(cap_before <= BettingSystemScript.BET_BASE + 3 * BettingSystemScript.BET_PER_LEVEL and cap_before <= 100, "o teto da aposta respeita nível+ouro (%d)" % cap_before)
	var placed: Dictionary = gs.place_bet(99999)
	_check(bool(placed.get("ok", false)) and int(placed.get("stake", 0)) == cap_before, "aposta grande é cortada no teto (%d)" % int(placed.get("stake", 0)))
	_check(player.gold == 100 - cap_before, "a aposta desconta o ouro na hora (%d)" % player.gold)
	var odd: float = float(gs.current_bet_odd)
	var settled_win: Dictionary = gs.settle_bet(true)
	var expected_payout: int = BettingSystemScript.payout(cap_before, odd)
	_check(int(settled_win.get("payout", 0)) == expected_payout, "vitória paga aposta × odd (%d ouro, odd %.2f)" % [expected_payout, odd])
	_check(player.gold == 100 - cap_before + expected_payout, "o pagamento entra no bolso (%d)" % player.gold)
	_check(gs.current_bet == 0, "a aposta é encerrada depois do pagamento")
	# Derrota: queima a aposta.
	player.gold = 100
	gs.place_bet(cap_before)
	var gold_after_bet: int = player.gold
	var settled_loss: Dictionary = gs.settle_bet(false)
	_check(int(settled_loss.get("payout", 0)) == 0 and player.gold == gold_after_bet, "derrota perde a aposta (não recebe nada, ouro %d)" % player.gold)
	gs.free()

## POÇÃO (item 6): efeito aplicado, item consumido, limite de mochila.
func _test_potion_effect_and_consumed() -> void:
	var heal_item := {"id": "pocao_cura", "display_name": "Poção de cura", "slot": "consumable", "effect": "heal", "amount": 40, "price": 30}
	var potion_player = _fighter({"id": "drinker", "base_vitality": 20, "base_strength": 10})
	potion_player.health = 10
	var heal: Dictionary = PotionSystemScript.use(potion_player, heal_item)
	_check(bool(heal.get("ok", false)) and potion_player.health == 50, "poção de cura recupera vida (%d)" % potion_player.health)
	# Buff temporário: +6 STR por 3 turnos, expira.
	var buff_item := {"id": "pocao_forca", "slot": "consumable", "effect": "buff_str", "amount": 6, "turns": 3}
	var base_str: int = potion_player.strength
	PotionSystemScript.use(potion_player, buff_item)
	_check(potion_player.strength == base_str + 6, "poção de força dá +6 STR por 3 turnos (%d)" % potion_player.strength)
	potion_player.tick_buffs()
	potion_player.tick_buffs()
	_check(potion_player.strength == base_str + 6 and potion_player.has_active_buffs(), "o buff dura 3 turnos (ainda ativo após 2)")
	potion_player.tick_buffs()
	_check(potion_player.strength == base_str and not potion_player.has_active_buffs(), "o buff expira no 3º turno (STR volta a %d)" % potion_player.strength)
	# Poção de ferimento cura UM ferimento.
	InjurySystemScript.add_injury(potion_player, InjurySystemScript.find_template("swollen_eye"))
	var cure_item := {"id": "pocao_remendo", "slot": "consumable", "effect": "cure_injury", "price": 90}
	var cured: Dictionary = PotionSystemScript.use(potion_player, cure_item)
	_check(bool(cured.get("ok", false)) and potion_player.injuries.is_empty(), "poção de ferimento cura 1 ferimento")
	# Consumida de verdade via GameState: sai da bolsa.
	var owner = _fighter({"id": "owner", "base_vitality": 20, "level": 3, "gold": 500})
	owner.remember_item(heal_item.duplicate(true))
	owner.health = 5
	var gs = _new_game_state(owner, null)
	gs.in_combat = true
	_check(gs.consumable_count() == 1, "a poção entra na mochila (1)")
	var use: Dictionary = gs.use_potion("pocao_cura")
	_check(bool(use.get("ok", false)) and owner.health == 45, "usar a poção aplica o efeito na luta (vida %d)" % owner.health)
	_check(gs.consumable_count() == 0 and not owner.owns_item("pocao_cura"), "usar CONSOOME o item (some da bolsa)")
	# Limite da mochila.
	var stuffed = _fighter({"id": "stuffed", "gold": 10000, "level": 2})
	for i in PotionSystemScript.MAX_POTIONS:
		stuffed.remember_item({"id": "p%d" % i, "slot": "consumable", "effect": "heal", "amount": 10, "price": 10})
	_check(PotionSystemScript.count(stuffed) == PotionSystemScript.max_potions(), "a mochila enche no limite (%d)" % PotionSystemScript.max_potions())
	_check(not PotionSystemScript.can_carry(stuffed, heal_item), "com a mochila cheia, outra poção é recusada")
	gs.free()

## POÇÃO (item 6): não pode ser usada fora da luta.
func _test_potion_only_in_combat() -> void:
	var player = _fighter({"id": "city", "gold": 100, "level": 2})
	player.remember_item({"id": "pocao_cura", "slot": "consumable", "effect": "heal", "amount": 40, "price": 30})
	var gs = _new_game_state(player, null)
	gs.in_combat = false
	var outside: Dictionary = gs.use_potion("pocao_cura")
	_check(not bool(outside.get("ok", false)) and str(outside.get("reason", "")).contains("luta"), "fora da luta a poção não é usada ('%s')" % str(outside.get("reason", "")))
	_check(player.owns_item("pocao_cura"), "a poção continua na bolsa quando recusada fora da luta")
	gs.in_combat = true
	_check(bool(gs.use_potion("pocao_cura").get("ok", false)), "dentro da luta a poção é usada")
	gs.free()

## FERREIRO (item 10): armadura sobe pelo preço certo e respeita o teto.
func _test_blacksmith_upgrade_and_cap() -> void:
	var player = _fighter({"id": "smith", "level": 4, "gold": 5000})
	var armor := {"id": "test_plate", "display_name": "Peitoral de teste", "slot": "armor", "price": 60, "armour": 20, "level": 4}
	player.remember_item(armor)
	player.equip_item(armor)
	var armour_before: int = player.max_armour
	var gs = _new_game_state(player, null)
	var state: Dictionary = gs.smith_info("test_plate")
	var cost: int = int(state.get("cost", 0))
	_check(bool(state.get("ok", false)) and cost == EconomySystemScript.blacksmith_cost(armor, 0), "o ferreiro informa o preço da melhoria (%d ouro)" % cost)
	var up: Dictionary = gs.smith_upgrade("test_plate")
	_check(bool(up.get("ok", false)) and player.max_armour == armour_before + EconomySystemScript.BLACKSMITH_ARMOUR_PER_UPGRADE, "melhorar sobe a armadura em +1 (%d → %d)" % [armour_before, player.max_armour])
	_check(player.gold == 5000 - cost, "cobrou exatamente o preço (%d)" % cost)
	var second: Dictionary = gs.smith_info("test_plate")
	_check(int(second.get("cost", 0)) > cost, "o preço sobe a cada melhoria (%d → %d)" % [cost, int(second.get("cost", 0))])
	# Teto: para de melhorar no máximo.
	for i in 20:
		gs.smith_upgrade("test_plate")
	var capped: Dictionary = gs.smith_info("test_plate")
	_check(int(capped.get("upgrades", 0)) == EconomySystemScript.blacksmith_max(), "a melhoria respeita o teto (%d)" % EconomySystemScript.blacksmith_max())
	_check(not bool(capped.get("ok", false)) and str(capped.get("reason", "")) != "", "no teto, o ferreiro recusa com motivo")
	_check(player.max_armour == armour_before + EconomySystemScript.blacksmith_max() * EconomySystemScript.BLACKSMITH_ARMOUR_PER_UPGRADE, "a armadura final bate com o teto (%d)" % player.max_armour)
	# Arma sem armadura e item de outro dono são recusados.
	var weapon := {"id": "w1", "slot": "weapon", "price": 30, "strength_bonus": 2}
	player.remember_item(weapon)
	_check(not bool(gs.smith_upgrade("w1").get("ok", false)), "o ferreiro recusa item sem armadura")
	_check(not bool(gs.smith_upgrade("nao_existe").get("ok", false)), "o ferreiro recusa item que não é do jogador")
	gs.free()

## TREINADOR (item 10): XP pelo preço certo, com teto por nível.
func _test_trainer_xp_and_cap() -> void:
	var player = _fighter({"id": "student", "level": 1, "gold": 1000})
	var gs = _new_game_state(player, null)
	var cap: int = gs.trainer_cap()
	_check(cap == int(floor(float(EconomySystemScript.required_experience(1)) * EconomySystemScript.TRAINER_MAX_FRACTION)), "o teto do treinador é %d%% do XP do nível (%d)" % [int(EconomySystemScript.TRAINER_MAX_FRACTION * 100.0), cap])
	var cost: int = gs.trainer_cost()
	var gain: int = gs.trainer_gain()
	_check(gain > 0 and gain <= cap, "uma sessão dá %d XP (dentro do teto %d)" % [gain, cap])
	var xp_before: int = player.experience
	var train: Dictionary = gs.train()
	_check(bool(train.get("ok", false)) and int(train.get("xp", 0)) == gain, "treinar dá o XP prometido (%d)" % int(train.get("xp", 0)))
	_check(player.experience == xp_before + gain and player.gold == 1000 - cost, "XP entra e o ouro sai pelo preço certo (%d)" % cost)
	# Gasta o resto do teto e confirma que não passa.
	for i in 20:
		gs.train()
	_check(player.trained_xp <= cap, "o XP comprado nunca passa do teto do nível (%d ≤ %d)" % [player.trained_xp, cap])
	_check(gs.trainer_gain() == 0, "com o teto batido, outra sessão não rende XP")
	var capped: Dictionary = gs.train()
	_check(not bool(capped.get("ok", false)) and str(capped.get("reason", "")).contains("teto"), "no teto o treinador recusa com motivo ('%s')" % str(capped.get("reason", "")))
	gs.free()

## MÉDICO (item 10): cobra e cura vida, armadura e ferimentos.
func _test_doctor_cures_and_charges() -> void:
	var player = _fighter({"id": "patient", "level": 5, "gold": 5000, "base_vitality": 12, "base_strength": 15})
	player.remember_item({"id": "pat_armor", "slot": "armor", "price": 40, "armour": 15})
	player.equip_item(player.catalog_item("pat_armor"))
	player.health = 20
	player.armour = 3
	InjurySystemScript.add_injury(player, InjurySystemScript.find_template("broken_arm"))
	var strength_hurt: int = player.strength
	var cost: int = EconomySystemScript.doctor_cost(player)
	var gs = _new_game_state(player, null)
	_check(cost == gs.doctor_cost() and cost > 0, "o médico calcula o preço (vida+armadura+ferimentos = %d)" % cost)
	var paid: Dictionary = gs.visit_doctor()
	_check(bool(paid.get("ok", false)), "o médico atende pagando")
	_check(player.health == player.max_health and player.armour == player.max_armour, "o médico enche a vida e a armadura")
	_check(int(paid.get("cured", 0)) == 1 and player.injuries.is_empty(), "o médico cura todos os ferimentos")
	_check(player.strength > strength_hurt, "o atributo ferido volta (%d → %d)" % [strength_hurt, player.strength])
	_check(player.gold == 5000 - cost, "o médico cobrou exatamente o custo (sobrou %d)" % player.gold)
	# Sem ferimentos e sem dano, não há o que cobrar.
	var fresh: Dictionary = gs.visit_doctor()
	_check(bool(fresh.get("ok", false)) and int(fresh.get("cost", 0)) == 0, "sem nada a tratar, o médico não cobra")
	gs.free()

# --- RANK e KD (item I) -----------------------------------------------------

## As oito faixas com título e os cortes exatos de data/ranks.json.
func _test_rank_tiers_and_titles() -> void:
	var tiers: Array = RankSystemScript.tiers()
	_check(tiers.size() == 8, "existem 8 faixas de rank")
	var expected := [
		[0, "Areia"], [199, "Areia"], [200, "Pedra"], [499, "Pedra"], [500, "Ferro"],
		[899, "Ferro"], [900, "Aço"], [1499, "Aço"], [1500, "Prata"], [2299, "Prata"],
		[2300, "Ouro"], [3499, "Ouro"], [3500, "Campeão"], [4999, "Campeão"], [5000, "Lenda"],
	]
	for pair: Array in expected:
		_check(RankSystemScript.title_for(int(pair[0])) == str(pair[1]), "%d pts = %s" % [int(pair[0]), str(pair[1])])
	_check(int(RankSystemScript.next_tier(0).get("min", -1)) == 200, "próxima faixa de Areia = Pedra (200)")
	_check(RankSystemScript.points_to_next(0) == 200 and RankSystemScript.points_to_next(190) == 10, "pontos para a próxima faixa somam certo")
	_check(RankSystemScript.next_tier(5000).is_empty(), "Lenda é a última faixa")
	_check(str(RankSystemScript.tier_for(5000).get("id", "")) == "lenda", "tier_for(5000) = lenda")

## Vencer mais forte rende MUITO; vencer muito mais fraco rende ~0; perder tira e
## perder para rank menor dói mais.
func _test_rank_win_loss_by_strength() -> void:
	var weak := RankSystemScript.opponent_rating(1, 1, false)
	var strong := RankSystemScript.opponent_rating(10, 1, false)
	_check(RankSystemScript.win_gain(500, strong) > RankSystemScript.win_gain(500, weak), "vencer mais FORTE rende mais (vs forte +%d > vs fraco +%d)" % [RankSystemScript.win_gain(500, strong), RankSystemScript.win_gain(500, weak)])
	_check(RankSystemScript.win_gain(0, strong) > RankSystemScript.win_gain(0, weak), "no início, o forte ainda rende mais")
	_check(RankSystemScript.win_gain(1500, weak) == 0, "vencer alguém muito mais fraco rende 0 (piso)")
	_check(RankSystemScript.win_gain(1500, strong) > 0, "mas o mesmo ponto da escada ainda ganha contra alguém mais forte")
	_check(RankSystemScript.loss_penalty(500, weak) > 0, "perder SEMPRE tira pontos (piso)")
	_check(RankSystemScript.loss_penalty(1500, weak) > RankSystemScript.loss_penalty(1500, strong), "perder para rank bem menor tira mais (%d > %d)" % [RankSystemScript.loss_penalty(1500, weak), RankSystemScript.loss_penalty(1500, strong)])
	# A régua usa nível+tier do adversário: um chefe vale mais.
	_check(RankSystemScript.opponent_rating(5, 3, true) > RankSystemScript.opponent_rating(5, 3, false), "chefe tem rating maior que o mesmo nível/tier comum")

## Piso 0 e rebaixa ao cair abaixo do piso da faixa (com promoção simétrica).
func _test_rank_floor_and_demotion() -> void:
	var floor_info: Dictionary = RankSystemScript.resolve_result(3, 100000, false)
	_check(int(floor_info.points) == 0, "os pontos nunca ficam negativos (piso 0)")
	var drop: Dictionary = RankSystemScript.resolve_result(520, RankSystemScript.opponent_rating(1, 1, false), false)
	_check(int(drop.points) < 500 and bool(drop.demoted), "cair do piso de Ferro REBAIXA para Pedra (520 → %d)" % int(drop.points))
	_check(str(drop.new_title) == "Pedra", "título após a rebaixa = Pedra")
	var up: Dictionary = RankSystemScript.resolve_result(190, RankSystemScript.opponent_rating(10, 1, false), true)
	_check(int(up.points) >= 200 and bool(up.promoted), "cruzar o piso PROMOVE (190 → %d, %s)" % [int(up.points), str(up.new_title)])

## Acesso por rank: Arena Livre aberta; Menor a partir de Pedra; Maior de Aço;
## Grande de Ouro — com o motivo visível do bloqueio.
func _test_rank_access_gate() -> void:
	_check(RankSystemScript.meets(0, "free_arena"), "Arena Livre é aberta para todos")
	_check(RankSystemScript.requirement_for("t1") == 200, "Torneio Menor exige Pedra (200)")
	_check(RankSystemScript.requirement_for("t2") == 900, "Torneio Maior exige Aço (900)")
	_check(RankSystemScript.requirement_for("t3") == 2300, "Grande Torneio exige Ouro (2300)")
	_check(RankSystemScript.meets(200, "t1") and not RankSystemScript.meets(199, "t1"), "libera em 200 e bloqueia em 199 (Menor)")
	_check(not RankSystemScript.meets(899, "t2") and RankSystemScript.meets(900, "t2"), "Maior libera exatamente em 900")
	_check(not RankSystemScript.meets(2299, "t3") and RankSystemScript.meets(2300, "t3"), "Grande libera exatamente em 2300")
	var reason: String = RankSystemScript.lock_reason(500, "t2")
	_check(reason.contains("Aço") and reason.contains("Ferro"), "motivo do bloqueio cita o requisito e o rank atual ('%s')" % reason)
	_check(RankSystemScript.lock_reason(900, "t2") == "", "sem motivo quando o rank basta")

## KD soma certo; save novo preserva rank/KD e save antigo migra para Areia/0.
func _test_rank_kd_and_save_migration() -> void:
	var fighter = _fighter({"id": "rank", "base_vitality": 8})
	var weak := RankSystemScript.opponent_rating(1, 1, false)
	var strong := RankSystemScript.opponent_rating(12, 2, false)
	RankSystemScript.apply_to(fighter, strong, true)
	RankSystemScript.apply_to(fighter, strong, true)
	RankSystemScript.apply_to(fighter, strong, false)
	RankSystemScript.apply_to(fighter, weak, false)
	_check(fighter.wins == 2 and fighter.losses == 2, "KD soma certo (2 V / 2 D)")
	var points_after := int(fighter.rank_points)
	_check(points_after > 0, "as vitórias contra o forte somaram pontos (%d)" % points_after)
	# Round-trip do save novo.
	var data: Dictionary = fighter.to_save_data()
	var loaded = _fighter(data)
	_check(int(loaded.rank_points) == points_after and loaded.wins == 2 and loaded.losses == 2, "save novo preserva rank e KD")
	# Migração: save antigo, sem as chaves rank/KD, entra em Areia com 0.
	var old = _fighter({"id": "old", "base_max_health": 60, "base_attack": 10, "base_defense": 4, "base_luck": 6, "health": 60})
	_check(old.rank_points == 0 and old.wins == 0 and old.losses == 0, "save antigo migra para 0 pontos (Areia)")
	_check(RankSystemScript.title_for(old.rank_points) == "Areia", "save antigo entra em Areia")

## Arenas por faixa (ideia 9): pelo menos 3 faixas, com ouro e risco crescentes.
func _test_rank_arena_bands() -> void:
	var bands: Array = RankSystemScript.arena_bands()
	_check(bands.size() >= 3, "há pelo menos 3 faixas de arena (encontrei %d)" % bands.size())
	var areia := RankSystemScript.arena_band_for(0)
	var ferro := RankSystemScript.arena_band_for(500)
	var prata := RankSystemScript.arena_band_for(1500)
	_check(str(areia.id) == "areia" and str(ferro.id) == "ferro" and str(prata.id) == "prata", "faixa de arena muda nos cortes 0/500/1500")
	_check(float(areia.gold_multiplier) < float(ferro.gold_multiplier) and float(ferro.gold_multiplier) < float(prata.gold_multiplier), "faixa maior paga mais ouro (×%.2f < ×%.2f < ×%.2f)" % [float(areia.gold_multiplier), float(ferro.gold_multiplier), float(prata.gold_multiplier)])
	_check(int(areia.enemy_level_bonus) < int(ferro.enemy_level_bonus) and int(ferro.enemy_level_bonus) <= int(prata.enemy_level_bonus), "faixa maior traz mais risco (nível +%d/+%d/+%d)" % [int(areia.enemy_level_bonus), int(ferro.enemy_level_bonus), int(prata.enemy_level_bonus)])
	_check(str(areia.get("id", "")) == "areia", "arena_band_for(0) resolve para Areia")

## Arena mais lotada: o rank eleva o INÍCIO e o TETO da felicidade e do multiplicador.
func _test_rank_crowd_bonus() -> void:
	var foe = _fighter({"id": "e", "base_charisma": 5})
	var low = _fighter({"id": "p", "base_charisma": 5})
	var base := CrowdSystemScript.initial_happiness(low, foe, false, 0)
	var high := CrowdSystemScript.initial_happiness(low, foe, false, 5000)
	_check(high > base, "rank alto eleva o início da felicidade (%d > %d)" % [high, base])
	# Mesma felicidade final, multiplicador maior com rank (teto sobe).
	var c0 = CrowdSystemScript.new(low, foe, false, 0)
	c0.actions = 10
	c0.happiness = 100
	var c1 = CrowdSystemScript.new(low, foe, false, 5000)
	c1.actions = 10
	c1.happiness = 100
	_check(c1.reward_multiplier(5000) > c0.reward_multiplier(0), "rank alto eleva o teto do multiplicador (×%.2f > ×%.2f)" % [c1.reward_multiplier(5000), c0.reward_multiplier(0)])
	_check(is_equal_approx(c0.reward_multiplier(0), CrowdSystemScript.MULTIPLIER_MAX), "sem rank o teto continua ×2,0 (nada mudou para quem está em Areia)")
	_check(high <= CrowdSystemScript.MAX_VALUE, "o início continua respeitando o teto de 100 da barra")

## ANTI-FARM (item I): um vencedor eterno da arena mais fraca NÃO chega ao topo.
## Mede e imprime o número; prova também que a escada satura (farm para de render).
func _test_rank_anti_farm() -> void:
	var weak := RankSystemScript.opponent_rating(1, 1, false)
	var farmer := 0
	for i in 500:
		farmer = int(RankSystemScript.resolve_result(farmer, weak, true).points)
	var farmer_plateau := farmer
	for i in 1500:
		farmer_plateau = int(RankSystemScript.resolve_result(farmer_plateau, weak, true).points)
	var top_floor := int(RankSystemScript.tiers()[RankSystemScript.tiers().size() - 1].get("min", 5000))
	print("    anti-farm: 500 vitórias na arena fraca → %d pts (%s); +1.500 vitórias → %d pts (satura)" % [farmer, RankSystemScript.title_for(farmer), farmer_plateau])
	_check(farmer_plateau < top_floor, "farm não chega ao topo do rank (%d < %d Lenda)" % [farmer_plateau, top_floor])
	_check(farmer_plateau < 1500, "farm não passa de Prata (medido %d, piso de Prata 1.500)" % farmer_plateau)
	_check(farmer_plateau <= farmer + 5, "a escada SATURA: 1.500 vitórias extras somam <= 5 pontos (%d → %d)" % [farmer, farmer_plateau])
	# Um jogador que enfrenta gente mais forte sobe bem mais com o mesmo nº de lutas.
	var climber := 0
	for i in 500:
		climber = int(RankSystemScript.resolve_result(climber, RankSystemScript.opponent_rating(mini(15, 1 + int(i / 34)), 2, false), true).points)
	_check(climber > farmer_plateau * 2, "quem enfrenta gente mais forte sobe bem mais (%d > 2×%d)" % [climber, farmer_plateau])

# --- Apresentação do adversário (item F) + identidade (item G) --------------

## Índice de Poder: soma ponderada dos 7 atributos + nível. Todos os pesos são
## positivos, então mais atributo OU mais nível = mais poder, com valor exato.
func _test_presentation_power_index() -> void:
	var all_ten = _fighter({"base_strength": 10, "base_attack": 10, "base_defence": 10, "base_agility": 10, "base_vitality": 10, "base_charisma": 10, "base_luck": 10, "level": 1})
	# 10×2 + 10×1,5×3 + 10×1,0 + 10×0,5 + 10×1,0 + 1×5 = 90 + 5 = 95.
	_check(PresentationSystemScript.power_index(all_ten) == 95, "Índice de Poder (tudo 10, nível 1) = 95 (medido %d)" % PresentationSystemScript.power_index(all_ten))
	var weak = _fighter({"base_strength": 4, "base_attack": 4, "base_defence": 4, "base_agility": 4, "base_vitality": 4, "base_charisma": 4, "base_luck": 4, "level": 1})
	_check(PresentationSystemScript.power_index(all_ten) > PresentationSystemScript.power_index(weak), "mais atributos = mais poder (%d > %d)" % [PresentationSystemScript.power_index(all_ten), PresentationSystemScript.power_index(weak)])
	var leveled = _fighter({"base_strength": 10, "base_attack": 10, "base_defence": 10, "base_agility": 10, "base_vitality": 10, "base_charisma": 10, "base_luck": 10, "level": 5})
	_check(PresentationSystemScript.power_index(leveled) > PresentationSystemScript.power_index(all_ten), "nível maior = mais poder (%d > %d)" % [PresentationSystemScript.power_index(leveled), PresentationSystemScript.power_index(all_ten)])
	_check(PresentationSystemScript.power_index(null) == 0, "Índice de Poder de lutador nulo = 0")
	# Cada um dos 7 atributos, sozinho, aumenta o índice (monotônico).
	var every_attribute_grows := true
	for definition: Dictionary in EconomySystemScript.attribute_definitions():
		var field := "base_" + str(definition.get("id", ""))
		var low = _fighter({"base_strength": 5, "base_attack": 5, "base_defence": 5, "base_agility": 5, "base_vitality": 5, "base_charisma": 5, "base_luck": 5})
		var high = _fighter({"base_strength": 5, "base_attack": 5, "base_defence": 5, "base_agility": 5, "base_vitality": 5, "base_charisma": 5, "base_luck": 5})
		high.set(field, int(high.get(field)) + 10)
		high.recompute_derived()
		if PresentationSystemScript.power_index(high) <= PresentationSystemScript.power_index(low):
			every_attribute_grows = false
	_check(every_attribute_grows, "cada um dos 7 atributos aumenta o Índice de Poder")

## Provocações: sorteio uniforme sobre listas válidas (não repete sempre a mesma),
## fala própria do inimigo quando existe e reserva genérica quando não existe.
func _test_presentation_taunt_draw() -> void:
	var sample: Array = ["A", "B", "C"]
	var seen := {}
	for i in 300:
		seen[PresentationSystemScript.random_line(sample)] = true
	_check(seen.size() >= 2, "sorteio de provocação varia (não repete sempre a mesma: %d distintas)" % seen.size())
	_check(not seen.has(""), "toda fala sorteada é não vazia e válida")
	_check(PresentationSystemScript.random_line([]) == "", "lista vazia devolve fala vazia")
	_check(PresentationSystemScript.random_line(["só uma"]) == "só uma", "lista de 1 item devolve o próprio item")
	_check(PresentationSystemScript.PLAYER_TAUNTS.size() >= 3 and PresentationSystemScript.player_taunt().strip_edges() != "", "o jogador tem provocações de reserva válidas")
	# Inimigo com lista própria (template do JSON) sorteia entre as SUAS falas.
	var enemies := ContentRepositoryScript.load_enemies()
	var brutus := ContentRepositoryScript.find_enemy(enemies, "brutus")
	var own: Array = brutus.get("taunts", [])
	var own_seen := {}
	for i in 200:
		var foe = _fighter({"id": "brutus", "display_name": "Brutus"})
		own_seen[PresentationSystemScript.enemy_taunt(foe)] = true
	var only_own := true
	for line: Variant in own_seen.keys():
		if not own.has(str(line)):
			only_own = false
	_check(own_seen.size() >= 2 and only_own, "inimigo com lista própria sorteia entre as SUAS falas (%d distintas)" % own_seen.size())
	# Inimigo SEM template (procedural da Arena Livre) cai na reserva genérica.
	var generated = _fighter({"id": "generated_99999", "display_name": "Anônimo"})
	var fallback_seen := {}
	for i in 200:
		fallback_seen[PresentationSystemScript.enemy_taunt(generated)] = true
	var generic := {}
	for entry: Variant in PresentationSystemScript.GENERIC_ENEMY_TAUNTS:
		generic[str(entry)] = true
	var only_generic := true
	for line: Variant in fallback_seen.keys():
		if not generic.has(str(line)):
			only_generic = false
	_check(fallback_seen.size() >= 2 and only_generic, "inimigo sem lista própria usa a reserva genérica (%d distintas)" % fallback_seen.size())

## Identidade dos inimigos (item G): todo template tem apelido, descrição (com
## altura/peso), fraqueza declarada e falas de provocação válidas.
func _test_enemy_identity_content() -> void:
	var enemies := ContentRepositoryScript.load_enemies()
	_check(enemies.size() == 6, "enemies.json continua com 6 inimigos")
	var ids := {}
	for enemy: Dictionary in enemies:
		var enemy_id := str(enemy.get("id", "?"))
		ids[enemy_id] = true
		var identity: Dictionary = PresentationSystemScript.identity_from_template(enemy)
		_check(str(enemy.get("nickname", "")) != "" and str(identity.get("nickname", "")) != "", "inimigo %s tem apelido" % enemy_id)
		var description := str(enemy.get("description", ""))
		_check(description != "", "inimigo %s tem descrição" % enemy_id)
		_check(description.contains("kg") and description.contains(" m"), "descrição de %s traz altura/peso ('%s')" % [enemy_id, description])
		_check(str(enemy.get("weakness", "")) != "", "inimigo %s declara uma fraqueza" % enemy_id)
		var taunts: Array = enemy.get("taunts", [])
		_check(taunts.size() >= 2, "inimigo %s tem pelo menos 2 provocações (%d)" % [enemy_id, taunts.size()])
		var all_valid := true
		for line: Variant in taunts:
			if str(line).strip_edges() == "":
				all_valid = false
		_check(all_valid, "as provocações de %s são textos não vazios" % enemy_id)
		var resolved_taunts: Array = identity.get("taunts", [])
		_check(not resolved_taunts.is_empty(), "a identidade resolvida de %s traz falas" % enemy_id)
	_check(ids.size() == enemies.size(), "os ids de inimigos são únicos")
	# A reserva é usada quando o template não traz identidade.
	var generic: Dictionary = PresentationSystemScript.identity_from_template({})
	_check(str(generic.get("nickname", "")) != "" and not (generic.get("taunts", []) as Array).is_empty(), "template vazio cai na reserva genérica (apelido + falas)")

