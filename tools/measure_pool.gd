extends SceneTree

## MEDIÇÃO DO POOL DE BOSSES FINAIS (etapa 10 / §5.3) — FERRAMENTA de apoio.
## NÃO é uma suíte: só MEDE e IMPRIME, para provar que TODO candidato do pool é
## uma luta justa no nível-alvo do tier E que a régua é a MESMA do
## tests/run_balance_test.gd (reproduzido aqui de propósito).
##
##   GODOT_SILENCE_ROOT_WARNING=1 <godot> --headless --path . -s res://tools/measure_pool.gd
##
## Para cada tier imprime:
##  - a REFERÊNCIA do boss antigo (`grande_gladiador`) no nível-alvo e no nível 5;
##  - cada candidato do pool nos DOIS níveis (nível-alvo = meta; nível 5 = escada);
##  - o pior caso (menor taxa) do tier no nível-alvo.

const CombatResolverScript := preload("res://scripts/systems/combat_resolver.gd")
const GladiatorDataScript := preload("res://scripts/models/gladiator_data.gd")
const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")
const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")
const ItemGeneratorScript := preload("res://scripts/systems/item_generator.gd")
const BossPoolScript := preload("res://scripts/systems/boss_pool.gd")

const SAMPLES := 400
const SEED_VALUE := 20261010
const REFERENCE_BOSS := "grande_gladiador"
const TARGET_LEVELS := {0: 5, 1: 8, 2: 12}

func _initialize() -> void:
	seed(SEED_VALUE)
	var enemies := ContentRepositoryScript.load_enemies()
	var tiers := ContentRepositoryScript.load_tournaments()
	for tier_index in tiers.size():
		var tier: Dictionary = tiers[tier_index]
		var tier_id := str(tier.get("id", ""))
		var level: int = int(TARGET_LEVELS.get(tier_index, 8))
		var rounds: Array = tier.get("rounds", [])
		var pool := BossPoolScript.pool_for(tier_id)
		print("")
		print("--- %s (nível-alvo %d) ---" % [str(tier.get("name", "?")), level])
		var ref_target := _rate(rounds, enemies, level, tier_index, REFERENCE_BOSS)
		var ref_l5 := _rate(rounds, enemies, 5, tier_index, REFERENCE_BOSS)
		print("  %-22s ref. antiga | alvo %3d%% | nível 5 %3d%%" % [REFERENCE_BOSS, int(round(ref_target)), int(round(ref_l5))])
		var worst_target := 999.0
		var worst_boss := ""
		for boss_id: String in pool:
			var t_rate := _rate(rounds, enemies, level, tier_index, boss_id)
			var l5_rate := _rate(rounds, enemies, 5, tier_index, boss_id)
			var template := ContentRepositoryScript.find_enemy(enemies, boss_id)
			print("  %-22s grau %d | alvo %3d%% | nível 5 %3d%%" % [str(template.get("display_name", boss_id)), int(template.get("grade", 0)), int(round(t_rate)), int(round(l5_rate))])
			if t_rate < worst_target:
				worst_target = t_rate
				worst_boss = str(template.get("display_name", boss_id))
		print("  PIOR CASO no alvo: %s = %d%%" % [worst_boss, int(round(worst_target))])
	print("")
	print("MEDIÇÃO DO POOL: FIM")
	quit(0)

func _rate(rounds: Array, enemies: Array, level: int, tier_index: int, final_boss_id: String) -> float:
	var cleared := 0
	for i in SAMPLES:
		if _tournament(_make_player_equipped(level), rounds, enemies, level, tier_index, final_boss_id):
			cleared += 1
	return 100.0 * float(cleared) / float(SAMPLES)

func _tournament(player, rounds: Array, enemies: Array, level: int, tier_index: int, final_boss_id: String) -> bool:
	for round_index in rounds.size():
		var template := {}
		if round_index == rounds.size() - 1:
			template = ContentRepositoryScript.find_enemy(enemies, final_boss_id)
		else:
			template = ContentRepositoryScript.find_enemy(enemies, str(rounds[round_index]))
		var foe = CombatResolverScript.enemy_for_level(level + tier_index * 2 + round_index, template)
		if _fight(player, foe):
			player.heal_full()
		else:
			return false
	return true

## Mesmo perfil de jogador do run_balance_test (_make_player_equipped).
func _make_player_equipped(level: int) -> GladiatorData:
	var points: int = EconomySystemScript.creation_points()
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
	for i in (maxi(0, level - 1)):
		player.grant_experience(player.required_experience())
		player.spend_attribute_point("strength")
		player.spend_attribute_point("strength")
		player.spend_attribute_point("vitality")
		player.spend_attribute_point("defence")
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

## Troca de golpes até alguém cair (vida cheia dos dois lados). Vitória = inimigo cai.
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
