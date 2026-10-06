class_name EconomySystem
extends RefCounted

## Regras puras de economia: recompensas por luta e preços de serviços.
## Sem interface ou estado global; números centralizados para playtest
## e comparação de balanceamento em docs/BALANCEAMENTO.md.

## Recompensa base de uma luta na Arena Livre, por nível do jogador.
## O XP cresce devagar de propósito: a curva é calibrada para exigir de ~3 lutas
## por nível (nível 1) a ~5 (nível 15) — ver required_experience(). A sequência de
## vitórias multiplica SÓ o ouro (ver GameState.on_victory): antes ela multiplicava
## o XP também e o personagem subia de nível a cada luta.
static func fight_rewards(player_level: int) -> Dictionary:
	var level: int = maxi(1, player_level)
	return {
		"gold": 16 + level * 8,
		"experience": 12 + level * 8,
	}

## XP necessário para sair do nível informado. Fonte única da verdade (o modelo
## GladiatorData.required_experience delega para cá).
static func required_experience(player_level: int) -> int:
	return 60 + (maxi(1, player_level) - 1) * 40

## Bônus de XP por enfrentar um inimigo mais forte (tier): pequeno de propósito,
## para um inimigo elite não valer um nível inteiro sozinho.
static func tier_experience_multiplier(enemy_tier: int) -> float:
	return 1.0 + 0.15 * float(maxi(0, enemy_tier - 1))

# --- Venda de itens --------------------------------------------------------

## Fração do preço de compra devolvida na venda. Vender é sempre prejuízo, mas
## devolve ouro para o próximo passo (a bolsa não é um depósito morto).
const SELL_RATIO := 0.4

## Preço de venda de um item (o item único de torneio não tem preço: não é vendável).
static func sell_price(item: Dictionary) -> int:
	if item.is_empty() or not is_sellable(item):
		return 0
	return maxi(1, int(round(float(int(item.get("price", 0))) * SELL_RATIO)))

## Item único (prêmio de torneio) não pode ser vendido.
static func is_sellable(item: Dictionary) -> bool:
	return not bool(item.get("unique", false))

## Soma dos bônus de um item de conteúdo (usado para comparar melhorias).
static func item_total_bonus(item: Dictionary) -> int:
	return int(item.get("strength_bonus", 0)) + int(item.get("attack_bonus", 0)) + int(item.get("defence_bonus", 0)) + int(item.get("agility_bonus", 0)) + int(item.get("vitality_bonus", 0)) + int(item.get("charisma_bonus", 0)) + int(item.get("luck_bonus", 0)) + int(item.get("armour", 0))

# --- Serviços: descanso e reroll da loja ----------------------------------

## Preço em ouro por ponto de vida recuperado no descanso (sobe devagar com o
## nível). Mantido baixo para o descanso ser atrativo: uma vitória cobre o
## descanso típico com lucro (morrer de propósito vira prejuízo).
static func rest_hp_price(player_level: int) -> int:
	return maxi(1, 1 + int(maxi(1, player_level) / 6))

## Custo para recuperar toda a vida E a armadura que faltam no descanso.
static func full_rest_cost(player) -> int:
	if player == null:
		return 0
	var missing := 0
	if player.has_method("missing_pool"):
		missing = int(player.missing_pool())
	else:
		missing = maxi(0, int(player.max_health) - int(player.health))
	return missing * rest_hp_price(int(player.level))

## Custo (em ouro) para rerolar o estoque da loja.
static func shop_reroll_cost(player_level: int) -> int:
	return 15 + maxi(1, player_level) * 5

# --- Serviços da cidade (item 10): médico, ferreiro e treinador -------------

## Preço de cura de UM ferimento no médico (sobe devagar com o nível).
const INJURY_CURE_BASE := 20
const INJURY_CURE_PER_LEVEL := 5

static func injury_cure_price(player_level: int) -> int:
	return INJURY_CURE_BASE + maxi(1, player_level) * INJURY_CURE_PER_LEVEL

## Custo do MÉDICO: recupera toda a vida + armadura que faltam E cura TODOS os
## ferimentos (é o único jeito pago de tirar sequela; a poção de ferimento cura
## um por vez, dentro da luta).
static func doctor_cost(player) -> int:
	if player == null:
		return 0
	var pool_cost := full_rest_cost(player)
	var count := 0
	if "injuries" in player:
		count = (player.injuries as Array).size()
	return pool_cost + count * injury_cure_price(int(player.level))

## FERREIRO: teto de melhorias por item (a proteção não pode virar infinita).
const BLACKSMITH_MAX_UPGRADES := 5
const BLACKSMITH_ARMOUR_PER_UPGRADE := 1

static func blacksmith_max() -> int:
	return BLACKSMITH_MAX_UPGRADES

## Custo de UMA melhoria de armadura de um item: sobe a cada melhoria já feita.
static func blacksmith_cost(item: Dictionary, current_upgrades: int) -> int:
	if item.is_empty():
		return 0
	var lvl := maxi(1, int(item.get("level", 1)))
	return 25 + lvl * 6 + maxi(0, current_upgrades) * 18

## TREINADOR: fração do XP do nível que dá para COMPRAR (o resto é na luta). O
## teto por nível impede que o ouro fure a curva de progressão.
const TRAINER_MAX_FRACTION := 0.35

