class_name CharacterScreen
extends Control

## Personagem: atributos, barra de XP, os 6 slots de equipamento e a BOLSA.
##
## Arrastar-e-soltar (Godot: _get_drag_data/_can_drop_data/_drop_data, na classe
## ItemDropPanel): arrastar um item DA BOLSA para o slot dele equipa; arrastar de
## um SLOT para a bolsa desequipa. Os botões EQUIPAR/VENDER fazem o mesmo caminho
## para quem joga só de mouse — a arrastada é atalho, não o único jeito.

signal closed

const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")
const ItemGeneratorScript := preload("res://scripts/systems/item_generator.gd")
const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")
const RankSystemScript := preload("res://scripts/systems/rank_system.gd")
const ItemDropPanelScript := preload("res://scripts/ui/item_drop_panel.gd")
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
const GREEN := Color("79cf7b")
const RED := Color("d95858")

const HINT := "Arraste um item da bolsa para o slot dele. Para tirar, arraste do slot de volta para a bolsa."

var _items: Array[Dictionary] = []
var _attributes: RichTextLabel
var _xp_bar: ProgressBar
var _xp_label: Label
var _points_box: VBoxContainer
var _equipment_grid: GridContainer
var _bag_zone: ItemDropPanelScript
var _bag: VBoxContainer
var _status: Label

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
		margin.add_theme_constant_override(side, 28)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	root.add_child(_make_label("PERSONAGEM", 28, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_attributes = RichTextLabel.new()
	_attributes.bbcode_enabled = true
	# 5 linhas: nome/nível/ouro, vida+armadura, RANK+KD, os 7 atributos, resumo.
	_attributes.custom_minimum_size = Vector2(0, 118)
	_attributes.add_theme_font_size_override("normal_font_size", 15)
	_attributes.add_theme_color_override("default_color", MUTED)
	_attributes.add_theme_stylebox_override("normal", _panel_style(PANEL_DARK, 10, 12))
	root.add_child(_attributes)
	root.add_child(_build_xp_row())
	_points_box = VBoxContainer.new()
	_points_box.add_theme_constant_override("separation", 6)
	root.add_child(_points_box)
	root.add_child(_build_columns())
	_status = _make_label(HINT, 14, DIM)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status)
	var back := Button.new()
	back.text = "VOLTAR À CIDADE"
	back.custom_minimum_size = Vector2(0, 46)
	back.add_theme_font_size_override("font_size", 16)
	back.pressed.connect(closed.emit)
	back.add_theme_color_override("font_color", Color("1a1420"))
	back.add_theme_stylebox_override("normal", _panel_style(Color("8f83b3"), 8, 14))
	back.add_theme_stylebox_override("hover", _panel_style(Color("9f93c2"), 8, 14))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(back)
	root.add_child(row)

## Barra de XP: o quanto falta para o próximo nível é a informação que o jogador
## mais precisa e era só texto escondido no meio do resumo.
func _build_xp_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(0, 22)
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_xp_bar.show_percentage = false
	_xp_bar.add_theme_stylebox_override("background", _bar_style(PANEL_DARK, Color("4a4154")))
	_xp_bar.add_theme_stylebox_override("fill", _bar_style(GOLD, GOLD))
	row.add_child(_xp_bar)
	_xp_label = _make_label("", 14, MUTED)
	_xp_label.custom_minimum_size = Vector2(230, 0)
	row.add_child(_xp_label)
	return row

func _build_columns() -> HBoxContainer:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# --- coluna esquerda: equipamento ---
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.1
	left.add_child(_make_label("EQUIPAMENTO", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_equipment_grid = GridContainer.new()
	_equipment_grid.columns = 3
	_equipment_grid.add_theme_constant_override("h_separation", 10)
	_equipment_grid.add_theme_constant_override("v_separation", 10)
	_equipment_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(_equipment_grid)
	columns.add_child(left)
	# --- coluna direita: bolsa ---
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_make_label("BOLSA", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	# A bolsa inteira é uma zona de drop: soltar um item equipado aqui desequipa.
	_bag_zone = ItemDropPanelScript.new()
	_bag_zone.accepts_item_kind = "equipped_item"
	_bag_zone.custom_minimum_size = Vector2(0, 250)
	_bag_zone.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bag_zone.add_theme_stylebox_override("panel", _border_style(PANEL_DARK, Color("6b6078")))
	_bag_zone.on_item_dropped = Callable(self, "_handle_drop_on_bag")
	_bag_zone.on_message = Callable(self, "_set_status")
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bag = VBoxContainer.new()
	_bag.add_theme_constant_override("separation", 8)
	_bag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_bag)
	_bag_zone.add_child(scroll)
	right.add_child(_bag_zone)
	columns.add_child(right)
	return columns

func _refresh() -> void:
	if GameState.player == null:
		return
	var p = GameState.player
	_xp_bar.max_value = maxi(1, p.required_experience())
	_xp_bar.value = mini(p.experience, p.required_experience())
	var pending := ""
	if p.pending_points > 0:
		pending = "   •   [color=#f5c451]%d ponto(s) de atributo esperando[/color]" % p.pending_points
	# RANK e KD (item I): separado do nível; o KD é o cartel de vitórias/derrotas.
	var next_tier := RankSystemScript.next_tier(p.rank_points)
	var rank_progress := "faixa máxima"
	if not next_tier.is_empty():
		rank_progress = "faltam %d pts para %s" % [RankSystemScript.points_to_next(p.rank_points), str(next_tier.get("title", "?"))]
	var rank_line := "[color=#f5c451]RANK %s (%d pts — %s)[/color]   [color=#cdbfd5]KD %d V / %d D[/color]" % [
		RankSystemScript.title_for(p.rank_points), p.rank_points, rank_progress, p.wins, p.losses,
	]
	_attributes.text = "[color=#f5c451]%s[/color]  •  Nível %d  •  %d ouro\n[color=#79cf7b]VIDA %d/%d[/color]   [color=#70b9e8]ARMADURA %d/%d[/color]\n%s\n[color=#bbaec1]FOR %d   ATT %d   DEF %d   AGI %d   VIT %d   CAR %d   SOR %d[/color]\n[color=#bbaec1]Equipado: %d de 6 slots   •   itens na bolsa: %d[/color]%s" % [
		p.display_name, p.level, p.gold, p.health, p.max_health, p.armour, p.max_armour,
		rank_line,
		p.strength, p.attack, p.defence, p.agility, p.vitality, p.charisma, p.luck,
		_equipped_count(), p.bag_items().size(), pending,
	]
	_xp_label.text = "XP %d / %d para o nível %d" % [p.experience, p.required_experience(), p.level + 1]
	for child in _equipment_grid.get_children():
		child.queue_free()
	for slot: String in SLOT_ORDER:
		_equipment_grid.add_child(_make_slot(slot))
	_refresh_bag()
	_refresh_points()

## Painel de distribuição dos pontos de atributo pendentes (os 7 atributos).
func _refresh_points() -> void:
	if _points_box == null:
		return
	for child in _points_box.get_children():
		child.queue_free()
	if GameState.player == null:
		return
	var pending: int = int(GameState.player.pending_points)
	if pending <= 0:
		return
	_points_box.add_child(_make_label("PONTOS PARA DISTRIBUIR: %d" % pending, 16, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 8)
	for definition: Dictionary in GameState.attribute_definitions():
		var stat_id := str(definition.get("id", ""))
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		cell.add_child(_make_label(str(definition.get("short", stat_id)), 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		var button := Button.new()
		button.name = "attrspend_%s" % stat_id
		button.text = "+"
		button.custom_minimum_size = Vector2(56, 30)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(spend_point.bind(stat_id))
		button.add_theme_color_override("font_color", Color("1a1420"))
		button.add_theme_stylebox_override("normal", _panel_style(Color("79cf7b"), 6, 6))
		button.add_theme_stylebox_override("hover", _panel_style(Color("8fd891"), 6, 6))
		cell.add_child(button)
		grid.add_child(cell)
	_points_box.add_child(grid)

## Gasta um ponto pendente no atributo e re-renderiza (usado pela UI e pelo QA).
func spend_point(stat_id: String) -> void:
	GameState.spend_attribute_point(stat_id)
	_refresh.call_deferred()

func _equipped_count() -> int:
	if GameState.player == null:
		return 0
	var total := 0
	for slot: String in SLOT_ORDER:
		if GameState.player.equipped_id(slot) != "":
			total += 1
	return total

func _make_slot(slot: String) -> ItemDropPanelScript:
	var panel := ItemDropPanelScript.new()
	# Nome único (o Godot renomeia nomes repetidos para "@Node@2"): o prefixo
	# equipslot_ é o que o QA conta para saber que os 6 slots foram desenhados.
	panel.name = "equipslot_%s" % slot
	panel.custom_minimum_size = Vector2(150, 104)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var color: Color = SLOT_COLORS.get(slot, MUTED)
	panel.add_theme_stylebox_override("panel", _border_style(PANEL_DARK, color))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	box.add_child(_make_label(str(SLOT_LABELS.get(slot, slot)), 13, color, HORIZONTAL_ALIGNMENT_CENTER))
	var item := _item_by_id(GameState.player.equipped_id(slot))
	if item.is_empty():
		var empty := _make_label("— vazio —\n(solte um item)", 13, Color("6b6078"), HORIZONTAL_ALIGNMENT_CENTER)
		empty.custom_minimum_size.y = 44
		panel.empty_hint = empty
		box.add_child(empty)
	else:
		var icon := _icon_rect(item, 34)
		if icon != null:
			var icon_center := CenterContainer.new()
			icon_center.add_child(icon)
			box.add_child(icon_center)
		var name_label := _make_label(str(item.get("display_name", "")), 14, INK, HORIZONTAL_ALIGNMENT_CENTER)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(name_label)
		box.add_child(_make_label(_bonus_text(item), 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	# Este slot aceita item da bolsa que pertença a ele, e pode ser arrastado para
	# a bolsa (payload de item equipado).
	panel.accepts_item_kind = "bag_item"
	panel.accepts_slot = slot
	panel.equipped_id_hint = GameState.player.equipped_id(slot)
	panel.on_item_dropped = Callable(self, "_handle_drop_on_slot")
	panel.on_message = Callable(self, "_set_status")
	if not item.is_empty():
		panel.drag_payload = {
			"kind": "equipped_item", "slot": slot,
			"id": str(item.get("id", "")), "name": str(item.get("display_name", "item")),
		}
	return panel

func _refresh_bag() -> void:
	for child in _bag.get_children():
		child.queue_free()
	if GameState.player == null:
		return
	var items: Array[Dictionary] = GameState.player.bag_items()
	var index := 0
	for item: Dictionary in items:
		_bag.add_child(_make_bag_row(item, index))
		index += 1
	# Instrução no vazio da zona de drop: a bolsa é alvo de arrastar também.
	_bag.add_child(_make_label("(arraste um item equipado para cá para desequipar)", 13, Color("6b6078")))

func _make_bag_row(item: Dictionary, index: int) -> ItemDropPanelScript:
	var slot := str(item.get("slot", "weapon"))
	var row := ItemDropPanelScript.new()
	# Nome único por linha (prefixo contado pelo QA): nomes repetidos o Godot
	# renomeia para "@Node@2" e o teste de estrutura deixaria de enxergar.
	row.name = "bagrow_%d" % index
	row.add_theme_stylebox_override("panel", _panel_style(PANEL, 8, 10))
	row.accepts_item_kind = "equipped_item"
	row.on_item_dropped = Callable(self, "_handle_drop_on_bag")
	row.on_message = Callable(self, "_set_status")
	row.drag_payload = {
		"kind": "bag_item", "slot": slot,
		"id": str(item.get("id", "")), "name": str(item.get("display_name", "item")),
	}
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	row.add_child(box)
	var icon := _icon_rect(item, 30)
	if icon != null:
		box.add_child(icon)
	else:
		var swatch := ColorRect.new()
		swatch.color = SLOT_COLORS.get(slot, MUTED)
		swatch.custom_minimum_size = Vector2(12, 12)
		box.add_child(swatch)
	var rarity_color := Color(str(item.get("rarity_color", "b9b0be")))
	var text := "%s   [color=#bbaec1]%s • %s • nível %d • venda %d ouro[/color]\n[color=#79cf7b]%s[/color]" % [
		str(item.get("display_name", "")), str(item.get("rarity", "Comum")),
		str(SLOT_LABELS.get(slot, slot)).to_lower(), int(item.get("level", 1)),
		EconomySystemScript.sell_price(item), _bonus_text(item),
	]
	var info := RichTextLabel.new()
	info.bbcode_enabled = true
	info.fit_content = true
	info.scroll_active = false
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_font_size_override("normal_font_size", 14)
	info.add_theme_color_override("default_color", INK)
	info.text = text
	box.add_child(info)
	box.add_child(_make_small_button("EQUIPAR", Color("70b9e8"), func() -> void: _equip_from_bag(item)))
	box.add_child(_make_sell_button(item))
	return row

func _make_sell_button(item: Dictionary) -> Button:
	var item_id := str(item.get("id", ""))
	var value := EconomySystemScript.sell_price(item)
	var sellable := EconomySystemScript.is_sellable(item)
	var label := "NÃO VENDÁVEL"
	if sellable:
		label = "VENDER (%d)" % value
	var button := _make_small_button(label, GOLD, func() -> void: _sell(item_id))
	button.disabled = not sellable
	if not sellable:
		button.tooltip_text = "Item único de torneio: não pode ser vendido."
	return button

func _make_small_button(text_value: String, color: Color, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(120, 38)
	button.add_theme_font_size_override("font_size", 13)
	button.pressed.connect(action)
	button.add_theme_color_override("font_color", Color("1a1420"))
	button.add_theme_color_override("font_disabled_color", Color("8a8091"))
	button.add_theme_stylebox_override("normal", _panel_style(color, 6, 8))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12), 6, 8))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("4a4154"), 6, 8))
	return button

# --- Ações -----------------------------------------------------------------

func _equip_from_bag(item: Dictionary) -> void:
	GameState.equip_item(item)
	_set_status("Equipado: %s." % str(item.get("display_name", "item")))
	_refresh.call_deferred()

func _sell(item_id: String) -> void:
	var info: Dictionary = GameState.sell_item(item_id)
	if bool(info.get("ok", false)):
		_set_status("Vendido: %s por %d ouro." % [str(info.get("name", "item")), int(info.get("gold", 0))])
	else:
		_set_status("%s — %s" % [str(info.get("name", "Item")), str(info.get("reason", "não foi possível vender"))])
	_refresh.call_deferred()

func _handle_drop_on_slot(data: Variant, target_slot: String) -> void:
	var payload := data as Dictionary
	if str(payload.get("kind", "")) != "bag_item":
		return
	var item := _item_by_id(str(payload.get("id", "")))
	if item.is_empty():
		_set_status("Item não encontrado na bolsa.")
		return
	if str(item.get("slot", "")) != target_slot:
		_set_status("%s não vai no slot %s." % [
			str(item.get("display_name", "item")), str(SLOT_LABELS.get(target_slot, target_slot))])
		return
	GameState.equip_item(item)
	_set_status("Equipado: %s no slot %s." % [
		str(item.get("display_name", "item")), str(SLOT_LABELS.get(target_slot, target_slot))])
	_refresh.call_deferred()

func _handle_drop_on_bag(data: Variant, _target_slot: String) -> void:
	var payload := data as Dictionary
	if str(payload.get("kind", "")) != "equipped_item":
		return
	var slot := str(payload.get("slot", ""))
	var item_name := str(payload.get("name", "item"))
	if GameState.unequip_slot(slot):
		_set_status("%s voltou para a bolsa (slot %s livre)." % [item_name, str(SLOT_LABELS.get(slot, slot))])
	else:
		_set_status("Não foi possível desequipar %s." % item_name)
	_refresh.call_deferred()

func _set_status(text_value: String) -> void:
	if _status != null:
		_status.text = text_value

# --- Utilidades ------------------------------------------------------------

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
	if int(item.get("strength_bonus", 0)) > 0:
		parts.append("STR+%d" % int(item.get("strength_bonus", 0)))
	if int(item.get("attack_bonus", 0)) > 0:
		parts.append("ATT+%d" % int(item.get("attack_bonus", 0)))
	if int(item.get("defence_bonus", 0)) > 0:
		parts.append("DEF+%d" % int(item.get("defence_bonus", 0)))
	if int(item.get("agility_bonus", 0)) > 0:
		parts.append("AGI+%d" % int(item.get("agility_bonus", 0)))
	if int(item.get("vitality_bonus", 0)) > 0:
		parts.append("VIT+%d" % int(item.get("vitality_bonus", 0)))
	if int(item.get("charisma_bonus", 0)) > 0:
		parts.append("CAR+%d" % int(item.get("charisma_bonus", 0)))
	if int(item.get("luck_bonus", 0)) > 0:
		parts.append("SOR+%d" % int(item.get("luck_bonus", 0)))
	if int(item.get("armour", 0)) > 0:
		parts.append("ARM+%d" % int(item.get("armour", 0)))
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

## Fundo de barra (a de XP) com contorno: sem o contorno ela não se lê como barra.
func _bar_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
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
