extends Node

const GladiatorDataScript := preload("res://scripts/models/gladiator_data.gd")
const ContentRepositoryScript := preload("res://scripts/repositories/content_repository.gd")
const CombatResolverScript := preload("res://scripts/systems/combat_resolver.gd")
const EconomySystemScript := preload("res://scripts/systems/economy_system.gd")
const ItemGeneratorScript := preload("res://scripts/systems/item_generator.gd")
const SaveSystemScript := preload("res://scripts/systems/save_system.gd")
const RankSystemScript := preload("res://scripts/systems/rank_system.gd")

## Teto duro do multiplicador do público na entrada de on_victory. O teto REAL
## depende do rank (CrowdSystem.reward_multiplier), que passa de ×2,0 nas faixas
## altas — este valor só impede um multiplicador absurdo vindo de fora.
const MULTIPLIER_HARD_CAP := 3.0

signal campaign_started(player)
signal player_changed(player)

## Modo de jogo: "free" (Arena Livre, infinita) ou "tournament" (Torneio).
var mode: String = "free"
var player
var current_enemy

## Arena Livre: percorre as arenas de data/campaign.json e, ao derrotar o chefe,
## reinicia a sequência com +1 "volta" (lap) — dificuldade cresce sem fim.
var stage_index: int = 0
var lap: int = 0
var _stages: Array[Dictionary] = []

## Sequência de vitórias consecutivas na Arena Livre. Cada vitória aumenta a
## recompensa (ver EconomySystem.streak_reward_multiplier); perder zera tudo.
var win_streak: int = 0

## Torneio: sequência fixa por nível (tier), sem loja/descanso/salvar no meio.
var tourney_tier_id: String = ""
var tourney_round: int = 0
var tourney_prize: int = 0
var _tiers: Array[Dictionary] = []

## Estoque procedural da loja (tipo -> Array de itens) e o nível em que foi
## gerado — rerolha de graça quando o jogador sobe de nível.
var shop_stock: Dictionary = {}
var _shop_roll_level: int = -1

func _ready() -> void:
	_stages = ContentRepositoryScript.load_campaign()
	_tiers = ContentRepositoryScript.load_tournaments()

# --- Arena Livre (free) -----------------------------------------------------

func stage_total() -> int:
	return _stages.size()

func current_stage() -> Dictionary:
	if mode != "free" or _stages.is_empty() or stage_index < 0 or stage_index >= _stages.size():
		return {}
	return _stages[stage_index]

func current_stage_name() -> String:
	if mode == "tournament":
		return "%s — Combate %d/%d" % [tournament_tier_name(), tourney_round + 1, tournament_round_total()]
	return "Arena Livre"

func is_boss_stage() -> bool:
	if mode == "tournament":
		return tourney_round >= tournament_round_total() - 1
	return bool(current_stage().get("boss", false))

func arena_number() -> int:
	if mode == "tournament":
		return tourney_round + 1
	return stage_index + 1

func enemy_level_for_current_stage() -> int:
	if player == null:
		return 1
	if mode == "tournament":
		return maxi(1, player.level + _tier_index(tourney_tier_id) * 2 + tourney_round)
	return maxi(1, player.level + int(current_stage().get("level_offset", 0)) + lap * 2)

func build_current_foe():
	if mode == "tournament":
		var enemies := ContentRepositoryScript.load_enemies()
		var tier := tournament_tier()
		if tier.is_empty() or tourney_round < 0 or tourney_round >= tournament_round_total():
			return null
		var enemy_id := str(tier.get("rounds", [])[tourney_round])
		var template := ContentRepositoryScript.find_enemy(enemies, enemy_id)
		if template.is_empty():
			return null
		return CombatResolverScript.enemy_for_level(enemy_level_for_current_stage(), template)
	# Arena Livre: inimigo procedural com nível/atributos/tier/tipo aleatórios
	# e um conjunto de equipamento (itens de data/items.json afetam o status).
	# A FAIXA DE ARENA (ideia 9) eleva o nível do inimigo nas faixas maiores:
	# quanto maior o rank, mais ouro E mais risco.
	if player == null:
		return null
	var band := arena_band()
	var level_bonus := int(band.get("enemy_level_bonus", 0))
	return GladiatorDataScript.new(CombatResolverScript.generate_enemy(player.level + level_bonus, ContentRepositoryScript.load_items()))

