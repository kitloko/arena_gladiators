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

var _pending_result

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

func _on_new_gladiator() -> void:
	GameState.clear_save()
	show_creation()

func _on_tournament_requested(tier_id: String) -> void:
	if GameState.start_tournament(tier_id):
		show_prefight()

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
func show_prefight() -> void:
	GameState.current_enemy = GameState.build_current_foe()
	_clear_screens()
	var screen := PreFightScreenScene.instantiate()
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
	show_result()

func show_result() -> void:
	_clear_screens()
	var screen := ResultScreenScene.instantiate()
	add_child(screen)
	screen.set_result(_pending_result)
	screen.action_requested.connect(_on_result_action)

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
		"end_victory", "end_defeat":
			GameState.finish_tournament()
			show_end(action == "end_victory")

func show_end(victory: bool) -> void:
	_clear_screens()
	var screen := EndScreenScene.instantiate()
	add_child(screen)
	screen.set_outcome(victory)
	screen.restarted.connect(show_city)
