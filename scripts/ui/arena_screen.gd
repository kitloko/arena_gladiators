class_name ArenaScreen
extends Control

## Tela de arena: mostra a luta, coleta estatísticas e emite fight_finished(result)
## quando termina. Regras de dano/IA ficam no CombatResolver; economia no EconomySystem.
##
## Ações nomeadas por tipo de arma (GOLPE/GOLPE FORTE/INVESTIDA para melee,
## TIRO/TIRO CERTEIRO/BOMBARDEO para ranged), DEFESA FIRME, AVANÇAR/RECUAR,
## TAUNT (com a % na tela) e DORMIR. Cada ação devolve um resultado estruturado
## (hit/dodged/blocked/blocked_amount/critical/damage) guardado em combat_results,
## para a próxima etapa (barra de felicidade do público) consumir por ação.
##
## A armadura é um pool separado: a arena mostra DUAS barras por lutador
## (VIDA x/y e ARMADURA x/y).

signal fight_finished(result)

const BACKGROUND := Color("14111c")
const PANEL := Color("272033")
const PANEL_LIGHT := Color("382d47")
const GOLD := Color("f5c451")
const RED := Color("d95858")
const GREEN := Color("79cf7b")
const INK := Color("f7edf4")
const ARMOUR_COLOR := Color("70b9e8")
const CombatResolverScript := preload("res://scripts/systems/combat_resolver.gd")
const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")
const CrowdSystemScript := preload("res://scripts/systems/crowd_system.gd")
const PotionSystemScript := preload("res://scripts/systems/potion_system.gd")
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

## Resultado estruturado de CADA ação (por ação, na ordem), e o último.
var combat_results: Array[Dictionary] = []
var last_action_result: Dictionary = {}

## Felicidade do público (item H): barra 0-100% no topo, movida pelos eventos da
## luta. O público é exposto ao teste de fluxo (nome público, como `distance`).
var crowd
## Rodada corrente sem ninguém perder vida (gera vaias crescentes no fim).
var _round_cold: bool = true

var _total_hits := 0
var _criticals := 0
var _damage_dealt := 0
var _damage_taken := 0
var _enemy_moves := 0
## FERIMENTO (item 2): a luta ficou marcada por um crítico forte TOMADO pelo
## jogador — agrava a chance de sequela na derrota.
var _took_critical := false
## SEGUNDO SOPRO (Coração de Bronze, etapa 9): já usou o "não cai" nesta luta?
var _second_wind_used := false
## Chance do INIMIGO provocar em vez de atacar (o Elmo do Imperador imuniza, etapa 9).
const ENEMY_TAUNT_CHANCE := 0.15

