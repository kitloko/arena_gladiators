class_name TournamentWarning
extends Control

## Aviso obrigatório ANTES de entrar no torneio (etapa 11 / §6.1).
##
## A morte dentro do torneio APAGA o personagem (permadeath). Por isso a entrada
## passa por aqui: um aviso em VERMELHO (MORTE NO TORNEIO = PERSONAGEM APAGADO) e
## a confirmação explícita ENTRAR MESMO ASSIM. Sem confirmar, o roteador (app.gd)
## NÃO chama start_tournament — o torneio simplesmente não começa.

signal confirmed(tier_id: String)
signal cancelled

const BACKGROUND := Color("14111c")
const PANEL_DARK := Color("1d1726")
const GOLD := Color("f5c451")
const RED := Color("d95858")
const INK := Color("f7edf4")
const MUTED := Color("cdbfd5")
const DIM := Color("bbaec1")

var tier_id: String = ""
var tier_name: String = "Torneio"

func set_tier(id: String) -> void:
	tier_id = id
	tier_name = "Torneio"
	for tier: Dictionary in GameState.tournament_tiers():
		if str(tier.get("id", "")) == id:
			tier_name = str(tier.get("name", "Torneio"))
			break
	if is_inside_tree():
		_rebuild()

func _ready() -> void:
	build_interface()

func _rebuild() -> void:
	for child in get_children():
		child.free()
	build_interface()

func build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKGROUND
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _border_style(PANEL_DARK, RED))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(680, 0)
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)
	root.add_child(make_label("TORNEIO — MORTE PERMANENTE", 22, RED, HORIZONTAL_ALIGNMENT_CENTER))
	var warning := make_label("MORTE NO TORNEIO = PERSONAGEM APAGADO", 30, RED, HORIZONTAL_ALIGNMENT_CENTER)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(warning)
	var sub := make_label("Você está prestes a entrar no %s." % tier_name, 16, INK, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(sub)
	# Quebrado em linhas curtas de propósito: em uma linha só o texto estourava a
	# largura do painel e a parte final ("Arena Livre continua SEM morte
	# permanente") era cortada na borda — justo a frase que precisa ser lida.
	var body := make_label("Se perder QUALQUER combate aqui dentro, o seu gladiador morre:\no SAVE DA CAMPANHA é apagado e não há volta.\nA Arena Livre continua SEM morte permanente — é lá que você testa a build sem medo.", 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(body)
	root.add_child(make_label("Só o registro do Mural dos caídos permanece (nome, rank, KD, torneio e carrasco).", 13, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)
	var confirm := make_button("ENTRAR MESMO ASSIM", RED)
	confirm.custom_minimum_size = Vector2(320, 56)
	confirm.add_theme_font_size_override("font_size", 18)
	confirm.pressed.connect(_on_confirm)
	row.add_child(confirm)
	var back := make_button("VOLTAR", Color("8f83b3"))
	back.custom_minimum_size = Vector2(150, 56)
	back.pressed.connect(_on_cancel)
	row.add_child(back)

func _on_confirm() -> void:
	confirmed.emit(tier_id)

func _on_cancel() -> void:
	cancelled.emit()

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
	button.custom_minimum_size = Vector2(220, 48)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("1a1420"))
	button.add_theme_stylebox_override("normal", _panel_style(color, 8, 12))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12), 8, 12))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.12), 8, 12))
	return button

func _border_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style

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
