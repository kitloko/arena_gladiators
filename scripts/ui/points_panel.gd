class_name PointsPanel
extends Control

## Painel MODAL "só pontos" (etapa 6, correção 1a). Mostra APENAS os pontos de
## atributo pendentes — nada de bolsa/equipamento/loja — e é aberto POR CIMA da
## tela de resultado da rodada. Fechar devolve o controle à tela de resultado;
## nunca leva o jogador à cidade (era essa a causa raiz do bug do torneio).
##
## Tem o método `spend_point` (nome estável: a QA e os testes localizam o painel
## por ele), os botões `attrspend_<atributo>` e um botão "VOLTAR AO RESULTADO".

signal closed

const GOLD := Color("f5c451")
const PANEL_DARK := Color("1d1726")
const GREEN := Color("79cf7b")
const INK := Color("f7edf4")
const MUTED := Color("cdbfd5")

var _pending_label: Label
var _buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_DARK, 14, 30))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(560, 0)
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	root.add_child(_make_label("DISTRIBUIR PONTOS", 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var pending := 0
	if GameState.player != null:
		pending = int(GameState.player.pending_points)
	_pending_label = _make_label("PONTOS PARA DISTRIBUIR: %d" % pending, 16, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_pending_label)
	root.add_child(_make_label("Você está no torneio: distribua os pontos e volte ao RESULTADO da rodada.", 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 8)
	root.add_child(grid)
	for definition: Dictionary in GameState.attribute_definitions():
		var stat_id := str(definition.get("id", ""))
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		cell.add_child(_make_label(str(definition.get("short", stat_id)), 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		var button := Button.new()
		# Nome estável: a QA e a suíte de fluxo contam/localizam por este prefixo.
		button.name = "attrspend_%s" % stat_id
		button.text = "+"
		button.custom_minimum_size = Vector2(56, 30)
		button.add_theme_font_size_override("font_size", 16)
		button.disabled = pending <= 0
		button.pressed.connect(spend_point.bind(stat_id))
		button.add_theme_color_override("font_color", Color("1a1420"))
		button.add_theme_stylebox_override("normal", _panel_style(GREEN, 6, 6))
		button.add_theme_stylebox_override("hover", _panel_style(Color("8fd891"), 6, 6))
		button.add_theme_stylebox_override("disabled", _panel_style(Color("4a4154"), 6, 6))
		cell.add_child(button)
		_buttons[stat_id] = button
		grid.add_child(cell)
	root.add_child(_make_label("Os pontos vão direto nos atributos. Fechar aqui devolve você à rodada.", 12, Color("bbaec1"), HORIZONTAL_ALIGNMENT_CENTER))
	var back := Button.new()
	back.text = "VOLTAR AO RESULTADO"
	back.custom_minimum_size = Vector2(0, 48)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.add_theme_font_size_override("font_size", 16)
	back.add_theme_color_override("font_color", Color("1a1420"))
	back.add_theme_stylebox_override("normal", _panel_style(Color("8f83b3"), 8, 14))
	back.add_theme_stylebox_override("hover", _panel_style(Color("9f93c2"), 8, 14))
	back.pressed.connect(closed.emit)
	root.add_child(back)

## Gasta um ponto no atributo e atualiza o painel (nome estável usado pelos testes).
func spend_point(stat_id: String) -> void:
	if GameState.player == null:
		return
	if GameState.spend_attribute_point(stat_id):
		_refresh()

func _refresh() -> void:
	if GameState.player == null:
		return
	var pending := int(GameState.player.pending_points)
	if _pending_label != null:
		_pending_label.text = "PONTOS PARA DISTRIBUIR: %d" % pending
	for key: Variant in _buttons.keys():
		(_buttons[key] as Button).disabled = pending <= 0

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
