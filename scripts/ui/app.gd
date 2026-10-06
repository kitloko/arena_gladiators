extends Control

## Roteador de telas. A CIDADE é o hub: descansar, Arena Livre, Torneios,
## loja e personagem/bolsa. Fluxos:
##   (sem save) criação -> loja inicial -> cidade
##   cidade -> arena -> resultado -> (cidade/arena/loja)
##   cidade -> torneio -> arena -> ... -> fim -> cidade
## Não contém regras; só navega e salva quando apropriado.

const CreationScreenScene := preload("res://scenes/creation_screen.tscn")
const CityScreenScene := preload("res://scenes/city_screen.tscn")
const PreFightScreenScene := preload("res://scenes/pre_fight_screen.tscn")
const ArenaScreenScene := preload("res://scenes/arena.tscn")
const ResultScreenScene := preload("res://scenes/result_screen.tscn")
const ShopScreenScene := preload("res://scenes/shop_screen.tscn")
const CharacterScreenScene := preload("res://scenes/character_screen.tscn")
const EndScreenScene := preload("res://scenes/end_screen.tscn")
const TournamentWarningScene := preload("res://scenes/tournament_warning.tscn")
const FallenScreenScene := preload("res://scenes/fallen_screen.tscn")
const MuralScreenScene := preload("res://scenes/mural_screen.tscn")

var _pending_result
var _result_modal: Node = null

func _ready() -> void:
	if GameState.has_save():
		GameState.continue_campaign()
		show_city()
	else:
		show_creation()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameState.persist_if_free()

func _clear_screens() -> void:
	for child in get_children():
		child.queue_free()
	_result_modal = null

# --- Criação ------------------------------------------------------------

func show_creation() -> void:
	_clear_screens()
	var screen := CreationScreenScene.instantiate()
	add_child(screen)
	screen.confirmed.connect(_on_creation_confirmed)

func _on_creation_confirmed(player_name: String, allocation: Dictionary) -> void:
	GameState.start_new_campaign(player_name, allocation)
	GameState.save_progress()
	show_shop()

# --- Cidade (hub) ---------------------------------------------------------

func show_city() -> void:
	# A CIDADE é proibida durante um torneio (etapa 6, correção 1b): o jogador é
	# devolvido à rodada em andamento, com o aviso de onde está.
	if GameState.player != null and not GameState.city_allowed():
		_redirect_to_tournament(GameState.tournament_notice())
		return
	GameState.in_combat = false
	if GameState.player != null and not GameState.is_tournament():
		GameState.save_progress()
	_clear_screens()
	var screen := CityScreenScene.instantiate()
	add_child(screen)
	screen.arena_requested.connect(show_prefight)
	screen.tournament_requested.connect(_on_tournament_requested)
	screen.shop_requested.connect(show_shop)
	screen.character_requested.connect(show_character)
	screen.new_requested.connect(_on_new_gladiator)
	screen.mural_requested.connect(show_mural)

## Aviso de bloqueio da cidade: volta para o RESULTADO pendente (se houver) ou
## para a apresentação da rodada em andamento — nunca recomeça o torneio.
func _redirect_to_tournament(notice: String) -> void:
	if _pending_result != null:
		show_result_modal(notice)
	else:
		show_prefight(notice)

func _on_new_gladiator() -> void:
	GameState.clear_save()
	show_creation()

func _on_tournament_requested(tier_id: String) -> void:
	# §6.1: NINGUÉM entra no torneio sem a confirmação explícita do permadeath.
	# Quem confirma, inicia; quem não confirma, não entra (start_tournament nunca
	# é chamado — o torneio simplesmente não começa).
	show_tournament_warning(tier_id)

## Aviso obrigatório antes de entrar no torneio (etapa 11 / §6.1): a tela de
## aviso vermelho (TournamentWarning) só emite `confirmed` no ENTRAR MESMO ASSIM.
func show_tournament_warning(tier_id: String) -> void:
	if GameState.player == null:
		show_creation()
		return
	_clear_screens()
	var screen := TournamentWarningScene.instantiate()
	add_child(screen)
	screen.set_tier(tier_id)
	screen.confirmed.connect(_on_tournament_confirmed)
	screen.cancelled.connect(show_city)

func _on_tournament_confirmed(tier_id: String) -> void:
	# Só DEPOIS da confirmação o torneio começa de fato.
	if GameState.start_tournament(tier_id):
		show_prefight()
	else:
		show_city()

