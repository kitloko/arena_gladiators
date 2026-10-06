class_name ItemGenerator
extends RefCounted

## Geração procedural de itens da loja: cada tipo (ex.: adagas) pode mostrar até
## N itens diferentes, com nível, raridade e bônus aleatórios que escalam com o
## nível do jogador. Regras puras: não acessa estado global nem interface.
##
## Bônus conforme a peça: armas dão STR (dano), ATT (precisão), AGI e SOR;
## peças de proteção dão 'armour' (pool separado da vida), DEF, VIT, AGI, SOR e CHA.

const PER_TYPE := 3

const RARITIES := [
	{"id": "comum", "label": "Comum", "weight": 45, "mult": 1.0, "color": "b9b0be"},
	{"id": "incomum", "label": "Incomum", "weight": 30, "mult": 1.25, "color": "79cf7b"},
	{"id": "raro", "label": "Raro", "weight": 17, "mult": 1.55, "color": "70b9e8"},
	{"id": "epico", "label": "Épico", "weight": 8, "mult": 1.95, "color": "c06ee0"},
]

## Chaves de bônus que um item pode ter (armour é 1/8 da "escada" de atributos;
## entra no preço com peso reduzido porque é pool, não atributo).
const BONUS_KEYS := ["str", "att", "def", "agi", "vit", "cha", "luck", "armour"]

## Categorias de topo da loja com seus tipos (subcategorias).
static func top_categories() -> Array[Dictionary]:
	return [
		{"id": "arma", "label": "ARMAS", "subtypes": _weapon_types()},
		{"id": "armadura", "label": "ARMADURAS", "subtypes": _armor_types()},
	]

## Perfis por tipo de arma (bônus base por nível 1, raridade comum).
static func _weapon_types() -> Array[Dictionary]:
	return [
		{"id": "espada", "label": "Espadas", "slot": "weapon", "kind": "melee", "reach": 1, "hands": 1, "nouns": ["Espada curta", "Espada de aço", "Espada longa", "Gládio"], "profile": {"str": 3.2}},
		{"id": "adaga", "label": "Adagas", "slot": "weapon", "kind": "melee", "reach": 1, "hands": 1, "nouns": ["Adaga", "Adaga serrilhada", "Estilete", "Punhal"], "profile": {"str": 1.7, "agi": 1.5, "luck": 1.0}},
		{"id": "machado", "label": "Machados", "slot": "weapon", "kind": "melee", "reach": 1, "hands": 1, "nouns": ["Machado de 1 mão", "Machado de batalha", "Machado largo"], "profile": {"str": 4.4}},
		{"id": "lanca", "label": "Lanças", "slot": "weapon", "kind": "melee", "reach": 2, "hands": 2, "nouns": ["Lança", "Lança longa", "Pique"], "profile": {"str": 2.7, "att": 0.8, "def": 0.8}},
		{"id": "arco", "label": "Arcos", "slot": "weapon", "kind": "ranged", "reach": 1, "hands": 2, "nouns": ["Arco curto", "Arco de caça", "Arco composto"], "profile": {"str": 2.9, "att": 1.0}},
		{"id": "besta", "label": "Bestas", "slot": "weapon", "kind": "ranged", "reach": 1, "hands": 2, "nouns": ["Besta", "Besta de guerra"], "profile": {"str": 3.9, "att": 1.0}},
		{"id": "arremesso", "label": "Facas de arremesso", "slot": "weapon", "kind": "ranged", "reach": 1, "hands": 1, "nouns": ["Facas de arremesso", "Shuriken"], "profile": {"str": 1.6, "agi": 1.3, "luck": 1.0}},
	]

## Perfis das peças de defesa (um tipo por slot do corpo).
static func _armor_types() -> Array[Dictionary]:
	return [
		{"id": "peitoral", "label": "Peitorais", "slot": "armor", "nouns": ["Túnica", "Couraça de couro", "Cota de malha", "Armadura de placas"], "profile": {"armour": 8.0, "vit": 0.5}},
		{"id": "capacete", "label": "Capacetes", "slot": "helmet", "nouns": ["Capuz", "Elmo de ferro", "Elmo cerrado", "Bacinete"], "profile": {"armour": 4.5, "def": 0.8, "luck": 0.8}},
		{"id": "luvas", "label": "Luvas", "slot": "gloves", "nouns": ["Ataduras", "Luvas de couro", "Manoplas de ferro"], "profile": {"str": 0.9, "armour": 2.0}},
		{"id": "botas", "label": "Botas", "slot": "boots", "nouns": ["Sandálias", "Botas de couro", "Grevas de bronze"], "profile": {"armour": 2.2, "agi": 1.1}},
		{"id": "cinto", "label": "Cintos", "slot": "belt", "nouns": ["Cinto de corda", "Cinto de couro", "Cinto de campeão"], "profile": {"armour": 1.6, "vit": 0.8}},
	]