static func trainer_cap(player) -> int:
	if player == null:
		return 0
	return int(floor(float(required_experience(int(player.level))) * TRAINER_MAX_FRACTION))

## XP que UMA sessão de treino dá (quem aplica o teto é o GameState).
static func trainer_gain(player) -> int:
	if player == null:
		return 0
	return 8 + int(player.level) * 4

## Custo em ouro de UMA sessão de treino.
static func trainer_cost(player) -> int:
	if player == null:
		return 0
	return 25 + int(player.level) * 10

# --- Sequência de vitórias (Arena Livre) -----------------------------------

## Multiplicador de recompensa pela sequência de vitórias: +12% por vitória
## consecutiva, até +180% (15 vitórias seguidas).
static func streak_reward_multiplier(win_streak: int) -> float:
	return 1.0 + 0.12 * float(maxi(0, mini(win_streak, 15)))

## Bônus percentual exibido na interface (ex.: 60 = +60%).
static func streak_bonus_percent(win_streak: int) -> int:
	return int(round((streak_reward_multiplier(win_streak) - 1.0) * 100.0))

# --- Atributos (7) ---------------------------------------------------------

## Pontos de atributo ganhos por nível: distribuídos entre os 7 atributos.
static func attribute_points_per_level() -> int:
	return 4

## Os SETE atributos do jogo. STA e MAG não existem nesta versão.
## `stat` é o campo base_* do modelo; `short` é a sigla usada nas telas.
static func attribute_definitions() -> Array[Dictionary]:
	return [
		{"id": "strength", "label": "Força", "short": "STR", "stat": "base_strength"},
		{"id": "attack", "label": "Ataque", "short": "ATT", "stat": "base_attack"},
		{"id": "defence", "label": "Defesa", "short": "DEF", "stat": "base_defence"},
		{"id": "agility", "label": "Agilidade", "short": "AGI", "stat": "base_agility"},
		{"id": "vitality", "label": "Vitalidade", "short": "VIT", "stat": "base_vitality"},
		{"id": "charisma", "label": "Carisma", "short": "CHA", "stat": "base_charisma"},
		{"id": "luck", "label": "Sorte", "short": "SOR", "stat": "base_luck"},
	]

# --- Criação neutra (sem classe) -----------------------------------------

## Pontos de atributo disponíveis e dinheiro inicial para a loja.
static func creation_points() -> int:
	return 20

static func starting_gold() -> int:
	return 80

## Perfis dos SETE atributos: valor base neutro + ganho por ponto.
static func creation_stats() -> Dictionary:
	return {
		"strength": {"label": "Força", "short": "STR", "base": 8, "per_point": 1, "stat": "base_strength"},
		"attack": {"label": "Ataque", "short": "ATT", "base": 8, "per_point": 1, "stat": "base_attack"},
		"defence": {"label": "Defesa", "short": "DEF", "base": 3, "per_point": 1, "stat": "base_defence"},
		"agility": {"label": "Agilidade", "short": "AGI", "base": 5, "per_point": 1, "stat": "base_agility"},
		"vitality": {"label": "Vitalidade", "short": "VIT", "base": 6, "per_point": 1, "stat": "base_vitality"},
		"charisma": {"label": "Carisma", "short": "CHA", "base": 5, "per_point": 1, "stat": "base_charisma"},
		"luck": {"label": "Sorte", "short": "SOR", "base": 5, "per_point": 1, "stat": "base_luck"},
	}

## Valor final de um atributo dado a distribuição de pontos.
static func neutral_total(stat_id: String, allocation: Dictionary) -> int:
	var spec: Dictionary = creation_stats().get(stat_id, {})
	var count := int(allocation.get(stat_id, 0))
	return int(spec.get("base", 0)) + count * int(spec.get("per_point", 0))

# --- Desconto/pechincha na loja -------------------------------------------

## Desconto de MERCADO na loja: CARISMA é o principal; SORTE ajuda. É o preço bom
## de praxe do comerciante, pequeno de propósito (teto 15%): quem quer desconto de
## verdade PECHINCHA (HaggleSystem), que soma a este e sobe até 35% no total.
static func shop_discount(player) -> float:
	if player == null:
		return 0.0
	var cha := float(player.charisma)
	var luk := float(player.luck)
	return clampf(cha * 0.004 + luk * 0.002, 0.0, 0.15)

## Preço efetivo de compra para um jogador: desconto de MERCADO (CARISMA/SORTE)
## MAIS o desconto conquistado na PECHINCHA daquele item (se ganhou), com o teto
## total de 35%. Item nunca haggled = só o desconto de mercado.
static func price_for_player(item: Dictionary, player) -> int:
	var base := int(item.get("price", 0))
	if base <= 0:
		return 0
	var discount := 0.0
	if player != null:
		discount = shop_discount(player)
		if player.has_method("haggle_mark_for"):
			var mark: Dictionary = player.haggle_mark_for(str(item.get("id", "")))
			if str(mark.get("result", "")) == "won":
				discount += float(mark.get("discount", 0.0))
	discount = clampf(discount, 0.0, 0.35)
	var discounted := float(base) * (1.0 - discount)
	return maxi(1, int(round(discounted)))
