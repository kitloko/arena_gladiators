class_name MuralScreen
extends Control

## MURAL DOS CAÍDOS — lista completa (etapa 11 / §6.4). Modal por cima da tela
## atual (cidade ou tela de queda): mostra todos os gladiadores mortos em
## torneio, mais recentes primeiro, com nome, rank/título, KD, torneio, carrasco
## e data. Não contém regras: lê o registro local via FallenWall.

signal closed

const FallenWallScript := preload("res://scripts/systems/fallen_wall.gd")

const PANEL := Color("1d1726")
const GOLD := Color("f5c451")
const RED := Color("d95858")
const INK := Color("f7edf4")
const MUTED := Color("cdbfd5")
const DIM := Color("bbaec1")

func _ready() -> void:
	build_interface()

func build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _border_style(PANEL, RED))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(760, 0)
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	root.add_child(make_label("MURAL DOS CAÍDOS", 26, RED, HORIZONTAL_ALIGNMENT_CENTER))
	var entries: Array = FallenWallScript.entries()
	if entries.is_empty():
		root.add_child(make_label("Nenhum gladiador caiu num torneio ainda. Que continue assim.", 16, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		root.add_child(make_label("%d caído(s) registrado(s) neste computador (registro LOCAL, não na nuvem)." % entries.size(), 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(0, 400)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		root.add_child(scroll)
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 6)
		scroll.add_child(list)
		for rec: Variant in entries:
			if rec is Dictionary:
				list.add_child(_entry_card(rec))
	var close := Button.new()
	close.text = "FECHAR"
	close.custom_minimum_size = Vector2(0, 48)
	close.add_theme_font_size_override("font_size", 16)
	close.add_theme_color_override("font_color", Color("1a1420"))
	close.add_theme_stylebox_override("normal", _panel_style(Color("8f83b3"), 8, 12))
	close.add_theme_stylebox_override("hover", _panel_style(Color("a99bd0"), 8, 12))
	close.pressed.connect(closed.emit)
	root.add_child(close)

func _entry_card(rec: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color("271a2e"), 8, 10))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	box.add_child(make_label("%s — RANK %s (%d pts)   •   KD %d V / %d D" % [
		str(rec.get("name", "?")), str(rec.get("rank_title", "?")), int(rec.get("rank_points", 0)),
		int(rec.get("wins", 0)), int(rec.get("losses", 0))], 15, GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	var nick := str(rec.get("executioner_nickname", ""))
	var carrasco := str(rec.get("executioner", "um adversário sem nome"))
	if nick != "":
		carrasco += " «%s»" % nick
	box.add_child(make_label("Caiu no %s (rodada %d/%d), por %s. Títulos vencidos: %d.   %s" % [
		str(rec.get("tournament", "Torneio")), int(rec.get("round", 1)), int(rec.get("rounds", 1)),
		carrasco, int(rec.get("tournaments_won", 0)), str(rec.get("date", ""))], 12, MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	return panel

func make_label(text_value: String, size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	return label

func _border_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := _panel_style(fill, 14, 28)
	style.border_color = border
	style.set_border_width_all(3)
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
