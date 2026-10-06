class_name CityScreen
extends Control

## Cidade (item B do plano 2.0) — cenário com LOCAIS CLICÁVEIS no lugar da lista de
## botões: fundo usando a CIDADE GERADA da faixa de rank do jogador (etapa 7 do
## plano 3.0: manifest/AssetCatalog), um HUD do personagem no canto (nome, nível,
## RANK com título, vida, ouro) e os destinos como botões-ícone com nome e dica.
##
## Fallback: se a cidade gerada faltar, cai nos assets antigos
## (arena_ground.jpeg + as 2 muralhas) — o jogo nunca fica sem fundo.
##
## Destino bloqueado por RANK (item I) aparece TRANCADO com o motivo
## ("Precisa de rank Aço — você está em Ferro"). A Arena Livre é sempre aberta.

signal arena_requested
signal tournament_requested(tier_id: String)
signal shop_requested
signal character_requested
signal new_requested

const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")
const RankSystemScript := preload("res://scripts/systems/rank_system.gd")

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
const SPRITE_BASE := "res://assets/sprites/"

var _rest_dialog: Control = null
var _new_dialog: Control = null
## Diálogo de SERVIÇO da cidade (médico/ferreiro/treinador).
var _service_dialog: Control = null
var _notice: String = ""

func _ready() -> void:
	_build_interface()

