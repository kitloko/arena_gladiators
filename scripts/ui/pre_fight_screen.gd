class_name PreFightScreen
extends Control

## Tela de apresentação do adversário (item F), mostrada ANTES de cada luta
## (Arena Livre e torneio). Os dois lutadores frente a frente — retrato, nome +
## apelido e descrição —, as estatísticas comparadas em duas colunas com um VS no
## meio, o ÍNDICE DE PODER de cada lado, as provocações sorteadas de cada um em
## balão e o botão ENTRAR NA ARENA (que emite fight_started).
##
## Não contém regras: a fórmula do Índice de Poder e o sorteio das falas vivem em
## scripts/systems/presentation_system.gd (testado headless). Só desenha, em
## layout compacto para caber na viewport de 1100×700 SEM rolagem e sem esconder
## o botão ENTRAR NA ARENA.

signal fight_started

const PresentationSystemScript := preload("res://scripts/systems/presentation_system.gd")
const RankSystemScript := preload("res://scripts/systems/rank_system.gd")

const BACKGROUND := Color("14111c")
const PANEL := Color("272033")
const PANEL_DARK := Color("1d1726")
const GOLD := Color("f5c451")
const RED := Color("d95858")
const GREEN := Color("79cf7b")
const INK := Color("f7edf4")
const MUTED := Color("cdbfd5")
const DIM := Color("bbaec1")
const ARMOUR_COLOR := Color("70b9e8")
const SPRITE_BASE := "res://assets/sprites/"
const PORTRAIT_SIZE := 84
const CARD_WIDTH := 300

var player
var foe
var player_power: int = 0
var enemy_power: int = 0
var player_taunt: String = ""
var enemy_taunt: String = ""

func _ready() -> void:
	player = GameState.player
	foe = GameState.current_enemy
	player_power = PresentationSystemScript.power_index(player)
	enemy_power = PresentationSystemScript.power_index(foe)
	player_taunt = PresentationSystemScript.player_taunt()
	enemy_taunt = PresentationSystemScript.enemy_taunt(foe)
	build_interface()

## Chamado pelo botão ENTRAR NA ARENA: o roteador (app.gd) abre a luta.
func enter_arena() -> void:
	fight_started.emit()

