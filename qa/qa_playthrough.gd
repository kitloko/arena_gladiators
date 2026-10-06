extends Control

## QA visual da ETAPA 10 (docs/PLANO_3.0.md §5.1/§5.3), com o jogo ABERTO num
## display virtual. Prova em imagem DUAS FINAIS DIFERENTES:
##   1) o boss FINAL SORTEADO do pool do PRÓPRIO tier (nome/apelido/descrição/
##      fraqueza/provocação) + a faixa COMBATE FINAL + o GRAU (1 a 5 ★);
##   2) o mesmo na ARENA e o cartaz de vitória;
##   3) o PRÊMIO (item do boss pela tabela de drop do grau sorteado).
## As duas finais usam tiers diferentes (Menor = graus 1-3; Grande = graus 4-5),
## então os bosses E os graus são garantidamente diferentes.
## Salva em user://qa_playthrough/ (o script de QA copia para fora).
##
##   xvfb-run -a -s "-screen 0 1100x700x24" <godot> --path . res://qa/qa_playthrough.tscn

const PreFightScene := preload("res://scenes/pre_fight_screen.tscn")
const ArenaScene := preload("res://scenes/arena.tscn")
const ResultScene := preload("res://scenes/result_screen.tscn")
const CharacterScene := preload("res://scenes/character_screen.tscn")
const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")

const OUT_DIR := "user://qa_playthrough/"

var _lines: Array[String] = []

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	get_tree().create_timer(180.0).timeout.connect(_finish)
	await _run()
	_finish()

func _finish() -> void:
	for line: String in _lines:
		print(line)
	print("QA PLAYTHROUGH: FIM")
	get_tree().quit(0)

func _say(text: String) -> void:
	_lines.append(text)

func _run() -> void:
	GameState.clear_save()
	GameState.start_new_campaign("QA10", {})
	GameState.player.level = 10
	GameState.player.recompute_derived()
	# ARMA forte para o QA (só acelera a luta; não muda o boss sorteado).
	var blade := {
		"id": "qa_blade", "display_name": "Lâmina de QA", "slot": "weapon",
		"kind": "melee", "reach": 1, "hands": 1,
		"strength_bonus": 30, "attack_bonus": 14, "agility_bonus": 8, "armour": 0,
	}
	GameState.player.equip_item(blade)

	# As duas finais: Menor (pool de graus 1-3) e Grande (pool de graus 4-5).
	# Tiers diferentes => pools disjuntos => bosses E graus diferentes, garantido.
	var season := [
		{"tier": "t1", "rank": 2300, "label": "final_menor"},
		{"tier": "t3", "rank": 5000, "label": "final_grande"},
	]

	var shot_index := 0
	for entry: Dictionary in season:
		var tier_id := str(entry.tier)
		var label := str(entry.label)
		GameState.player.rank_points = int(entry.rank)
		# Campanha reiniciada por tier: a memória do sorteio é por tier e persiste,
		# então as duas finais não repetem o mesmo boss.
		if not GameState.start_tournament(tier_id):
			_say("ERRO: não conseguiu iniciar o torneio %s (rank insuficiente?)" % tier_id)
			return
		GameState.tourney_round = GameState.tournament_round_total() - 1
		GameState.current_enemy = GameState.build_current_foe()
		if GameState.current_enemy == null:
			_say("ERRO: sem boss na rodada final de %s" % tier_id)
			return
		var boss_id := str(GameState.current_enemy.id)
		var boss_name := str(GameState.current_enemy.display_name)
		var grade := GameState.current_boss_grade()
		_say("FINAL %s (%s): boss SORTEADO = %s | id=%s | grau=%d %s" % [
			label, GameState.tournament_tier_name(), boss_name, boss_id, grade, BossDropTable.stars(grade)])

		# (1) APRESENTAÇÃO: COMBATE FINAL + boss sorteado + GRAU.
		var prefight := PreFightScene.instantiate()
		add_child(prefight)
		await _wait(1.1)
		await _shot("%02d_apresentacao_%s" % [shot_index + 1, label])
		shot_index += 1
		prefight.queue_free()
		await _wait(0.2)

		# (2) ARENA: faixa COMBATE FINAL com o grau do boss sorteado.
		var arena := ArenaScene.instantiate()
		add_child(arena)
		await _wait(0.8)
		await _shot("%02d_arena_%s" % [shot_index + 1, label])
		shot_index += 1

		# Força uma vitória: inimigo a 1 de vida, colado, sem esquiva/defesa/armadura.
		GameState.player.health = GameState.player.max_health
		GameState.player.armour = GameState.player.max_armour
		arena.distance = 1
		arena.player_pos = 1
		arena.enemy_pos = 2
		GameState.current_enemy.base_agility = 0
		GameState.current_enemy.base_defence = 0
		GameState.current_enemy.recompute_derived()
		GameState.current_enemy.health = 1
		GameState.current_enemy.armour = 0
		GameState.current_enemy.vulnerable = true
		arena.refresh()
		await _wait(0.3)
		arena.player_action("golpe")
		await _wait(0.9)
		await _shot("%02d_vitoria_%s" % [shot_index + 1, label])
		shot_index += 1

		var result = arena._banner_result
		if result == null:
			_say("ERRO: sem resultado de vitória em %s" % label)
			arena.queue_free()
			return
		var loot: Array = result.loot
		_say("FINAL %s: ouro=%d | itens do boss=%d" % [label, int(result.gold), loot.size()])
		for item: Dictionary in loot:
			var is_unique := UniqueItems.tier_of(str(item.get("id", ""))) != ""
			_say("PRÊMIO %s: %s | raridade=%s | único=%s" % [
				label, str(item.get("display_name", "")), str(item.get("rarity", "")), str(is_unique)])
		arena.queue_free()
		await _wait(0.2)

		# (3) RESUMO da luta com o item do boss (nome + raridade).
		var summary := ResultScene.instantiate()
		add_child(summary)
		summary.set_result(result)
		await _wait(0.6)
		await _shot("%02d_resultado_%s" % [shot_index + 1, label])
		shot_index += 1
		summary.queue_free()
		await _wait(0.2)

		GameState.finish_tournament()
		await _wait(0.2)

	# (4) BOLSA com VARIAÇÕES ÚNICAS (não vendáveis).
	GameState.add_item_to_bag(UniqueItems.find("manto_do_publico"))
	GameState.add_item_to_bag(UniqueItems.find("adaga_da_viuva"))
	var bag := CharacterScene.instantiate()
	add_child(bag)
	await _wait(1.0)
	await _shot("%02d_bolsa_variacao_unica" % (shot_index + 1))
	var manto: Dictionary = UniqueItems.find("manto_do_publico")
	_say("bolsa: itens=%d | Manto do Público vendável=%s | preço de venda=%d" % [GameState.player.bag_items().size(), str(EconomySystemScript.is_sellable(manto)), EconomySystemScript.sell_price(manto)])

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var err := image.save_png("%s%s.png" % [OUT_DIR, shot_name])
	if err == OK:
		_say("screenshot OK: %s (%dx%d)" % [shot_name, image.get_width(), image.get_height()])
	else:
		_say("ERRO no screenshot %s (err %d)" % [shot_name, err])
