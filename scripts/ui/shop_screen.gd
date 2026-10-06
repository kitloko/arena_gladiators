class_name ShopScreen
extends Control

## Loja procedural entre lutas (e inicial antes da 1ª batalha):
## 1) escolha a categoria (ARMAS / ARMADURAS); 2) dentro dela, o tipo
## (ex.: Adagas, Machados, Arcos / Capacetes, Cintos); 3) vê até 3 itens
## diferentes daquele tipo, gerados com nível, raridade e bônus aleatórios.
## O estoque rerolha de graça ao subir de nível ou por ouro (botão REROLAR).

signal closed

const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")
const ItemGeneratorScript := preload("res://scripts/systems/item_generator.gd")
const SLOT_TITLES := {
	"weapon": "ARMA", "armor": "ARMADURA", "helmet": "CAPACETE",
	"gloves": "LUVAS", "boots": "BOTAS", "belt": "CINTO",
}

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

var _categories: Array[Dictionary] = []
var _category: String = "arma"
var _subtype: String = ""
var _gold_label: Label
var _category_row: HBoxContainer
var _subtype_row: HBoxContainer
var _list: VBoxContainer
var _reroll_button: Button
var _status_label: Label

func _ready() -> void:
	_categories = ItemGeneratorScript.top_categories()
	GameState.ensure_shop_stock()
	_select_category(_category, true)
	_build_interface()
	_render()

