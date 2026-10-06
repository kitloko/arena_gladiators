class_name CreationScreen
extends Control

## Criação neutra (sem classe): nome + distribuição de 20 pontos entre os SETE
## atributos (STR/ATT/DEF/AGI/VIT/CHA/SOR). Ao confirmar, emite a distribuição;
## o roteador inicia a campanha e leva o jogador à loja inicial.

signal confirmed(player_name: String, allocation: Dictionary)
signal continue_requested
signal tournament_requested(tier_id: String)

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

var _points_left: int = EconomySystemScript.creation_points()
var _allocation: Dictionary = {}
var _name_field: LineEdit
var _points_label: Label
var _preview: RichTextLabel
var _confirm_button: Button
var _stat_values: Dictionary = {}

func _ready() -> void:
	_build_interface()
	DebugLog.info("Tela de criação neutra pronta.")

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
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 16, 26))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(720, 0)
	root.add_theme_constant_override("separation", 7)
	panel.add_child(root)
	if GameState.has_save():
		var continue_button := Button.new()
		continue_button.text = "▶ CONTINUAR CAMPANHA (Arena Livre)"
		continue_button.custom_minimum_size = Vector2(0, 44)
		continue_button.add_theme_font_size_override("font_size", 15)
		continue_button.pressed.connect(continue_requested.emit)
		_style_button(continue_button, GREEN)
		root.add_child(continue_button)
		root.add_child(_make_label("TORNEIOS (sem loja/descanso):", 12, MUTED, HORIZONTAL_ALIGNMENT_LEFT))
		var tier_row := HBoxContainer.new()
		tier_row.add_theme_constant_override("separation", 8)
		for tier: Dictionary in GameState.tournament_tiers():
			var tier_button := Button.new()
			tier_button.text = "▸ %s" % str(tier.get("name", "Torneio"))
			tier_button.custom_minimum_size = Vector2(0, 38)
			tier_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tier_button.add_theme_font_size_override("font_size", 13)
			tier_button.pressed.connect(tournament_requested.emit.bind(str(tier.get("id", ""))))
			_style_button(tier_button, RED)
			tier_row.add_child(tier_button)
		root.add_child(tier_row)
		root.add_child(_make_label("— ou crie um novo gladiador —", 12, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("CRIE SEU GLADIADOR", 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("Gladiador neutro: distribua os %d pontos entre os 7 atributos. Você recebe %d de ouro para equipar antes da 1ª luta." % [EconomySystemScript.creation_points(), EconomySystemScript.starting_gold()], 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("Nome do gladiador", 13, INK))
	_name_field = LineEdit.new()
	_name_field.placeholder_text = "Ex.: Cassian, Lúcio, Valéria…"
	_name_field.max_length = 18
	_name_field.custom_minimum_size = Vector2(0, 36)
	_name_field.add_theme_font_size_override("font_size", 17)
	_name_field.text_changed.connect(_on_name_changed)
	root.add_child(_name_field)
	_points_label = _make_label("", 16, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_points_label)
	# Os 7 atributos em duas colunas para caber na tela sem cortar.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	root.add_child(grid)
	for definition: Dictionary in EconomySystemScript.attribute_definitions():
		grid.add_child(_make_stat_row(str(definition.get("id", ""))))
	_preview = RichTextLabel.new()
	_preview.bbcode_enabled = true
	_preview.custom_minimum_size = Vector2(0, 72)
	_preview.add_theme_font_size_override("normal_font_size", 13)
	_preview.add_theme_color_override("default_color", MUTED)
	_preview.add_theme_stylebox_override("normal", _panel_style(PANEL_DARK, 10, 12))
	root.add_child(_preview)
	_confirm_button = Button.new()
	_confirm_button.text = "IR À LOJA (equipar antes da luta)"
	_confirm_button.custom_minimum_size = Vector2(0, 46)
	_confirm_button.add_theme_font_size_override("font_size", 16)
	_confirm_button.disabled = true
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_style_button(_confirm_button, GOLD)
	root.add_child(_confirm_button)
	_refresh()

func _make_stat_row(stat_id: String) -> HBoxContainer:
	var spec: Dictionary = EconomySystemScript.creation_stats().get(stat_id, {})
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := _make_label("%s %s" % [str(spec.get("short", "")), str(spec.get("label", stat_id))], 13, INK)
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)
	var minus := _make_small_button("-")
	minus.pressed.connect(_add_point.bind(stat_id, -1))
	row.add_child(minus)
	var value := _make_label("0", 16, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	value.custom_minimum_size = Vector2(34, 0)
	row.add_child(value)
	_stat_values[stat_id] = value
	var plus := _make_small_button("+")
	plus.pressed.connect(_add_point.bind(stat_id, 1))
	row.add_child(plus)
	var hint := _make_label("+%d" % int(spec.get("per_point", 0)), 11, DIM)
	row.add_child(hint)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	return row

func _make_small_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(32, 30)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("1a1420"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("7b6fa0"), 6, 4))
	button.add_theme_stylebox_override("hover", _panel_style(Color("8f83b3"), 6, 4))
	return button

func _add_point(stat_id: String, delta: int) -> void:
	var current := int(_allocation.get(stat_id, 0))
	var next := current + delta
	if next < 0:
		return
	if delta > 0 and _points_left <= 0:
		return
	_allocation[stat_id] = next
	_points_left -= delta
	_refresh()

## Expõe um atalho para testes/automação distribuírem pontos.
func allocate_points(stat_id: String, count: int) -> void:
	for i in count:
		_add_point(stat_id, 1)

func _on_name_changed(_new_text: String) -> void:
	_refresh()

func _refresh() -> void:
	_points_label.text = "Pontos restantes: %d" % _points_left
	for stat_id in _stat_values.keys():
		var count := int(_allocation.get(stat_id, 0))
		_stat_values[stat_id].text = str(count)
	var lines: Array[String] = []
	for definition: Dictionary in EconomySystemScript.attribute_definitions():
		var stat_id := str(definition.get("id", ""))
		var value := EconomySystemScript.neutral_total(stat_id, _allocation)
		lines.append("[color=#cdbfd5]%s[/color] [color=#f5c451]%d[/color]" % [str(definition.get("short", stat_id)), value])
	_preview.text = "  ".join(lines)
	var name_ok := _name_field != null and _name_field.text.strip_edges() != ""
	_confirm_button.disabled = not (name_ok and _points_left == 0)

func _on_confirm_pressed() -> void:
	var player_name := _name_field.text.strip_edges()
	if player_name == "" or _points_left != 0:
		return
	confirmed.emit(player_name, _allocation.duplicate())

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
	button.add_theme_color_override("font_disabled_color", Color("8a8091"))
	button.add_theme_stylebox_override("normal", _panel_style(color, 8, 14))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12), 8, 14))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.12), 8, 14))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("4a4154"), 8, 14))

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