var status_label: Label
var distance_label: Label
var distance_track: HBoxContainer
var crowd_bar: ProgressBar
var crowd_label: Label
var hero_card: VBoxContainer
var foe_card: VBoxContainer
var combat_log: RichTextLabel
var action_row: GridContainer
var _action_buttons: Dictionary = {}
var _items: Array = []
var _inspector: Control = null
## Cartaz de fim de luta (etapa 6, correção 2a): "VOCÊ VENCEU"/"VOCÊ PERDEU"
## mostrado ANTES do resumo; só o CONTINUAR libera o sinal fight_finished.
var _end_banner: Control = null
var _banner_result = null

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
var _hero_armour_bar: ProgressBar
var _enemy_armour_bar: ProgressBar
var _hero_armour_label: Label
var _enemy_armour_label: Label
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
## Faixa de arena desta luta (ideia 9): id/título + o CENÁRIO GERADO da faixa
## (etapa 7 do plano 3.0, via AssetCatalog/manifesto). No COMBATE FINAL usa o covil
## vermelho do boss. Fallback: a arena antiga da faixa, tingida como antes.
var arena_band_id: String = "areia"
var arena_band_title: String = "Arenas de Areia"
## Id da arte de arena desta luta ("" quando caiu no fallback antigo).
var arena_art_id: String = ""
var _arena_roll: int = 0
## Muralhas laterais órfãs: só aparecem no fallback (a arte nova já tem muralha).
var _stage_walls: Array[TextureRect] = []

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
	# COMBATE FINAL (etapa 6, correção 4): faixa inconfundível na rodada final.
	if GameState.is_final_tournament_round():
		root.add_child(_make_final_banner())
	elif foe != null and bool(foe.boss):
		root.add_child(make_label("BOSS — GRAU DE DIFICULDADE  %s  (%d/5)" % [BossDropTable.stars(GameState.current_boss_grade()), GameState.current_boss_grade()], 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	status_label = make_label("", 15, Color("cdbfd5"), HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(status_label)
	# Barra da felicidade do público (item H): 0 a 100%, SEMPRE visível no topo.
	var crowd_box := VBoxContainer.new()
	crowd_box.add_theme_constant_override("separation", 2)
	root.add_child(crowd_box)
	crowd_label = make_label("PÚBLICO DA ARENA  0%", 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	crowd_box.add_child(crowd_label)
	crowd_bar = ProgressBar.new()
	crowd_bar.max_value = float(CrowdSystemScript.MAX_VALUE)
	crowd_bar.value = 0.0
	crowd_bar.show_percentage = false
	crowd_bar.custom_minimum_size = Vector2(0, 14)
	crowd_bar.add_theme_stylebox_override("background", panel_style(PANEL_LIGHT, 6))
	crowd_bar.add_theme_stylebox_override("fill", panel_style(GOLD, 6))
	crowd_box.add_child(crowd_bar)
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
	# Muralhas laterais (assets órfãos reaproveitados): dão profundidade ao palco
	# sem inventar arte nova.
	_add_stage_wall("arena", "arena_wall_left", true)
	_add_stage_wall("arena", "arena_wall_right", false)
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
	action_row = GridContainer.new()
	action_row.columns = 5
	action_row.add_theme_constant_override("h_separation", 10)
	action_row.add_theme_constant_override("v_separation", 6)
	root.add_child(action_row)

func start_new_fight() -> void:
	# Reaproveita o adversário já apresentado na tela de apresentação (item F) —
	# senão o inimigo procedural da Arena Livre seria regerado e não seria o mesmo
	# que o jogador acabou de ver. Fallback: monta aqui se a tela não veio antes.
	foe = GameState.current_enemy
	if foe == null:
		foe = GameState.build_current_foe()
	if foe == null:
		fight_active = false
		crowd = null
		log_lines = ["[color=#d95858]Não há inimigo configurado para esta arena.[/color]"]
		refresh()
		return
	GameState.current_enemy = foe
	fight_active = true
	# Nova luta: poses voltam ao repouso (caso a tela seja reaproveitada).
	_hero_pose = "idle"
	_enemy_pose = "idle"
	# POÇÕES (item 6): marca que estamos EM LUTA — só aqui a bolsa deixa usar poção.
	GameState.in_combat = true
	round_number = 1
	# Felicidade do público (item H): início pelo CARISMA dos dois lutadores, com
	# piso de 60 em luta contra chefe (stage boss ou template "boss": true).
	# O RANK (item I) eleva o início/teto — arena mais lotada nas faixas altas.
	var is_boss: bool = GameState.is_boss_stage() or bool(foe.boss)
	var rank_points: int = int(GameState.player.rank_points) if GameState.player != null else 0
	crowd = CrowdSystemScript.new(GameState.player, foe, is_boss, rank_points)
	_arena_roll = _compute_arena_roll()
	_apply_arena_band()
	_round_cold = true
	_total_hits = 0
	_criticals = 0
	_damage_dealt = 0
	_damage_taken = 0
	_enemy_moves = 0
	_took_critical = false
	_second_wind_used = false
	combat_results = []
	last_action_result = {}
	distance = CombatResolverScript.ARENA_START_RANGE
	player_pos = 1
	enemy_pos = 1 + distance
	_build_action_buttons()
	log_lines = ["[color=#f5c451]%s — %s entra na arena! (distância %d)[/color]" % [GameState.current_stage_name(), foe.display_name, distance]]
	# COMBATE FINAL (correção 4): o log avisa que só aqui o troféu aparece.
	if GameState.is_final_tournament_round():
		log_lines.append("[color=#ffd54a]COMBATE FINAL — só aqui o troféu do campeão aparece![/color]")
	set_actions_enabled(true)
	_apply_action_states()
	DebugLog.info("Luta iniciada: %s contra %s (arena %d/%d)." % [GameState.player.display_name, foe.display_name, GameState.arena_number(), GameState.stage_total()])
	refresh()
	# Reaplica as posições depois do layout final (tamanho real do palco).
	_position_fighters.call_deferred()

## Monta os botões de ação conforme o TIPO de arma equipada (melee/ranged).
func _build_action_buttons() -> void:
	for child in action_row.get_children():
		child.queue_free()
	_action_buttons.clear()
	var weapon := GameState.player_weapon()
	if weapon.is_empty():
		weapon = {"kind": "melee", "reach": 1}
	for action: Dictionary in CombatResolverScript.attack_actions_for(weapon):
		_add_action_button(str(action.get("label", "ATAQUE")), str(action.get("id", "")), GOLD)
	_add_action_button("DEFESA FIRME", "defend", ARMOUR_COLOR)
	_add_action_button("EXIBIR", "exhibit", Color("e8a13a"))
	_add_action_button("AVANÇAR", "advance", GREEN)
	_add_action_button("RECUAR", "retreat", Color("d9a45b"))
	_add_action_button(_taunt_label(), "taunt", Color("e06bb5"))
	_add_action_button("DORMIR", "sleep", Color("8f83b3"))
	_add_potion_buttons()
	var skill: Dictionary = GameState.player_skill()
	if not skill.is_empty():
		_add_action_button(str(skill.get("display_name", "Habilidade")), "skill", Color("b08de7"))

func _add_action_button(text_value: String, kind: String, color: Color) -> void:
	var button := make_button(text_value, color)
	button.pressed.connect(player_action.bind(kind))
	_action_buttons[kind] = button
	action_row.add_child(button)

## POÇÕES (item 6): uma AÇÃO por tipo de poção na bolsa, com a contagem no rótulo.
## Usar gasta o turno (o inimigo age depois) e consome o item.
func _add_potion_buttons() -> void:
	var potions: Array[Dictionary] = PotionSystemScript.potions(GameState.player)
	var seen: Dictionary = {}
	for entry: Dictionary in potions:
		var item_id := str(entry.get("id", ""))
		if item_id == "" or seen.has(item_id):
			continue
		seen[item_id] = true
		var count := 0
		for other: Dictionary in potions:
			if str(other.get("id", "")) == item_id:
				count += 1
		_add_action_button("POÇÃO: %s (%d)" % [str(entry.get("display_name", "poção")), count], "potion:%s" % item_id, Color("79cf7b"))

func _taunt_label() -> String:
	var chance := 0.0
	if foe != null and GameState.player != null:
		chance = CombatResolverScript.taunt_chance(GameState.player, foe)
	return "TAUNT: (%d%%)" % int(round(chance * 100.0))

func player_action(kind: String) -> void:
	if not fight_active:
		return
	set_actions_enabled(false)
	if crowd != null:
		crowd.register_action()
		# Defender/recuar em sequência satura; qualquer outra ação zera a sequência.
		if kind != "defend" and kind != "retreat":
			crowd.reset_action_streaks()
	var defense_bonus := 0
	var enemy_phase_consumed := false
	var attacked := false
	# POÇÕES (item 6): usar uma poção é a ação do turno — aplica o efeito, consome
	# o item e deixa o inimigo agir. Se a poção não servir (nada a curar), o turno
	# é DEVOLVIDO (o inimigo não ganha uma ação de graça).
	if kind.begins_with("potion:"):
		var used: bool = _player_use_potion(kind.substr("potion:".length()))
		refresh()
		await get_tree().create_timer(0.35).timeout
		if used:
			enemy_turn(0)
		else:
			_finish_round()
		return
	match kind:
		"advance":
			_advance_player(false)
		"retreat":
			_retreat_player()
		"defend":
			defense_bonus = CombatResolverScript.DEFEND_GUARD_BONUS
			_play_pose(true, "defend", 0.5)
			log_lines.append("[color=#70b9e8]%s assume uma defesa firme (reduz o próximo dano).[/color]" % GameState.player.display_name)
			_crowd_event("defend")
		"sleep":
			_player_sleep()
		"taunt":
			enemy_phase_consumed = _player_taunt()
		"exhibit":
			_player_exhibit()
		"investida":
			_advance_player(true)
			_player_named_attack("investida")
			attacked = true
		"skill":
			var skill_action: Dictionary = GameState.player_skill()
			if not skill_action.is_empty():
				_player_attack(float(skill_action.get("multiplier", 1.0)), float(skill_action.get("accuracy", 1.0)), 1.0, "%s usa %s" % [GameState.player.display_name, str(skill_action.get("display_name", "habilidade"))])
				attacked = true
		"golpe", "golpe_forte", "tiro", "tiro_certeiro", "bombardeio":
			_player_named_attack(kind)
			attacked = true
		_:
			pass
	# Drama: vida abaixo de 30% e AINDA atacando → +4 no turno.
	if attacked and crowd != null and float(GameState.player.health) < float(GameState.player.max_health) * CrowdSystemScript.DRAMA_HEALTH_FRACTION:
		_crowd_event("drama")
	refresh()
	if foe.is_defeated():
		win_fight()
		return
	# O REVIDAR pode derrubar o jogador durante a própria ação: não deixa o
	# inimigo agir contra um corpo caído.
	if GameState.player.is_defeated():
		lose_fight()
		return
	await get_tree().create_timer(0.45).timeout
	if enemy_phase_consumed:
		_finish_round()
	else:
		enemy_turn(defense_bonus)

func _advance_player(from_investida: bool) -> void:
	if player_pos >= enemy_pos - 1:
		if not from_investida:
			log_lines.append("[color=#bbaec1]%s já está colado ao adversário.[/color]" % GameState.player.display_name)
		return
	player_pos = mini(enemy_pos - 1, player_pos + 1)
	_sync_distance()
	_hero_moving = true
	log_lines.append("[color=#79cf7b]%s avança (distância %d).[/color]" % [GameState.player.display_name, distance])

func _retreat_player() -> void:
	if player_pos <= 0:
		return
	player_pos = maxi(0, player_pos - 1)
	_sync_distance()
	_hero_moving = true
	log_lines.append("[color=#d9a45b]%s recua (distância %d).[/color]" % [GameState.player.display_name, distance])
	_crowd_event("retreat")

func enemy_turn(defense_bonus: int) -> void:
	if not fight_active:
		return
	# TAUNT DO INIMIGO (etapa 9): corpo a corpo pode PROVOCAR em vez de atacar — te
	# deixa exposto ao próximo golpe. O ELMO DO IMPERADOR dá IMUNIDADE total.
	if foe.enemy_kind != "ranged" and randf() < ENEMY_TAUNT_CHANCE:
		_enemy_taunt()
		_finish_round()
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
	GameState.player.vulnerable = false
	if crowd != null:
		crowd.clear_exposed()
	_finish_round()

## Provocação do INIMIGO (etapa 9): troca o ataque por um Taunt que deixa o
## jogador EXPOSTO ao próximo golpe. Resistida pela SORTE/DEF e ANULADA de vez
## pelo Elmo do Imperador (imunidade). Consome o turno do inimigo.
func _enemy_taunt() -> void:
	_play_pose(false, "attack", 0.4)
	if UniqueItems.taunt_immune(GameState.player):
		log_lines.append("[color=#f5c451]%s provoca — o Elmo do Imperador te mantém IMUNE a Taunt![/color]" % foe.display_name)
		return
	var chance := CombatResolverScript.taunt_chance(foe, GameState.player)
	if randf() > chance:
		log_lines.append("[color=#bbaec1]%s provoca, mas você não se abala.[/color]" % foe.display_name)
		return
	GameState.player.vulnerable = true
	log_lines.append("[color=#e06bb5]Taunt: %s te provoca — você fica ABERTO ao próximo golpe![/color]" % foe.display_name)

## Fecha o turno: incrementa a rodada, atualiza a tela e devolve as ações (ou derrota).
func _finish_round() -> void:
	# POÇÕES (item 6): os buffs temporários duram N TURNOS — ao fechar a rodada
	# passam um turno e os que expirarem avisam no log.
	if GameState.player != null:
		for buff: Variant in GameState.player.tick_buffs():
			if buff is Dictionary:
				log_lines.append("[color=#bbaec1]O efeito de poção em %s acabou.[/color]" % str((buff as Dictionary).get("attr", "atributo")))
	# Rodada fria (ninguém perdeu vida) faz o público vaiar; rodada normal esfria
	# devagar — assim a barra nunca fica parada no teto.
	if crowd != null:
		_log_crowd(crowd.end_round(_round_cold))
	_round_cold = true
	round_number += 1
	refresh()
	if GameState.player.is_defeated() and _try_second_wind():
		set_actions_enabled(true)
		_apply_action_states()
	elif GameState.player.is_defeated():
		lose_fight()
	elif foe != null and foe.is_defeated():
		# O jogador aparou e revidou, derrubando o inimigo no turno dele.
		win_fight()
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
	# ABERTO (EXIBIR): o inimigo ataca com +25% de precisão e a esquiva não vale.
	# Contra quem DORMIU vale a vulnerabilidade do sono (mais precisão, sem esquiva).
	var exhibit_open: bool = crowd != null and bool(crowd.exposed)
	if exhibit_open:
		accuracy = clampf(accuracy + CrowdSystemScript.EXHIBIT_OPEN_ACCURACY, 0.0, 1.0)
		GameState.player.vulnerable = true
		message += " enquanto você se exibe"
	elif bool(GameState.player.vulnerable):
		accuracy = clampf(accuracy + CombatResolverScript.SLEEP_VULNERABLE_ACCURACY, 0.0, 1.0)
		message += " contra você exposto"
	_play_pose(false, "attack", 0.35)
	var result: Dictionary = CombatResolverScript.resolve_positional_attack(foe, GameState.player, weapon, distance, multiplier, accuracy, defense_bonus)
	if bool(result.get("out_of_range", false)):
		log_lines.append("[color=#bbaec1]%s tenta atacar, mas está longe demais (distância %d).[/color]" % [foe.display_name, distance])
		return
	_spawn_attack_effect(false, str(weapon.get("kind", "melee")), distance)
	_apply_combat_result(foe, GameState.player, message, result)
	if bool(result.hit) and int(result.entered) > 0 and not bool(result.blocked):
		_play_pose(true, "hit", 0.3)

func _player_attack(multiplier: float, accuracy: float, penalty_scale: float, message: String, attack_id: String = "") -> void:
	var weapon := GameState.player_weapon()
	if weapon.is_empty():
		weapon = {"kind": "melee", "reach": 1}
	_play_pose(true, "attack", 0.35)
	var result: Dictionary = CombatResolverScript.resolve_positional_attack(GameState.player, foe, weapon, distance, multiplier, accuracy, 0, penalty_scale, attack_id)
	if bool(result.get("out_of_range", false)):
		log_lines.append("[color=#bbaec1]%s, mas está longe demais (distância %d).[/color]" % [message, distance])
		_crowd_event("missed")
		return
	_spawn_attack_effect(true, str(weapon.get("kind", "melee")), distance)
	_apply_combat_result(GameState.player, foe, message, result)
	if bool(result.hit) and int(result.entered) > 0 and not bool(result.blocked):
		_play_pose(false, "hit", 0.3)

## Ataque nomeado por tipo de arma (GOLPE/GOLPE FORTE/TIRO/TIRO CERTEIRO/BOMBARDEO).
func _player_named_attack(kind: String) -> void:
	var weapon := GameState.player_weapon()
	if weapon.is_empty():
		weapon = {"kind": "melee", "reach": 1}
	var action := CombatResolverScript.find_action(CombatResolverScript.attack_actions_for(weapon), kind)
	if action.is_empty():
		return
	_player_attack(float(action.get("multiplier", 1.0)), float(action.get("accuracy", 1.0)), float(action.get("penalty_scale", 1.0)), "%s usa %s" % [GameState.player.display_name, str(action.get("label", "ataque"))], kind)

## DORMIR: cura 25% da vida máxima, mas deixa VULNERÁVEL no próximo golpe.
func _player_sleep() -> void:
	var heal := int(round(float(GameState.player.max_health) * CombatResolverScript.SLEEP_HEAL_FRACTION))
	var before := int(GameState.player.health)
	GameState.player.health = mini(GameState.player.max_health, GameState.player.health + heal)
	var gained := int(GameState.player.health) - before
	GameState.player.vulnerable = true
	_play_pose(true, "defend", 0.6)
	if gained > 0:
		_spawn_status_text(true, "+%d" % gained, GREEN)
	log_lines.append("[color=#8f83b3]%s dorme e recupera %d de vida — mas fica VULNERÁVEL no próximo golpe.[/color]" % [GameState.player.display_name, gained])
	_crowd_event("sleep")

## EXIBIR (item H §5): gasta o turno, melhora a felicidade do público (rendendo
## cada vez menos na mesma luta) e deixa o jogador ABERTO — o inimigo ataca com
## +25% de precisão e a esquiva não vale no turno seguinte.
func _player_exhibit() -> void:
	_play_pose(true, "defend", 0.6)
	log_lines.append("[color=#f5c451]%s se exibe para o público![/color]" % GameState.player.display_name)
	var entry := _crowd_event("exhibit")
	# MANTO DO PÚBLICO (etapa 9): EXIBIR rende +50% e NÃO deixa você aberto.
	if UniqueItems.exhibit_boost(GameState.player) and crowd != null:
		var bonus := int(round(float(maxi(0, int(entry.get("delta", 0)))) * 0.5))
		if bonus > 0:
			_log_crowd(crowd.apply_bonus("exhibit_bonus", bonus))
		crowd.clear_exposed()
		log_lines.append("[color=#f5c451]O Manto do Público encanta a plateia (+50%) e mantém você fechado.[/color]")

## POÇÕES (item 6): bebe uma poção da mochila durante a luta. O efeito é aplicado
## pelo GameState (regra única) e o item é CONSUMIDO. Devolve false se a poção não
## deu em nada (aí o turno é devolvido ao jogador).
func _player_use_potion(item_id: String) -> bool:
	var info: Dictionary = GameState.use_potion(item_id)
	if not bool(info.get("ok", false)):
		log_lines.append("[color=#bbaec1]Não foi possível usar a poção: %s.[/color]" % str(info.get("reason", "sem efeito")))
		return false
	var item: Dictionary = info.get("item", {})
	var effect_label := "efeito"
	if not item.is_empty():
		effect_label = PotionSystemScript.effect_label(item)
	_play_pose(true, "defend", 0.5)
	log_lines.append("[color=#79cf7b]%s bebe %s — %s.[/color]" % [GameState.player.display_name, str(item.get("display_name", "uma poção")), str(info.get("message", effect_label))])
	_spawn_status_text(true, "POÇÃO", Color("79cf7b"))
	_crowd_event("potion")
	# Refaz os botões: a contagem baixou e a poção acaba some quando zera.
	_build_action_buttons()
	_apply_action_states()
	return true

## Registra um evento de público, escreve a variação no log e solta um balão.
func _crowd_event(event_id: String) -> Dictionary:
	if crowd == null:
		return {}
	var entry: Dictionary = crowd.apply_event(event_id)
	_log_crowd(entry)
	return entry

func _log_crowd(entry: Dictionary) -> void:
	if entry.is_empty():
		return
	var delta := int(entry.get("delta", 0))
	# O tédio (-1/rodada) é sutil e fica fora do log; o resto aparece para o
	# jogador entender por que a barra subiu ou desceu.
	if absi(delta) < 2:
		return
	log_lines.append("[color=#f5c451]%s[/color]" % CrowdSystemScript.log_line(entry))
	_spawn_crowd_bubble(delta)

## Balão flutuante perto da barra do público com a variação (+8 / -5).
func _spawn_crowd_bubble(delta: int) -> void:
	if crowd_bar == null or not crowd_bar.is_inside_tree():
		return
	var label := make_label("%+d" % delta, 16, GOLD if delta > 0 else Color("e08a8a"), HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(48, 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	add_child(label)
	var rect := crowd_bar.get_global_rect()
	label.position = Vector2(rect.position.x + rect.size.x * 0.5 - 24.0, rect.position.y - 18.0)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -22), 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.15)
	tween.chain().tween_callback(label.queue_free)

## TAUNT: chance por CHA (vs CHA/DEF/SOR do alvo) com peso do STR. Devolve true
## quando o Taunt CONSUMIU o turno do inimigo (sucesso).
func _player_taunt() -> bool:
	var chance := CombatResolverScript.taunt_chance(GameState.player, foe)
	_play_pose(true, "defend", 0.4)
	if randf() > chance:
		log_lines.append("[color=#bbaec1]%s provoca %s, mas ele resiste.[/color]" % [GameState.player.display_name, foe.display_name])
		return false
	var effect := CombatResolverScript.roll_taunt_effect()
	match str(effect.get("id", "")):
		"advance":
			var can_advance := enemy_pos > player_pos + 1
			if can_advance and not CombatResolverScript.taunt_push_resisted(foe):
				enemy_pos = maxi(player_pos + 1, enemy_pos - 1)
				_sync_distance()
				_enemy_moving = true
				log_lines.append("[color=#e06bb5]Taunt: %s avança um passo forçado (distância %d).[/color]" % [foe.display_name, distance])
			else:
				if can_advance:
					log_lines.append("[color=#e06bb5]Taunt: %s resiste ao empurrão.[/color]" % foe.display_name)
				_enemy_forced_attack()
		"reckless":
			log_lines.append("[color=#e06bb5]Taunt: %s ataca imprudentemente.[/color]" % foe.display_name)
			_enemy_forced_attack()
		_:
			log_lines.append("[color=#e06bb5]Taunt: %s tropeça e perde o turno.[/color]" % foe.display_name)
	return true

## Ataque do inimigo forçado pelo Taunt: precisão baixa, consome o turno dele.
func _enemy_forced_attack() -> void:
	_play_pose(false, "attack", 0.35)
	var forced_weapon := _foe_weapon()
	var result: Dictionary = CombatResolverScript.resolve_positional_attack(foe, GameState.player, forced_weapon, distance, 1.0, 0.5, 0)
	if bool(result.get("out_of_range", false)):
		log_lines.append("[color=#bbaec1]%s tenta atacar, mas está longe demais.[/color]" % foe.display_name)
		return
	_spawn_attack_effect(false, str(forced_weapon.get("kind", "melee")), distance)
	_apply_combat_result(foe, GameState.player, "%s ataca (precisão baixa)" % foe.display_name, result)
	if bool(result.hit) and int(result.entered) > 0 and not bool(result.blocked):
		_play_pose(true, "hit", 0.3)

func _foe_weapon() -> Dictionary:
	if foe == null:
		return {"kind": "melee", "reach": 1}
	var kind := str(foe.enemy_kind)
	var reach: int = int(foe.enemy_reach) if int(foe.enemy_reach) > 0 else CombatResolverScript.ENEMY_REACH
	return {"kind": kind, "reach": reach}

## Registra o resultado estruturado da ação e escreve o feedback pedido:
## ERROU (esquiva/precisão) ou "aparou X, entrou Y" (auto-defesa), com sinalização.
func _apply_combat_result(attacker, target, message: String, result: Dictionary) -> void:
	var entry := result.duplicate()
	entry["attacker"] = attacker.display_name if attacker != null else ""
	entry["target"] = target.display_name if target != null else ""
	entry["message"] = message
	combat_results.append(entry)
	last_action_result = entry
	var is_player_attack: bool = attacker == GameState.player
	var target_is_player: bool = target == GameState.player
	# Marca a rodada como "com sangue" quando alguém perde vida de verdade.
	if int(result.get("health_damage", 0)) > 0 or int(result.get("counter_health_damage", 0)) > 0:
		_round_cold = false
	_apply_crowd_from_result(result, is_player_attack)
	_log_trait_notes(result)
	if bool(result.get("dodged", false)):
		log_lines.append("[color=#bbaec1]%s — %s esQUIVA! ERROU.[/color]" % [message, target.display_name])
		_spawn_status_text(target_is_player, "ERROU", Color("bbaec1"))
		return
	if not bool(result.get("hit", false)):
		log_lines.append("[color=#bbaec1]%s, mas erra o golpe. ERROU.[/color]" % message)
		_spawn_status_text(target_is_player, "ERROU", Color("bbaec1"))
		return
	_total_hits += 1
	if bool(result.get("critical", false)):
		_criticals += 1
	# FERIMENTO (item 2): um crítico forte TOMADO pelo jogador marca a luta.
	if target_is_player and bool(result.get("critical", false)):
		_took_critical = true
	var entered := int(result.get("entered", 0))
	if is_player_attack:
		_damage_dealt += entered
	else:
		_damage_taken += entered
	if bool(result.get("blocked", false)):
		_flash_defense(target_is_player)
		_spawn_block_effect(target_is_player)
		_spawn_status_text(target_is_player, "APAROU %d" % int(result.get("blocked_amount", 0)), ARMOUR_COLOR)
		log_lines.append("[color=#70b9e8]%s: %s aparou %d, entrou %d.[/color]" % [message, target.display_name, int(result.get("blocked_amount", 0)), entered])
		if bool(result.get("countered", false)):
			_log_counter(attacker, target, result)
	else:
		var tag := " [color=#f5c451]CRÍTICO![/color]" if bool(result.get("critical", false)) else ""
		log_lines.append("%s e causa [color=#d95858]%d de dano[/color].%s" % [message, entered, tag])
	if entered > 0:
		_spawn_damage_text(target_is_player, entered, bool(result.get("critical", false)))
		_spawn_hit_effect(target_is_player)

## TRAÇOS (item 8): imprime no log cada mordida do traço de combate do inimigo
## (ex.: 'Frágil: +25% de dano', 'Ágil: esquivou com facilidade'). Sem isso a QA
## não teria como provar que o texto da fraqueza virou mecânica de verdade.
func _log_trait_notes(result: Dictionary) -> void:
	for note: Variant in result.get("trait_notes", []):
		var text := str(note).strip_edges()
		if text != "":
			log_lines.append("[color=#e8a13a]%s[/color]" % text)

## Deriva os eventos de público de um resultado de combate (regra única em
## CrowdSystem) e escreve cada variação no log.
func _apply_crowd_from_result(result: Dictionary, player_is_attacker: bool) -> void:
	if crowd == null:
		return
	for entry: Dictionary in crowd.apply_combat_result(result, player_is_attacker):
		_log_crowd(entry)

## REVIDAR (contra-ataque): quem aparou devolve parte do golpe ao atacante.
func _log_counter(attacker, target, result: Dictionary) -> void:
	var counter := int(result.get("counter_damage", 0))
	if counter <= 0 or target == null:
		return
	var attacker_name: String = attacker.display_name if attacker != null else "o atacante"
	log_lines.append("[color=#e8a13a]%s REVIDA e devolve [color=#d95858]%d de dano[/color] a %s![/color]" % [target.display_name, counter, attacker_name])
	_spawn_status_text(attacker == GameState.player, "REVIDOU", Color("e8a13a"))

func _apply_action_states() -> void:
	var can_attack := _weapon_can_attack()
	var can_advance := player_pos < enemy_pos - 1
	if _action_buttons.has("taunt"):
		_action_buttons["taunt"].text = _taunt_label()
	for kind: Variant in _action_buttons.keys():
		var button: Button = _action_buttons[kind]
		var key := str(kind)
		# POÇÕES (item 6): a poção é sempre uma ação disponível no seu turno.
		if key.begins_with("potion:"):
			button.disabled = false
			continue
		match key:
			"advance":
				button.disabled = not can_advance
			"retreat":
				button.disabled = player_pos <= 0
			"investida":
				button.disabled = not (can_attack or can_advance)
			"defend", "sleep", "taunt", "exhibit":
				button.disabled = false
			_:
				button.disabled = not can_attack

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

func win_fight() -> void:
	fight_active = false
	set_actions_enabled(false)
	# O DERROTADO fica na pose caída (o inimigo caiu); o herói continua em pé.
	_set_downed(false)
	var was_boss: bool = GameState.is_boss_stage()
	# Felicidade do público (item H) → multiplicador de OURO da vitória (×1,0..×2,0;
	# o teto sobe com o RANK — arena mais lotada, item I).
	var crowd_mult := 1.0
	if crowd != null:
		var rank_points: int = int(GameState.player.rank_points) if GameState.player != null else 0
		crowd_mult = float(crowd.reward_multiplier(rank_points))
	var rewards_spec: Dictionary = EconomySystemScript.fight_rewards(GameState.player.level)
	var rewards: Dictionary = GameState.on_victory(int(rewards_spec.gold), int(rewards_spec.experience), crowd_mult, _took_critical)
	var result = FightResultScript.new(true, round_number)
	_fill_result(result, int(rewards.gold), int(rewards.experience))
	_apply_rank_to_result(result, rewards.get("rank", {}))
	_apply_bet_to_result(result, rewards.get("bet", {}))
	_apply_injury_to_result(result, rewards.get("injury", {}))
	if result.injured:
		log_lines.append("[color=#e08a8a]FERIMENTO: %s — passe no MÉDICO.[/color]" % str((result.injury as Dictionary).get("label", "ferido")))
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
	_show_end_banner(result)

## SEGUNDO SOPRO (Coração de Bronze, etapa 9): sobrevive ao PRIMEIRO golpe fatal
## de cada luta — volta com 1 de vida, uma única vez. Devolve true se salvou.
func _try_second_wind() -> bool:
	if _second_wind_used or GameState.player == null:
		return false
	if not UniqueItems.second_wind(GameState.player):
		return false
	_second_wind_used = true
	GameState.player.health = 1
	log_lines.append("[color=#f5c451]O CORAÇÃO DE BRONZE pulsa! %s se recusa a cair — volta com 1 de vida![/color]" % GameState.player.display_name)
	_spawn_status_text(true, "SEGUNDO SOPRO", Color("f5c451"))
	return true

func lose_fight() -> void:
	fight_active = false
	set_actions_enabled(false)
	# O DERROTADO é o jogador: fica na pose caída.
	_set_downed(true)
	var outcome: Dictionary = GameState.on_defeat(_took_critical)
	var result = FightResultScript.new(false, round_number)
	_fill_result(result, 0, 0)
	_apply_rank_to_result(result, outcome.get("rank", {}))
	_apply_bet_to_result(result, outcome.get("bet", {}))
	_apply_injury_to_result(result, outcome.get("injury", {}))
	if result.injured:
		log_lines.append("[color=#e08a8a]FERIMENTO: %s — passe no MÉDICO.[/color]" % str((result.injury as Dictionary).get("label", "ferido")))
	result.boss = bool(outcome.boss)
	result.campaign_lost = bool(outcome.campaign_lost)
	result.penalty = int(outcome.penalty)
	result.tournament = bool(outcome.tournament)
	result.prize = int(outcome.get("kept", 0))
	GameState.persist_if_free()
	DebugLog.info("Derrota. Torneio perdido: %s." % result.campaign_lost)
	_show_end_banner(result)

## Cartaz de fim de luta (etapa 6, correção 2a): "VOCÊ VENCEU"/"VOCÊ PERDEU"
## GRANDE, com o nome do adversário e o número de rodadas, mais o botão CONTINUAR.
## Nada de trocar de tela no mesmo quadro: o sinal fight_finished só sai quando o
## jogador clica CONTINUAR (aí o app abre o resumo em modal por cima da arena).
func _show_end_banner(result) -> void:
	_banner_result = result
	if _end_banner != null:
		_end_banner.queue_free()
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_end_banner = overlay
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var victory: bool = bool(result.victory)
	var accent := GOLD if victory else RED
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _banner_style(accent))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(620, 0)
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var big := make_label("VOCÊ VENCEU" if victory else "VOCÊ PERDEU", 60, accent, HORIZONTAL_ALIGNMENT_CENTER)
	big.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	big.add_theme_constant_override("shadow_offset_x", 2)
	big.add_theme_constant_override("shadow_offset_y", 2)
	box.add_child(big)
	var opponent := str(result.opponent_name)
	if opponent == "":
		opponent = "o oponente"
	box.add_child(make_label("%s — %d rodadas" % [opponent, int(result.rounds)], 20, INK, HORIZONTAL_ALIGNMENT_CENTER))
	# Na rodada final, o cartaz reforça o COMBATE FINAL (correção 4).
	if GameState.is_final_tournament_round():
		box.add_child(make_label("COMBATE FINAL — %s" % GameState.final_boss_name(), 16, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var cont := Button.new()
	cont.text = "CONTINUAR"
	cont.custom_minimum_size = Vector2(0, 56)
	cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont.add_theme_font_size_override("font_size", 20)
	cont.add_theme_color_override("font_color", Color("1a1420"))
	cont.add_theme_stylebox_override("normal", panel_style(GREEN if victory else Color("d9a45b"), 10))
	cont.add_theme_stylebox_override("hover", panel_style((GREEN if victory else Color("d9a45b")).lightened(0.12), 10))
	cont.pressed.connect(_confirm_end_banner)
	box.add_child(cont)

## CONTINUAR do cartaz: fecha o cartaz e só AGORA libera o resultado para o modal.
func _confirm_end_banner() -> void:
	if _end_banner != null:
		_end_banner.queue_free()
		_end_banner = null
	fight_finished.emit(_banner_result)

func _banner_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1d1726")
	style.border_color = border
	style.set_border_width_all(3)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	return style

## Faixa do COMBATE FINAL na arena (etapa 6, correção 4): fundo vermelho escuro,
## contorno dourado e o nome do boss em destaque.
func _make_final_banner() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("3a1220")
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)
	box.add_child(make_label("COMBATE FINAL — %s" % GameState.final_boss_name(), 20, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(make_label("GRAU DE DIFICULDADE  %s  (%d/5)  — define a tabela de drop" % [BossDropTable.stars(GameState.current_boss_grade()), GameState.current_boss_grade()], 14, Color("f5c451"), HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(make_label("A última luta do torneio. Só aqui o troféu do campeão aparece.", 12, Color("e08a8a"), HORIZONTAL_ALIGNMENT_CENTER))
	return panel

func _fill_result(result, gold_value: int, xp_value: int) -> void:
	result.hits = _total_hits
	result.criticals = _criticals
	result.damage_dealt = _damage_dealt
	result.damage_taken = _damage_taken
	result.gold = gold_value
	result.experience = xp_value
	if crowd != null:
		result.crowd_happiness = crowd.value()
		result.crowd_multiplier = float(crowd.reward_multiplier())
		result.quick_fight = crowd.is_quick_fight()
	if foe != null:
		result.opponent_name = foe.display_name
	result.arena_band_id = arena_band_id
	result.arena_band_title = arena_band_title

## Copia a variação de rank da luta para o resultado exibido.
func _apply_rank_to_result(result, rank_info: Dictionary) -> void:
	if rank_info.is_empty():
		return
	result.rank_change_known = true
	result.rank_delta = int(rank_info.get("delta", 0))
	result.rank_points = int(rank_info.get("points", 0))
	result.rank_title = str(rank_info.get("new_title", ""))
	result.rank_promoted = bool(rank_info.get("promoted", false))
	result.rank_demoted = bool(rank_info.get("demoted", false))

## Copia o resultado da APOSTA (item 5) para a tela de resultado.
func _apply_bet_to_result(result, bet_info: Dictionary) -> void:
	if bet_info.is_empty() or not bool(bet_info.get("active", false)):
		return
	result.bet_active = true
	result.bet_stake = int(bet_info.get("stake", 0))
	result.bet_odd = float(bet_info.get("odd", 0.0))
	result.bet_won = bool(bet_info.get("won", false))
	result.bet_payout = int(bet_info.get("payout", 0))

## Copia o FERIMENTO (item 2) deixado por esta luta para a tela de resultado.
func _apply_injury_to_result(result, injury_info: Dictionary) -> void:
	if injury_info.is_empty():
		return
	var injury: Dictionary = injury_info.get("injury", {})
	result.injured = bool(injury_info.get("injured", false)) and not injury.is_empty()
	result.injury = injury

func refresh() -> void:
	status_label.text = "NÍVEL %d  •  %d XP  •  %d OURO  •  RODADA %d  •  %s" % [GameState.player.level, GameState.player.experience, GameState.player.gold, round_number, arena_band_title]
	distance_label.text = "DISTÂNCIA: %d" % distance
	if crowd != null and crowd_bar != null:
		crowd_bar.value = float(crowd.value())
		crowd_label.text = "PÚBLICO DA ARENA  %d%%" % int(crowd.value())
	if _action_buttons.has("taunt"):
		_action_buttons["taunt"].text = _taunt_label()
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
	card.add_child(make_label("ARMADURA  %d / %d" % [fighter.armour, fighter.max_armour], 16, ARMOUR_COLOR))
	var bar := ProgressBar.new()
	bar.max_value = fighter.max_health
	bar.value = fighter.health
	bar.show_percentage = false
	bar.custom_minimum_size.y = 13
	bar.add_theme_stylebox_override("background", panel_style(PANEL_LIGHT, 5))
	bar.add_theme_stylebox_override("fill", panel_style(tint, 5))
	card.add_child(bar)
	card.add_child(make_label("FOR %d  ATT %d  DEF %d  AGI %d  VIT %d  CAR %d  SOR %d" % [fighter.strength, fighter.attack, fighter.defence, fighter.agility, fighter.vitality, fighter.charisma, fighter.luck], 13, Color("cdbfd5")))
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
	button.custom_minimum_size = Vector2(150, 42)
	button.add_theme_font_size_override("font_size", 14)
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

## Muralha decorativa no palco (asset órfão reaproveitado): só aparece no FALLBACK —
## a arena gerada já traz muralha/arquibancada próprias.
func _add_stage_wall(folder: String, file_name: String, on_left: bool) -> void:
	var texture := _load_sprite(folder, file_name)
	if texture == null:
		return
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate = Color(1, 1, 1, 0.5)
	rect.custom_minimum_size = Vector2(80, 0)
	rect.set_anchors_preset(Control.PRESET_LEFT_WIDE if on_left else Control.PRESET_RIGHT_WIDE)
	rect.offset_left = 0.0
	rect.offset_right = 80.0 if on_left else 0.0
	if not on_left:
		rect.offset_left = -80.0
		rect.offset_right = 0.0
	_stage.add_child(rect)
	_stage_walls.append(rect)

## Rolagem estável por luta (para o cenário variar dentro da faixa sem sorteio
## não-reprodutível): combina a arena atual, a volta e o rank do jogador.
func _compute_arena_roll() -> int:
	var base := GameState.arena_number() + GameState.lap
	if GameState.player != null:
		base += int(GameState.player.rank_points / 100)
	return absi(base)

## Cenário por faixa de rank (ideia 9 + etapa 7): a arena GERADA da faixa
## (AssetCatalog/manifesto) — e o covil vermelho no COMBATE FINAL. Fallback: a
## arena antiga da faixa, tingida como antes, com as muralhas laterais.
func _apply_arena_band() -> void:
	var band := GameState.arena_band()
	arena_band_id = str(band.get("id", "areia"))
	arena_band_title = str(band.get("title", "Arenas de Areia"))
	if _stage_bg == null:
		return
	var is_final: bool = GameState.is_final_tournament_round()
	arena_art_id = AssetCatalog.arena_id(arena_band_id, is_final, _arena_roll)
	var texture: Texture2D = AssetCatalog.texture(arena_art_id)
	var used_generated := texture != null
	if not used_generated:
		arena_art_id = ""
		texture = _load_sprite("arena", str(band.get("texture", "arena_background")))
	if texture != null:
		_stage_bg.texture = texture
	_stage_bg.self_modulate = Color.WHITE if used_generated else Color(str(band.get("tint", "ffffff")))
	for wall: TextureRect in _stage_walls:
		wall.visible = not used_generated

func _load_pose_set(folder: String) -> Dictionary:
	var base := "enemy" if folder == "enemies" else folder
	return {
		"idle": _load_sprite(folder, base),
		"attack": _load_sprite(folder, base + "_attack"),
		"hit": _load_sprite(folder, base + "_hit"),
		"defend": _load_sprite(folder, base + "_defend"),
	}

## Cria o "grupo" de um lutador (rótulo + barras de vida/armadura + sprite) no palco.
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
	var bar_w := 118.0
	var left := (GROUP_W - bar_w) * 0.5
	# VIDA (barra + número)
	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(bar_w, 10)
	bar.position = Vector2(left, 11)
	bar.add_theme_stylebox_override("background", panel_style(PANEL_LIGHT, 4))
	bar.add_theme_stylebox_override("fill", panel_style(GREEN if is_hero else RED, 4))
	group.add_child(bar)
	var hp_text := make_label("", 10, Color("f7edf4"), HORIZONTAL_ALIGNMENT_CENTER)
	hp_text.custom_minimum_size = Vector2(bar_w, 12)
	hp_text.position = Vector2(left, 0)
	hp_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	hp_text.add_theme_constant_override("shadow_offset_x", 1)
	hp_text.add_theme_constant_override("shadow_offset_y", 1)
	hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(hp_text)
	# ARMADURA (barra + número)
	var armour_bar := ProgressBar.new()
	armour_bar.max_value = 100.0
	armour_bar.value = 0.0
	armour_bar.show_percentage = false
	armour_bar.custom_minimum_size = Vector2(bar_w, 8)
	armour_bar.position = Vector2(left, 32)
	armour_bar.add_theme_stylebox_override("background", panel_style(PANEL_LIGHT, 4))
	armour_bar.add_theme_stylebox_override("fill", panel_style(ARMOUR_COLOR, 4))
	group.add_child(armour_bar)
	var armour_text := make_label("", 10, ARMOUR_COLOR, HORIZONTAL_ALIGNMENT_CENTER)
	armour_text.custom_minimum_size = Vector2(bar_w, 12)
	armour_text.position = Vector2(left, 21)
	armour_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	armour_text.add_theme_constant_override("shadow_offset_x", 1)
	armour_text.add_theme_constant_override("shadow_offset_y", 1)
	armour_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(armour_text)
	var tag := make_label("", 12, Color("f7edf4"), HORIZONTAL_ALIGNMENT_CENTER)
	tag.custom_minimum_size = Vector2(GROUP_W, 16)
	tag.position = Vector2(0, 42)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(tag)
	if is_hero:
		_hero_sprite = sprite
		_hero_bar = bar
		_hero_hp_label = hp_text
		_hero_armour_bar = armour_bar
		_hero_armour_label = armour_text
		_hero_tag = tag
		_hero_group = group
	else:
		_enemy_sprite = sprite
		_enemy_bar = bar
		_enemy_hp_label = hp_text
		_enemy_armour_bar = armour_bar
		_enemy_armour_label = armour_text
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
	# Poeira nos pés de quem se moveu (recuo/avanço) — antes de reposicionar.
	if _hero_moving:
		_spawn_dust_effect(true)
	if _enemy_moving:
		_spawn_dust_effect(false)
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
	var armour_bar := _hero_armour_bar if is_hero else _enemy_armour_bar
	var armour_label := _hero_armour_label if is_hero else _enemy_armour_label
	var tag := _hero_tag if is_hero else _enemy_tag
	var pose := _hero_pose if is_hero else _enemy_pose
	# PONTO ÚNICO de troca de sprite (herói E inimigo passam por aqui): a arte do
	# dono (assets/gen/characters.json, por char_id + pose) tem PRECEDÊNCIA; sem
	# entrada/PNG, cai no conjunto atual hero_*/enemy_*. Ver FighterVisuals.
	var char_id := _hero_char_id() if is_hero else _enemy_char_id()
	var texture: Texture2D = FighterVisuals.resolve(char_id, pose, tex)
	if texture != null:
		sprite.texture = texture
	_apply_downed_look(sprite, pose)
	if bar.max_value != fighter.max_health:
		bar.max_value = float(fighter.max_health)
	bar.value = float(fighter.health)
	bar.add_theme_stylebox_override("fill", panel_style(GREEN if is_hero else RED, 4))
	hp_label.text = "VIDA %d/%d" % [int(fighter.health), int(fighter.max_health)]
	armour_bar.max_value = float(maxi(1, fighter.max_armour))
	armour_bar.value = float(fighter.armour)
	armour_label.text = "ARM %d/%d" % [int(fighter.armour), int(fighter.max_armour)]
	if is_hero:
		tag.text = "%s  •  Nv %d" % [GameState.player.display_name, GameState.player.level]
	else:
		tag.text = "%s  •  Nv %d" % [foe.display_name, foe.level]

## Id de arte do herói (chave do characters.json). Hoje é "hero" — o mesmo id da
## folha do dono (docs/ARTE.md §3-A).
func _hero_char_id() -> String:
	return "hero"

## Id de arte do inimigo: o id do adversário (brutus, imperator...) é a chave do
## characters.json; sem ele, "enemy" (cai no sprite atual enemy_*).
func _enemy_char_id() -> String:
	if foe != null:
		var cid := str(foe.id)
		if cid != "":
			return cid
	return "enemy"

## Pose de caído (fim de luta): usa a arte "caido" do dono se existir; senão a
## arena INCLINA e ESCURECE o sprite de "levado" (não precisa de arte nova).
func _apply_downed_look(sprite: TextureRect, pose: String) -> void:
	if sprite == null:
		return
	var downed := pose == "fallen"
	sprite.pivot_offset = Vector2(SPRITE_DISPLAY * 0.5, SPRITE_DISPLAY) if downed else Vector2.ZERO
	sprite.rotation = deg_to_rad(82.0) if downed else 0.0
	sprite.modulate = Color(0.55, 0.5, 0.56, 1.0) if downed else Color.WHITE

## Fim de luta: marca o derrotado na pose caída e atualiza o sprite. O cartaz de
## VOCÊ VENCEU/PERDEU continua por cima (é overlay da arena, não do palco).
func _set_downed(is_hero: bool) -> void:
	if is_hero:
		_hero_pose = "fallen"
	else:
		_enemy_pose = "fallen"
	_update_fighter_visuals(is_hero)

# --- Efeitos e projéteis procedurais (etapa 8) ------------------------------
# Tudo desenhado por código (FightEffects): NÃO bloqueia a luta nem muda o ritmo.

func _stage_ready() -> bool:
	return _stage != null and _hero_group != null and _enemy_group != null

## Âncora visual de um lutador (altura do peito) para efeitos e projéteis.
func _fighter_anchor(is_hero: bool) -> Vector2:
	var group := _hero_group if is_hero else _enemy_group
	if group == null:
		return Vector2.ZERO
	return group.position + Vector2(GROUP_W * 0.5, GROUP_H - SPRITE_DISPLAY * 0.55)

## Golpe: arco de corte (corpo a corpo) ou projétil voando (à distância).
func _spawn_attack_effect(is_hero: bool, weapon_kind: String, bands: int) -> void:
	if not _stage_ready():
		return
	var from := _fighter_anchor(is_hero)
	var to := _fighter_anchor(not is_hero)
	if weapon_kind == "ranged":
		FightEffects.projectile(_stage, from, to, bands)
	else:
		FightEffects.slice_arc(_stage, from, to)

## Aparo: anel de faísca curto no defensor.
func _spawn_block_effect(is_hero: bool) -> void:
	if not _stage_ready():
		return
	FightEffects.spark_ring(_stage, _fighter_anchor(is_hero))

## Dano levado: respingo curto no sentido de quem bateu.
func _spawn_hit_effect(is_hero: bool) -> void:
	if not _stage_ready():
		return
	FightEffects.hit_spray(_stage, _fighter_anchor(is_hero), _fighter_anchor(not is_hero) - _fighter_anchor(is_hero))

## Recuo/avanço: puff de poeira nos pés.
func _spawn_dust_effect(is_hero: bool) -> void:
	if not _stage_ready():
		return
	FightEffects.dust_puff(_stage, _fighter_anchor(is_hero))

## Número de dano flutuante acima do lutador atingido ("life hit").
func _spawn_damage_text(is_hero: bool, amount: int, critical: bool) -> void:
	if _stage == null or amount <= 0:
		return
	var color := Color("ffd54a") if critical else Color("ff6b6b")
	var size := 23 if critical else 18
	_spawn_floating(is_hero, "-%d" % amount, color, size)

## Texto flutuante de estado (APAROU X / ERROU / +cura) acima do lutador.
func _spawn_status_text(is_hero: bool, text_value: String, color: Color) -> void:
	_spawn_floating(is_hero, text_value, color, 15)

func _spawn_floating(is_hero: bool, text_value: String, color: Color, size: int) -> void:
	if _stage == null or text_value == "":
		return
	var group := _hero_group if is_hero else _enemy_group
	if group == null:
		return
	var label := make_label(text_value, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(120, 0)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cx := group.position.x + GROUP_W * 0.5
	var cy := group.position.y + GROUP_H - SPRITE_DISPLAY * 0.55
	label.position = Vector2(cx - 60.0, cy)
	_stage.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -46), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)

## Sinalização visual de defesa: flash azulado no alvo que aparou.
func _flash_defense(is_hero: bool) -> void:
	var group := _hero_group if is_hero else _enemy_group
	if group == null:
		return
	var tween := create_tween()
	tween.tween_property(group, "modulate", Color("9fd0ff"), 0.08)
	tween.tween_property(group, "modulate", Color.WHITE, 0.28)

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
	root.custom_minimum_size = Vector2(460, 0)
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
	root.add_child(make_label("VIDA  %d / %d   •   ARMADURA  %d / %d" % [foe.health, foe.max_health, foe.armour, foe.max_armour], 15, INK, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(make_label("FOR %d   ATT %d   DEF %d   AGI %d" % [foe.strength, foe.attack, foe.defence, foe.agility], 16, INK, HORIZONTAL_ALIGNMENT_CENTER))
	root.add_child(make_label("VIT %d   CAR %d   SOR %d" % [foe.vitality, foe.charisma, foe.luck], 16, INK, HORIZONTAL_ALIGNMENT_CENTER))
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
	return "  ".join(parts)