# --- Torneio -----------------------------------------------------------------

func is_tournament() -> bool:
	return mode == "tournament"

func tournament_tiers() -> Array[Dictionary]:
	return _tiers.duplicate()

func tournament_tier() -> Dictionary:
	return _tier_by_id(tourney_tier_id)

func tournament_tier_name() -> String:
	return str(tournament_tier().get("name", "Torneio"))

func tournament_round_total() -> int:
	return int(tournament_tier().get("rounds", []).size())

func tournament_prize() -> int:
	return tourney_prize

## Inicia um torneio com o personagem atual (sem loja/descanso; não salva).
## BLOQUEIA por RANK (item I): Torneio Menor exige Pedra, Maior exige Aço,
## Grande exige Ouro. O motivo do bloqueio é mostrado pela cidade.
func start_tournament(tier_id: String) -> bool:
	if player == null or _tier_by_id(tier_id).is_empty():
		return false
	if not tournament_unlocked(tier_id):
		return false
	mode = "tournament"
	tourney_tier_id = tier_id
	tourney_round = 0
	tourney_prize = 0
	current_enemy = null
	# Entrar no torneio cura a vida cheia: quem vinha machucado da arena lutava a
	# primeira rodada em desvantagem enquanto as seguintes já curavam (heal_full em
	# _on_tournament_victory). O torneio não tem descanso nem loja no meio.
	player.heal_full()
	campaign_started.emit(player)
	player_changed.emit(player)
	return true

## Encerra o torneio e volta ao modo Arena Livre (persiste ganhos no save).
func finish_tournament() -> void:
	mode = "free"
	save_progress()

func _tier_index(tier_id: String) -> int:
	for i in _tiers.size():
		if str(_tiers[i].get("id", "")) == tier_id:
			return i
	return 0

func _tier_by_id(tier_id: String) -> Dictionary:
	for tier: Dictionary in _tiers:
		if str(tier.get("id", "")) == tier_id:
			return tier
	return {}

# --- Criação / continuação -------------------------------------------------

func start_new_campaign(player_name: String, allocation: Dictionary = {}) -> void:
	player = GladiatorDataScript.new({
		"id": "player",
		"display_name": player_name,
		"archetype_id": "",
		"level": 1,
		"gold": EconomySystemScript.starting_gold(),
		"base_strength": EconomySystemScript.neutral_total("strength", allocation),
		"base_attack": EconomySystemScript.neutral_total("attack", allocation),
		"base_defence": EconomySystemScript.neutral_total("defence", allocation),
		"base_agility": EconomySystemScript.neutral_total("agility", allocation),
		"base_vitality": EconomySystemScript.neutral_total("vitality", allocation),
		"base_charisma": EconomySystemScript.neutral_total("charisma", allocation),
		"base_luck": EconomySystemScript.neutral_total("luck", allocation),
	})
	player.health = player.max_health
	current_enemy = null
	mode = "free"
	stage_index = 0
	lap = 0
	win_streak = 0
	tourney_prize = 0
	shop_stock = {}
	_shop_roll_level = -1
	campaign_started.emit(player)
	player_changed.emit(player)

func has_save() -> bool:
	return SaveSystemScript.has_save()

func save_progress() -> bool:
	if player == null or mode != "free":
		return false
	return SaveSystemScript.save_game(_export_save())

## Salva no modo Arena Livre. Pontos de nível pendentes NÃO impedem o save: eles
## são distribuídos depois, na tela de Personagem, e não podem ser perdidos.
func persist_if_free() -> void:
	if player == null or mode != "free":
		return
	save_progress()

func clear_save() -> void:
	SaveSystemScript.delete_save()

func continue_campaign() -> bool:
	var data := SaveSystemScript.load_game()
	if data.is_empty() or not data.has("player"):
		return false
	_stages = ContentRepositoryScript.load_campaign()
	player = GladiatorDataScript.new(data.get("player", {}))
	stage_index = int(data.get("stage_index", 0))
	lap = int(data.get("lap", 0))
	win_streak = int(data.get("win_streak", 0))
	current_enemy = null
	mode = "free"
	tourney_prize = 0
	shop_stock = {}
	_shop_roll_level = -1
	campaign_started.emit(player)
	player_changed.emit(player)
	return true

