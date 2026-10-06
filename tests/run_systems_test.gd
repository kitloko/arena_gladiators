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
	_test_gladiator_progression()
	_test_movement_and_range()
	_test_equipment_and_inventory()
	_test_items_and_campaign_content()
	_test_level_up_options()
	_test_item_data_defaults()
	_test_archetypes_content()
	_test_save_roundtrip()
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
					same = same and int(a.get("attack_bonus", 0)) == int(b.get("attack_bonus", 0))
					same = same and int(a.get("defense_bonus", 0)) == int(b.get("defense_bonus", 0))
					same = same and int(a.get("luck_bonus", 0)) == int(b.get("luck_bonus", 0))
					same = same and int(a.get("health_bonus", 0)) == int(b.get("health_bonus", 0))
					same = same and int(a.get("price", 0)) == int(b.get("price", 0))
					if same:
						distinct_ok = false
			if not found_baseline:
				has_baseline = false
	_check(subtypes == 12 and per_type_ok, "loja procedural: 12 tipos com 1 a 3 itens de preço > 0")
	_check(has_baseline, "cada tipo traz ao menos um item Comum (base acessível)")
	_check(distinct_ok, "itens do mesmo tipo nunca são idênticos (nome diferente = status diferente)")
	var fighter = GladiatorDataScript.new({"id": "r", "level": 5, "max_health": 60, "health": 30})
	var hp_price := EconomySystemScript.rest_hp_price(5)
	_check(hp_price >= 1 and EconomySystemScript.full_rest_cost(fighter) == 30 * hp_price, "descanso: custo = vida faltante × preço por ponto (barato, sobe devagar)")
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
	_check(CombatResolverScript.DEFEND_GUARD_BONUS == 6, "DEFEND_GUARD_BONUS == 6")

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

func _test_resolve_attack_hit_and_miss() -> void:
	var attacker = GladiatorDataScript.new({"id": "tester_a", "display_name": "Atacante", "attack": 12, "defense": 2, "luck": 8, "max_health": 60})
	var defender = GladiatorDataScript.new({"id": "tester_d", "display_name": "Defensor", "attack": 6, "defense": 3, "luck": 2, "max_health": 60})
	var hp_before: int = defender.health
	var hit_result: Dictionary = CombatResolverScript.resolve_attack(attacker, defender, 1.0, 1.0, 0)
	_check(bool(hit_result.hit), "ataque com acerto 1.0 sempre acerta")
	if bool(hit_result.hit):
		_check(int(hit_result.damage) >= 1, "dano minimo 1")
		_check(defender.health == maxi(0, hp_before - int(hit_result.damage)), "vida reduzida conforme dano")
	var another = GladiatorDataScript.new({"id": "tester_d2", "attack": 6, "defense": 3, "luck": 2, "max_health": 60})
	var hp_another: int = another.health
	var miss_result: Dictionary = CombatResolverScript.resolve_attack(attacker, another, 1.0, 0.0, 0)
	_check(not bool(miss_result.hit), "acerto 0.0 sempre erra")
	_check(another.health == hp_another, "erro nao causa dano")

func _test_gladiator_progression() -> void:
	var fighter = GladiatorDataScript.new({"id": "prog", "level": 1, "max_health": 50})
	fighter.receive_damage(200)
	_check(fighter.health == 0 and fighter.is_defeated(), "dano excessivo leva a 0 e derrota")
	fighter.heal_full()
	_check(fighter.health == 50, "heal_full restaura a vida")
	# O valor de XP vem da regra (EconomySystem.required_experience), não de um
	# número solto no teste: quando a curva muda, o teste continua medindo o
	# mecanismo em vez de exigir a curva antiga.
	var needed: int = EconomySystemScript.required_experience(1)
	var leveled: bool = fighter.grant_experience(needed)
	_check(leveled and fighter.level == 2, "%d xp no nivel 1 sobe para nivel 2" % needed)
	_check(fighter.pending_level_ups == 1, "nivel ganho fica pendente de escolha")
	_check(fighter.attack == 10, "nivel nao altera atributos sem a escolha")
	var applied: bool = fighter.apply_level_up({"stat": "base_attack", "amount": 3, "heal": false})
	_check(applied and fighter.pending_level_ups == 0, "escolha de treino consome o nivel pendente")
	_check(fighter.base_attack == 13 and fighter.attack == 13, "escolha de forca aumenta o ataque")

