class_name EndScreen
extends Control

## Tela final da campanha: vitória ou derrota, com botão para nova campanha.

signal restarted

const BACKGROUND := Color("14111c")
const PANEL := Color("272033")
const GOLD := Color("f5c451")
const RED := Color("d95858")
const GREEN := Color("79cf7b")
const INK := Color("f7edf4")
const MUTED := Color("cdbfd5")

func _ready() -> void:
	set_outcome(true)

func set_outcome(victory: bool) -> void:
	for child in get_children():
		child.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKGROUND
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 16, 40))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(560, 0)
	root.add_theme_constant_override("separation", 16)
	panel.add_child(root)
	var title_text := "CAMPEÃO DA ARENA!" if victory else "A QUEDA DO GLADIADOR"
	var subtitle := ""
	if victory and GameState.player != null:
		subtitle = "%s venceu as cinco arenas e derrubou o Imperador. A multidão canta seu nome." % GameState.player.display_name
	elif GameState.player != null:
		subtitle = "%s foi derrotado na campanha. A lenda fica para a próxima tentativa." % GameState.player.display_name
	else:
		subtitle = "A campanha terminou."
	root.add_child(_make_label(title_text, 32, GREEN if victory else RED, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label(subtitle, 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_spacer(8))
	var button := Button.new()
	button.text = "VOLTAR AO ACAMPAMENTO"
	button.custom_minimum_size = Vector2(0, 54)
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(restarted.emit)
	_style_button(button, GOLD)
	root.add_child(button)

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

func _style_button(button: Button, color: Color) -> void:
	button.add_theme_color_override("font_color", Color("1a1420"))
	button.add_theme_color_override("font_hover_color", Color("1a1420"))
	button.add_theme_color_override("font_pressed_color", Color("1a1420"))
	button.add_theme_stylebox_override("normal", _panel_style(color, 8, 14))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12), 8, 14))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.12), 8, 14))

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
