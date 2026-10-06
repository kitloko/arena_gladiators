extends Node

## Smoke test do fluxo com Cidade (hub) e bolsa:
## criação -> loja inicial -> cidade -> arena (distância visual / botões) ->
## resultado -> seguir -> salvar/continuar -> torneio -> fim -> cidade.

const MainScene := preload("res://Main.tscn")

var _failures: int = 0

func _ready() -> void:
	_run_test()

func _run_test() -> void:
	GameState.clear_save()
	var app = MainScene.instantiate()
	add_child(app)
	await get_tree().process_frame
	# 1) Criação
	var creation = _find_by_method(app, "_on_confirm_pressed")
	_check(creation != null, "sem save, app começa na criação")
	if creation == null:
		_finish()
		return
	creation._name_field.text = "Tester"
	creation.allocate_points("attack", 12)
	await get_tree().process_frame
	_check(not creation._confirm_button.disabled, "confirmar liberado")
	creation._on_confirm_pressed()
	await get_tree().create_timer(0.4).timeout
	_check(GameState.player != null and GameState.player.base_attack == 20 and GameState.player.gold == 80, "criação neutra aplicada (80 ouro)")
	# 2) Loja inicial
	_check(_find_by_method(app, "_on_mutation") != null, "loja inicial abre após a criação")
	var buy_button = _find_button(app, "COMPRAR")
	if buy_button != null and not buy_button.disabled:
		buy_button.pressed.emit()
		await get_tree().create_timer(0.2).timeout
	_check(GameState.player.equipped_id("weapon") != "", "compra equipa uma arma")
	_press_button(app, "VOLTAR À ARENA  →")
	await get_tree().create_timer(0.4).timeout
	# 3) Cidade (hub)
	_check(_find_label_contains(app, "CIDADE") != null, "cidade abre após a loja inicial")
	_check(_find_button_contains(app, "PERSONAGEM E BOLSA") != null, "cidade tem personagem/bolsa")
	# 4) Personagem/Bolsa e voltar
	_press_button_contains(app, "PERSONAGEM E BOLSA")
	await get_tree().create_timer(0.3).timeout
	_check(_find_by_method(app, "_on_mutation") != null or _find_label_contains(app, "Bolsa") != null, "tela do personagem mostra a bolsa")
	_press_button(app, "VOLTAR À CIDADE")
	await get_tree().create_timer(0.3).timeout
	# 5) Arena Livre a partir da cidade
	_press_button_contains(app, "Arena Livre")
	await get_tree().create_timer(0.4).timeout
	var arena = _find_by_method(app, "start_new_fight")
	_check(arena != null and GameState.current_enemy != null, "luta começa a partir da cidade")
	if arena == null:
		_finish()
		return
	_check(_find_button(app, "Avançar") != null, "ações de movimento presentes")
	_check(int(arena.distance) == 3, "começa a distância 3")
	_check(arena.distance_track != null and arena.distance_track.get_child_count() == 9, "trilha visual da arena com muralhas (9 células)")
	var attack_btn = _find_button(app, "Atacar")
	_check(attack_btn != null and attack_btn.disabled, "Atacar desabilitado fora de alcance (melee a 3 passos)")
	var round_before: int = int(arena.round_number)
	arena.player_action("attack")
	await get_tree().create_timer(0.8).timeout
	_check(int(arena.round_number) == round_before + 1, "turno do inimigo executou exatamente uma vez")
	# 6) Vitória com nível pendente
	GameState.player.health = GameState.player.max_health
	GameState.player.experience = GameState.player.required_experience() - 5
	arena.distance = 1
	GameState.current_enemy.health = 1
	arena.player_action("attack")
	await get_tree().create_timer(0.6).timeout
	var result = _find_by_method(app, "set_result")
	_check(result != null, "resultado aparece")
	if result == null:
		_finish()
		return
	_press_button(app, "Força")
	await get_tree().create_timer(0.3).timeout
	_press_button(app, "SEGUIR")
	await get_tree().create_timer(0.4).timeout
	_check(_find_by_method(app, "start_new_fight") != null and GameState.current_enemy != null, "seguir inicia uma nova luta (inimigo gerado)")
	_check(GameState.has_save(), "progresso salvo automaticamente")
	var gold_saved: int = GameState.player.gold
	var attack_saved: int = GameState.player.attack
	_check(GameState.continue_campaign(), "continue_campaign carrega o save")
	_check(GameState.player.gold == gold_saved and GameState.player.attack == attack_saved, "continue restaura ouro e atributos")
	# 7) Torneio (acumula prêmio, item único)
	_check(GameState.start_tournament("t2"), "torneio inicia")
	_check(GameState.is_tournament() and GameState.build_current_foe() != null, "torneio tem oponente")
	var gold_before: int = GameState.player.gold
	var r1: Dictionary = GameState.on_victory(50, 40)
	_check(bool(r1.tournament) and int(r1.prize) > 0 and not bool(r1.campaign_cleared), "vitória no torneio acumula prêmio")
	GameState.tourney_round = GameState.tournament_round_total() - 1
	var rfinal: Dictionary = GameState.on_victory(50, 40)
	_check(bool(rfinal.campaign_cleared) and GameState.player.owns_item("gladius_magnus"), "vencer o Grande Gladiador entrega o item único")
	_check(GameState.player.gold > gold_before, "prêmio entra no ouro")
	GameState.finish_tournament()
	# 8) Fim de torneio leva à cidade com save
	app.show_end(true)
	await get_tree().create_timer(0.3).timeout
	_press_button(app, "VOLTAR AO ACAMPAMENTO")
	await get_tree().create_timer(0.4).timeout
	_check(_find_label_contains(app, "CIDADE") != null and GameState.has_save(), "fim do torneio volta à cidade e mantém o save")
	GameState.clear_save()
	_finish()

func _press_button(root: Node, text_value: String) -> void:
	var button = _find_button(root, text_value)
	if button != null:
		button.pressed.emit()

func _press_button_contains(root: Node, text_value: String) -> void:
	var button = _find_button_contains(root, text_value)
	if button != null:
		button.pressed.emit()

func _find_by_method(node: Node, method_name: String) -> Node:
	if node.has_method(method_name):
		return node
	for child in node.get_children():
		var found = _find_by_method(child, method_name)
		if found != null:
			return found
	return null

func _find_button(root: Node, text_value: String):
	if root is Button and (root.text == text_value or str(root.text).split("\n")[0] == text_value):
		return root
	for child in root.get_children():
		var found = _find_button(child, text_value)
		if found != null:
			return found
	return null

func _find_button_contains(root: Node, text_value: String):
	if root is Button and str(root.text).contains(text_value):
		return root
	for child in root.get_children():
		var found = _find_button_contains(child, text_value)
		if found != null:
			return found
	return null

func _find_label_contains(root: Node, text_value: String):
	if root is Label and str(root.text).contains(text_value):
		return root
	for child in root.get_children():
		var found = _find_label_contains(child, text_value)
		if found != null:
			return found
	return null

func _finish() -> void:
	if _failures == 0:
		print("PASS: fluxo com cidade/bolsa e arena visual ok.")
		get_tree().quit(0)
	else:
		print("FAIL: %d verificacao(oes) falharam." % _failures)
		get_tree().quit(1)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok - %s" % label)
	else:
		_failures += 1
		printerr("  FALHOU - %s" % label)
