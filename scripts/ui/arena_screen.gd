class_name ArenaScreen
extends Control

## Tela de arena: mostra a luta, coleta estatísticas e emite fight_finished(result)
## quando termina. Regras de dano/IA ficam no CombatResolver; economia no EconomySystem.

signal fight_finished(result)

const BACKGROUND := Color("14111c")
const PANEL := Color("272033")
const PANEL_LIGHT := Color("382d47")
const GOLD := Color("f5c451")
const RED := Color("d95858")
const GREEN := Color("79cf7b")
const INK := Color("f7edf4")
const CombatResolverScript := preload("res://scripts/systems/combat_resolver.gd")
const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")
const FightResultScript := preload("res://scripts/models/fight_result.gd")
const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")
const SLOT_ORDER := ["weapon", "armor", "helmet", "gloves", "boots", "belt"]
const SLOT_TITLES := {
	"weapon": "ARMA", "armor": "ARMADURA", "helmet": "CAPACETE",
	"gloves": "LUVAS", "boots": "BOTAS", "belt": "CINTO",
}

var foe
var round_number: int = 1
var fight_active := true
var log_lines: Array[String] = []
var distance: int = 3
## Posição de cada lutador na pista 0..6 (muralha atrás de cada um).
var player_pos: int = 1
var enemy_pos: int = 4

var _total_hits := 0
var _criticals := 0
var _damage_dealt := 0
var _damage_taken := 0
var _enemy_moves := 0

var status_label: Label
var distance_label: Label
var distance_track: HBoxContainer
var hero_card: VBoxContainer
var foe_card: VBoxContainer
var combat_log: RichTextLabel
var action_row: HBoxContainer
var _action_buttons: Dictionary = {}
var _items: Array = []
var _inspector: Control = null

## --- Camada visual (sprites) ---
const SPRITE_BASE := "res://assets/sprites/"
const GROUP_W := 190
const GROUP_H := 220
const SPRITE_DISPLAY := 160
const FIGHTER_FEET_RATIO := 0.9

var _stage: Control
var _stage_bg: TextureRect
var _hero_group: Control
var _enemy_group: Control
var _hero_sprite: TextureRect
var _enemy_sprite: TextureRect
var _hero_bar: ProgressBar
var _enemy_bar: ProgressBar
var _hero_hp_label: Label
var _enemy_hp_label: Label
var _hero_tag: Label
var _enemy_tag: Label
var _hero_tex: Dictionary = {}
var _enemy_tex: Dictionary = {}
var _hero_moving := false
var _enemy_moving := false
var _hero_tween: Tween
var _enemy_tween: Tween
var _hero_pose := "idle"
var _enemy_pose := "idle"

func _ready() -> void:
	_items = ContentRepositoryScript.load_items()
	_hero_tex = _load_pose_set("hero")
	_enemy_tex = _load_pose_set("enemies")
	build_interface()
	start_new_fight()

