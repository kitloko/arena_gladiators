class_name FallenScreen
extends Control

## Tela de QUEDA (etapa 11 / §6.2): conta a história do gladiador morto no
## torneio — nome, rank/título, KD, torneios vencidos e QUEM foi o carrasco —,
## avisa que o save foi apagado e mostra o Mural dos caídos.
##
## Não contém regras: só desenha o registro que o GameState gravou (last_fall) e
## a lista do Mural (FallenWall).

signal restarted
signal mural_requested

const FallenWallScript := preload("res://scripts/systems/fallen_wall.gd")

const BACKGROUND := Color("14111c")
const PANEL := Color("2a1018")
const GOLD := Color("f5c451")
const RED := Color("d95858")
const GREEN := Color("79cf7b")
const INK := Color("f7edf4")
const MUTED := Color("cdbfd5")
const DIM := Color("bbaec1")

var entry: Dictionary = {}

func _ready() -> void:
	if entry.is_empty():
		entry = GameState.last_fall
	build_interface()

## Reinjeta o registro (a tela de queda também pode ser montada pela QA).
func set_entry(value: Dictionary) -> void:
	entry = value
	if is_inside_tree():
		for child in get_children():
			child.free()
		build_interface()

func build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKGROUND
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)
	var name := str(entry.get("name", "O Gladiador"))
	root.add_child(make_label("A QUEDA DE %s" % name.to_upper(), 30, RED, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(make_label("O Mural dos caídos guarda a memória. O personagem, não.", 13, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 12, 16))
	root.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	panel.add_child(body)
	body.add_child(make_label("Nível %d   •   RANK %s (%d pts)" % [int(entry.get("level", 1)), str(entry.get("rank_title", "Areia")), int(entry.get("rank_points", 0))], 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	body.add_child(make_label("KD %d V / %d D   •   Torneios vencidos: %d   •   Ouro: %d" % [int(entry.get("wins", 0)), int(entry.get("losses", 0)), int(entry.get("tournaments_won", 0)), int(entry.get("gold", 0))], 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var final_text := " O combate final." if bool(entry.get("boss", false)) else ""
	body.add_child(make_label("Caiu no %s — rodada %d/%d.%s" % [str(entry.get("tournament", "Torneio")), int(entry.get("round", 1)), int(entry.get("rounds", 1)), final_text], 14, INK, HORIZONTAL_ALIGNMENT_CENTER))
	var executioner := str(entry.get("executioner", ""))
	if executioner == "":
		executioner = "um adversário sem nome"
	var nick := str(entry.get("executioner_nickname", ""))
	var carrasco := "CARRASCO: %s" % executioner
	if nick != "":
		carrasco += "   «%s»" % nick
	body.add_child(make_label(carrasco, 19, RED, HORIZONTAL_ALIGNMENT_CENTER))
	body.add_child(make_label("O SAVE DA CAMPANHA FOI APAGADO. Este gladiador não volta — só o registro abaixo.", 13, Color("e08a8a"), HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(make_label("MURAL DOS CAÍDOS", 16, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_build_mural_list())
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	var new_button := make_button("NOVO GLADIADOR", GOLD)
	new_button.pressed.connect(restarted.emit)
	row.add_child(new_button)
	var mural_button := make_button("VER O MURAL DOS CAÍDOS", Color("8f83b3"))
	mural_button.pressed.connect(mural_requested.emit)
	row.add_child(mural_button)

func _build_mural_list() -> Control:
	var entries: Array = FallenWallScript.entries()
	if entries.is_empty():
		return make_label("Nenhum caído registrado ainda.", 12, DIM, HORIZONTAL_ALIGNMENT_CENTER)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 150)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	for rec: Variant in entries:
		if rec is Dictionary:
			list.add_child(_mural_line(rec))
	return scroll

func _mural_line(rec: Dictionary) -> Label:
	var nick := str(rec.get("executioner_nickname", ""))
	var carrasco := str(rec.get("executioner", "?"))
	if nick != "":
		carrasco += " «%s»" % nick
	return make_label("• %s — RANK %s, KD %d/%d, %s, por %s   (%s)" % [
		str(rec.get("name", "?")), str(rec.get("rank_title", "?")), int(rec.get("wins", 0)), int(rec.get("losses", 0)),
		str(rec.get("tournament", "?")), carrasco, str(rec.get("date", ""))], 12, MUTED, HORIZONTAL_ALIGNMENT_LEFT)

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
	button.custom_minimum_size = Vector2(260, 50)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("1a1420"))
	button.add_theme_stylebox_override("normal", _panel_style(color, 8, 12))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12), 8, 12))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.12), 8, 12))
	return button

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