func _test_equipment_and_inventory() -> void:
	var items := ContentRepositoryScript.load_items()
	var fighter = GladiatorDataScript.new({"id": "p2", "base_max_health": 60, "base_attack": 10, "base_defense": 4, "base_luck": 6})
	fighter.equip_weapon(ContentRepositoryScript.find_item(items, "dagger"))
	_check(fighter.attack == 13 and fighter.defense == 4, "equipar arma soma bonus nos derivados")
	_check(fighter.owns_item("dagger"), "equipar registra item no inventario")
	fighter.equip_armor(ContentRepositoryScript.find_item(items, "leather_armor"))
	_check(fighter.defense == 9, "equipar armadura soma defesa")
	fighter.equip_weapon(ContentRepositoryScript.find_item(items, "short_sword"))
	_check(fighter.attack == 12, "trocar arma recalcula (remove o bonus antigo)")
	_check(fighter.owns_item("dagger") and fighter.owns_item("short_sword"), "inventario guarda armas trocadas")
	var helm = ContentRepositoryScript.find_item(items, "iron_helm")
	fighter.equip_item(helm)
	_check(fighter.equipped_id("helmet") == "iron_helm" and fighter.defense == 13, "capacete equipa no slot correto")
	var belt = ContentRepositoryScript.find_item(items, "rope_belt")
	fighter.equip_item(belt)
	_check(fighter.max_health == 73 and fighter.owns_item("rope_belt"), "cinto adiciona vida maxima (60+5 couro+8 cinto)")

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
		if int(e.get("base_max_health", 0)) <= 0 or int(e.get("base_attack", 0)) <= 0:
			tiers_ok = false
	_check(tiers_ok, "gerador cria inimigos com tier 1-3 e recompensa >= 1")
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
			var fighter = GladiatorDataScript.new(e)
			if fighter.attack <= 0 or fighter.max_health <= 0:
				geared = false
	_check(geared, "gerador com itens equipa sempre uma arma e mantém status válidos")

func _test_level_up_options() -> void:
	var options := EconomySystemScript.level_up_options()
	_check(options.size() >= 4, "ha pelo menos 4 opcoes de treino")
	for option: Dictionary in options:
		_check(option.has("id") and option.has("label") and option.has("stat") and option.has("amount"), "opcao de treino tem campos completos")

func _test_item_data_defaults() -> void:
	var item = ItemDataScript.new({"id": "tempered_blade", "display_name": "Lamina temperada", "slot": "weapon", "price": 45, "attack_bonus": 2, "defense_bonus": 1})
	_check(item.slot == "weapon", "ItemData le slot do JSON")
	_check(int(item.price) == 45, "ItemData le preco do JSON")
	_check(int(item.attack_bonus) == 2 and int(item.defense_bonus) == 1, "ItemData le bonus do JSON")

## O nome do item tem que acompanhar o preço dentro do tipo: em cada estoque gerado,
## um item mais caro nunca pode ter substantivo mais fraco na ordem canônica do
## data/*.json. Sem isto, o item mais caro do estoque saía como "Espada curta" e o mais
## barato como "Espada longa" — nome contradizendo o preço na mesma tela.
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
						# Preço igual não define ordem na tela: só compara quando é diferente.
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

## Curva de XP: subir de nível tem de custar lutas, não uma luta. Antes a sequência
## de vitórias multiplicava o XP (até +180%) e o personagem subia a cada luta.
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

## O XP da vitória não pode crescer com a sequência de vitórias: era isso que fazia
## o personagem subir de nível a cada luta depois de algumas vitórias seguidas.
func _test_streak_does_not_boost_experience() -> void:
	var best_case := 0
	for level in range(1, 16):
		var base: int = int(EconomySystemScript.fight_rewards(level).experience)
		# Melhor caso possível do nível: inimigo tier 3 (o bônus de XP mais alto).
		var per_fight := int(round(float(base) * EconomySystemScript.tier_experience_multiplier(3)))
		best_case = per_fight
		var fights := int(ceil(float(EconomySystemScript.required_experience(level)) / float(maxi(1, per_fight))))
		_check(fights >= 3, "nível %d: mesmo no melhor caso são %d lutas para subir (mínimo 3)" % [level, fights])
	_check(EconomySystemScript.streak_reward_multiplier(10) > 1.0, "a sequência continua premiando o ouro")
	_check(best_case > 0, "o cálculo do XP por luta é positivo")

## Venda: 40% do preço de compra; o item único de torneio não entra no mercado.
func _test_sell_rules() -> void:
	_check(EconomySystemScript.sell_price({"id": "teste", "price": 100}) == 40, "venda devolve 40 por cento do preço")
	var trophy := {"id": "gladius_magnus", "display_name": "Gládio", "price": 250, "unique": true}
	_check(EconomySystemScript.sell_price(trophy) == 0, "item único não tem preço de venda")
	_check(not EconomySystemScript.is_sellable(trophy), "item único não é vendável")
	_check(EconomySystemScript.sell_price({}) == 0, "item vazio não tem preço de venda")

