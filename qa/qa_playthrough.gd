extends Control

## QA visual da ETAPA 9 (docs/PLANO_3.0.md §5.2/§5.3), com o jogo ABERTO num
## display virtual. Prova em imagem:
##   1) o GRAU DE DIFICULDADE do boss (1 a 5 ⭐) na APRESENTAÇÃO e na ARENA;
##   2) a vitória do torneio com o ITEM DO BOSS pela TABELA DE DROP (nome+raridade);
##   3) a BOLSA com VARIAÇÕES ÚNICAS (não vendáveis).
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
	get_tree().create_timer(150.0).timeout.connect(_finish)
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
	GameState.start_new_campaign("QA9", {})
	GameState.player.rank_points = 900
	GameState.player.level = 8
	GameState.player.recompute_derived()
	var blade := {
		"id": "qa_blade", "display_name": "Lâmina de QA", "slot": "weapon",
		"kind": "melee", "reach": 1, "hands": 1,
		"strength_bonus": 20, "attack_bonus": 10, "agility_bonus": 6, "armour": 0,
	}
	GameState.player.equip_item(blade)
	if not GameState.start_tournament("t2"):
		_say("ERRO: não conseguiu iniciar o torneio t2 (rank insuficiente?)")
		return
	GameState.tourney_round = GameState.tournament_round_total() - 1
	GameState.current_enemy = GameState.build_current_foe()
	if GameState.current_enemy == null:
		_say("ERRO: sem boss na rodada final")
		return
	var grade := GameState.current_boss_grade()
	_say("boss da FINAL: %s | grau=%d %s" % [GameState.current_enemy.display_name, grade, BossDropTable.stars(grade)])

	# (1) APRESENTAÇÃO: faixa do COMBATE FINAL + o GRAU (1 a 5 ⭐).
	var prefight := PreFightScene.instantiate()
	add_child(prefight)
	await _wait(1.1)
	await _shot("01_apresentacao_grau_boss")
	prefight.queue_free()
	await _wait(0.2)

	# (2) ARENA: faixa do COMBATE FINAL com o grau.
	var arena := ArenaScene.instantiate()
	add_child(arena)
	await _wait(0.8)
	await _shot("02_arena_grau_boss")

	# Força uma vitória: inimigo a 1 de vida, colado e sem esquiva/defesa.
	GameState.player.health = GameState.player.max_health
	arena.distance = 1
	arena.player_pos = 1
	arena.enemy_pos = 2
	GameState.current_enemy.base_agility = 0
	GameState.current_enemy.base_defence = 0
	GameState.current_enemy.recompute_derived()
	GameState.current_enemy.health = 1
	arena.refresh()
	await _wait(0.3)
	arena.player_action("golpe")
	await _wait(0.9)
	await _shot("03_vitoria_torneio")

	var result = arena._banner_result
	if result == null:
		_say("ERRO: sem resultado de vitória")
		arena.queue_free()
		return
	var loot: Array = result.loot
	_say("VITÓRIA: ouro=%d | item(ns) do boss=%d" % [int(result.gold), loot.size()])
	for item: Dictionary in loot:
		var is_unique := UniqueItems.tier_of(str(item.get("id", ""))) != ""
		_say("ITEM DO BOSS: %s | raridade=%s | único=%s" % [str(item.get("display_name", "")), str(item.get("rarity", "")), str(is_unique)])
	arena.queue_free()
	await _wait(0.2)

	# (3) RESUMO da luta com o item do boss (nome + raridade).
	var summary := ResultScene.instantiate()
	add_child(summary)
	summary.set_result(result)
	await _wait(0.6)
	await _shot("04_resultado_item_do_boss")
	summary.queue_free()
	await _wait(0.2)

	# (4) BOLSA com VARIAÇÕES ÚNICAS (não vendáveis).
	GameState.add_item_to_bag(UniqueItems.find("manto_do_publico"))
	GameState.add_item_to_bag(UniqueItems.find("adaga_da_viuva"))
	var bag := CharacterScene.instantiate()
	add_child(bag)
	await _wait(1.0)
	await _shot("05_bolsa_variacao_unica")
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