func build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKGROUND
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)
	root.add_child(make_label("APRESENTAÇÃO — %s" % GameState.current_stage_name(), 21, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(make_label("Os dois frente a frente. Estude o adversário antes de entrar na arena.", 12, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	# Frente a frente: card de cada lutador com um VS no meio.
	var versus := HBoxContainer.new()
	versus.alignment = BoxContainer.ALIGNMENT_CENTER
	versus.add_theme_constant_override("separation", 16)
	root.add_child(versus)
	versus.add_child(build_fighter_card(true))
	var vs_box := VBoxContainer.new()
	vs_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vs_box.add_theme_constant_override("separation", 1)
	vs_box.custom_minimum_size = Vector2(150, 0)
	versus.add_child(vs_box)
	vs_box.add_child(make_label("VS", 42, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	vs_box.add_child(make_label("ÍNDICE DE PODER", 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	vs_box.add_child(make_label("%d  ×  %d" % [player_power, enemy_power], 17, INK, HORIZONTAL_ALIGNMENT_CENTER))
	versus.add_child(build_fighter_card(false))
	# Comparação em duas colunas (VOCÊ ... VS ... INIMIGO): os 7 atributos, vida e
	# armadura máximas, o Índice de Poder e o rank/KD de cada lado.
	root.add_child(build_comparison())
	root.add_child(make_label("ÍNDICE DE PODER = STR×2 + ATT×1,5 + DEF×1,5 + AGI×1,5 + VIT×1 + CAR×0,5 + SOR×1 + NÍVEL×5", 10, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	# Provocações sorteadas (uma de cada lado).
	root.add_child(build_taunts())
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(button_row)
	var enter := make_button("ENTRAR NA ARENA", GREEN)
	enter.custom_minimum_size = Vector2(340, 42)
	enter.add_theme_font_size_override("font_size", 18)
	enter.pressed.connect(enter_arena)
	button_row.add_child(enter)

## Card de um lutador: retrato, nome, apelido e descrição (o inimigo também
## declara a fraqueza). O rank/KD aparecem na tabela de comparação.
func build_fighter_card(is_player: bool) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	card.add_theme_constant_override("separation", 1)
	var fighter = player if is_player else foe
	var tint := GREEN if is_player else RED
	var portrait := _portrait_texture(is_player)
	if portrait != null:
		var rect := TextureRect.new()
		rect.texture = portrait
		rect.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(rect)
	if fighter == null:
		card.add_child(make_label("SEM LUTADOR", 18, tint, HORIZONTAL_ALIGNMENT_CENTER))
		return card
	card.add_child(make_label(str(fighter.display_name), 18, tint, HORIZONTAL_ALIGNMENT_CENTER))
	if is_player:
		var title: String = RankSystemScript.title_for(int(fighter.rank_points))
		card.add_child(make_label("Gladiador de %s" % title, 12, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
		var wins := int(fighter.wins)
		var losses := int(fighter.losses)
		card.add_child(_wrapped_label("Nível %d, %d %s e %d %s. %d de ouro no bolso." % [
			int(fighter.level), wins, ("vitória" if wins == 1 else "vitórias"),
			losses, ("derrota" if losses == 1 else "derrotas"), int(fighter.gold)], 11, MUTED, CARD_WIDTH))
	else:
		var identity: Dictionary = PresentationSystemScript.enemy_identity(fighter)
		card.add_child(make_label(str(identity.get("nickname", "")), 12, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
		card.add_child(_wrapped_label(str(identity.get("description", "")), 11, MUTED, CARD_WIDTH))
		card.add_child(_wrapped_label("Fraqueza: %s" % str(identity.get("weakness", "")), 11, Color("e08a8a"), CARD_WIDTH))
	return card

## Tabela de comparação: três colunas (você | rótulo | inimigo) com o VS no topo.
func build_comparison() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 0)
	grid.add_child(make_label("VOCÊ", 13, GREEN, HORIZONTAL_ALIGNMENT_RIGHT))
	grid.add_child(make_label("VS", 13, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	grid.add_child(make_label(_enemy_title(), 13, RED, HORIZONTAL_ALIGNMENT_LEFT))
	for definition: Dictionary in PresentationSystemScript.ATTRIBUTES:
		var attr_id := str(definition.get("id", ""))
		grid.add_child(make_label("%d" % PresentationSystemScript.attribute_value(player, attr_id), 13, INK, HORIZONTAL_ALIGNMENT_RIGHT))
		grid.add_child(make_label(str(definition.get("short", "")), 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		grid.add_child(make_label("%d" % PresentationSystemScript.attribute_value(foe, attr_id), 13, INK, HORIZONTAL_ALIGNMENT_LEFT))
	# Vida e armadura MÁXIMAS.
	grid.add_child(_compare_value(player, "max_health", HORIZONTAL_ALIGNMENT_RIGHT))
	grid.add_child(make_label("VIDA MÁX", 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	grid.add_child(_compare_value(foe, "max_health", HORIZONTAL_ALIGNMENT_LEFT))
	grid.add_child(_compare_value(player, "max_armour", HORIZONTAL_ALIGNMENT_RIGHT))
	grid.add_child(make_label("ARMADURA", 12, ARMOUR_COLOR, HORIZONTAL_ALIGNMENT_CENTER))
	grid.add_child(_compare_value(foe, "max_armour", HORIZONTAL_ALIGNMENT_LEFT))
	# Índice de Poder em destaque.
	grid.add_child(make_label("%d" % player_power, 16, GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
	grid.add_child(make_label("PODER", 13, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	grid.add_child(make_label("%d" % enemy_power, 16, GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	# Rank e KD: o jogador tem; o inimigo não carrega rank.
	grid.add_child(make_label(_player_rank_line(), 12, GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
	grid.add_child(make_label("RANK", 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	grid.add_child(make_label("sem rank", 12, DIM, HORIZONTAL_ALIGNMENT_LEFT))
	grid.add_child(make_label(_player_kd_line(), 12, MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	grid.add_child(make_label("KD", 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	grid.add_child(make_label("—", 12, DIM, HORIZONTAL_ALIGNMENT_LEFT))
	return grid

## Provocações: uma fala sorteada de cada lado em caixa de fala.
func build_taunts() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_speech_box("VOCÊ DIZ", player_taunt, GREEN))
	row.add_child(_speech_box("%s DIZ" % _enemy_title().to_upper(), enemy_taunt, RED))
	return row

func _speech_box(caption: String, line: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", panel_style(PANEL, 8, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)
	box.add_child(make_label(caption, 11, color, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_wrapped_label("\"%s\"" % line, 13, INK, 300))
	return panel

func _enemy_title() -> String:
	if foe == null:
		return "INIMIGO"
	return str(foe.display_name)

func _player_rank_line() -> String:
	if player == null:
		return "—"
	return "%s (%d pts)" % [RankSystemScript.title_for(int(player.rank_points)), int(player.rank_points)]

func _player_kd_line() -> String:
	if player == null:
		return "—"
	return "%d V / %d D" % [int(player.wins), int(player.losses)]

func _compare_value(fighter, field: String, alignment: int) -> Label:
	var value := 0
	if fighter != null:
		value = int(fighter.get(field))
	return make_label("%d" % value, 13, INK, alignment)

func _portrait_texture(is_player: bool) -> Texture2D:
	if is_player:
		return _load_sprite("hero", "hero")
	return _load_sprite("enemies", "enemy")

func _load_sprite(folder: String, file_name: String) -> Texture2D:
	for ext: String in ["png", "jpeg", "jpg"]:
		var path := "%s%s/%s.%s" % [SPRITE_BASE, folder, file_name, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null

func _wrapped_label(text_value: String, size: int, color: Color, min_width: int) -> Label:
	var label := make_label(text_value, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(min_width, 0)
	return label

func make_label(text_value: String, size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	return label

func make_button(text_value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(200, 42)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("1a1420"))
	button.add_theme_stylebox_override("normal", panel_style(color, 8, 12))
	button.add_theme_stylebox_override("hover", panel_style(color.lightened(0.12), 8, 12))
	return button

func panel_style(color: Color, radius: int, content_margin: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = content_margin
	style.content_margin_right = content_margin
	style.content_margin_top = content_margin
	style.content_margin_bottom = content_margin
	return style