func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKGROUND
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 34)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	root.add_child(_make_label("LOJA DO FERREIRO", 30, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_status_label = _make_label("", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_status_label)
	root.add_child(_make_label("Escolha a categoria e o tipo. Cada tipo mostra até 3 itens gerados.", 13, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_category_row = HBoxContainer.new()
	_category_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_category_row.add_theme_constant_override("separation", 10)
	root.add_child(_category_row)
	_subtype_row = HBoxContainer.new()
	_subtype_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_subtype_row.add_theme_constant_override("separation", 8)
	_subtype_row.custom_minimum_size.y = 40
	root.add_child(_subtype_row)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 340)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	root.add_child(_make_label("A loja rerolha de graça quando você sobe de nível. Use ouro para rerolar antes disso.", 12, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 12)
	_reroll_button = Button.new()
	_reroll_button.text = "REROLAR LOJA"
	_reroll_button.custom_minimum_size = Vector2(200, 46)
	_reroll_button.add_theme_font_size_override("font_size", 15)
	_reroll_button.pressed.connect(_on_reroll_pressed)
	_style_button(_reroll_button, ABILITY)
	bottom.add_child(_reroll_button)
	var continue_button := Button.new()
	continue_button.text = "VOLTAR À ARENA  →"
	continue_button.custom_minimum_size = Vector2(200, 46)
	continue_button.add_theme_font_size_override("font_size", 16)
	continue_button.pressed.connect(closed.emit)
	_style_button(continue_button, GREEN)
	bottom.add_child(continue_button)
	root.add_child(bottom)

func _select_category(category_id: String, force := false) -> void:
	if _category == category_id and not force:
		return
	_category = category_id
	var subtype: Dictionary = _subtype_for_category(category_id)
	if not subtype.is_empty():
		_subtype = str(subtype.get("id", ""))
	else:
		_subtype = ""

func _subtype_for_category(category_id: String) -> Dictionary:
	for category: Dictionary in _categories:
		if str(category.get("id", "")) == category_id:
			var subs: Array = category.get("subtypes", [])
			if not subs.is_empty():
				return subs[0]
	return {}

func _subtypes_of(category_id: String) -> Array:
	for category: Dictionary in _categories:
		if str(category.get("id", "")) == category_id:
			return category.get("subtypes", [])
	return []

func _render() -> void:
	_update_status()
	_render_category_buttons()
	_render_subtype_buttons()
	_render_items()
	_update_reroll()

func _update_status() -> void:
	if GameState.player == null:
		_status_label.text = ""
		return
	_status_label.text = "Nível %d  •  %d ouro" % [GameState.player.level, GameState.player.gold]

func _render_category_buttons() -> void:
	for child in _category_row.get_children():
		child.queue_free()
	for category: Dictionary in _categories:
		var button := Button.new()
		button.text = str(category.get("label", "?"))
		button.custom_minimum_size = Vector2(150, 42)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_select_category.bind(str(category.get("id", "")), true))
		button.pressed.connect(_on_mutation)
		var is_active := str(category.get("id", "")) == _category
		_style_button(button, GOLD if is_active else Color("4a4154"))
		_category_row.add_child(button)

func _render_subtype_buttons() -> void:
	for child in _subtype_row.get_children():
		child.queue_free()
	for subtype: Dictionary in _subtypes_of(_category):
		var button := Button.new()
		button.text = str(subtype.get("label", "?"))
		button.custom_minimum_size = Vector2(0, 36)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 13)
		var subtype_id := str(subtype.get("id", ""))
		button.pressed.connect(_set_subtype.bind(subtype_id))
		var is_active := subtype_id == _subtype
		_style_button(button, Color("70b9e8") if is_active else Color("3a3145"))
		_subtype_row.add_child(button)

func _set_subtype(subtype_id: String) -> void:
	if _subtype != subtype_id:
		_subtype = subtype_id
		_render_items()

func _render_items() -> void:
	for child in _list.get_children():
		child.free()
	var items: Array = GameState.shop_stock_for(_subtype)
	if items.is_empty():
		_list.add_child(_make_label("Nenhum item disponível neste tipo agora.", 15, DIM, HORIZONTAL_ALIGNMENT_CENTER))
		return
	for item: Dictionary in items:
		_list.add_child(_make_row(item))

func _make_row(item: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_DARK, 10, 14))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	panel.add_child(hbox)
	var icon_path := ItemGeneratorScript.item_icon_path(item)
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(44, 44)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	hbox.add_child(info)
	var rarity_color := Color(str(item.get("rarity_color", "b9b0be")))
	var rarity_label := str(item.get("rarity", "Comum"))
	var item_level := int(item.get("level", 1))
	var name_label := _make_label("%s" % str(item.get("display_name", "Item")), 18, rarity_color)
	info.add_child(name_label)
	var meta := "%s  •  nível %d" % [rarity_label, item_level]
	info.add_child(_make_label(meta, 13, DIM))
	var bonuses := _bonus_text(item)
	info.add_child(_make_label(bonuses, 14, GREEN))
	_add_equip_comparison(info, item)
	var kind_hint := _kind_text(item)
	if kind_hint != "":
		info.add_child(_make_label(kind_hint, 12, DIM))
	var slot_title := str(SLOT_TITLES.get(str(item.get("slot", "weapon")), "ITEM"))
	info.add_child(_make_label("Lugar: %s   •   %d ouro" % [slot_title, int(item.get("price", 0))], 12, DIM))
	var action := CenterContainer.new()
	var button := Button.new()
	button.custom_minimum_size = Vector2(170, 46)
	button.add_theme_font_size_override("font_size", 14)
	var item_id := str(item.get("id", ""))
	var slot := str(item.get("slot", "weapon"))
	var equipped_id: String = GameState.player.equipped_id(slot) if GameState.player != null else ""
	if equipped_id == item_id:
		button.text = "Equipado"
		button.disabled = true
		_style_button(button, Color("4a4154"))
	elif GameState.player.owns_item(item_id):
		button.text = "EQUIPAR"
		button.pressed.connect(GameState.equip_item.bind(item))
		button.pressed.connect(_on_mutation)
		_style_button(button, Color("70b9e8"))
	else:
		var price := int(item.get("price", 0))
		button.text = "COMPRAR"
		button.disabled = GameState.player.gold < price
		button.pressed.connect(GameState.purchase_item.bind(item))
		button.pressed.connect(_on_mutation)
		_style_button(button, GOLD)
	action.add_child(button)
	hbox.add_child(action)
	return panel

func _bonus_text(item: Dictionary) -> String:
	var parts: Array[String] = []
	if int(item.get("attack_bonus", 0)) > 0:
		parts.append("ATQ +%d" % int(item.get("attack_bonus", 0)))
	if int(item.get("defense_bonus", 0)) > 0:
		parts.append("DEF +%d" % int(item.get("defense_bonus", 0)))
	if int(item.get("luck_bonus", 0)) > 0:
		parts.append("SORTE +%d" % int(item.get("luck_bonus", 0)))
	if int(item.get("health_bonus", 0)) > 0:
		parts.append("VIDA +%d" % int(item.get("health_bonus", 0)))
	return "  ".join(parts) if not parts.is_empty() else "sem bônus"

## Mostra a diferença entre o que está equipado no slot e o item da loja,
## com a variação por status (verde = melhora, vermelho = piora).
func _add_equip_comparison(info: VBoxContainer, item: Dictionary) -> void:
	if GameState.player == null:
		return
	var slot := str(item.get("slot", "weapon"))
	var equipped_id: String = GameState.player.equipped_id(slot)
	if equipped_id == "" or equipped_id == str(item.get("id", "")):
		return
	var equipped_item: Dictionary = GameState.item_data(equipped_id)
	if equipped_item.is_empty():
		return
	info.add_child(_make_label("vs equipado: %s" % str(equipped_item.get("display_name", equipped_id)), 12, DIM))
	var stats := [
		["ATQ", "attack_bonus"], ["DEF", "defense_bonus"], ["SORTE", "luck_bonus"], ["VIDA", "health_bonus"],
	]
	for stat: Array in stats:
		var current_value := int(equipped_item.get(str(stat[1]), 0))
		var shop_value := int(item.get(str(stat[1]), 0))
		if current_value == 0 and shop_value == 0:
			continue
		var delta := shop_value - current_value
		var color := GREEN if delta > 0 else (RED if delta < 0 else MUTED)
		var delta_text := "=" if delta == 0 else ("%+d" % delta)
		info.add_child(_make_label("%s  %+d → %+d    [%s]" % [str(stat[0]), current_value, shop_value, delta_text], 13, color))

func _kind_text(item: Dictionary) -> String:
	if str(item.get("slot", "")) != "weapon":
		return ""
	var kind := str(item.get("kind", "melee"))
	if kind == "ranged":
		return "À distância (precisão cai com a distância)"
	return "Corpo a corpo (alcance %d)" % int(item.get("reach", 1))

func _update_reroll() -> void:
	if GameState.player == null:
		return
	var cost := GameState.shop_reroll_cost()
	_reroll_button.text = "REROLAR LOJA (%d ouro)" % cost
	_reroll_button.disabled = GameState.player.gold < cost

func _on_reroll_pressed() -> void:
	var result: Dictionary = GameState.reroll_shop()
	_on_mutation()

## Re-renderiza a tela (chamado após comprar/equipar/rerolar/trocar de aba).
func _on_mutation() -> void:
	_render.call_deferred()

func _style_button(button: Button, color: Color) -> void:
	button.add_theme_color_override("font_color", Color("1a1420"))
	button.add_theme_color_override("font_hover_color", Color("1a1420"))
	button.add_theme_color_override("font_pressed_color", Color("1a1420"))
	button.add_theme_color_override("font_disabled_color", Color("8a8091"))
	button.add_theme_stylebox_override("normal", _panel_style(color, 8, 14))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12), 8, 14))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.12), 8, 14))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("4a4154"), 8, 14))

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
