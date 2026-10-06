class_name EconomySystem
extends RefCounted

## Regras puras de economia: recompensas por luta e preços de serviços.
## Sem interface ou estado global; números centralizados para playtest
## e comparação de balanceamento em docs/BALANCEAMENTO.md.

static func fight_rewards(player_level: int) -> Dictionary:
	var level: int = maxi(1, player_level)
	return {
		"gold": 16 + level * 8,
		"experience": 18 + level * 7,
	}

## Soma dos bônus de um item de conteúdo (usado para comparar melhorias).
static func item_total_bonus(item: Dictionary) -> int:
	return int(item.get("attack_bonus", 0)) + int(item.get("defense_bonus", 0))

# --- Serviços: descanso e reroll da loja ----------------------------------

## Preço em ouro por ponto de vida recuperado no descanso (sobe devagar com o
## nível). Mantido baixo para o descanso ser atrativo: uma vitória cobre o
## descanso típico com lucro (morrer de propósito vira prejuízo).
static func rest_hp_price(player_level: int) -> int:
	return maxi(1, 1 + int(maxi(1, player_level) / 6))

## Custo para recuperar toda a vida que falta no descanso.
static func full_rest_cost(player) -> int:
	if player == null:
		return 0
	var missing := maxi(0, int(player.max_health) - int(player.health))
	return missing * rest_hp_price(int(player.level))

## Custo (em ouro) para rerolar o estoque da loja.
static func shop_reroll_cost(player_level: int) -> int:
	return 15 + maxi(1, player_level) * 5

# --- Sequência de vitórias (Arena Livre) -----------------------------------

## Multiplicador de recompensa pela sequência de vitórias: +12% por vitória
## consecutiva, até +180% (15 vitórias seguidas).
static func streak_reward_multiplier(win_streak: int) -> float:
	return 1.0 + 0.12 * float(maxi(0, mini(win_streak, 15)))

## Bônus percentual exibido na interface (ex.: 60 = +60%).
static func streak_bonus_percent(win_streak: int) -> int:
	return int(round((streak_reward_multiplier(win_streak) - 1.0) * 100.0))

## Opções de treino ao subir de nível. A aplicação é genérica no modelo
## (base_* + amount, com cura opcional).
static func level_up_options() -> Array[Dictionary]:
	return [
		{"id": "vigor", "label": "Vigor", "description": "+12 de vida máxima e cura completa", "stat": "base_max_health", "amount": 12, "heal": true},
		{"id": "power", "label": "Força", "description": "+3 de ataque", "stat": "base_attack", "amount": 3, "heal": false},
		{"id": "guard", "label": "Proteção", "description": "+3 de defesa", "stat": "base_defense", "amount": 3, "heal": false},
		{"id": "luck", "label": "Sorte", "description": "+2 de sorte", "stat": "base_luck", "amount": 2, "heal": false},
	]

# --- Criação neutra (sem classe) -----------------------------------------

## Pontos de atributo disponíveis e dinheiro inicial para a loja.
static func creation_points() -> int:
	return 12

static func starting_gold() -> int:
	return 80

## Perfis dos quatro atributos: valor base neutro + ganho por ponto.
static func creation_stats() -> Dictionary:
	return {
		"health": {"label": "Vida", "base": 46, "per_point": 6, "stat": "base_max_health"},
		"attack": {"label": "Força", "base": 8, "per_point": 1, "stat": "base_attack"},
		"defense": {"label": "Defesa", "base": 3, "per_point": 1, "stat": "base_defense"},
		"luck": {"label": "Sorte", "base": 5, "per_point": 1, "stat": "base_luck"},
	}

## Valor final de um atributo dado a distribuição de pontos.
static func neutral_total(stat_id: String, allocation: Dictionary) -> int:
	var spec: Dictionary = creation_stats().get(stat_id, {})
	var count := int(allocation.get(stat_id, 0))
	return int(spec.get("base", 0)) + count * int(spec.get("per_point", 0))