func _export_save() -> Dictionary:
	return {"version": 2, "stage_index": stage_index, "lap": lap, "win_streak": win_streak, "player": player.to_save_data()}

# --- Rank / KD / faixas de arena (item I e ideia 9) -------------------------

## Rating do adversário atual (usa o inimigo materializado; se não houver,
## deriva do nível/tier da arena corrente — o torneio monta o inimigo no build).
func opponent_rating() -> int:
	if player == null:
		return 0
	if current_enemy != null:
		return RankSystemScript.opponent_rating_for(current_enemy)
	var tier := 1
	if mode == "tournament":
		tier = _tier_index(tourney_tier_id) + 1
	return RankSystemScript.opponent_rating(enemy_level_for_current_stage(), tier, false)

## Aplica o resultado de UMA luta ao rank/KD do jogador e devolve o antes/depois
## (delta, títulos, promoção/rebaixa). Só mexe em pontos/wins/losses.
func apply_rank_result(victory: bool) -> Dictionary:
	if player == null:
		return {}
	return RankSystemScript.apply_to(player, opponent_rating(), victory)

## Faixa de arena da Arena Livre conforme o rank (ideia 9).
func arena_band() -> Dictionary:
	var points := 0
	if player != null:
		points = int(player.rank_points)
	return RankSystemScript.arena_band_for(points)

func arena_band_title() -> String:
	return str(arena_band().get("title", "Arenas de Areia"))

## Requisito de rank de um torneio (0 = livre).
func tournament_requirement(tier_id: String) -> int:
	return RankSystemScript.requirement_for(tier_id)

func tournament_unlocked(tier_id: String) -> bool:
	if player == null:
		return false
	return RankSystemScript.meets(int(player.rank_points), tier_id)

## Motivo visível do bloqueio ("" quando liberado).
func tournament_lock_reason(tier_id: String) -> String:
	var points := 0
	if player != null:
		points = int(player.rank_points)
	return RankSystemScript.lock_reason(points, tier_id)

func player_rank_title() -> String:
	var points := 0
	if player != null:
		points = int(player.rank_points)
	return RankSystemScript.title_for(points)

# --- Vitória / derrota -----------------------------------------------------

## Aplica a recompensa e avança o modo atual. Retorna o que a tela de resultado
## precisa mostrar (gold de bolso na Arena Livre; prêmio acumulado no torneio).
## `crowd_multiplier` é o multiplicador da felicidade do público (item H, ×1,0 a
## ×2,0) e vale UMA vez, no fim da luta, só sobre o OURO.
func on_victory(gold_reward: int, xp_reward: int, crowd_multiplier: float = 1.0) -> Dictionary:
	if player == null:
		return {"gold": 0, "prize": 0, "experience": 0, "leveled_up": false, "campaign_cleared": false, "tournament": false}
	# RANK/KD (item I): vencer move o rank conforme a força do adversário.
	var rank_info: Dictionary = apply_rank_result(true)
	# O teto do público sobe com o rank (arena mais lotada): o clamp NÃO pode
	# cortar em ×2,0, senão o bônus de rank não chega à recompensa.
	var crowd := clampf(crowd_multiplier, 1.0, MULTIPLIER_HARD_CAP)
	var result: Dictionary
	if mode == "tournament":
		result = _on_tournament_victory(gold_reward, xp_reward, crowd)
	else:
		result = _on_free_victory(gold_reward, xp_reward, crowd)
	result["rank"] = rank_info
	return result