## Rola uma raridade (comum → épico, ponderada).
static func roll_rarity() -> Dictionary:
	var r := randi_range(1, 100)
	if r <= int(RARITIES[0].weight):
		return RARITIES[0]
	if r <= int(RARITIES[0].weight) + int(RARITIES[1].weight):
		return RARITIES[1]
	if r <= int(RARITIES[0].weight) + int(RARITIES[1].weight) + int(RARITIES[2].weight):
		return RARITIES[2]
	return RARITIES[3]

## Estoque completo da loja: até PER_TYPE itens diferentes por tipo.
static func generate_shop_stock(player_level: int, per_type: int = PER_TYPE) -> Dictionary:
	var stock := {}
	for category: Dictionary in top_categories():
		for subtype: Dictionary in category.get("subtypes", []):
			var subtype_id := str(subtype.get("id", ""))
			stock[subtype_id] = _generate_type_items(subtype, maxi(1, player_level), per_type)
	return stock

## Um único item sorteado (tipo, raridade e nível), usado como prêmio de torneio.
## `min_rarity_index` garante um piso de raridade para o tier (0 = comum).
static func generate_reward_item(player_level: int, min_rarity_index: int = 0) -> Dictionary:
	var subtypes: Array[Dictionary] = []
	for category: Dictionary in top_categories():
		for subtype: Dictionary in category.get("subtypes", []):
			subtypes.append(subtype)
	if subtypes.is_empty():
		return {}
	var subtype: Dictionary = subtypes[randi_range(0, subtypes.size() - 1)]
	var nouns: Array = subtype.get("nouns", [])
	var rarity := roll_rarity()
	var wanted := clampi(min_rarity_index, 0, RARITIES.size() - 1)
	if rarity_index(rarity) < wanted:
		rarity = RARITIES[wanted]
	var noun := str(nouns[randi_range(0, maxi(0, nouns.size() - 1))])
	return _make_item(subtype, noun, rarity, maxi(1, player_level + randi_range(0, 1)))

## Posição da raridade na tabela (comum = 0). Comparação por id, nunca por igualdade
## de dicionário.
static func rarity_index(rarity: Dictionary) -> int:
	for index in RARITIES.size():
		if str(RARITIES[index].get("id", "")) == str(rarity.get("id", "")):
			return index
	return 0

static func _generate_type_items(subtype: Dictionary, player_level: int, count: int) -> Array[Dictionary]:
	# `canonical` guarda a ordem do data/*.json (do substantivo mais simples ao mais
	# forte). `nouns` é a cópia embaralhada: decide QUAIS nomes aparecem no estoque.
	var canonical: Array = subtype.get("nouns", [])
	var nouns := canonical.duplicate()
	nouns.shuffle()
	var items: Array[Dictionary] = []
	for i in mini(count, nouns.size()):
		var noun := str(nouns[i])
		# O primeiro item de cada tipo é sempre Comum no nível do jogador, para
		# haver sempre uma opção acessível; o restante é aleatório.
		var rarity := RARITIES[0] if i == 0 else roll_rarity()
		var item_level := player_level if i == 0 else maxi(1, player_level + randi_range(-1, 1))
		var candidate := _make_item(subtype, noun, rarity, item_level)
		# Nomes diferentes devem ter status/preço diferentes: nunca deixar dois
		# itens do mesmo tipo idênticos (mesma raridade, nível e bônus).
		var guard := 0
		while guard < 18 and _collides_with(items, candidate):
			rarity = roll_rarity()
			item_level = maxi(1, player_level + randi_range(-1, 1))
			candidate = _make_item(subtype, noun, rarity, item_level)
			guard += 1
		items.append(candidate)
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("price", 0)) < int(b.get("price", 0)))
	# O nome tem que acompanhar o poder do item. QUAIS substantivos aparecem continua
	# aleatório (o embaralhamento acima), mas a ORDEM entre eles volta a ser a canônica
	# do tipo: sem isto o item mais barato do estoque saía como "Espada longa" e o mais
	# caro como "Espada curta", contradizendo preço e bônus na mesma lista.
	var chosen := nouns.slice(0, items.size())
	chosen.sort_custom(func(a, b) -> bool: return canonical.find(str(a)) < canonical.find(str(b)))
	for index in items.size():
		items[index]["display_name"] = str(chosen[index])
	return items

## Dois itens são "iguais" se têm a mesma raridade, nível, bônus e preço.
static func _collides_with(items: Array, candidate: Dictionary) -> bool:
	for existing: Dictionary in items:
		var same := str(existing.get("rarity", "")) == str(candidate.get("rarity", ""))
		same = same and int(existing.get("level", 0)) == int(candidate.get("level", 0))
		same = same and int(existing.get("price", 0)) == int(candidate.get("price", 0))
		for key: String in BONUS_KEYS:
			if int(existing.get(_bonus_field(key), 0)) != int(candidate.get(_bonus_field(key), 0)):
				same = false
				break
		if same:
			return true
	return false

