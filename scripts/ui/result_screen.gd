class_name ResultScreen
extends Control

## Tela de resultado: mostra um FightResult e deixa o jogador decidir o
## próximo passo. Se houver níveis pendentes, primeiro o jogador escolhe o
## treino (decisão de progressão); depois exibe as ações de campanha.
## Apenas mostra informação e encaminha decisões; não calcula regras.

signal action_requested(action: String)

const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")
const ItemGeneratorScript := preload("res://scripts/systems/item_generator.gd")
const PointsPanelScript := preload("res://scripts/ui/points_panel.gd")

const BACKGROUND := Color("14111c")
const PANEL := Color("272033")
const PANEL_DARK := Color("1d1726")
const GOLD := Color("f5c451")
const RED := Color("d95858")
const GREEN := Color("79cf7b")
const INK := Color("f7edf4")
const MUTED := Color("cdbfd5")
const DIM := Color("bbaec1")
const ABILITY := Color("e06bb5")

var _result
var _title: Label
var _body: VBoxContainer
var _rest_dialog: Control = null
## Aviso opcional (ex.: "Você está no torneio — Combate 2/4") mostrado no topo.
var notice: String = ""
## Painel modal "só pontos" (correção 1a) e diálogo de confirmação do abandono.
var _points_panel: Control = null
var _abandon_dialog: Control = null
## Contador para dar nome único a cada ficha de prêmio (o QA conta por prefixo).
var _loot_card_index: int = 0

func _ready() -> void:
	_build_interface()

func set_result(result) -> void:
	_result = result
	_render()

func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# MODAL: fundo escurecido (não opaco) — a arena continua visível por baixo.
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.74)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 16, 40))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(640, 0)
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)
	if notice != "":
		root.add_child(_make_label(notice, 15, Color("f5c451"), HORIZONTAL_ALIGNMENT_CENTER))
	_title = _make_label("", 32, INK, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_title)
	# O corpo rola sozinho quando o resumo passa da altura da caixa modal.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_body = VBoxContainer.new()
	_body.custom_minimum_size = Vector2(640, 0)
	_body.add_theme_constant_override("separation", 14)
	scroll.add_child(_body)

func _render() -> void:
	for child in _body.get_children():
		child.free()
	if _result == null:
		_title.text = "SEM RESULTADO"
		return
	_render_summary()