func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKGROUND
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_add_scenery()
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 22)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	# Topo: HUD do personagem (canto) + título da cidade.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	root.add_child(top)
	top.add_child(_build_hud())
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	top.add_child(title_box)
	title_box.add_child(_make_label("CIDADE", 34, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	title_box.add_child(_make_label("Praça dos Gladiadores — escolha o seu destino no cenário", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if _notice != "":
		var notice_color := GREEN if _notice.begins_with("Descanso completo") else Color("d9a45b")
		title_box.add_child(_make_label(_notice, 14, notice_color, HORIZONTAL_ALIGNMENT_CENTER))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	root.add_child(_build_locations())

## Cenário de fundo: a CIDADE GERADA da faixa de rank (etapa 7). Se o PNG faltar,
## cai no cenário antigo (chão + muralhas da arena) — mesma cara de antes, para o
## jogo nunca ficar sem fundo.
var city_art_id: String = ""

func _add_scenery() -> void:
	var band_id := str(GameState.arena_band().get("id", "areia"))
	city_art_id = AssetCatalog.city_id(band_id)
	var city: Texture2D = AssetCatalog.texture(city_art_id)
	var used_generated := city != null
	var backdrop_texture: Texture2D = city
	if backdrop_texture == null:
		backdrop_texture = _load_scenery("arena", "arena_ground")
	if backdrop_texture != null:
		var ground_rect := TextureRect.new()
		ground_rect.texture = backdrop_texture
		ground_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ground_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		ground_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ground_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(ground_rect)
	if not used_generated:
		# Fallback: as muralhas antigas (a cidade gerada já traz muralha própria).
		city_art_id = ""
		_add_wall("arena", "arena_wall_left", true)
		_add_wall("arena", "arena_wall_right", false)
	# Sombra para o texto e os botões lerem bem sobre o cenário. A arte nova já
	# escurece a faixa de baixo (onde os botões de local ficam), então a sombra é
	# mais leve; no fallback mantém a sombra de antes.
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.34 if used_generated else 0.52)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

func _add_wall(folder: String, file_name: String, on_left: bool) -> void:
	var texture := _load_scenery(folder, file_name)
	if texture == null:
		return
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate = Color(1, 1, 1, 0.55)
	if on_left:
		rect.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		rect.offset_right = 120.0
	else:
		rect.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		rect.offset_left = -120.0
	add_child(rect)

func _load_scenery(folder: String, file_name: String) -> Texture2D:
	for ext: String in ["png", "jpeg", "jpg"]:
		var path := "%s%s/%s.%s" % [SPRITE_BASE, folder, file_name, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null

## HUD do personagem no canto: nome, nível, RANK com título, vida e ouro.
func _build_hud() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _border_style(PANEL_DARK, GOLD))
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(300, 0)
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var p = GameState.player
	if p == null:
		box.add_child(_make_label("Sem gladiador", 16, INK, HORIZONTAL_ALIGNMENT_LEFT))
		return panel
	box.add_child(_make_label(p.display_name, 20, INK, HORIZONTAL_ALIGNMENT_LEFT))
	var rank_line := "Nível %d   •   RANK %s (%d pts)" % [p.level, RankSystemScript.title_for(p.rank_points), p.rank_points]
	box.add_child(_make_label(rank_line, 14, GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(_make_label("VIDA %d/%d   •   ARMADURA %d/%d" % [p.health, p.max_health, p.armour, p.max_armour], 14, GREEN, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(_make_label("OURO %d   •   KD %d V / %d D" % [p.gold, p.wins, p.losses], 14, MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	# FERIMENTOS (item 2): sequelas persistentes à mostra no HUD.
	var injuries: Array = GameState.injuries()
	if not injuries.is_empty():
		box.add_child(_make_label("FERIDO: %s" % GameState.injury_summary(), 12, Color("e08a8a"), HORIZONTAL_ALIGNMENT_LEFT))
	return panel

## Faixa inferior com os LOCAIS clicáveis (nome + dica no tooltip).
func _build_locations() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 12, 16))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(_make_label("LOCAIS — clique para ir. Destinos trancados mostram o rank exigido.", 13, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	# Arena Livre: sempre aberta. O nome da faixa de arena aparece no rótulo.
	var arena_label := "» Arena Livre — %s" % GameState.arena_band_title()
	var arena_button := _location_button(arena_label, GREEN, "Lutar na Arena Livre (sem loja/descanso no meio).", true)
	arena_button.pressed.connect(arena_requested.emit)
	grid.add_child(arena_button)
	# Torneios: cada um com requisito de rank (trancado mostra o motivo).
	for tier: Dictionary in GameState.tournament_tiers():
		var tier_id := str(tier.get("id", ""))
		var tier_name := str(tier.get("name", "Torneio"))
		var unlocked: bool = GameState.tournament_unlocked(tier_id)
		var label := "» %s" % tier_name
		var hint := "Torneio do início ao fim: vencer uma luta devolve a vida."
		if not unlocked:
			var reason: String = GameState.tournament_lock_reason(tier_id)
			label = "» %s — TRANCADO (%s)" % [tier_name, reason]
			hint = reason
		var button := _location_button(label, RED, hint, unlocked)
		if unlocked:
			button.pressed.connect(tournament_requested.emit.bind(tier_id))
		grid.add_child(button)
	# Loja.
	var shop_button := _location_button("» Loja", GOLD, "Comprar e vender equipamento (desconto por CAR/SOR).", true)
	shop_button.pressed.connect(shop_requested.emit)
	grid.add_child(shop_button)
	# Descansar.
	var rest_button := _location_button("» Descansar (custa ouro)", Color("70b9e8"), "Recuperar vida e armadura pagando ouro.", true)
	rest_button.pressed.connect(_open_rest_dialog)
	grid.add_child(rest_button)
	# SERVIÇOS DA CIDADE (item 10): médico, ferreiro e treinador.
	var doctor_button := _location_button("» MÉDICO", GREEN, "Curar vida, armadura e TODOS os ferimentos por ouro.", true)
	doctor_button.pressed.connect(_open_doctor_dialog)
	grid.add_child(doctor_button)
	var smith_button := _location_button("» FERREIRO", Color("d9a45b"), "Melhorar a armadura de um item (+1 por melhoria, com teto).", true)
	smith_button.pressed.connect(_open_smith_dialog)
	grid.add_child(smith_button)
	var trainer_button := _location_button("» TREINADOR", ABILITY, "Pagar ouro por XP, com teto por nível.", true)
	trainer_button.pressed.connect(_open_trainer_dialog)
	grid.add_child(trainer_button)
	# Personagem e bolsa.
	var char_button := _location_button("» PERSONAGEM E BOLSA", ABILITY, "Ver atributos, ferimentos, RANK/KD, equipar e vender itens.", true)
	char_button.pressed.connect(character_requested.emit)
	grid.add_child(char_button)
	# Novo gladiador.
	var new_button := _location_button("» NOVO GLADIADOR", Color("8f83b3"), "Começar do zero (apaga o progresso — pede confirmação).", true)
	new_button.pressed.connect(_open_new_dialog)
	grid.add_child(new_button)
	return panel

func _location_button(text_value: String, color: Color, hint: String, enabled: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.tooltip_text = hint
	button.custom_minimum_size = Vector2(0, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 14)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.disabled = not enabled
	_style_button(button, color)
	return button

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_rest_dialog = null
	_new_dialog = null
	_service_dialog = null
	_build_interface()

# --- Descanso pago ----------------------------------------------------------

func _open_rest_dialog() -> void:
	if GameState.player == null or _rest_dialog != null:
		return
	var p = GameState.player
	var missing := maxi(0, p.max_health - p.health)
	var missing_armour := maxi(0, p.max_armour - p.armour)
	var full_cost: int = GameState.full_rest_cost()
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_rest_dialog = overlay
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_rest_dialog())
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_DARK, 14, 30))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(430, 0)
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	root.add_child(_make_label("DESCANSAR", 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	if missing == 0 and missing_armour == 0:
		root.add_child(_make_label("Sua vida e armadura estão cheias — nada a recuperar.", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		_add_dialog_button(root, "FECHAR", _close_rest_dialog)
		return
	root.add_child(_make_label("VIDA %d/%d   •   ARMADURA %d/%d   (faltam %d no total)" % [p.health, p.max_health, p.armour, p.max_armour, missing + missing_armour], 15, INK, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("Descanso completo custa %d ouro. Você tem %d." % [full_cost, p.gold], 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if p.gold < full_cost:
		root.add_child(_make_label("Sem ouro suficiente: o descanso recupera apenas o que o ouro permitir (não garante vida cheia).", 13, Color("d9a45b"), HORIZONTAL_ALIGNMENT_CENTER))
		var per_hp := EconomySystemScript.rest_hp_price(p.level)
		var can_heal := mini(missing, int(p.gold / per_hp))
		root.add_child(_make_label("Com seu ouro atual você recupera até ~%d de vida por %d ouro." % [can_heal, per_hp], 13, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	var rest_button := Button.new()
	rest_button.text = "DESCANSAR (%d ouro)" % full_cost
	rest_button.custom_minimum_size = Vector2(190, 46)
	rest_button.add_theme_font_size_override("font_size", 15)
	rest_button.pressed.connect(_do_rest)
	_style_button(rest_button, GREEN)
	row.add_child(rest_button)
	var cancel := Button.new()
	cancel.text = "CANCELAR"
	cancel.custom_minimum_size = Vector2(130, 46)
	cancel.add_theme_font_size_override("font_size", 15)
	cancel.pressed.connect(_close_rest_dialog)
	_style_button(cancel, Color("8f83b3"))
	row.add_child(cancel)

func _do_rest() -> void:
	if GameState.player == null:
		return
	var info: Dictionary = GameState.rest()
	var cost := int(info.get("cost", 0))
	var healed := int(info.get("healed", 0))
	if bool(info.get("full", false)):
		_notice = "Descanso completo: gastou %d de ouro e recuperou toda a vida (%d)." % [cost, healed]
	else:
		_notice = "Ouro insuficiente: gastou %d de ouro e recuperou %d de vida (vida %d/%d)." % [cost, healed, GameState.player.health, GameState.player.max_health]
	_close_rest_dialog()
	_rebuild()

func _close_rest_dialog() -> void:
	if _rest_dialog != null:
		_rest_dialog.queue_free()
		_rest_dialog = null

# --- SERVIÇOS DA CIDADE (item 10): médico, ferreiro, treinador --------------

## Abre um diálogo de serviço e devolve o VBox onde o conteúdo é montado.
func _open_service_dialog(title: String, width: int) -> VBoxContainer:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_service_dialog = overlay
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_service_dialog())
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_DARK, 14, 30))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(width, 0)
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	root.add_child(_make_label(title, 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	return root

func _close_service_dialog() -> void:
	if _service_dialog != null:
		_service_dialog.queue_free()
		_service_dialog = null

## Linha de botão (com cor) adicionada a um HBox.
func _service_button(text_value: String, color: Color, target: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(200, 46)
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(target)
	_style_button(button, color)
	return button

## MÉDICO: cura vida/armadura e TODOS os ferimentos por ouro.
func _open_doctor_dialog() -> void:
	if GameState.player == null or _service_dialog != null:
		return
	var p = GameState.player
	var root := _open_service_dialog("MÉDICO", 470)
	var cost: int = GameState.doctor_cost()
	var injuries: Array = GameState.injuries()
	root.add_child(_make_label("VIDA %d/%d   •   ARMADURA %d/%d" % [p.health, p.max_health, p.armour, p.max_armour], 15, INK, HORIZONTAL_ALIGNMENT_CENTER))
	if injuries.is_empty():
		root.add_child(_make_label("FERIMENTOS: nenhum.", 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		root.add_child(_make_label("FERIMENTOS (%d):" % injuries.size(), 14, RED, HORIZONTAL_ALIGNMENT_CENTER))
		for injury: Dictionary in injuries:
			root.add_child(_make_label("• %s" % str(injury.get("label", "ferimento")), 13, Color("e08a8a"), HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("Tratamento completo: %d ouro (cura vida, armadura e todos os ferimentos). Você tem %d." % [cost, p.gold], 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("O ferimento NÃO sara sozinho: descansar recupera a vida, mas a sequela só sai aqui.", 12, DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	var treat := _service_button("TRATAR (%d ouro)" % cost if cost > 0 else "NADA A TRATAR", GREEN, _do_doctor)
	treat.disabled = cost <= 0 or p.gold < cost
	row.add_child(treat)
	_add_dialog_button(root, "FECHAR", _close_service_dialog)

func _do_doctor() -> void:
	var info: Dictionary = GameState.visit_doctor()
	if bool(info.get("ok", false)):
		_notice = "Médico: gastou %d de ouro e curou %d ferimento(s)." % [int(info.get("cost", 0)), int(info.get("cured", 0))]
	else:
		_notice = "Médico: %s." % str(info.get("reason", "não foi possível tratar"))
	_close_service_dialog()
	_rebuild()

## FERREIRO: melhora a armadura de um item (+1 por melhoria, com teto e preço crescente).
func _open_smith_dialog() -> void:
	if GameState.player == null or _service_dialog != null:
		return
	var p = GameState.player
	var root := _open_service_dialog("FERREIRO", 540)
	root.add_child(_make_label("Melhoria de armadura: +1 de proteção por melhoria, preço crescente, no máximo %d por peça." % GameState.smith_max_upgrades(), 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var upgradable: Array = []
	for owned_id: Variant in p.owned_item_ids:
		var item: Dictionary = GameState.item_data(str(owned_id))
		if not item.is_empty() and int(item.get("armour", 0)) > 0:
			upgradable.append(item)
	if upgradable.is_empty():
		root.add_child(_make_label("Você não tem peças com armadura para melhorar.", 15, DIM, HORIZONTAL_ALIGNMENT_CENTER))
		_add_dialog_button(root, "FECHAR", _close_service_dialog)
		return
	for item: Dictionary in upgradable:
		var state: Dictionary = GameState.smith_info(str(item.get("id", "")))
		root.add_child(_make_smith_row(item, state))
	_add_dialog_button(root, "FECHAR", _close_service_dialog)

func _make_smith_row(item: Dictionary, state: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 8, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(_make_label(str(item.get("display_name", "Item")), 16, INK, HORIZONTAL_ALIGNMENT_LEFT))
	var upgrades := int(state.get("upgrades", 0))
	var maxed := upgrades >= int(state.get("max", 0))
	info.add_child(_make_label("ARMADURA %d   •   melhorias %d/%d" % [int(state.get("armour", 0)), upgrades, int(state.get("max", 0))], 13, DIM, HORIZONTAL_ALIGNMENT_LEFT))
	var button := _service_button("MELHORAR" if maxed else "MELHORAR (+1) — %d ouro" % int(state.get("cost", 0)), Color("d9a45b"), _do_smith.bind(str(item.get("id", ""))))
	button.custom_minimum_size = Vector2(220, 40)
	button.disabled = maxed or GameState.player.gold < int(state.get("cost", 0))
	if maxed:
		button.text = "MELHORIA MÁXIMA"
	row.add_child(button)
	return panel

func _do_smith(item_id: String) -> void:
	var info: Dictionary = GameState.smith_upgrade(item_id)
	if bool(info.get("ok", false)):
		_notice = "Ferreiro: a peça foi para +%d de armadura (melhoria %d) por %d ouro." % [int(info.get("armour", 0)), int(info.get("upgrades", 0)), int(info.get("cost", 0))]
	else:
		_notice = "Ferreiro: %s." % str(info.get("reason", "não foi possível melhorar"))
	_close_service_dialog()
	_rebuild()
	_open_smith_dialog()

## TREINADOR: paga ouro por XP, com teto por nível.
func _open_trainer_dialog() -> void:
	if GameState.player == null or _service_dialog != null:
		return
	var p = GameState.player
	var root := _open_service_dialog("TREINADOR", 470)
	var cap: int = GameState.trainer_cap()
	var trained: int = GameState.trained_xp()
	var gain: int = GameState.trainer_gain()
	var cost: int = GameState.trainer_cost()
	root.add_child(_make_label("Nível %d   •   XP %d/%d" % [p.level, p.experience, p.required_experience()], 15, INK, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("XP comprado neste nível: %d de %d (o teto zera ao subir de nível)." % [trained, cap], 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if gain > 0:
		root.add_child(_make_label("Uma sessão rende +%d XP por %d ouro. Você tem %d." % [gain, cost, p.gold], 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		root.add_child(_make_label("Teto de treino do nível atingido — o treinador não rende mais XP até você subir de nível.", 14, Color("d9a45b"), HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	var train_button := _service_button("TREINAR (+%d XP) — %d ouro" % [gain, cost] if gain > 0 else "TETO ATINGIDO", ABILITY, _do_train)
	train_button.disabled = gain <= 0 or p.gold < cost
	row.add_child(train_button)
	_add_dialog_button(root, "FECHAR", _close_service_dialog)

func _do_train() -> void:
	var info: Dictionary = GameState.train()
	if bool(info.get("ok", false)):
		_notice = "Treinador: +%d XP por %d ouro%s." % [int(info.get("xp", 0)), int(info.get("cost", 0)), (" — SUBIU DE NÍVEL!" if bool(info.get("leveled_up", false)) else "")]
	else:
		_notice = "Treinador: %s." % str(info.get("reason", "não foi possível treinar"))
	_close_service_dialog()
	_rebuild()
	_open_trainer_dialog()

# --- Novo gladiador ---------------------------------------------------------

## Apagar o save era o único botão da cidade que agia no primeiro clique, sem
## confirmação: um clique errado destruía o progresso. Agora confirma antes.
func _open_new_dialog() -> void:
	if _new_dialog != null:
		return
	var current := "nenhum gladiador salvo ainda"
	var p = GameState.player
	if p != null:
		current = "%s, nível %d, %d ouro" % [p.display_name, p.level, p.gold]
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_new_dialog = overlay
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_new_dialog())
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_DARK, 14, 30))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(470, 0)
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)
	root.add_child(_make_label("NOVO GLADIADOR", 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("Isto apaga o progresso salvo (%s) e começa do zero.\nNão há como desfazer." % current, 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	var confirm := Button.new()
	confirm.text = "APAGAR E COMEÇAR DE NOVO"
	confirm.custom_minimum_size = Vector2(250, 46)
	confirm.add_theme_font_size_override("font_size", 15)
	confirm.pressed.connect(_confirm_new_gladiator)
	_style_button(confirm, RED)
	row.add_child(confirm)
	var cancel := Button.new()
	cancel.text = "CANCELAR"
	cancel.custom_minimum_size = Vector2(130, 46)
	cancel.add_theme_font_size_override("font_size", 15)
	cancel.pressed.connect(_close_new_dialog)
	_style_button(cancel, Color("8f83b3"))
	row.add_child(cancel)

func _confirm_new_gladiator() -> void:
	_close_new_dialog()
	new_requested.emit()

func _close_new_dialog() -> void:
	if _new_dialog != null:
		_new_dialog.queue_free()
		_new_dialog = null

func _add_dialog_button(root: VBoxContainer, text_value: String, target: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(target)
	_style_button(button, Color("70b9e8"))
	root.add_child(button)

func _style_button(button: Button, color: Color) -> void:
	button.add_theme_color_override("font_color", Color("1a1420"))
	button.add_theme_color_override("font_hover_color", Color("1a1420"))
	button.add_theme_color_override("font_pressed_color", Color("1a1420"))
	button.add_theme_color_override("font_disabled_color", Color("b9aec2"))
	button.add_theme_stylebox_override("normal", _panel_style(color, 8, 14))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12), 8, 14))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.12), 8, 14))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("3a3346"), 8, 14))

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
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