## Campo do dicionário do item correspondente a uma chave de bônus curta.
static func _bonus_field(key: String) -> String:
	match key:
		"str":
			return "strength_bonus"
		"att":
			return "attack_bonus"
		"def":
			return "defence_bonus"
		"agi":
			return "agility_bonus"
		"vit":
			return "vitality_bonus"
		"cha":
			return "charisma_bonus"
		"luck":
			return "luck_bonus"
	return "armour"

static func _make_item(subtype: Dictionary, noun: String, rarity: Dictionary, item_level: int) -> Dictionary:
	var profile: Dictionary = subtype.get("profile", {})
	var mult := float(rarity.get("mult", 1.0))
	var growth := 1.0 + 0.22 * float(maxi(0, item_level - 1))
	var bonus := {"str": 0, "att": 0, "def": 0, "agi": 0, "vit": 0, "cha": 0, "luck": 0, "armour": 0}
	for key: String in BONUS_KEYS:
		if profile.has(key):
			bonus[key] = maxi(0, roundi(float(profile[key]) * growth * mult) + randi_range(-1, 1))
	var slot := str(subtype.get("slot", "weapon"))
	var category := "arma" if slot == "weapon" else "armadura"
	var total_stats: int = int(bonus["str"]) + int(bonus["att"]) + int(bonus["def"]) + int(bonus["agi"]) + int(bonus["vit"]) + int(bonus["cha"]) + int(bonus["luck"]) + int(round(float(bonus["armour"]) * 0.35))
	var price := int(round((10 + float(total_stats) * (8 + item_level * 2)) * (1.0 + (float(rarity.get("mult", 1.0)) - 1.0) * 0.6)))
	price = maxi(6, price)
	var item := {
		"id": "%s_%s_%s_l%d_%d" % [slot.substr(0, 3), str(subtype.get("id", "item")), str(rarity.get("id", "comum")), item_level, randi_range(1000, 99999)],
		"display_name": noun,
		"slot": slot,
		"subtype": str(subtype.get("id", "")),
		"category": category,
		"level": item_level,
		"rarity": str(rarity.get("label", "Comum")),
		"rarity_color": str(rarity.get("color", "b9b0be")),
		"strength_bonus": int(bonus["str"]),
		"attack_bonus": int(bonus["att"]),
		"defence_bonus": int(bonus["def"]),
		"agility_bonus": int(bonus["agi"]),
		"vitality_bonus": int(bonus["vit"]),
		"charisma_bonus": int(bonus["cha"]),
		"luck_bonus": int(bonus["luck"]),
		"armour": int(bonus["armour"]),
		"price": price,
	}
	if slot == "weapon":
		item["kind"] = str(subtype.get("kind", "melee"))
		item["reach"] = int(subtype.get("reach", 1))
		item["hands"] = int(subtype.get("hands", 1))
	return item

## Ícone (assets/sprites/items/*.png) do item. Funciona para itens processuais
## (pelo "subtype") e para os itens legados de data/items.json (pelo id).
static func item_icon_path(item: Dictionary) -> String:
	if item.is_empty():
		return ""
	var file := str(_ICON_BY_SUBTYPE.get(str(item.get("subtype", "")), ""))
	if file == "":
		file = str(_ICON_BY_ID.get(str(item.get("id", "")), ""))
	if file == "":
		file = str(_ICON_BY_SLOT.get(str(item.get("slot", "")), ""))
	if file == "":
		return ""
	return "res://assets/sprites/items/%s.png" % file

const _ICON_BY_SUBTYPE := {
	"espada": "sword", "adaga": "dagger", "machado": "axe", "lanca": "spear",
	"arco": "bow", "besta": "crossbow", "arremesso": "throwing_knife",
	"peitoral": "armor", "capacete": "helmet", "luvas": "gloves",
	"botas": "boots", "cinto": "belt",
}

const _ICON_BY_ID := {
	"short_sword": "sword", "dagger": "dagger", "hand_axe": "axe", "battle_axe": "axe",
	"spear": "spear", "short_bow": "bow", "crossbow": "crossbow", "throwing_knives": "throwing_knife",
	"gladius_magnus": "sword",
	"cloth_tunic": "armor", "leather_armor": "armor", "chain_mail": "armor", "plate_armor": "armor",
	"cloth_hood": "helmet", "iron_helm": "helmet", "great_helm": "helmet",
	"cloth_wraps": "gloves", "leather_gloves": "gloves", "iron_gauntlets": "gloves",
	"sandals": "boots", "leather_boots": "boots", "greaves": "boots",
	"rope_belt": "belt", "leather_belt": "belt", "champion_belt": "belt",
}

const _ICON_BY_SLOT := {
	"weapon": "sword", "armor": "armor", "helmet": "helmet",
	"gloves": "gloves", "boots": "boots", "belt": "belt",
}
