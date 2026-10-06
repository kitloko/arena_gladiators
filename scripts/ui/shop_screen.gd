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
const PotionSystemScript := preload("res://scripts/systems/potion_system.gd")
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
## Altura máxima da lista de itens da loja. O que couber é sempre um número
## inteiro de cards — nunca um card cortado ao meio (ver _fit_list_height).
const MAX_LIST_HEIGHT := 340.0

var _categories: Array[Dictionary] = []
var _category: String = "arma"
var _subtype: String = ""
var _gold_label: Label
var _category_row: HBoxContainer
var _subtype_row: HBoxContainer
var _list: VBoxContainer
var _scroll: ScrollContainer
var _reroll_button: Button
var _status_label: Label
## Mensagem da última ação (pechincha etc.) mostrada junto do ouro.
var _flash_text := ""
var _flash_color := MUTED

func _ready() -> void:
	_categories = ItemGeneratorScript.top_categories()
	# POÇÕES (item 6): categoria fixa de consumíveis de combate (data/items.json).
	_categories.append({"id": "pocoes", "label": "POÇÕES", "subtypes": [{"id": "pocoes", "label": "Consumíveis de combate"}]})
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
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(0, MAX_LIST_HEIGHT)
	_scroll.size_flags_vertical = Control.SIZE_FILL
	root.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
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
	if _flash_text != "":
		_status_label.text += "   —   " + _flash_text
		_status_label.add_theme_color_override("font_color", _flash_color)
	else:
		_status_label.add_theme_color_override("font_color", MUTED)

## Mostra uma mensagem curta na linha de status (resultado da pechincha etc.).
func _flash(text_value: String, color: Color) -> void:
	_flash_text = text_value
	_flash_color = color
	_update_status()

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
	# A altura só pode ser decidida depois do layout dos cards (ver _fit_list_height).
	_fit_list_height.call_deferred()

## Fecha a altura da lista em um número INTEIRO de cards: com 3 itens por tipo, o
## jogador vê os 3 inteiros (ou rola a lista) sem nunca ver um card cortado ao meio.
func _fit_list_height() -> void:
	await get_tree().process_frame
	var rows := _list.get_children()
	if rows.is_empty():
		return
	var tallest := 0.0
	for row in rows:
		if row is Control:
			tallest = maxf(tallest, (row as Control).size.y)
	if tallest <= 0.0:
		return
	var spacing := float(_list.get_theme_constant("separation"))
	var card := tallest + spacing
	var whole := clampi(int(floor((MAX_LIST_HEIGHT + spacing) / card)), 1, rows.size())
	_scroll.custom_minimum_size.y = whole * card - spacing

func _make_row(item: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_DARK, 10, 10))
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
	info.add_theme_constant_override("separation", 2)
	hbox.add_child(info)
	# Card compacto (4 linhas enxutas): nome + raridade na mesma linha e a
	# comparação com o equipado em UMA linha em vez de quatro.
	var rarity_color := Color(str(item.get("rarity_color", "b9b0be")))
	var rarity_label := str(item.get("rarity", "Comum"))
	var item_level := int(item.get("level", 1))
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_row.add_child(_make_label(str(item.get("display_name", "Item")), 17, rarity_color))
	var title_spacer := Control.new()
	title_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_spacer)
	title_row.add_child(_make_label("%s  •  nível %d" % [rarity_label, item_level], 12, DIM))
	info.add_child(title_row)
	var consumable := str(item.get("slot", "")) == "consumable"
	var bonuses := _bonus_text(item)
	if consumable:
		bonuses = PotionSystemScript.effect_label(item)
	var kind_hint := _kind_text(item)
	info.add_child(_make_label("%s%s" % [bonuses, ("  •  %s" % kind_hint) if kind_hint != "" else ""], 13, GREEN))
	var slot_title := str(SLOT_TITLES.get(str(item.get("slot", "weapon")), "ITEM"))
	var buy_price := GameState.item_price(item)
	var price_label := "Lugar: %s  •  %d ouro" % [slot_title, buy_price]
	if buy_price < int(item.get("price", 0)):
		price_label += "  (preço com desconto)"
	info.add_child(_make_label(price_label, 12, DIM))
	_add_equip_comparison(info, item)
	var item_id := str(item.get("id", ""))
	var slot := str(item.get("slot", "weapon"))
	var action := VBoxContainer.new()
	action.alignment = BoxContainer.ALIGNMENT_CENTER
	action.add_theme_constant_override("separation", 4)
	var button := Button.new()
	button.custom_minimum_size = Vector2(180, 46)
	button.add_theme_font_size_override("font_size", 14)
	var equipped_id: String = GameState.player.equipped_id(slot) if GameState.player != null else ""
	if consumable:
		# POÇÃO (item 6): a compra vai para a BOLSA, com limite de mochila; pode repetir.
		var carried := PotionSystemScript.count(GameState.player)
		var full := carried >= PotionSystemScript.MAX_POTIONS
		button.text = ("MOCHILA CHEIA (%d/%d)" % [carried, PotionSystemScript.MAX_POTIONS]) if full else "COMPRAR"
		button.disabled = full or GameState.player.gold < buy_price
		button.pressed.connect(GameState.purchase_item.bind(item))
		button.pressed.connect(_on_mutation)
		_style_button(button, GOLD)
	elif equipped_id == item_id:
		button.text = "Equipado"
		button.disabled = true
		_style_button(button, Color("4a4154"))
	elif GameState.player.owns_item(item_id):
		button.text = "EQUIPAR"
		button.pressed.connect(GameState.equip_item.bind(item))
		button.pressed.connect(_on_mutation)
		_style_button(button, Color("70b9e8"))
	else:
		button.text = "COMPRAR"
		button.disabled = GameState.player.gold < buy_price
		button.pressed.connect(GameState.purchase_item.bind(item))
		button.pressed.connect(_on_mutation)
		_style_button(button, GOLD)
	action.add_child(button)
	# PECHINCHA (item 4): tentativa única por item; falhar TRAVA aquele item.
	var haggle_button := _make_haggle_button(item)
	if haggle_button != null:
		action.add_child(haggle_button)
	hbox.add_child(action)
	return panel

