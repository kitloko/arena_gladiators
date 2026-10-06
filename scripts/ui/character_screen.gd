class_name CharacterScreen
extends Control

## Personagem estilo RPG: atributos, slots de equipamento (quadrados como nos
## RPGs, um por parte do corpo) e a BOLSA com os itens possuídos p/ trocar.

signal closed

const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")
const ItemGeneratorScript := preload("res://scripts/systems/item_generator.gd")
const SLOT_ORDER := ["weapon", "armor", "helmet", "gloves", "boots", "belt"]
const SLOT_LABELS := {
	"weapon": "ARMA", "armor": "ARMADURA", "helmet": "CAPACETE",
	"gloves": "LUVAS", "boots": "BOTAS", "belt": "CINTO",
}
const SLOT_COLORS := {
	"weapon": Color("d9a45b"), "armor": Color("79cf7b"), "helmet": Color("70b9e8"),
	"gloves": Color("e06bb5"), "boots": Color("b08de7"), "belt": Color("f5c451"),
}

const BACKGROUND := Color("14111c")
const PANEL := Color("272033")
const PANEL_DARK := Color("1d1726")
const GOLD := Color("f5c451")
const INK := Color("f7edf4")
const MUTED := Color("cdbfd5")
const DIM := Color("bbaec1")

var _items: Array[Dictionary] = []
var _attributes: RichTextLabel
var _equipment_grid: GridContainer
var _bag: VBoxContainer

func _ready() -> void:
	_items = ContentRepositoryScript.load_items()
	_build_interface()
	_refresh()

