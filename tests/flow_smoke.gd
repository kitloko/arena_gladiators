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
	# A criação só liberta o botão com TODOS os pontos distribuídos (hoje 20),
	# agora entre os 7 atributos.
	creation.allocate_points("strength", 12)
	creation.allocate_points("vitality", EconomySystemScript.creation_points() - 12)
	await get_tree().process_frame
	_check(not creation._confirm_button.disabled, "confirmar liberado")
	creation._on_confirm_pressed()
	await get_tree().create_timer(0.4).timeout
	_check(GameState.player != null and GameState.player.base_strength == 20 and GameState.player.gold == 80, "criação neutra aplicada (80 ouro)")
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
	_check(_find_label_contains(app, "RANK") != null, "tela do personagem mostra o RANK")
	_check(_find_label_contains(app, "KD") != null, "tela do personagem mostra o KD (vitórias/derrotas)")
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
	_check(_find_button(app, "AVANÇAR") != null, "ações de movimento presentes")
	_check(int(arena.distance) == 3, "começa a distância 3")
	_check(arena.distance_track != null and arena.distance_track.get_child_count() == 9, "trilha visual da arena com muralhas (9 células)")
	# A arena mostra DUAS barras com números por lutador (vida e armadura).
	_check(_find_label_contains(app, "VIDA") != null and _find_label_contains(app, "ARM") != null, "arena mostra as barras de VIDA e ARMADURA")
	var attack_btn = _find_button(app, "GOLPE")
	_check(attack_btn != null and attack_btn.disabled, "GOLPE desabilitado fora de alcance (melee a 3 passos)")
	_check(_find_button_contains(app, "TAUNT:") != null, "ação TAUNT presente com a porcentagem na tela")
	# Felicidade do público (item H): barra no topo + ação EXIBIR funcional.
	_check(_find_label_contains(app, "PÚBLICO") != null, "arena mostra a barra de PÚBLICO no topo")
	_check(str(arena.arena_band_title) != "", "arena mostra a faixa de arena (ideia 9): '%s'" % str(arena.arena_band_title))
	_check(arena.crowd != null and int(arena.crowd.value()) >= 0 and int(arena.crowd.value()) <= 100, "barra de público na faixa 0..100 (medido %d)" % int(arena.crowd.value()))
	var exhibit_btn = _find_button(app, "EXIBIR")
	_check(exhibit_btn != null, "ação EXIBIR presente na arena")
	var crowd_before_exhibit: int = int(arena.crowd.value())
	var rounds_before_exhibit: int = int(arena.round_number)
	if exhibit_btn != null:
		exhibit_btn.pressed.emit()
		await get_tree().create_timer(0.7).timeout
	_check(int(arena.round_number) == rounds_before_exhibit + 1, "EXIBIR gasta o turno (o inimigo age e a rodada avança)")
	_check(int(arena.crowd.value()) != crowd_before_exhibit, "EXIBIR move a barra de público (%d → %d)" % [crowd_before_exhibit, int(arena.crowd.value())])
	var round_before: int = int(arena.round_number)
	arena.player_action("golpe")
	await get_tree().create_timer(0.8).timeout
	_check(int(arena.round_number) == round_before + 1, "turno do inimigo executou exatamente uma vez")
	# 6) Vitória com pontos de nível pendentes
	GameState.player.health = GameState.player.max_health
	GameState.player.armour = GameState.player.max_armour
	GameState.player.experience = GameState.player.required_experience() - 5
	arena.distance = 1
	arena.player_pos = 1
	arena.enemy_pos = 2
	GameState.current_enemy.health = 1
	# Zera esquiva/auto-defesa do inimigo para a ação de abate ser determinística.
	GameState.current_enemy.base_agility = 0
	GameState.current_enemy.base_defence = 0
	GameState.current_enemy.recompute_derived()
	# A sequência de vitórias multiplica o OURO, não o XP. Era o XP inflado pela
	# sequência (até +180%) que fazia o personagem subir de nível a cada luta.
	GameState.win_streak = 9
	var level_before_kill: int = GameState.player.level
	var gold_before_kill: int = GameState.player.gold
	var points_before_kill: int = GameState.player.pending_points
	var enemy_multiplier := float(GameState.current_enemy.reward_multiplier)
	var tier_multiplier := EconomySystemScript.tier_experience_multiplier(int(GameState.current_enemy.enemy_tier))
	var base_rewards: Dictionary = EconomySystemScript.fight_rewards(level_before_kill)
	arena.player_action("golpe")
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
	# Felicidade do público (item H): luta definida em ≤3 ações não multiplica o ouro.
	_check(bool(fought.quick_fight) and is_equal_approx(float(fought.crowd_multiplier), 1.0), "luta de ≤3 ações não multiplica o ouro do público (×1,0)")
	_check(_find_label_contains(app, "Público") != null, "tela de resultado mostra a linha do público")
	# Subir de nível dá pontos de atributo (4 por nível) — distribuídos aqui.
	_check(GameState.player.level > level_before_kill and GameState.player.pending_points > points_before_kill, "subir de nível gera pontos de atributo pendentes")
	while GameState.player.pending_points > 0:
		GameState.spend_attribute_point("strength")
	await get_tree().process_frame
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
	# O Torneio Maior exige rank Aço (900): o jogador normal já teria subido até lá.
	GameState.player.rank_points = 900
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
	# 9b) Cidade como cenário (item B) + bloqueio por rank (item I).
	_check(_find_label_contains(app, "LOCAIS") != null, "cidade mostra os LOCAIS sobre o cenário")
	_check(_find_label_contains(app, "RANK") != null, "HUD da cidade mostra o RANK")
	_check(_count_texture_rects(app) > 0, "cidade usa cenário de fundo (assets de arena reaproveitados)")
	for label in ["Arena Livre", "Loja", "Descansar", "PERSONAGEM E BOLSA", "NOVO GLADIADOR", "Torneio Menor", "Torneio Maior", "Grande Torneio"]:
		_check(_find_button_contains(app, label) != null, "cidade: destino alcançável — %s" % label)
	var menor_btn = _find_button_contains(app, "Torneio Menor")
	var maior_btn = _find_button_contains(app, "Torneio Maior")
	var grande_btn = _find_button_contains(app, "Grande Torneio")
	_check(menor_btn != null and not menor_btn.disabled, "Torneio Menor liberado (rank Aço)")
	_check(maior_btn != null and not maior_btn.disabled, "Torneio Maior liberado (rank Aço)")
	_check(grande_btn != null and grande_btn.disabled and str(grande_btn.text).contains("TRANCADO"), "Grande Torneio TRANCADO (exige Ouro)")
	_check(str(grande_btn.text).contains("Ouro"), "o destino trancado mostra o motivo do rank ('%s')" % str(grande_btn.text))
	# Subir de rank destranca o destino (rebuild ao voltar à cidade).
	GameState.player.rank_points = 5000
	_press_button_contains(app, "PERSONAGEM E BOLSA")
	await get_tree().create_timer(0.3).timeout
	_press_button(app, "VOLTAR À CIDADE")
	await get_tree().create_timer(0.3).timeout
	var grande_freed = _find_button_contains(app, "Grande Torneio")
	_check(grande_freed != null and not grande_freed.disabled, "Grande Torneio destranca com rank Ouro+")
	# Diálogo de confirmação do NOVO GLADIADOR continua existindo.
	_press_button_contains(app, "NOVO GLADIADOR")
	await get_tree().create_timer(0.2).timeout
	_check(_find_button(app, "APAGAR E COMEÇAR DE NOVO") != null, "NOVO GLADIADOR pede confirmação")
	_press_button(app, "CANCELAR")
	await get_tree().create_timer(0.2).timeout
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

## Conta TextureRects na árvore: usado para provar que a cidade desenha cenário.
func _count_texture_rects(root: Node, found: int = 0) -> int:
	if root is TextureRect and root.texture != null:
		found += 1
	for child in root.get_children():
		found = _count_texture_rects(child, found)
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