func build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKGROUND
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 7)
	margin.add_child(root)
	root.add_child(make_label("ARENA DOS GLADIADORES", 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	status_label = make_label("", 15, Color("cdbfd5"), HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(status_label)
	# Palco da luta: cenário de fundo + lutadores em sprite que andam nas células.
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(0, 250)
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.clip_contents = true
	root.add_child(_stage)
	_stage_bg = TextureRect.new()
	_stage_bg.texture = _load_sprite("arena", "arena_background")
	if _stage_bg.texture != null:
		_stage_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_stage_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_stage_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_stage_bg)
	_hero_group = _make_fighter_group(true)
	_enemy_group = _make_fighter_group(false)
	_stage.add_child(_hero_group)
	_stage.add_child(_enemy_group)
	_stage.resized.connect(_position_fighters)
	distance_label = make_label("", 13, Color("bbaec1"), HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(distance_label)
	distance_track = HBoxContainer.new()
	distance_track.add_theme_constant_override("separation", 2)
	distance_track.custom_minimum_size = Vector2(0, 20)
	root.add_child(distance_track)
	combat_log = RichTextLabel.new()
	combat_log.bbcode_enabled = true
	combat_log.custom_minimum_size.y = 108
	combat_log.add_theme_font_size_override("normal_font_size", 15)
	combat_log.add_theme_color_override("default_color", INK)
	combat_log.add_theme_stylebox_override("normal", panel_style(PANEL, 10))
	root.add_child(combat_log)
	action_row = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 12)
	root.add_child(action_row)
	for data in [["Atacar", "attack", GOLD], ["Golpe arriscado", "risk", RED], ["Defender", "defend", Color("70b9e8")], ["Avançar", "advance", Color("79cf7b")], ["Recuar", "retreat", Color("d9a45b")]]:
		var button := make_button(str(data[0]), data[2])
		button.pressed.connect(player_action.bind(str(data[1])))
		_action_buttons[str(data[1])] = button
		action_row.add_child(button)
	var skill: Dictionary = GameState.player_skill()
	if not skill.is_empty():
		var skill_button := make_button(str(skill.get("display_name", "Habilidade")), Color("e06bb5"))
		skill_button.pressed.connect(player_action.bind("skill"))
		_action_buttons["skill"] = skill_button
		action_row.add_child(skill_button)

func start_new_fight() -> void:
	foe = GameState.build_current_foe()
	if foe == null:
		fight_active = false
		log_lines = ["[color=#d95858]Não há inimigo configurado para esta arena.[/color]"]
		refresh()
		return
	GameState.current_enemy = foe
	fight_active = true
	round_number = 1
	_total_hits = 0
	_criticals = 0
	_damage_dealt = 0
	_damage_taken = 0
	_enemy_moves = 0
	distance = CombatResolverScript.ARENA_START_RANGE
	player_pos = 1
	enemy_pos = 1 + distance
	log_lines = ["[color=#f5c451]%s — %s entra na arena! (distância %d)[/color]" % [GameState.current_stage_name(), foe.display_name, distance]]
	set_actions_enabled(true)
	_apply_action_states()
	DebugLog.info("Luta iniciada: %s contra %s (arena %d/%d)." % [GameState.player.display_name, foe.display_name, GameState.arena_number(), GameState.stage_total()])
	refresh()
	# Reaplica as posições depois do layout final (tamanho real do palco).
	_position_fighters.call_deferred()

func player_action(kind: String) -> void:
	if not fight_active:
		return
	set_actions_enabled(false)
	var defense_bonus := 0
	match kind:
		"advance":
			player_pos = mini(enemy_pos - 1, player_pos + 1)
			_sync_distance()
			_hero_moving = true
			log_lines.append("[color=#79cf7b]%s avança (distância %d).[/color]" % [GameState.player.display_name, distance])
		"retreat":
			player_pos = maxi(0, player_pos - 1)
			_sync_distance()
			_hero_moving = true
			log_lines.append("[color=#d9a45b]%s recua (distância %d).[/color]" % [GameState.player.display_name, distance])
		"attack":
			_player_attack(1.0, 1.0, "%s ataca" % GameState.player.display_name)
		"defend":
			defense_bonus = CombatResolverScript.DEFEND_GUARD_BONUS
			_play_pose(true, "defend", 0.5)
			log_lines.append("[color=#70b9e8]%s assume uma guarda firme (+%d defesa).[/color]" % [GameState.player.display_name, defense_bonus])
		"risk":
			_player_attack(1.65, 0.58, "%s tenta um golpe arriscado" % GameState.player.display_name)
		"skill":
			var skill_action: Dictionary = GameState.player_skill()
			if not skill_action.is_empty():
				_player_attack(float(skill_action.get("multiplier", 1.0)), float(skill_action.get("accuracy", 1.0)), "%s usa %s" % [GameState.player.display_name, str(skill_action.get("display_name", "habilidade"))])
	refresh()
	if foe.is_defeated():
		win_fight()
		return
	await get_tree().create_timer(0.45).timeout
	enemy_turn(defense_bonus)

func enemy_turn(defense_bonus: int) -> void:
	if not fight_active:
		return
	if foe.enemy_kind == "ranged":
		_enemy_moves += 1
		if distance < CombatResolverScript.ENEMY_RANGED_RETREAT and enemy_pos < CombatResolverScript.ARENA_MAX_RANGE:
			enemy_pos = mini(CombatResolverScript.ARENA_MAX_RANGE, enemy_pos + 1)
			_sync_distance()
			_enemy_moving = true
			log_lines.append("[color=#d9a45b]%s recua e mantém distância (distância %d).[/color]" % [foe.display_name, distance])
		else:
			_enemy_attack_or_special(defense_bonus, {"kind": "ranged"})
	else:
		var reach: int = int(foe.enemy_reach) if int(foe.enemy_reach) > 0 else CombatResolverScript.ENEMY_REACH
		if distance > reach:
			enemy_pos = maxi(player_pos + 1, enemy_pos - 1)
			_sync_distance()
			_enemy_moving = true
			log_lines.append("[color=#d95858]%s se aproxima (distância %d).[/color]" % [foe.display_name, distance])
		else:
			_enemy_moves += 1
			_enemy_attack_or_special(defense_bonus, {"kind": "melee", "reach": reach})
	round_number += 1
	refresh()
	if GameState.player.is_defeated():
		lose_fight()
	else:
		set_actions_enabled(true)
		_apply_action_states()

func _enemy_attack_or_special(defense_bonus: int, weapon: Dictionary) -> void:
	var action: Dictionary = CombatResolverScript.choose_enemy_action()
	var multiplier := float(action.multiplier)
	var accuracy := float(action.accuracy)
	var message := "%s contra-ataca" % foe.display_name
	var special: Dictionary = GameState.enemy_special(foe.id)
	if not special.is_empty() and _enemy_moves % 3 == 0:
		message = "%s usa %s!" % [foe.display_name, str(special.get("display_name", "golpe especial"))]
		multiplier = float(special.get("multiplier", 1.6))
		accuracy = float(special.get("accuracy", 0.7))
	elif str(action.kind) == "brutal":
		message = "%s desfere um golpe brutal" % foe.display_name
	_play_pose(false, "attack", 0.35)
	var result: Dictionary = CombatResolverScript.resolve_positional_attack(foe, GameState.player, weapon, distance, multiplier, accuracy, defense_bonus)
	if bool(result.get("out_of_range", false)):
		log_lines.append("[color=#bbaec1]%s tenta atacar, mas está longe demais (distância %d).[/color]" % [foe.display_name, distance])
		return
	_apply_combat_result(foe, GameState.player, message, result)
	if bool(result.hit) and int(result.damage) > 0:
		_play_pose(true, "hit", 0.3)

func _apply_action_states() -> void:
	var can_attack := _weapon_can_attack()
	for kind: Variant in _action_buttons.keys():
		var button: Button = _action_buttons[kind]
		match str(kind):
			"attack", "risk", "skill":
				button.disabled = not can_attack
			"advance":
				button.disabled = distance <= CombatResolverScript.ARENA_MIN_RANGE
			"retreat":
				button.disabled = player_pos <= 0
			_:
				button.disabled = false

func _weapon_can_attack() -> bool:
	var weapon := GameState.player_weapon()
	if weapon.is_empty():
		weapon = {"kind": "melee", "reach": 1}
	return CombatResolverScript.can_attack_at(distance, weapon)

func _sync_distance() -> void:
	distance = maxi(CombatResolverScript.ARENA_MIN_RANGE, enemy_pos - player_pos)

func _make_legend_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var player_swatch := ColorRect.new()
	player_swatch.color = GREEN
	player_swatch.custom_minimum_size = Vector2(12, 12)
	row.add_child(player_swatch)
	row.add_child(make_label("você", 13, Color("cdbfd5")))
	var enemy_swatch := ColorRect.new()
	enemy_swatch.color = RED
	enemy_swatch.custom_minimum_size = Vector2(12, 12)
	row.add_child(enemy_swatch)
	row.add_child(make_label("inimigo", 13, Color("cdbfd5")))
	row.add_child(make_label("▐ muralha 1–%d" % CombatResolverScript.ARENA_MAX_RANGE, 13, Color("6b6078")))
	return row

func _update_track() -> void:
	for child in distance_track.get_children():
		child.queue_free()
	var wall_left := make_label("▌", 20, Color("6b6078"), HORIZONTAL_ALIGNMENT_CENTER)
	wall_left.custom_minimum_size.y = 24
	distance_track.add_child(wall_left)
	for i in CombatResolverScript.ARENA_MAX_RANGE + 1:
		var cell := make_label("", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		cell.custom_minimum_size.y = 22
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == player_pos:
			cell.text = "●"
			cell.add_theme_color_override("font_color", GREEN)
		elif i == enemy_pos:
			cell.text = "●"
			cell.add_theme_color_override("font_color", RED)
			cell.mouse_filter = Control.MOUSE_FILTER_STOP
			cell.gui_input.connect(_on_enemy_marker_input)
		else:
			cell.text = "·"
			cell.add_theme_color_override("font_color", Color("4a4154"))
		distance_track.add_child(cell)
	var wall_right := make_label("▐", 20, Color("6b6078"), HORIZONTAL_ALIGNMENT_CENTER)
	wall_right.custom_minimum_size.y = 24
	distance_track.add_child(wall_right)

func _player_attack(multiplier: float, accuracy: float, message: String) -> void:
	var weapon := GameState.player_weapon()
	if weapon.is_empty():
		weapon = {"kind": "melee", "reach": 1}
	_play_pose(true, "attack", 0.35)
	var result: Dictionary = CombatResolverScript.resolve_positional_attack(GameState.player, foe, weapon, distance, multiplier, accuracy, 0)
	if bool(result.get("out_of_range", false)):
		log_lines.append("[color=#bbaec1]%s, mas está longe demais (distância %d).[/color]" % [message, distance])
		return
	_apply_combat_result(GameState.player, foe, message, result)
	if bool(result.hit) and int(result.damage) > 0:
		_play_pose(false, "hit", 0.3)

func _apply_combat_result(attacker, target, message: String, result: Dictionary) -> void:
	if not bool(result.hit):
		log_lines.append("[color=#bbaec1]%s, mas erra![/color]" % message)
		return
	var is_player_attack: bool = attacker == GameState.player
	_total_hits += 1
	if bool(result.critical):
		_criticals += 1
	if is_player_attack:
		_damage_dealt += int(result.damage)
	else:
		_damage_taken += int(result.damage)
	# Dano flutuante sobre quem levou o golpe.
	_spawn_damage_text(target == GameState.player, int(result.damage), bool(result.critical))
	var tag := " [color=#f5c451]CRÍTICO![/color]" if bool(result.critical) else ""
	log_lines.append("%s e causa [color=#d95858]%d de dano[/color].%s" % [message, int(result.damage), tag])

func win_fight() -> void:
	fight_active = false
	set_actions_enabled(false)
	var was_boss: bool = GameState.is_boss_stage()
	var rewards_spec: Dictionary = EconomySystemScript.fight_rewards(GameState.player.level)
	var rewards: Dictionary = GameState.on_victory(int(rewards_spec.gold), int(rewards_spec.experience))
	var result = FightResultScript.new(true, round_number)
	_fill_result(result, int(rewards.gold), int(rewards.experience))
	result.leveled_up = bool(rewards.leveled_up)
	result.boss = was_boss
	result.campaign_cleared = bool(rewards.campaign_cleared)
	result.tournament = bool(rewards.tournament)
	result.prize = int(rewards.prize)
	# Prêmios de item (torneio): a tela de resultado mostra a ficha de cada um.
	for entry: Variant in rewards.get("loot", []):
		if entry is Dictionary:
			result.loot.append(entry)
	GameState.persist_if_free()
	DebugLog.info("Vitória na arena %d/%d." % [GameState.arena_number(), GameState.stage_total()])
	fight_finished.emit(result)

func lose_fight() -> void:
	fight_active = false
	set_actions_enabled(false)
	var outcome: Dictionary = GameState.on_defeat()
	var result = FightResultScript.new(false, round_number)
	_fill_result(result, 0, 0)
	result.boss = bool(outcome.boss)
	result.campaign_lost = bool(outcome.campaign_lost)
	result.penalty = int(outcome.penalty)
	result.tournament = bool(outcome.tournament)
	result.prize = int(outcome.get("kept", 0))
	GameState.persist_if_free()
	DebugLog.info("Derrota. Torneio perdido: %s." % result.campaign_lost)
	fight_finished.emit(result)

func _fill_result(result, gold_value: int, xp_value: int) -> void:
	result.hits = _total_hits
	result.criticals = _criticals
	result.damage_dealt = _damage_dealt
	result.damage_taken = _damage_taken
	result.gold = gold_value
	result.experience = xp_value
	if foe != null:
		result.opponent_name = foe.display_name

func refresh() -> void:
	status_label.text = "NÍVEL %d  •  %d XP  •  %d OURO  •  RODADA %d" % [GameState.player.level, GameState.player.experience, GameState.player.gold, round_number]
	distance_label.text = "DISTÂNCIA: %d" % distance
	_update_track()
	_position_fighters()
	combat_log.text = "\n".join(log_lines.slice(maxi(0, log_lines.size() - 6)))
	combat_log.scroll_to_line(combat_log.get_line_count())

func fill_card(card: VBoxContainer, fighter, is_hero: bool) -> void:
	for child in card.get_children():
		child.queue_free()
	var tint := GREEN if is_hero else RED
	card.add_child(make_label(fighter.display_name.to_upper(), 23, tint))
	card.add_child(make_label("Nível %d" % fighter.level, 15, Color("cdbfd5")))
	card.add_child(make_label("VIDA  %d / %d" % [fighter.health, fighter.max_health], 18, INK))
	var bar := ProgressBar.new()
	bar.max_value = fighter.max_health
	bar.value = fighter.health
	bar.show_percentage = false
	bar.custom_minimum_size.y = 13
	bar.add_theme_stylebox_override("background", panel_style(PANEL_LIGHT, 5))
	bar.add_theme_stylebox_override("fill", panel_style(tint, 5))
	card.add_child(bar)
	card.add_child(make_label("ATQ %d   DEF %d   SORTE %d" % [fighter.attack, fighter.defense, fighter.luck], 15, Color("cdbfd5")))
	card.add_child(make_label("Arma: %s" % _fighter_weapon_name(fighter), 13, Color("bbaec1")))
	if not is_hero:
		var details := Button.new()
		details.text = "VER DETALHES ▸"
		details.custom_minimum_size.y = 26
		details.add_theme_font_size_override("font_size", 12)
		details.add_theme_color_override("font_color", Color("1a1420"))
		details.add_theme_stylebox_override("normal", panel_style(Color("d9a45b"), 6))
		details.add_theme_stylebox_override("hover", panel_style(Color("d9a45b").lightened(0.12), 6))
		details.pressed.connect(_open_enemy_inspect)
		card.add_child(details)
	for child in card.get_children():
		if child is Button:
			continue
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _fighter_weapon_name(fighter) -> String:
	var weapon_id: String = fighter.equipped_id("weapon")
	if weapon_id != "":
		var found := ContentRepositoryScript.find_item(_items, weapon_id)
		if fighter == GameState.player:
			found = GameState.item_data(weapon_id)
		if not found.is_empty():
			return str(found.get("display_name", weapon_id.replace("_", " ").capitalize()))
		return weapon_id.replace("_", " ").capitalize()
	if fighter.weapon_label != "":
		return fighter.weapon_label
	return "Punhos"

func set_actions_enabled(enabled: bool) -> void:
	for child in action_row.get_children():
		if child is Button:
			child.disabled = not enabled

func make_card() -> VBoxContainer:
	var card := VBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 5)
	return card

func panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

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
	button.custom_minimum_size = Vector2(150, 46)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("1a1420"))
	button.add_theme_stylebox_override("normal", panel_style(color, 8))
	button.add_theme_stylebox_override("hover", panel_style(color.lightened(0.12), 8))
	return button

# --- Camada visual (sprites do palco) ---------------------------------------

func _load_sprite(folder: String, file_name: String) -> Texture2D:
	for ext: String in ["png", "jpeg", "jpg"]:
		var path := "%s%s/%s.%s" % [SPRITE_BASE, folder, file_name, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null

func _load_pose_set(folder: String) -> Dictionary:
	var base := "enemy" if folder == "enemies" else folder
	return {
		"idle": _load_sprite(folder, base),
		"attack": _load_sprite(folder, base + "_attack"),
		"hit": _load_sprite(folder, base + "_hit"),
		"defend": _load_sprite(folder, base + "_defend"),
	}

## Cria o "grupo" de um lutador (rótulo + barra + sprite) dentro do palco.
func _make_fighter_group(is_hero: bool) -> Control:
	var group := Control.new()
	group.custom_minimum_size = Vector2(GROUP_W, GROUP_H)
	var sprite := TextureRect.new()
	sprite.custom_minimum_size = Vector2(SPRITE_DISPLAY, SPRITE_DISPLAY)
	sprite.position = Vector2((GROUP_W - SPRITE_DISPLAY) * 0.5, GROUP_H - SPRITE_DISPLAY - 2.0)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(sprite)
	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(118, 12)
	bar.position = Vector2((GROUP_W - 118) * 0.5, 6)
	bar.add_theme_stylebox_override("background", panel_style(PANEL_LIGHT, 4))
	bar.add_theme_stylebox_override("fill", panel_style(GREEN if is_hero else RED, 4))
	group.add_child(bar)
	# Número de vida sobre a barra (ex.: 82/82)
	var hp_text := make_label("", 11, Color("f7edf4"), HORIZONTAL_ALIGNMENT_CENTER)
	hp_text.custom_minimum_size = Vector2(118, 14)
	hp_text.position = Vector2((GROUP_W - 118) * 0.5, 4)
	hp_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	hp_text.add_theme_constant_override("shadow_offset_x", 1)
	hp_text.add_theme_constant_override("shadow_offset_y", 1)
	hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(hp_text)
	var tag := make_label("", 12, Color("f7edf4"), HORIZONTAL_ALIGNMENT_CENTER)
	tag.custom_minimum_size = Vector2(GROUP_W, 18)
	tag.position = Vector2(0, 24)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(tag)
	if is_hero:
		_hero_sprite = sprite
		_hero_bar = bar
		_hero_hp_label = hp_text
		_hero_tag = tag
		_hero_group = group
	else:
		_enemy_sprite = sprite
		_enemy_bar = bar
		_enemy_hp_label = hp_text
		_enemy_tag = tag
		_enemy_group = group
		sprite.flip_h = true  # inimigo olha para a esquerda (herói está à esquerda)
		sprite.mouse_filter = Control.MOUSE_FILTER_STOP
		sprite.gui_input.connect(_on_enemy_marker_input)
	return group

## Posiciona os lutadores nas células do palco e atualiza barras/rótulos/poses.
func _position_fighters() -> void:
	if _stage == null or foe == null:
		return
	var w := maxf(_stage.size.x, 400.0)
	var h := maxf(_stage.size.y, 200.0)
	var foot_y := h * FIGHTER_FEET_RATIO
	var left := 44.0
	var right := w - 44.0
	var max_cell := float(CombatResolverScript.ARENA_MAX_RANGE)
	var hero_x := lerpf(left, right, float(player_pos) / max_cell)
	var enemy_x := lerpf(left, right, float(enemy_pos) / max_cell)
	var hero_target := Vector2(hero_x - GROUP_W * 0.5, foot_y - GROUP_H)
	var enemy_target := Vector2(enemy_x - GROUP_W * 0.5, foot_y - GROUP_H)
	_move_fighter(_hero_group, hero_target, _hero_moving)
	_move_fighter(_enemy_group, enemy_target, _enemy_moving)
	_hero_moving = false
	_enemy_moving = false
	_update_fighter_visuals(true)
	_update_fighter_visuals(false)

func _move_fighter(group: Control, target: Vector2, moving: bool) -> void:
	if moving:
		var tween := create_tween()
		tween.tween_property(group, "position", target, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		group.position = target

func _update_fighter_visuals(is_hero: bool) -> void:
	var fighter = GameState.player if is_hero else foe
	if fighter == null:
		return
	var tex: Dictionary = _hero_tex if is_hero else _enemy_tex
	var sprite := _hero_sprite if is_hero else _enemy_sprite
	var bar := _hero_bar if is_hero else _enemy_bar
	var hp_label := _hero_hp_label if is_hero else _enemy_hp_label
	var tag := _hero_tag if is_hero else _enemy_tag
	var pose := _hero_pose if is_hero else _enemy_pose
	var texture: Texture2D = tex.get(pose, {}) if tex.has(pose) else null
	if texture == null:
		texture = tex.get("idle", null)
	if texture != null:
		sprite.texture = texture
	if bar.max_value != fighter.max_health:
		bar.max_value = float(fighter.max_health)
	bar.value = float(fighter.health)
	bar.add_theme_stylebox_override("fill", panel_style(GREEN if is_hero else RED, 4))
	hp_label.text = "%d/%d" % [int(fighter.health), int(fighter.max_health)]
	if is_hero:
		tag.text = "%s  •  Nv %d" % [GameState.player.display_name, GameState.player.level]
	else:
		tag.text = "%s  •  Nv %d" % [foe.display_name, foe.level]

## Número de dano flutuante acima do lutador atingido ("life hit").
func _spawn_damage_text(is_hero: bool, amount: int, critical: bool) -> void:
	if _stage == null or amount <= 0:
		return
	var group := _hero_group if is_hero else _enemy_group
	if group == null:
		return
	var color := Color("ffd54a") if critical else Color("ff6b6b")
	var size := 23 if critical else 18
	var label := make_label("-%d" % amount, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(90, 0)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cx := group.position.x + GROUP_W * 0.5
	var cy := group.position.y + GROUP_H - SPRITE_DISPLAY * 0.55
	label.position = Vector2(cx - 45.0, cy)
	_stage.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -46), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)

## Troca a pose (ataque/dano/defesa) e volta ao repouso depois.
func _play_pose(is_hero: bool, pose: String, duration: float) -> void:
	if is_hero:
		_hero_pose = pose
	else:
		_enemy_pose = pose
	_update_fighter_visuals(is_hero)
	var tween := create_tween()
	tween.tween_interval(maxf(0.05, duration))
	tween.tween_callback(_revert_pose.bind(is_hero, pose))

func _revert_pose(is_hero: bool, pose: String) -> void:
	if is_hero and _hero_pose == pose:
		_hero_pose = "idle"
		_update_fighter_visuals(true)
	elif not is_hero and _enemy_pose == pose:
		_enemy_pose = "idle"
		_update_fighter_visuals(false)

# --- Inspeção do inimigo (clicar no card ou no ●) ---------------------------
func _on_foe_card_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_enemy_inspect()

func _on_enemy_marker_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_enemy_inspect()

func _close_enemy_inspect() -> void:
	if _inspector != null:
		_inspector.queue_free()
		_inspector = null

## Painel com todos os status e o equipamento do inimigo atual.
func _open_enemy_inspect() -> void:
	if foe == null or _inspector != null:
		return
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_inspector = overlay
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_enemy_inspect())
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style(PANEL, 14))
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(440, 0)
	root.add_theme_constant_override("separation", 9)
	panel.add_child(root)
	root.add_child(make_label(foe.display_name.to_upper(), 25, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(make_label(_enemy_kind_line(), 14, Color("bbaec1"), HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(make_label("Nível %d   •   %s   •   Recompensa ×%s" % [foe.level, _tier_badge(), str(foe.reward_multiplier)], 14, Color("bbaec1"), HORIZONTAL_ALIGNMENT_CENTER))
	var bar := ProgressBar.new()
	bar.max_value = foe.max_health
	bar.value = foe.health
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	bar.add_theme_stylebox_override("background", panel_style(PANEL_LIGHT, 5))
	bar.add_theme_stylebox_override("fill", panel_style(RED, 5))
	root.add_child(bar)
	root.add_child(make_label("VIDA  %d / %d" % [foe.health, foe.max_health], 16, INK, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(make_label("ATQ %d    DEF %d    SORTE %d" % [foe.attack, foe.defense, foe.luck], 17, INK, HORIZONTAL_ALIGNMENT_CENTER))
	var weapon_name: String = _fighter_weapon_name(foe)
	if weapon_name != "":
		root.add_child(make_label("Empunha: %s" % weapon_name, 14, Color("bbaec1"), HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(make_label("EQUIPAMENTO", 14, Color("bbaec1"), HORIZONTAL_ALIGNMENT_CENTER))
	var any_item := false
	for slot: String in SLOT_ORDER:
		var item_id: String = foe.equipped_id(slot)
		if item_id == "":
			continue
		var item := ContentRepositoryScript.find_item(_items, item_id)
		var item_name := str(item.get("display_name", item_id.replace("_", " ").capitalize()))
		var bonus := _item_bonus_line(item)
		var line := "%s — %s" % [str(SLOT_TITLES.get(slot, slot.to_upper())), item_name]
		if bonus != "":
			line += "   [%s]" % bonus
		root.add_child(make_label(line, 14, Color("79cf7b"), HORIZONTAL_ALIGNMENT_CENTER))
		any_item = true
	if not any_item:
		root.add_child(make_label("Sem equipamento — luta com o corpo.", 13, Color("6b6078"), HORIZONTAL_ALIGNMENT_CENTER))
	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var close_button := Button.new()
	close_button.text = "FECHAR"
	close_button.custom_minimum_size = Vector2(140, 40)
	close_button.add_theme_font_size_override("font_size", 15)
	close_button.add_theme_color_override("font_color", Color("1a1420"))
	close_button.add_theme_stylebox_override("normal", panel_style(Color("70b9e8"), 8))
	close_button.add_theme_stylebox_override("hover", panel_style(Color("70b9e8").lightened(0.12), 8))
	close_button.pressed.connect(_close_enemy_inspect)
	close_row.add_child(close_button)
	root.add_child(close_row)

func _enemy_kind_line() -> String:
	if foe == null:
		return ""
	if foe.enemy_kind == "ranged":
		return "Tipo: à distância (mantém distância e atira)"
	var reach: int = int(foe.enemy_reach) if int(foe.enemy_reach) > 0 else CombatResolverScript.ENEMY_REACH
	return "Tipo: corpo a corpo (só acerta a até %d passo%s de distância)" % [reach, "s" if reach > 1 else ""]

func _tier_badge() -> String:
	match int(foe.enemy_tier):
		3:
			return "TIER III"
		2:
			return "TIER II"
		_:
			return "TIER I"

func _item_bonus_line(item: Dictionary) -> String:
	var parts: Array[String] = []
	if int(item.get("attack_bonus", 0)) > 0:
		parts.append("ATQ +%d" % int(item.get("attack_bonus", 0)))
	if int(item.get("defense_bonus", 0)) > 0:
		parts.append("DEF +%d" % int(item.get("defense_bonus", 0)))
	if int(item.get("luck_bonus", 0)) > 0:
		parts.append("SORTE +%d" % int(item.get("luck_bonus", 0)))
	if int(item.get("health_bonus", 0)) > 0:
		parts.append("VIDA +%d" % int(item.get("health_bonus", 0)))
	return "  ".join(parts)