## Vitória na Arena Livre. A FAIXA DE ARENA (ideia 9) multiplica o ouro: faixas
## maiores pagam mais.
func _on_free_victory(gold_reward: int, xp_reward: int, crowd: float) -> Dictionary:
	# Arena Livre: recompensa escala pelo tier do inimigo E pela sequência de
	# vitórias (win streak). Perder zera a sequência — por isso vale descansar
	# para continuar vencendo e não perder o bônus acumulado.
	win_streak += 1
	var mult := 1.0
	if current_enemy != null:
		mult = float(current_enemy.reward_multiplier)
	var streak_mult := EconomySystemScript.streak_reward_multiplier(win_streak)
	var band_mult := float(arena_band().get("gold_multiplier", 1.0))
	# Ouro: escala com o tier do inimigo E com a sequência de vitórias E com a
	# felicidade do público (item H) E com a faixa de arena (ideia 9).
	var gold_gain := int(round(float(maxi(0, gold_reward)) * mult * streak_mult * crowd * band_mult))
	# XP: escala SÓ com o tier (bônus pequeno). A sequência multiplicava o XP também,
	# e com 5 vitórias seguidas no nível 1 a luta rendia mais XP que o nível exigia —
	# o personagem subia de nível a cada luta.
	var enemy_tier: int = 1
	if current_enemy != null:
		enemy_tier = int(current_enemy.enemy_tier)
	var tier_xp_mult := EconomySystemScript.tier_experience_multiplier(enemy_tier)
	var xp_gain := int(round(float(maxi(0, xp_reward)) * tier_xp_mult))
	player.gold += gold_gain
	var leveled_up: bool = player.grant_experience(xp_gain)
	player_changed.emit(player)
	return {"gold": gold_gain, "prize": 0, "experience": xp_gain, "leveled_up": leveled_up, "campaign_cleared": false, "tournament": false, "streak": win_streak, "streak_bonus_pct": EconomySystemScript.streak_bonus_percent(win_streak), "band": str(arena_band().get("id", "areia"))}

func _on_tournament_victory(gold_reward: int, xp_reward: int, crowd_multiplier: float = 1.0) -> Dictionary:
	var tier := tournament_tier()
	var multiplier := float(tier.get("reward_multiplier", 1.0))
	# Mesma arena do item H: a felicidade do público multiplica o prêmio da rodada.
	var gold_prize := int(round(float(maxi(0, gold_reward)) * multiplier * clampf(crowd_multiplier, 1.0, 2.0)))
	var xp_gain := int(round(float(maxi(0, xp_reward)) * multiplier))
	var leveled_up: bool = player.grant_experience(xp_gain)
	tourney_prize += gold_prize
	var final_round := is_boss_stage()
	var tier_index := _tier_index(tourney_tier_id)
	# Cada rodada vencida entrega UM item (raridade com piso pelo tier). Antes o
	# torneio dava só ouro e XP: vencer não deixava nada na mão do jogador.
	var loot: Array[Dictionary] = []
	var round_item := _grant_reward_item(int(player.level), tier_index)
	if not round_item.is_empty():
		loot.append(round_item)
	var cleared := false
	if final_round:
		# Campeão: leva todo o prêmio + o item único do Grande Gladiador — agora ele
		# entra na BOLSA (antes era equipado em silêncio, então o prêmio não aparecia).
		player.gold += tourney_prize
		var trophy := _grant_unique_item("gladius_magnus")
		if not trophy.is_empty():
			loot.append(trophy)
		cleared = true
	else:
		tourney_round += 1
	# Regra do torneio: vencer uma luta devolve a vida cheia para o próximo.
	player.heal_full()
	player_changed.emit(player)
	return {"gold": 0, "prize": gold_prize, "experience": xp_gain, "leveled_up": leveled_up, "campaign_cleared": cleared, "tournament": true, "loot": loot}

## Prêmio de rodada: item procedural que vai para a bolsa (não equipa à força) e
## volta para a tela de resultado exibir a ficha.
func _grant_reward_item(player_level: int, tier_index: int) -> Dictionary:
	if player == null:
		return {}
	var minimum_rarity := clampi(tier_index, 0, 2)
	var item := ItemGeneratorScript.generate_reward_item(player_level, minimum_rarity)
	if item.is_empty():
		return {}
	player.remember_item(item)
	return item

func _grant_unique_item(item_id: String) -> Dictionary:
	var item := ContentRepositoryScript.find_item(ContentRepositoryScript.load_items(), item_id)
	if item.is_empty() or player == null:
		return {}
	if not player.owns_item(item_id):
		player.remember_item(item)
	player_changed.emit(player)
	return item

# --- Venda de itens da bolsa -----------------------------------------------

