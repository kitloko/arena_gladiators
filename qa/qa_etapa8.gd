extends Control

## QA visual da ETAPA 8 (fora do repo de jogo, em work/qa): abre a arena de
## verdade num display virtual, força as poses/efeitos e tira um print de cada
## um. Salva em user://qa_etapa8/ (copiados para fora pelo script de QA).
##
##   xvfb-run -a -s "-screen 0 1100x700x24" <godot> --path . res://qa/qa_etapa8.tscn

const ArenaScene := preload("res://scenes/arena.tscn")
const OUT_DIR := "user://qa_etapa8/"

var _lines: Array[String] = []

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	get_tree().create_timer(120.0).timeout.connect(_finish)
	await _run()
	_finish()

func _finish() -> void:
	for line: String in _lines:
		print(line)
	print("QA ETAPA 8: FIM")
	get_tree().quit(0)

func _say(text: String) -> void:
	_lines.append(text)

func _run() -> void:
	GameState.clear_save()
	GameState.start_new_campaign("QA", {})
	GameState.player.rank_points = 0
	# Arma À DISTÂNCIA para o caminho do projétil ser o de verdade (TIRO).
	var bow := {
		"id": "qa_bow", "display_name": "Arco de QA", "slot": "weapon",
		"kind": "ranged", "reach": 1, "hands": 2,
		"strength_bonus": 6, "attack_bonus": 8, "armour": 0,
	}
	GameState.player.equip_weapon(bow)
	_say("arma equipada: %s | kind=%s" % [GameState.player_weapon().get("display_name", "?"), GameState.player_weapon().get("kind", "?")])
	GameState.current_enemy = GameState.build_current_foe()
	if GameState.current_enemy == null:
		_say("ERRO: sem inimigo")
		return
	_say("inimigo: %s (id=%s)" % [GameState.current_enemy.display_name, GameState.current_enemy.id])
	var arena = ArenaScene.instantiate()
	add_child(arena)
	await _wait(0.9)
	# Abre a distância para o projétil e o arco de corte terem espaço no palco.
	arena.distance = 3
	arena.player_pos = 1
	arena.enemy_pos = 4
	arena.refresh()
	await _wait(0.3)
	# Deixa os dois vivos (a foto é a pose, não o fim da luta).
	GameState.player.health = GameState.player.max_health
	GameState.current_enemy.health = GameState.current_enemy.max_health
	arena.refresh()
	await _wait(0.2)

	# (1) HERÓI na pose de ATAQUE.
	arena._play_pose(true, "attack", 30.0)
	await _wait(0.15)
	await _shot("01_hero_ataque")

	# (2) HERÓI atacando + INIMIGO levando o golpe (a pose dele) + respingo de dano.
	arena._play_pose(false, "hit", 30.0)
	arena._spawn_hit_effect(false)
	await _wait(0.12)
	await _shot("02_hero_ataque_inimigo_levado")

	# (3) HERÓI APARANDO (defesa) + faísca de aparo.
	arena._play_pose(true, "defend", 30.0)
	arena._play_pose(false, "attack", 30.0)
	arena._spawn_block_effect(true)
	await _wait(0.12)
	await _shot("03_hero_defendendo_aparou")

	# (4) Arco de corte do golpe corpo a corpo.
	arena._play_pose(true, "attack", 30.0)
	arena._play_pose(false, "hit", 30.0)
	arena._spawn_attack_effect(true, "melee", arena.distance)
	await _wait(0.10)
	await _shot("04_arco_de_corte_melee")

	# (5) PROJÉTIL voando: usa o caminho REAL da ação à distância (TIRO).
	arena._play_pose(true, "idle", 0.0)
	arena._play_pose(false, "idle", 0.0)
	arena.distance = 4
	arena.player_pos = 1
	arena.enemy_pos = 5
	arena.refresh()
	await _wait(0.25)
	arena.player_action("tiro")
	await _wait(0.12)
	await _shot("05_projetil_voado")
	_say("projétil: disparado por player_action('tiro') com arco (kind=%s)" % GameState.player_weapon().get("kind", "?"))
	await _wait(0.9)

	# (6) Derrotado na pose CAÍDA (o cartaz fica por cima quando a luta acaba).
	arena._set_downed(false)
	await _wait(0.15)
	await _shot("06_inimigo_caido")
	_say("pose caído aplicada no derrotado (rotação + escurecido)")

	# (7) Hero caído (derrota).
	arena._set_downed(true)
	arena._set_downed(false)
	await _wait(0.15)
	await _shot("07_hero_caido")

	# Prova do drop-in: as poses vêm do manifesto do dono se os PNGs existirem.
	var m := FighterVisuals.manifest()
	var hero_entry: Dictionary = (m.get("characters", {}) as Dictionary).get("hero", {})
	_say("caracters.json: herói presente=%s | pose idle=%s" % [str(FighterVisuals.has_character("hero")), str(hero_entry.get("idle", ""))])
	var pose_path := FighterVisuals.path_for("hero", "ataque")
	_say("resolução da pose de ataque do herói: %s" % (pose_path if pose_path != "" else "<vazio: usando o sprite atual hero_ataque.png>"))
	_say("pose_for_event(attack)=%s defend=%s hit=%s fallen=%s idle=%s" % [
		FighterVisuals.pose_for_event("attack"), FighterVisuals.pose_for_event("defend"),
		FighterVisuals.pose_for_event("hit"), FighterVisuals.pose_for_event("fallen"),
		FighterVisuals.pose_for_event("idle")])

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var err := image.save_png("%s%s.png" % [OUT_DIR, name])
	if err == OK:
		_say("screenshot OK: %s (%dx%d)" % [name, image.get_width(), image.get_height()])
	else:
		_say("ERRO no screenshot %s (err %d)" % [name, err])
