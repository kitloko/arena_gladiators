extends Node

## Smoke test do fluxo com Cidade (hub) e bolsa:
## criação -> loja inicial -> cidade -> arena (distância visual / botões) ->
## resultado -> seguir -> salvar/continuar -> torneio -> fim -> cidade.

const MainScene := preload("res://Main.tscn")
const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")
const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")

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
	# A criação só liberta o botão com TODOS os pontos distribuídos (hoje 20).
	creation.allocate_points("attack", 12)
	creation.allocate_points("health", EconomySystemScript.creation_points() - 12)
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
	_check(_find_label_contains(app, "BOLSA") != null, "tela do personagem mostra a bolsa")
	_check(_find_label_contains(app, "EQUIPAMENTO") != null, "tela do personagem mostra os 6 slots de equipamento")
	_check(_find_label_contains(app, "Arraste um item da bolsa") != null, "tela do personagem ensina o arrastar-e-soltar")
	_check(_find_label_contains(app, "arraste um item equipado") != null, "a bolsa anuncia que e zona de desequipar")
	_check(_find_by_method(app, "_get_drag_data") != null, "os paineis de item implementam arrastar-e-soltar")
	_check(_count_named(app, "equipslot_") == 6, "a tela desenha os 6 slots de equipamento")
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
	# A sequência de vitórias multiplica o OURO, não o XP. Era o XP inflado pela
	# sequência (até +180%) que fazia o personagem subir de nível a cada luta.
	GameState.win_streak = 9
	var level_before_kill: int = GameState.player.level
	var gold_before_kill: int = GameState.player.gold
	var enemy_multiplier := float(GameState.current_enemy.reward_multiplier)
	var tier_multiplier := EconomySystemScript.tier_experience_multiplier(int(GameState.current_enemy.enemy_tier))
	var base_rewards: Dictionary = EconomySystemScript.fight_rewards(level_before_kill)
	arena.player_action("attack")
	await get_tree().create_timer(0.6).timeout
	var result = _find_by_method(app, "set_result")
	_check(result != null, "resultado aparece")
	if result == null:
		_finish()
		return
	var fought = result._result
	var expected_xp := int(round(float(int(base_rewards.experience)) * tier_multiplier))
	var expected_gold := int(round(float(int(base_rewards.gold)) * enemy_multiplier * EconomySystemScript.streak_reward_multiplier(10)))
	_check(int(fought.experience) == expected_xp, "XP da vitória não é inflado pela sequência de vitórias (medido %d, esperado %d)" % [int(fought.experience), expected_xp])
	_check(int(fought.gold) == expected_gold and int(fought.gold) > int(base_rewards.gold), "a sequência de vitórias aumenta o ouro da vitória (medido %d)" % int(fought.gold))
	_check(GameState.player.gold == gold_before_kill + int(fought.gold), "o ouro do resumo bate com o ouro do personagem")
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
	# 7) Torneio (acumula prêmio, cura na entrada, item por rodada, item único)
	# Entrar machucado tem de curar: o torneio não tem descanso nem loja no meio.
	GameState.player.health = maxi(1, GameState.player.max_health - 30)
	_check(GameState.start_tournament("t2"), "torneio inicia")
	_check(GameState.player.health == GameState.player.max_health, "entrar no torneio enche a vida")
	_check(GameState.is_tournament() and GameState.build_current_foe() != null, "torneio tem oponente")
	var gold_before: int = GameState.player.gold
	var bag_before: int = GameState.player.bag_items().size()
	var r1: Dictionary = GameState.on_victory(50, 40)
	_check(bool(r1.tournament) and int(r1.prize) > 0 and not bool(r1.campaign_cleared), "vitória no torneio acumula prêmio")
	var loot1: Array = r1.get("loot", [])
	_check(loot1.size() == 1 and GameState.player.bag_items().size() == bag_before + 1, "vencer rodada de torneio dá um item na bolsa")
	_check(GameState.player.health == GameState.player.max_health, "vencer rodada cura para a próxima")
	GameState.tourney_round = GameState.tournament_round_total() - 1
	var rfinal: Dictionary = GameState.on_victory(50, 40)
	_check(bool(rfinal.campaign_cleared) and GameState.player.owns_item("gladius_magnus"), "vencer o Grande Gladiador entrega o item único")
	_check(GameState.player.gold > gold_before, "prêmio entra no ouro")
	var loot_final: Array = rfinal.get("loot", [])
	_check(loot_final.size() == 2, "rodada final mostra o item da rodada mais o item único")
	_check(GameState.player.equipped_id("weapon") != "gladius_magnus", "item único entra na bolsa em vez de ser equipado à força")
	_check(GameState.player.bag_items().size() >= 2, "os prêmios de item ficam na bolsa")
	# 8) Bolsa: vender, desequipar e reequipar
	var bag_now: Array[Dictionary] = GameState.player.bag_items()
	var first_item: Dictionary = bag_now[0]
	var first_id := str(first_item.get("id", ""))
	var gold_pre_sale: int = GameState.player.gold
	var sale: Dictionary = GameState.sell_item(first_id)
	_check(bool(sale.ok) and GameState.player.gold == gold_pre_sale + EconomySystemScript.sell_price(first_item), "vender credita 40 por cento do preco")
	_check(not GameState.player.owns_item(first_id), "item vendido sai da bolsa")
	var trophy_sale: Dictionary = GameState.sell_item("gladius_magnus")
	_check(not bool(trophy_sale.ok) and str(trophy_sale.reason) != "", "item único de torneio não pode ser vendido")
	# O item equipado não pode ser vendido: vender exigiria tirar do corpo, e o
	# jogador perderia o bônus sem aviso. A tentativa tem de ser recusada.
	var weapon_id: String = GameState.player.equipped_id("weapon")
	_check(weapon_id != "", "há arma equipada para testar o desequipar")
	var equipped_sale: Dictionary = GameState.sell_item(weapon_id)
	_check(not bool(equipped_sale.ok) and str(equipped_sale.reason) != "", "não vende item equipado")
	_check(GameState.unequip_slot("weapon") and GameState.player.equipped_id("weapon") == "", "desequipar limpa o slot da arma")
	var bag_ids: Array[String] = []
	for entry: Dictionary in GameState.player.bag_items():
		bag_ids.append(str(entry.get("id", "")))
	_check(weapon_id in bag_ids, "item desequipado volta para a bolsa")
	GameState.equip_item(GameState.item_data(weapon_id))
	_check(GameState.player.equipped_id("weapon") == weapon_id, "reequipar da bolsa funciona")
	GameState.finish_tournament()
	# 9) Fim de torneio leva à cidade com save
	app.show_end(true)
	await get_tree().create_timer(0.3).timeout
	_press_button(app, "VOLTAR AO ACAMPAMENTO")
	await get_tree().create_timer(0.4).timeout
	_check(_find_label_contains(app, "CIDADE") != null and GameState.has_save(), "fim do torneio volta à cidade e mantém o save")
	# 10) Bolsa cheia: preço de venda visível e item único fora do mercado.
	GameState.add_item_to_bag(ContentRepositoryScript.find_item(ContentRepositoryScript.load_items(), "dagger"))
	_check(GameState.player.bag_items().size() >= 2, "add_item_to_bag coloca item na bolsa")
	_press_button_contains(app, "PERSONAGEM E BOLSA")
	await get_tree().create_timer(0.3).timeout
	_check(_find_label_contains(app, "venda") != null, "a bolsa mostra o preco de venda de cada item")
	_check(_find_button_contains(app, "NÃO VENDÁVEL") != null, "o item único de torneio aparece como não vendável")
	_check(_find_button_contains(app, "VENDER") != null, "a bolsa tem botao de vender")
	_check(_find_button_contains(app, "EQUIPAR") != null, "a bolsa tem botao de equipar")
	_check(_count_named(app, "bagrow_") == GameState.player.bag_items().size(), "a bolsa desenha uma linha por item (%d)" % GameState.player.bag_items().size())
	_press_button(app, "VOLTAR À CIDADE")
	await get_tree().create_timer(0.3).timeout
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

## Conta nós nomeados (prefixo) na árvore viva: mede a estrutura desenhada pela
## tela sem depender do texto dos rótulos.
func _count_named(root: Node, prefix: String, found: int = 0) -> int:
	if str(root.name).begins_with(prefix):
		found += 1
	for child in root.get_children():
		found = _count_named(child, prefix, found)
	return found

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
	# RichTextLabel também conta: a bolsa e a ficha de item usam BBCode.
	if root is RichTextLabel and str(root.text).contains(text_value):
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