## Vende um item da bolsa (nunca o equipado) e credita 40% do preço de compra.
## Devolve valor, nome e o motivo quando recusa — a interface mostra o motivo.
func sell_item(item_id: String) -> Dictionary:
	var info := {"ok": false, "gold": 0, "name": "", "reason": ""}
	if player == null:
		info["reason"] = "sem personagem"
		return info
	var item: Dictionary = player.catalog_item(item_id)
	if item.is_empty():
		info["reason"] = "item desconhecido"
		return info
	info["name"] = str(item.get("display_name", "Item"))
	if player.is_equipped(item_id):
		info["reason"] = "está equipado: desequipe antes de vender"
		return info
	if not EconomySystemScript.is_sellable(item):
		info["reason"] = "item único de torneio: não pode ser vendido"
		return info
	var value := EconomySystemScript.sell_price(item)
	if not player.remove_owned(item_id):
		info["reason"] = "não foi possível remover da bolsa"
		return info
	player.gold += value
	info["ok"] = true
	info["gold"] = value
	player_changed.emit(player)
	save_progress()
	return info

## Derrota: Arena Livre perde 25% do ouro e acorda curado (segue o jogo);
## Torneio encerra a inscrição e devolve apenas metade do prêmio acumulado.
func on_defeat() -> Dictionary:
	# RANK/KD (item I): perder SEMPRE tira pontos (perder para rank menor dói mais).
	var rank_info: Dictionary = apply_rank_result(false)
	var result: Dictionary
	if mode == "tournament":
		result = _on_tournament_defeat()
	else:
		result = _on_free_defeat()
	result["rank"] = rank_info
	return result

func _on_free_defeat() -> Dictionary:
	# Perder na Arena Livre zera a sequência de vitórias (adeus, bônus).
	win_streak = 0
	var boss := is_boss_stage()
	var penalty := 0
	if player != null:
		penalty = int(ceil(player.gold * 0.25))
		player.gold = maxi(0, player.gold - penalty)
		player.heal_full()
		player_changed.emit(player)
	return {"penalty": penalty, "boss": boss, "campaign_lost": false, "tournament": false}

func _on_tournament_defeat() -> Dictionary:
	var kept := int(floor(tourney_prize * 0.5))
	var penalty := tourney_prize - kept
	if player != null:
		player.gold += kept
		player.heal_full()
	tourney_prize = 0
	player_changed.emit(player)
	return {"penalty": penalty, "boss": is_boss_stage(), "campaign_lost": true, "tournament": true, "kept": kept}

func rest() -> Dictionary:
	## Descanso pago: cada ponto de vida/armadura faltante custa ouro (sobe com o
	## nível). Restaura vida e armadura juntas. Sem ouro suficiente, recupera
	## apenas a parte proporcional ao ouro disponível (vida primeiro, depois armadura).
	var info := {"healed": 0, "cost": 0, "full": false, "missing": 0}
	if player == null:
		return info
	var missing: int = int(player.missing_pool())
	info["missing"] = missing
	if missing == 0:
		return info
	var per_unit := EconomySystemScript.rest_hp_price(player.level)
	var full_cost := missing * per_unit
	if player.gold >= full_cost:
		player.gold -= full_cost
		player.heal_full()
		info = {"healed": missing, "cost": full_cost, "full": true, "missing": missing}
	else:
		var units := mini(missing, int(player.gold / per_unit))
		var cost := units * per_unit
		player.gold -= cost
		_apply_rest_units(units)
		info = {"healed": units, "cost": cost, "full": units >= missing, "missing": missing}
	player_changed.emit(player)
	save_progress()
	return info

## Recupera `units` pontos de descanso: enche a vida primeiro, depois a armadura.
func _apply_rest_units(units: int) -> void:
	var remaining := units
	var to_health := mini(remaining, maxi(0, player.max_health - player.health))
	player.health += to_health
	remaining -= to_health
	var to_armour := mini(remaining, maxi(0, player.max_armour - player.armour))
	player.armour += to_armour

## Custo em ouro do descanso completo (toda a vida faltante).
func full_rest_cost() -> int:
	return EconomySystemScript.full_rest_cost(player)

# --- Loja procedural (estoque, reroll) --------------------------------------

## Rerrolla (grátis) quando o jogador sobe de nível; senão devolve o estoque.
func ensure_shop_stock() -> Dictionary:
	if player == null:
		return {}
	if shop_stock.is_empty() or _shop_roll_level != player.level:
		shop_stock = ItemGeneratorScript.generate_shop_stock(player.level)
		_shop_roll_level = player.level
	return shop_stock