## Bolsa e equipamento no modelo: desequipar devolve à bolsa, equipar tira dela e
## item equipado não pode ser removido (é o que a venda exige).
func _test_bag_and_unequip() -> void:
	var player = GladiatorDataScript.new({"id": "p", "base_max_health": 50, "base_attack": 10})
	var sword := {"id": "sw1", "display_name": "Espada", "slot": "weapon", "price": 100, "attack_bonus": 4}
	player.remember_item(sword)
	_check(player.bag_items().size() == 1, "item lembrado aparece na bolsa")
	player.equip_item(sword)
	_check(player.equipped_id("weapon") == "sw1" and player.bag_items().is_empty(), "equipar tira o item da bolsa")
	_check(player.attack == 14, "equipar aplica o bônus")
	_check(not player.remove_owned("sw1"), "item equipado não pode ser removido da bolsa")
	_check(player.unequip("weapon") and player.equipped_id("weapon") == "", "desequipar limpa o slot")
	_check(player.attack == 10, "desequipar devolve o atributo")
	_check(player.bag_items().size() == 1, "item desequipado volta para a bolsa")
	_check(player.remove_owned("sw1") and player.bag_items().is_empty(), "item desequipado pode ser removido")

## Valida o conteúdo de `data/archetypes.json` (os dados existem e carregam). A escolha
## de classe não existe na criação, então isto é validação de conteúdo, não de sistema.
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
	var duelist = GladiatorDataScript.new({"id": "p", "archetype_id": "duelist", "max_health": 60})
	_check(duelist.archetype_id == "duelist", "GladiatorData guarda archetype_id")

func _test_save_roundtrip() -> void:
	var test_path := "user://tests_save.json"
	var fighter = GladiatorDataScript.new({"id": "p", "display_name": "Tester", "level": 3, "gold": 99, "base_max_health": 60, "base_attack": 10, "base_defense": 4, "base_luck": 6, "pending_level_ups": 1})
	fighter.equip_weapon(ContentRepositoryScript.find_item(ContentRepositoryScript.load_items(), "dagger"))
	_check(SaveSystemScript.save_game({"version": 1, "stage_index": 2, "player": fighter.to_save_data()}, test_path), "save_game grava o arquivo")
	_check(SaveSystemScript.has_save(test_path), "has_save detecta o arquivo")
	var data := SaveSystemScript.load_game(test_path)
	var loaded = GladiatorDataScript.new(data.get("player", {}))
	_check(loaded.level == 3 and loaded.gold == 99 and loaded.attack == 13, "load recupera nivel/ouro/equipamento")
	_check(int(data.get("stage_index", -1)) == 2, "load recupera progresso da campanha")
	SaveSystemScript.delete_save(test_path)
	_check(not SaveSystemScript.has_save(test_path), "delete_save remove o arquivo")

func _test_movement_and_range() -> void:
	_check(CombatResolverScript.move_toward(3) == 2 and CombatResolverScript.move_toward(1) == 1, "avancar reduz a distancia respeitando o minimo")
	_check(CombatResolverScript.move_away(3) == 4 and CombatResolverScript.move_away(6) == 6, "recuar aumenta a distancia respeitando o maximo")
	var melee := {"kind": "melee", "reach": 1}
	var ranged := {"kind": "ranged"}
	_check(CombatResolverScript.can_attack_at(1, melee) and not CombatResolverScript.can_attack_at(2, melee), "melee so acerta dentro do alcance")
	_check(CombatResolverScript.can_attack_at(6, ranged), "ranged ataca de qualquer distancia")
	_check(CombatResolverScript.ranged_accuracy(1.0, 3) < CombatResolverScript.ranged_accuracy(1.0, 1), "ranged erra mais quanto maior a distancia")
	var attacker = GladiatorDataScript.new({"id": "a", "attack": 12, "defense": 2, "luck": 8, "max_health": 60})
	var defender = GladiatorDataScript.new({"id": "d", "attack": 6, "defense": 3, "luck": 2, "max_health": 60})
	var out_range: Dictionary = CombatResolverScript.resolve_positional_attack(attacker, defender, melee, 3, 1.0, 1.0, 0)
	_check(bool(out_range.get("out_of_range", false)) and not bool(out_range.hit), "melee fora de alcance nao acerta")
	var hp_before: int = defender.health
	CombatResolverScript.resolve_positional_attack(attacker, defender, melee, 1, 1.0, 1.0, 0)
	_check(defender.health < hp_before, "melee em alcance causa dano")

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok - %s" % label)
	else:
		_failures += 1
		printerr("  FALHOU - %s" % label)