# --- Loja / personagem -----------------------------------------------------

func show_shop() -> void:
	_clear_screens()
	var screen := ShopScreenScene.instantiate()
	add_child(screen)
	screen.closed.connect(show_city)

func show_character() -> void:
	_clear_screens()
	var screen := CharacterScreenScene.instantiate()
	add_child(screen)
	screen.closed.connect(show_city)

# --- Apresentação / arena / resultado ---------------------------------------

## Apresentação do adversário (item F): materializa o adversário UMA vez, guarda em
## GameState.current_enemy e mostra a tela de apresentação antes de CADA luta
## (Arena Livre e torneio). O combate só começa quando o jogador clica em
## ENTRAR NA ARENA (sinal fight_started → show_arena).
## `notice` (opcional) é o aviso de bloqueio do torneio (correção 1b).
func show_prefight(notice: String = "") -> void:
	GameState.in_combat = false
	# Cada luta tem a SUA aposta: zera a anterior antes de apostar de novo.
	GameState.reset_bet()
	GameState.current_enemy = GameState.build_current_foe()
	_clear_screens()
	var screen := PreFightScreenScene.instantiate()
	screen.set("notice", notice)
	add_child(screen)
	screen.fight_started.connect(show_arena)

func show_arena() -> void:
	if GameState.player != null and not GameState.is_tournament():
		GameState.save_progress()
	_clear_screens()
	var screen := ArenaScreenScene.instantiate()
	add_child(screen)
	screen.fight_finished.connect(_on_fight_finished)

func _on_fight_finished(result) -> void:
	_pending_result = result
	# A arena já mostrou o cartaz GANHOU/PERDEU; o resumo abre por cima dela.
	show_result_modal()

## Resumo da luta como MODAL por cima da arena (correção 2): a arena continua
## montada por baixo; só as ações do modal trocam de tela.
func show_result_modal(notice: String = "") -> void:
	GameState.in_combat = false
	if _result_modal != null and is_instance_valid(_result_modal):
		_result_modal.queue_free()
	var screen := ResultScreenScene.instantiate()
	screen.set("notice", notice)
	add_child(screen)
	_result_modal = screen
	screen.set_result(_pending_result)
	screen.action_requested.connect(_on_result_action)

## Compatibilidade: quem já chamava show_result() passa a abrir o modal.
func show_result() -> void:
	show_result_modal()

func _on_result_action(action: String) -> void:
	match action:
		"shop":
			show_shop()
		"character":
			show_character()
		"rest":
			GameState.rest()
			show_prefight()
		"next", "retry":
			show_prefight()
		"camp":
			GameState.save_progress()
			show_city()
		"abandon":
			# ABANDONAR TORNEIO (correção 1c): registra a derrota no KD e volta à
			# cidade (agora permitida, porque o modo voltou a ser Arena Livre).
			_pending_result = null
			GameState.abandon_tournament()
			show_city()
		"end_victory":
			GameState.finish_tournament()
			show_end(true)
		"end_defeat":
			# MORTE NO TORNEIO (§6.2/§6.5): o GameState grava o Mural dos caídos
			# ANTES de apagar o save da campanha. Depois, a TELA DE QUEDA conta a
			# história. (A Arena Livre nunca chega aqui com derrota: lá não há
			# permadeath — o resultado da arena livre segue o fluxo normal.)
			GameState.apply_permadeath()
			show_fallen()

## Tela de queda (§6.2): o gladiador morreu num torneio. Mostra nome, rank,
## KD, torneios vencidos e o carrasco, e o Mural dos caídos.
func show_fallen() -> void:
	_pending_result = null
	GameState.in_combat = false
	_clear_screens()
	var screen := FallenScreenScene.instantiate()
	add_child(screen)
	screen.restarted.connect(show_creation)
	screen.mural_requested.connect(show_mural)

## Mural dos caídos (§6.4): MODAL por cima da tela atual (cidade ou queda) —
## não troca de tela, por isso não chama _clear_screens.
func show_mural() -> void:
	var overlay := MuralScreenScene.instantiate()
	add_child(overlay)
	overlay.closed.connect(overlay.queue_free)

func show_end(victory: bool) -> void:
	_clear_screens()
	var screen := EndScreenScene.instantiate()
	add_child(screen)
	screen.set_outcome(victory)
	screen.restarted.connect(show_city)