func shop_stock_for(subtype: String) -> Array:
	ensure_shop_stock()
	return shop_stock.get(subtype, [])

func shop_reroll_cost() -> int:
	return EconomySystemScript.shop_reroll_cost(player.level if player != null else 1)

## Reroll pago (mesmo nível). Retorna {ok, cost}.
func reroll_shop() -> Dictionary:
	var cost := shop_reroll_cost()
	if player == null or player.gold < cost:
		return {"ok": false, "cost": cost}
	player.gold -= cost
	shop_stock = ItemGeneratorScript.generate_shop_stock(player.level)
	_shop_roll_level = player.level
	player_changed.emit(player)
	save_progress()
	return {"ok": true, "cost": cost}

## Resolve o dicionário de um item: primeiro o catálogo do jogador (itens
## processuais), depois o conteúdo estático data/items.json (legado/único).
func item_data(item_id: String) -> Dictionary:
	if item_id == "":
		return {}
	if player != null:
		var owned: Dictionary = player.catalog_item(item_id)
		if not owned.is_empty():
			return owned
	return ContentRepositoryScript.find_item(ContentRepositoryScript.load_items(), item_id)

# --- Equipamento / loja ----------------------------------------------------

func equip_item(item: Dictionary) -> void:
	if player == null or item.is_empty():
		return
	player.equip_item(item)
	player_changed.emit(player)
	save_progress()

## Desequipa um slot: o item volta para a bolsa (usado pelo arrastar-e-soltar).
func unequip_slot(slot: String) -> bool:
	if player == null:
		return false
	if not player.unequip(slot):
		return false
	player_changed.emit(player)
	save_progress()
	return true

## Coloca um item na bolsa (ganho de prêmio, por exemplo) sem equipar.
func add_item_to_bag(item: Dictionary) -> bool:
	if player == null or item.is_empty():
		return false
	player.remember_item(item)
	player_changed.emit(player)
	save_progress()
	return true

func purchase_item(item: Dictionary) -> bool:
	if player == null or item.is_empty():
		return false
	var price := EconomySystemScript.price_for_player(item, player)
	if player.gold < price:
		return false
	player.gold -= price
	equip_item(item)
	return true

## Preço de compra para o jogador atual (com o desconto de CARISMA/SORTE).
func item_price(item: Dictionary) -> int:
	return EconomySystemScript.price_for_player(item, player)

# --- Nível -------------------------------------------------------------

## Os SETE atributos entre os quais os pontos de nível são distribuídos.
func attribute_definitions() -> Array[Dictionary]:
	return EconomySystemScript.attribute_definitions()

## Gasta um dos pontos pendentes no atributo escolhido (tela de Personagem).
func spend_attribute_point(attribute_id: String) -> bool:
	if player == null:
		return false
	if player.spend_attribute_point(attribute_id):
		player_changed.emit(player)
		save_progress()
		return true
	return false

## Habilidade do arquétipo (Investida / Golpe Devastador / Estocada).
##
## Na prática devolve vazio, e isso é esperado: a criação do personagem é NEUTRA
## de propósito (creation_screen.gd — "criação neutra (sem classe)") e nada no jogo
## grava um archetype_id no jogador. A arena já sabe usar o dicionário quando ele
## existir (botão de habilidade + CombatResolver), então falta só a escolha de
## classe na criação — decisão de design, não bug de código.
func player_skill() -> Dictionary:
	if player == null:
		return {}
	var archetype_id := str(player.archetype_id)
	if archetype_id == "":
		return {}
	for entry: Dictionary in ContentRepositoryScript.load_archetypes():
		if str(entry.get("id", "")) == archetype_id:
			return entry.get("skill", {})
	return {}

## Item (dicionário de conteúdo) da arma equipada no momento.
func player_weapon() -> Dictionary:
	if player == null:
		return {}
	return item_data(player.equipped_id("weapon"))

## Habilidade exclusiva de um inimigo (dados em data/enemies.json).
func enemy_special(enemy_id: String) -> Dictionary:
	var enemies := ContentRepositoryScript.load_enemies()
	var template := ContentRepositoryScript.find_enemy(enemies, enemy_id)
	return template.get("special", {})