## Botão PECHINCHAR do item: mostra a chance (CHA/SOR) e o estado da tentativa.
## Depois de pechinchado (ganho OU perdido) o item fica travado para sempre.
func _make_haggle_button(item: Dictionary) -> Button:
	if GameState.player == null:
		return null
	var item_id := str(item.get("id", ""))
	var button := Button.new()
	button.custom_minimum_size = Vector2(180, 32)
	button.add_theme_font_size_override("font_size", 12)
	if GameState.haggle_attempted(item_id):
		if GameState.haggle_result(item_id) == "won":
			button.text = "PECHINCHA: SUCESSO"
		else:
			button.text = "PECHINCHA: TRAVADA"
		button.disabled = true
		_style_button(button, Color("4a4154"))
		return button
	button.text = "PECHINCHAR (%d%%)" % int(round(GameState.haggle_chance() * 100.0))
	button.pressed.connect(_on_haggle.bind(item))
	_style_button(button, ABILITY)
	return button

## Tenta pechinchar: aplica a regra do HaggleSystem (uma vez por item, falha trava).
func _on_haggle(item: Dictionary) -> void:
	var info: Dictionary = GameState.haggle(item)
	if bool(info.get("success", false)):
		_flash("Pechincha certa: %d%% de desconto!" % int(round(float(info.get("discount", 0.0)) * 100.0)), GREEN)
	elif bool(info.get("ok", false)):
		_flash("O comerciante não cedeu — o item ficou TRAVADO no preço normal.", RED)
	else:
		_flash(str(info.get("reason", "não foi possível pechinchar")), DIM)
	_render.call_deferred()

func _bonus_text(item: Dictionary) -> String:
	var parts: Array[String] = []
	if int(item.get("strength_bonus", 0)) > 0:
		parts.append("STR +%d" % int(item.get("strength_bonus", 0)))
	if int(item.get("attack_bonus", 0)) > 0:
		parts.append("ATT +%d" % int(item.get("attack_bonus", 0)))
	if int(item.get("defence_bonus", 0)) > 0:
		parts.append("DEF +%d" % int(item.get("defence_bonus", 0)))
	if int(item.get("agility_bonus", 0)) > 0:
		parts.append("AGI +%d" % int(item.get("agility_bonus", 0)))
	if int(item.get("vitality_bonus", 0)) > 0:
		parts.append("VIT +%d" % int(item.get("vitality_bonus", 0)))
	if int(item.get("charisma_bonus", 0)) > 0:
		parts.append("CAR +%d" % int(item.get("charisma_bonus", 0)))
	if int(item.get("luck_bonus", 0)) > 0:
		parts.append("SOR +%d" % int(item.get("luck_bonus", 0)))
	if int(item.get("armour", 0)) > 0:
		parts.append("ARM +%d" % int(item.get("armour", 0)))
	return "  ".join(parts) if not parts.is_empty() else "sem bônus"

## Mostra a diferença entre o que está equipado no slot e o item da loja em UMA
## linha, com a variação por status (verde = melhora, vermelho = piora). Antes
## eram cinco linhas empilhadas, o que estourava a altura do card.
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
	var stats := [
		["STR", "strength_bonus"], ["ATT", "attack_bonus"], ["DEF", "defence_bonus"],
		["AGI", "agility_bonus"], ["VIT", "vitality_bonus"], ["CAR", "charisma_bonus"],
		["SOR", "luck_bonus"], ["ARM", "armour"],
	]
	var parts: Array[String] = []
	for stat: Array in stats:
		var current_value := int(equipped_item.get(str(stat[1]), 0))
		var shop_value := int(item.get(str(stat[1]), 0))
		if current_value == 0 and shop_value == 0:
			continue
		var delta := shop_value - current_value
		var color := "79cf7b" if delta > 0 else ("d95858" if delta < 0 else "bbaec1")
		parts.append("[color=#%s]%s %d→%d[/color]" % [color, str(stat[0]), current_value, shop_value])
	if parts.is_empty():
		return
	var line := RichTextLabel.new()
	line.bbcode_enabled = true
	line.fit_content = true
	line.scroll_active = false
	line.add_theme_font_size_override("normal_font_size", 12)
	line.add_theme_color_override("default_color", DIM)
	line.text = "vs %s:  %s" % [str(equipped_item.get("display_name", equipped_id)), "   ".join(parts)]
	info.add_child(line)

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