func _render_summary() -> void:
	_loot_card_index = 0
	var victory: bool = bool(_result.victory)
	_title.text = "VITÓRIA" if victory else "DERROTA"
	_title.add_theme_color_override("font_color", GREEN if victory else RED)
	var opponent := str(_result.opponent_name)
	if opponent == "":
		opponent = "o oponente"
	var lines: Array[String] = []
	var tournament: bool = bool(_result.tournament)
	if victory:
		var target_line := "[color=#cdbfd5]%s venceu em %d rodadas.[/color]" % [opponent, int(_result.rounds)]
		if bool(_result.boss):
			target_line = "[color=#f5c451]O CHEFE %s caiu![/color]" % opponent.to_upper()
		lines.append(target_line)
		if tournament:
			lines.append("[color=#f5c451]Prêmio desta luta: +%d de ouro[/color]  •  [color=#cdbfd5]+%d XP[/color]" % [int(_result.prize), int(_result.experience)])
			lines.append("[color=#bbaec1]Prêmio acumulado no torneio: %d.[/color]" % GameState.tournament_prize())
			lines.append("[color=#79cf7b]Você acorda curado para o próximo combate.[/color]")
			if bool(_result.campaign_cleared):
				lines.append("[color=#79cf7b]CAMPEÃO! O item do boss está na sua bolsa.[/color]")
		else:
			lines.append("[color=#79cf7b]+%d ouro[/color]  •  [color=#cdbfd5]+%d XP[/color]" % [int(_result.gold), int(_result.experience)])
			lines.append("[color=#d9a45b]SEQUÊNCIA: %d vitória(s) seguidas — +%d%% na recompensa[/color]" % [GameState.win_streak, EconomySystemScript.streak_bonus_percent(GameState.win_streak)])
			if GameState.player != null:
				lines.append("[color=#70b9e8]VIDA %d/%d  •  %d ouro[/color]" % [GameState.player.health, GameState.player.max_health, GameState.player.gold])
			lines.append("[color=#bbaec1]Perder zera a sequência. Descansar preserva o bônus.[/color]")
	else:
		lines.append("[color=#cdbfd5]%s venceu em %d rodadas.[/color]" % [opponent, int(_result.rounds)])
		if tournament:
			lines.append("[color=#d95858]Você foi eliminado do torneio. Perdeu %d do prêmio acumulado.[/color]" % int(_result.penalty))
			if int(_result.prize) > 0:
				lines.append("[color=#bbaec1]Recuperou %d de ouro do prêmio.[/color]" % int(_result.prize))
		elif bool(_result.campaign_lost):
			lines.append("[color=#d95858]A campanha termina aqui.[/color]")
		else:
			lines.append("[color=#bbaec1]Você perdeu %d de ouro e acordou curado para tentar de novo.[/color]" % int(_result.penalty))
	lines.append("")
	lines.append("[color=#cdbfd5]Golpes certeiros: %d    Críticos: %d[/color]" % [int(_result.hits), int(_result.criticals)])
	lines.append("[color=#cdbfd5]Dano causado: %d    Dano sofrido: %d[/color]" % [int(_result.damage_dealt), int(_result.damage_taken)])
	# Felicidade do público (item H): valor final e multiplicador de ouro.
	if bool(_result.quick_fight):
		lines.append("[color=#bbaec1]Público: o público nem viu a luta — recompensa ×1,0.[/color]")
	else:
		var mult_text := ("%.1f" % float(_result.crowd_multiplier)).replace(".", ",")
		lines.append("[color=#f5c451]Público: %d%% → recompensa ×%s[/color]" % [int(_result.crowd_happiness), mult_text])
	# RANK/KD (item I): variação de rank da luta, com aviso de promoção/rebaixa.
	if bool(_result.rank_change_known):
		var delta := int(_result.rank_delta)
		var sign_text := "+%d" % delta if delta >= 0 else "%d" % delta
		lines.append("[color=#f5c451]RANK: %s — %s pts (%s)[/color]" % [str(_result.rank_title), int(_result.rank_points), sign_text])
		if bool(_result.rank_promoted):
			lines.append("[color=#79cf7b]PROMOVIDO de faixa![/color]")
		elif bool(_result.rank_demoted):
			lines.append("[color=#d95858]Você foi REBAIXADO de faixa.[/color]")
	# APOSTA (item 5): o que a aposta rendeu (ou queimou) nesta luta.
	if bool(_result.bet_active):
		if bool(_result.bet_won):
			lines.append("[color=#79cf7b]APOSTA: %d ouro em odd ×%.2f → recebeu %d ouro.[/color]" % [int(_result.bet_stake), float(_result.bet_odd), int(_result.bet_payout)])
		else:
			lines.append("[color=#d95858]APOSTA: %d ouro em odd ×%.2f → perdeu a aposta.[/color]" % [int(_result.bet_stake), float(_result.bet_odd)])
	# FERIMENTO (item 2): sequela NOVA que sobrevive à luta (o médico ou a poção cura).
	if bool(_result.injured):
		var injury: Dictionary = _result.injury
		lines.append("[color=#e08a8a]FERIMENTO — %s. Passe no MÉDICO (ou use uma poção de ferimento).[/color]" % str(injury.get("label", "ferido")))
	var extra_lines := (1 if bool(_result.bet_active) else 0) + (1 if bool(_result.injured) else 0)
	var summary := RichTextLabel.new()
	summary.bbcode_enabled = true
	summary.custom_minimum_size = Vector2(0, (170 if not _result.loot.is_empty() else 200) + extra_lines * 24)
	summary.add_theme_font_size_override("normal_font_size", 17)
	summary.add_theme_stylebox_override("normal", _panel_style(PANEL_DARK, 10, 20))
	summary.text = "\n".join(lines)
	_body.add_child(summary)
	# Prêmios de item: o torneio dava item sem mostrar nada (o único era equipado
	# em silêncio). Aqui vai a ficha do que entrou na bolsa.
	if victory and not _result.loot.is_empty():
		_body.add_child(_make_label("PRÊMIO DE ITEM — já está na sua bolsa", 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
		for entry: Dictionary in _result.loot:
			_body.add_child(_make_item_card(entry, _loot_card_index))
			_loot_card_index += 1
	# Subir de nível agora dá PONTOS de atributo (4 por nível), distribuídos num
	# painel MODAL "só pontos" por cima do resultado (etapa 6, correção 1a): nada
	# de trocar de tela — no torneio isso reiniciava a rodada.
	if GameState.player != null and GameState.player.pending_points > 0:
		_body.add_child(_make_label("NÍVEL %d — você tem %d ponto(s) de atributo para distribuir." % [GameState.player.level, GameState.player.pending_points], 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
		_add_action_button("DISTRIBUIR PONTOS", ABILITY, "points")
	if tournament:
		if victory and bool(_result.campaign_cleared):
			_add_action_button("CONCLUIR TORNEIO", GOLD, "end_victory")
		elif victory:
			_add_action_button("PRÓXIMO COMBATE", GREEN, "next")
		else:
			_add_action_button("ACEITAR A DERROTA", RED, "end_defeat")
		# Sair do torneio é decisão EXPLÍCITA (etapa 6, correção 1c): a cidade está
		# proibida no meio da disputa, então o abandono tem botão próprio e confirma.
		_add_action_button("ABANDONAR TORNEIO", Color("8f83b3"), "abandon")
	elif victory:
		_add_action_button("IR À LOJA", GOLD, "shop")
		_add_rest_button()
		_add_action_button("SEGUIR", GREEN, "next")
		_add_action_button("ACAMPAMENTO", Color("8f83b3"), "camp")
	else:
		_add_action_button("TENTAR NOVAMENTE", GREEN, "retry")
		_add_action_button("ACAMPAMENTO", Color("8f83b3"), "camp")

func _add_action_button(text_value: String, color: Color, action: String) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 16)
	# "points"/"abandon" abrem os modais LOCAIS desta tela (não trocam de tela);
	# o resto é roteado pelo app.gd.
	if action == "points":
		button.pressed.connect(_open_points_modal)
	elif action == "abandon":
		button.pressed.connect(_open_abandon_dialog)
	else:
		button.pressed.connect(action_requested.emit.bind(action))
	_style_button(button, color)
	_body.add_child(button)

## Botão "DESCANSAR (X ouro)": só descansa (não avança). O avanço é feito pelo
## botão SEGUIR já existente.
func _add_rest_button() -> void:
	if GameState.player == null:
		return
	var missing: int = int(GameState.player.max_health) - int(GameState.player.health)
	if missing <= 0:
		return
	var button := Button.new()
	button.text = "DESCANSAR (%d ouro)" % GameState.full_rest_cost()
	button.custom_minimum_size = Vector2(0, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(_open_rest_dialog)
	_style_button(button, Color("70b9e8"))
	_body.add_child(button)

func _open_rest_dialog() -> void:
	if GameState.player == null or _rest_dialog != null:
		return
	var p = GameState.player
	var missing := maxi(0, p.max_health - p.health)
	if missing <= 0:
		return
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
	root.custom_minimum_size = Vector2(440, 0)
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	root.add_child(_make_label("DESCANSAR", 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("VIDA  %d / %d   (faltam %d)" % [p.health, p.max_health, missing], 16, INK, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("Descanso completo custa %d ouro. Você tem %d." % [full_cost, p.gold], 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	if p.gold < full_cost:
		root.add_child(_make_label("Sem ouro suficiente: recupera apenas o que o ouro permitir.", 13, Color("d9a45b"), HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	var rest_button := Button.new()
	rest_button.text = "DESCANSAR (%d ouro)" % full_cost
	rest_button.custom_minimum_size = Vector2(190, 46)
	rest_button.add_theme_font_size_override("font_size", 15)
	rest_button.pressed.connect(_confirm_rest)
	_style_button(rest_button, GREEN)
	row.add_child(rest_button)
	var cancel := Button.new()
	cancel.text = "CANCELAR"
	cancel.custom_minimum_size = Vector2(120, 46)
	cancel.add_theme_font_size_override("font_size", 15)
	cancel.pressed.connect(_close_rest_dialog)
	_style_button(cancel, Color("8f83b3"))
	row.add_child(cancel)

func _confirm_rest() -> void:
	if GameState.player == null:
		return
	GameState.rest()
	_close_rest_dialog()
	_render.call_deferred()

func _close_rest_dialog() -> void:
	if _rest_dialog != null:
		_rest_dialog.queue_free()
		_rest_dialog = null

# --- Pontos (modal "só pontos") e abandono do torneio ----------------------

## Abre o painel "só pontos" POR CIMA do resultado (correção 1a). Distribuir os
## pontos NÃO sai desta tela — o torneio continua na mesma rodada.
func _open_points_modal() -> void:
	if _points_panel != null:
		return
	var panel = PointsPanelScript.new()
	add_child(panel)
	_points_panel = panel
	panel.closed.connect(_on_points_closed)

func _on_points_closed() -> void:
	if _points_panel != null:
		_points_panel.queue_free()
		_points_panel = null
	# Re-renderiza: sem pontos pendentes, o botão DISTRIBUIR PONTOS some.
	_render.call_deferred()

## Confirmação explícita do abandono (correção 1c): só o CONFIRMAR emite a ação.
func _open_abandon_dialog() -> void:
	if _abandon_dialog != null:
		return
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_abandon_dialog = overlay
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
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
	root.add_child(_make_label("ABANDONAR TORNEIO", 26, RED, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(_make_label("Você vai sair do torneio agora. Isto conta como DERROTA no seu KD,\nperde o prêmio acumulado (%d ouro) e devolve você à cidade." % GameState.tournament_prize(), 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	var confirm := Button.new()
	confirm.text = "CONFIRMAR ABANDONO"
	confirm.custom_minimum_size = Vector2(230, 46)
	confirm.add_theme_font_size_override("font_size", 15)
	confirm.pressed.connect(_confirm_abandon)
	_style_button(confirm, RED)
	row.add_child(confirm)
	var cancel := Button.new()
	cancel.text = "VOLTAR"
	cancel.custom_minimum_size = Vector2(130, 46)
	cancel.add_theme_font_size_override("font_size", 15)
	cancel.pressed.connect(_close_abandon_dialog)
	_style_button(cancel, Color("8f83b3"))
	row.add_child(cancel)

func _confirm_abandon() -> void:
	_close_abandon_dialog()
	action_requested.emit("abandon")

func _close_abandon_dialog() -> void:
	if _abandon_dialog != null:
		_abandon_dialog.queue_free()
		_abandon_dialog = null

## Ficha compacta do item ganho: nome, raridade, nível e bônus.
func _make_item_card(item: Dictionary, index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	# Nome único por ficha (prefixo contado pelo QA): nomes repetidos o Godot
	# renomeia para "@Node@2".
	panel.name = "itemcard_%d" % index
	var rarity_color := Color(str(item.get("rarity_color", "f5c451")))
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_DARK, 8, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var icon := _icon_rect(item, 30)
	if icon != null:
		row.add_child(icon)
	var line := RichTextLabel.new()
	line.bbcode_enabled = true
	line.fit_content = true
	line.scroll_active = false
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_theme_font_size_override("normal_font_size", 15)
	line.add_theme_color_override("default_color", rarity_color)
	var rarity_tag := str(item.get("rarity", "Comum"))
	if bool(item.get("unique", false)):
		rarity_tag += "   •   ITEM ÚNICO"
	line.text = "%s   [color=#bbaec1]%s • nível %d[/color]\n[color=#79cf7b]%s[/color]" % [
		str(item.get("display_name", "Item")), rarity_tag, int(item.get("level", 1)), _bonus_text(item),
	]
	row.add_child(line)
	return panel

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
	if parts.is_empty():
		return "sem bônus"
	return "  ".join(parts)

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
