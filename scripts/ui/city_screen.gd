class_name CityScreen
extends Control

## Cidade — hub do jogo: descansar (pagando ouro), lutar na Arena Livre, entrar
## em um torneio, ir à loja ou ver o personagem (status + bolsa).

signal arena_requested
signal tournament_requested(tier_id: String)
signal shop_requested
signal character_requested
signal new_requested

const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")

const BACKGROUND := Color("14111c")
const PANEL := Color("272033")
const PANEL_DARK := Color("1d1726")
const GOLD := Color("f5c451")
const RED := Color("d95858")
const GREEN := Color("79cf7b")
const INK := Color("f7edf4")
const MUTED := Color("cdbfd5")
const DIM := Color("bbaec1")
const ABILITY := Color("b08de7")

var _rest_dialog: Control = null
var _new_dialog: Control = null
var _notice: String = ""

func _ready() -> void:
	_build_interface()

func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKGROUND
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 16, 36))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(580, 0)
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)
	var who := "Gladiador anônimo"
	var status := ""
	if GameState.player != null:
		who = GameState.player.display_name
		status = "Nível %d  •  %d XP  •  VIDA %d/%d  •  %d ouro" % [GameState.player.level, GameState.player.experience, GameState.player.health, GameState.player.max_health, GameState.player.gold]
	root.add_child(_make_label("CIDADE", 34, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label(who, 22, INK, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label(status, 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if _notice != "":
		var notice_color := Color("79cf7b") if _notice.begins_with("Descanso completo") else Color("d9a45b")
		root.add_child(_make_label(_notice, 14, notice_color, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_spacer(4))
	_add_button(root, "⚔ LUTAR NA ARENA (Arena Livre)", GREEN, arena_requested.emit)
	root.add_child(_make_label("TORNEIOS (sem loja/descanso — do início ao fim; vencer uma luta devolve a vida):", 13, DIM, HORIZONTAL_ALIGNMENT_LEFT))
	var tier_row := HBoxContainer.new()
	tier_row.add_theme_constant_override("separation", 8)
	for tier: Dictionary in GameState.tournament_tiers():
		var tier_button := _make_big_button("▸ %s" % str(tier.get("name", "Torneio")), RED)
		tier_button.pressed.connect(tournament_requested.emit.bind(str(tier.get("id", ""))))
		tier_row.add_child(tier_button)
	root.add_child(tier_row)
	# Emojis fora do BMP (U+1F6D2 carrinho, U+1F6CC cama, U+1F464 busto) não existem na
	# fonte embutida do Godot: apareciam como quadradinho no lugar do ícone (medido com a
	# renderização real, não com Font.has_char(), que erra por causa do fallback).
	_add_button(root, "• LOJA", GOLD, shop_requested.emit)
	var rest_button := _make_big_button("• DESCANSAR (custa ouro)", Color("70b9e8"))
	rest_button.pressed.connect(_open_rest_dialog)
	root.add_child(rest_button)
	_add_button(root, "• PERSONAGEM E BOLSA", ABILITY, character_requested.emit)
	_add_button(root, "✦ NOVO GLADIADOR", Color("8f83b3"), _open_new_dialog)

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_rest_dialog = null
	_new_dialog = null
	_build_interface()

# --- Descanso pago ----------------------------------------------------------

func _open_rest_dialog() -> void:
	if GameState.player == null or _rest_dialog != null:
		return
	var p = GameState.player
	var missing := maxi(0, p.max_health - p.health)
	var full_cost: int = GameState.full_rest_cost()
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_rest_dialog = overlay
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_rest_dialog())
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_DARK, 14, 30))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(430, 0)
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	root.add_child(_make_label("DESCANSAR", 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	if missing == 0:
		root.add_child(_make_label("Sua vida está cheia — nada a recuperar.", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		_add_dialog_button(root, "FECHAR", _close_rest_dialog)
		return
	root.add_child(_make_label("VIDA  %d / %d   (faltam %d)" % [p.health, p.max_health, missing], 16, INK, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("Descanso completo custa %d ouro. Você tem %d." % [full_cost, p.gold], 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if p.gold < full_cost:
		root.add_child(_make_label("Sem ouro suficiente: o descanso recupera apenas o que o ouro permitir (não garante vida cheia).", 13, Color("d9a45b"), HORIZONTAL_ALIGNMENT_CENTER))
		var per_hp := EconomySystemScript.rest_hp_price(p.level)
		var can_heal := mini(missing, int(p.gold / per_hp))
		root.add_child(_make_label("Com seu ouro atual você recupera até ~%d de vida por %d ouro." % [can_heal, per_hp], 13, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	var rest_button := Button.new()
	rest_button.text = "DESCANSAR (%d ouro)" % full_cost
	rest_button.custom_minimum_size = Vector2(190, 46)
	rest_button.add_theme_font_size_override("font_size", 15)
	rest_button.pressed.connect(_do_rest)
	_style_button(rest_button, GREEN)
	row.add_child(rest_button)
	var cancel := Button.new()
	cancel.text = "CANCELAR"
	cancel.custom_minimum_size = Vector2(130, 46)
	cancel.add_theme_font_size_override("font_size", 15)
	cancel.pressed.connect(_close_rest_dialog)
	_style_button(cancel, Color("8f83b3"))
	row.add_child(cancel)

func _do_rest() -> void:
	if GameState.player == null:
		return
	var info: Dictionary = GameState.rest()
	var cost := int(info.get("cost", 0))
	var healed := int(info.get("healed", 0))
	if bool(info.get("full", false)):
		_notice = "Descanso completo: gastou %d de ouro e recuperou toda a vida (%d)." % [cost, healed]
	else:
		_notice = "Ouro insuficiente: gastou %d de ouro e recuperou %d de vida (vida %d/%d)." % [cost, healed, GameState.player.health, GameState.player.max_health]
	_close_rest_dialog()
	_rebuild()

func _close_rest_dialog() -> void:
	if _rest_dialog != null:
		_rest_dialog.queue_free()
		_rest_dialog = null

# --- Novo gladiador ---------------------------------------------------------

## Apagar o save era o único botão da cidade que agia no primeiro clique, sem
## confirmação: um clique errado destruía o progresso. Agora confirma antes.
func _open_new_dialog() -> void:
	if _new_dialog != null:
		return
	var current := "nenhum gladiador salvo ainda"
	var p = GameState.player
	if p != null:
		current = "%s, nível %d, %d ouro" % [p.display_name, p.level, p.gold]
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_new_dialog = overlay
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_new_dialog())
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_DARK, 14, 30))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(470, 0)
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)
	root.add_child(_make_label("NOVO GLADIADOR", 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("Isto apaga o progresso salvo (%s) e começa do zero.\nNão há como desfazer." % current, 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	var confirm := Button.new()
	confirm.text = "APAGAR E COMEÇAR DE NOVO"
	confirm.custom_minimum_size = Vector2(250, 46)
	confirm.add_theme_font_size_override("font_size", 15)
	confirm.pressed.connect(_confirm_new_gladiator)
	_style_button(confirm, RED)
	row.add_child(confirm)
	var cancel := Button.new()
	cancel.text = "CANCELAR"
	cancel.custom_minimum_size = Vector2(130, 46)
	cancel.add_theme_font_size_override("font_size", 15)
	cancel.pressed.connect(_close_new_dialog)
	_style_button(cancel, Color("8f83b3"))
	row.add_child(cancel)

func _confirm_new_gladiator() -> void:
	_close_new_dialog()
	new_requested.emit()

func _close_new_dialog() -> void:
	if _new_dialog != null:
		_new_dialog.queue_free()
		_new_dialog = null

func _add_dialog_button(root: VBoxContainer, text_value: String, target: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(target)
	_style_button(button, Color("70b9e8"))
	root.add_child(button)

func _add_button(root: VBoxContainer, text_value: String, color: Color, target: Callable) -> void:
	var button := _make_big_button(text_value, color)
	button.pressed.connect(target)
	root.add_child(button)

func _make_big_button(text_value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 16)
	_style_button(button, color)
	return button

func _style_button(button: Button, color: Color) -> void:
	button.add_theme_color_override("font_color", Color("1a1420"))
	button.add_theme_color_override("font_hover_color", Color("1a1420"))
	button.add_theme_color_override("font_pressed_color", Color("1a1420"))
	button.add_theme_color_override("font_disabled_color", Color("8a8091"))
	button.add_theme_stylebox_override("normal", _panel_style(color, 8, 14))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12), 8, 14))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.12), 8, 14))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("4a4154"), 8, 14))

func _spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	return spacer

func _make_label(text_value: String, size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	return label

func _panel_style(color: Color, radius: int, content_margin: int) -> StyleBoxFlat:
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
