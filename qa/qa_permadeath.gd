extends Control

## QA VISUAL da ETAPA 11 — PERMADEATH no torneio (§6).
##
## Abre num display virtual e tira um print de cada peça exigida:
##   01_aviso_vermelho  — a tela de AVISO (MORTE NO TORNEIO = PERSONAGEM APAGADO)
##   02_confirmacao     — o botão de confirmação ENTRAR MESMO ASSIM em foco
##   03_apresentacao    — a apresentação da rodada do torneio com o aviso vermelho
##   04_tela_de_queda   — a tela de queda (nome/rank/KD/títulos/carrasco)
##   05_mural           — o Mural dos caídos com o registro do caído
##
##   xvfb-run -a -s "-screen 0 1100x700x24" <godot> --path . res://qa/qa_permadeath.tscn

const TournamentWarningScene := preload("res://scenes/tournament_warning.tscn")
const PreFightScene := preload("res://scenes/pre_fight_screen.tscn")
const FallenScreenScene := preload("res://scenes/fallen_screen.tscn")
const MuralScreenScene := preload("res://scenes/mural_screen.tscn")
const FallenWallScript := preload("res://scripts/systems/fallen_wall.gd")

const OUT_DIR := "user://qa_permadeath/"

var _lines: Array[String] = []

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	get_tree().create_timer(120.0).timeout.connect(_finish)
	await _run()
	_finish()

func _finish() -> void:
	for line: String in _lines:
		print(line)
	print("QA ETAPA 11: FIM")
	get_tree().quit(0)

func _say(text: String) -> void:
	_lines.append(text)

func _run() -> void:
	GameState.clear_save()
	FallenWallScript.clear()
	GameState.start_new_campaign("Fúlvio", {})
	var player = GameState.player
	if player != null:
		player.level = 10
		if player.has_method("recompute_derived"):
			player.recompute_derived()
		player.rank_points = 5000
		player.wins = 11
		player.losses = 3
		player.tournaments_won = 2
	_say("campanha de QA criada: %s, rank %s, KD %d/%d, torneios vencidos %d" % [
		str(player.display_name), GameState.player_rank_title(), int(player.wins), int(player.losses), int(player.tournaments_won)])

	# 1) AVISO OBRIGATÓRIO (§6.1)
	var warn = TournamentWarningScene.instantiate()
	add_child(warn)
	warn.set_tier("t3")
	await _wait(0.9)
	await _shot("01_aviso_vermelho")
	var confirm_btn := _find_button(warn, "ENTRAR MESMO ASSIM")
	if confirm_btn != null:
		confirm_btn.grab_focus()
	await _wait(0.3)
	await _shot("02_confirmacao")
	_say("aviso exige termo literal? %s" % str(_find_label(warn, "MORTE NO TORNEIO = PERSONAGEM APAGADO") != null))
	warn.queue_free()
	await _wait(0.3)

	# 2) APRESENTAÇÃO da rodada do torneio — com o aviso vermelho (§6.1)
	GameState.start_tournament("t3")
	GameState.current_enemy = GameState.build_current_foe()
	var pre = PreFightScene.instantiate()
	add_child(pre)
	await _wait(1.0)
	await _shot("03_apresentacao")
	_say("apresentação tem o aviso vermelho? %s" % str(_find_label(pre, "MORTE NO TORNEIO = PERSONAGEM APAGADO") != null))
	pre.queue_free()
	await _wait(0.3)

	# 3) TELA DE QUEDA (§6.2) — simula a morte na FINAL (carrasco com apelido)
	GameState.tourney_round = GameState.tournament_round_total() - 1
	GameState.current_enemy = GameState.build_current_foe()
	var carrasco := str(GameState.current_enemy.display_name) if GameState.current_enemy != null else ""
	GameState.on_defeat(false)
	var entry: Dictionary = GameState.apply_permadeath()
	await _wait(0.2)
	_say("queda registrada — carrasco '%s' («%s»), save existe? %s" % [
		str(entry.get("executioner", "")), str(entry.get("executioner_nickname", "")), str(GameState.has_save())])
	var fallen = FallenScreenScene.instantiate()
	add_child(fallen)
	await _wait(1.1)
	await _shot("04_tela_de_queda")
	_say("tela de queda mostra o carrasco? %s" % str(_find_label(fallen, carrasco) != null))
	fallen.queue_free()
	await _wait(0.3)

	# 4) MURAL DOS CAÍDOS (§6.4)
	var mural = MuralScreenScene.instantiate()
	add_child(mural)
	await _wait(0.9)
	await _shot("05_mural")
	_say("Mural tem %d caído(s) registrado(s)" % FallenWallScript.count())
	mural.queue_free()
	await _wait(0.3)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _shot(file_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var path := OUT_DIR + file_name + ".png"
	var err := image.save_png(path)
	_say("PRINT %s -> %s (err=%d)" % [file_name, path, err])

func _find_button(root: Node, text_value: String) -> Button:
	if root is Button and (root as Button).text == text_value:
		return root as Button
	for child in root.get_children():
		var found := _find_button(child, text_value)
		if found != null:
			return found
	return null

func _find_label(root: Node, needle: String) -> Label:
	if root is Label and (root as Label).text.contains(needle):
		return root as Label
	for child in root.get_children():
		var found := _find_label(child, needle)
		if found != null:
			return found
	return null