func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKGROUND
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 36)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	root.add_child(_make_label("PERSONAGEM", 30, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_attributes = RichTextLabel.new()
	_attributes.bbcode_enabled = true
	_attributes.custom_minimum_size = Vector2(0, 56)
	_attributes.add_theme_font_size_override("normal_font_size", 16)
	_attributes.add_theme_color_override("default_color", MUTED)
	_attributes.add_theme_stylebox_override("normal", _panel_style(PANEL_DARK, 10, 14))
	root.add_child(_attributes)
	root.add_child(_make_label("EQUIPAMENTO", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var scroll_grid := ScrollContainer.new()
	scroll_grid.custom_minimum_size = Vector2(0, 220)
	_equipment_grid = GridContainer.new()
	_equipment_grid.columns = 3
	_equipment_grid.add_theme_constant_override("h_separation", 12)
	_equipment_grid.add_theme_constant_override("v_separation", 12)
	_equipment_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_grid.add_child(_equipment_grid)
	root.add_child(scroll_grid)
	root.add_child(_make_label("BOLSA (itens possuídos — clique em EQUIPAR para trocar)", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var scroll_bag := ScrollContainer.new()
	scroll_bag.custom_minimum_size = Vector2(0, 150)
	scroll_bag.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bag = VBoxContainer.new()
	_bag.add_theme_constant_override("separation", 8)
	_bag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_bag.add_child(_bag)
	root.add_child(scroll_bag)
	var back := Button.new()
	back.text = "VOLTAR À CIDADE"
	back.custom_minimum_size = Vector2(0, 48)
	back.add_theme_font_size_override("font_size", 16)
	back.pressed.connect(closed.emit)
	back.add_theme_color_override("font_color", Color("1a1420"))
	back.add_theme_stylebox_override("normal", _panel_style(Color("8f83b3"), 8, 14))
	back.add_theme_stylebox_override("hover", _panel_style(Color("9f93c2"), 8, 14))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(back)
	root.add_child(row)

func _refresh() -> void:
	if GameState.player == null:
		return
	var p = GameState.player
	_attributes.text = "[color=#f5c451]%s[/color]  •  Nível %d  •  %d ouro\n[color=#79cf7b]VIDA %d/%d[/color]   [color=#d9a45b]ATQ %d[/color]   [color=#70b9e8]DEF %d[/color]   [color=#e06bb5]SORTE %d[/color]" % [
		p.display_name, p.level, p.gold, p.health, p.max_health, p.attack, p.defense, p.luck,
	]
	for child in _equipment_grid.get_children():
		child.queue_free()
	for slot: String in SLOT_ORDER:
		_equipment_grid.add_child(_make_slot(slot))
	_refresh_bag()

func _make_slot(slot: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 92)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var color: Color = SLOT_COLORS.get(slot, MUTED)
	panel.add_theme_stylebox_override("panel", _border_style(PANEL_DARK, color))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	box.add_child(_make_label(str(SLOT_LABELS.get(slot, slot)), 13, color, HORIZONTAL_ALIGNMENT_CENTER))
	var item := _item_by_id(GameState.player.equipped_id(slot))
	if item.is_empty():
		var empty := _make_label("— vazio —", 15, Color("6b6078"), HORIZONTAL_ALIGNMENT_CENTER)
		empty.custom_minimum_size.y = 40
		box.add_child(empty)
	else:
		var icon := _icon_rect(item, 38)
		if icon != null:
			var icon_center := CenterContainer.new()
			icon_center.add_child(icon)
			box.add_child(icon_center)
		var name_label := _make_label(str(item.get("display_name", "")), 15, INK, HORIZONTAL_ALIGNMENT_CENTER)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(name_label)
		box.add_child(_make_label(_bonus_text(item), 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	return panel

func _refresh_bag() -> void:
	for child in _bag.get_children():
		child.queue_free()
	if GameState.player == null:
		return
	var owned_any := false
	for owned_id: String in GameState.player.owned_item_ids:
		var item := _item_by_id(owned_id)
		if item.is_empty():
			continue
		var slot := str(item.get("slot", "weapon"))
		if GameState.player.equipped_id(slot) == owned_id:
			continue
		owned_any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var icon := _icon_rect(item, 30)
		if icon != null:
			row.add_child(icon)
		else:
			var swatch := ColorRect.new()
			swatch.color = SLOT_COLORS.get(slot, MUTED)
			swatch.custom_minimum_size = Vector2(12, 12)
			row.add_child(swatch)
		var info := _make_label("%s — %s (%s)" % [str(item.get("display_name", "")), str(SLOT_LABELS.get(slot, slot)).to_lower(), _bonus_text(item)], 14, INK)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var equip := Button.new()
		equip.text = "EQUIPAR"
		equip.custom_minimum_size = Vector2(110, 38)
		equip.add_theme_font_size_override("font_size", 14)
		equip.pressed.connect(GameState.equip_item.bind(item))
		equip.pressed.connect(func() -> void: _refresh.call_deferred())
		equip.add_theme_color_override("font_color", Color("1a1420"))
		equip.add_theme_stylebox_override("normal", _panel_style(Color("70b9e8"), 6, 8))
		equip.add_theme_stylebox_override("hover", _panel_style(Color("8cc4ea"), 6, 8))
		row.add_child(equip)
		_bag.add_child(row)
	if not owned_any:
		_bag.add_child(_make_label("Bolsa vazia. Compre itens na loja.", 14, DIM))

## Resolve um item do jogador: catálogo processual primeiro, depois data/items.json.
func _item_by_id(item_id: String) -> Dictionary:
	if item_id == "":
		return {}
	if GameState.player != null:
		var cat: Dictionary = GameState.player.catalog_item(item_id)
		if not cat.is_empty():
			return cat
	return ContentRepositoryScript.find_item(_items, item_id)

## TextureRect com o ícone do item, ou null se não houver arquivo.
func _icon_rect(item: Dictionary, size: int) -> TextureRect:
	var path := ItemGeneratorScript.item_icon_path(item)
	if path == "" or not ResourceLoader.exists(path):
		return null
	var rect := TextureRect.new()
	rect.texture = load(path)
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func _bonus_text(item: Dictionary) -> String:
	var parts: Array[String] = []
	if int(item.get("attack_bonus", 0)) > 0:
		parts.append("ATQ+%d" % int(item.get("attack_bonus", 0)))
	if int(item.get("defense_bonus", 0)) > 0:
		parts.append("DEF+%d" % int(item.get("defense_bonus", 0)))
	if int(item.get("luck_bonus", 0)) > 0:
		parts.append("SORTE+%d" % int(item.get("luck_bonus", 0)))
	if int(item.get("health_bonus", 0)) > 0:
		parts.append("VIDA+%d" % int(item.get("health_bonus", 0)))
	return "  ".join(parts)

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

func _border_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
