class_name AssetCatalog
extends RefCounted

## Catálogo de arte gerada (etapa 7 do PLANO_3.0). Ponte entre as TELAS e a arte:
## lê o manifesto res://assets/gen/manifest.json e resolve, por id, o caminho do PNG.
##
## Contrato (docs/ARTE.md §3): os ids são os mesmos das folhas que o dono vai gerar
## (B1/B2/B3 cidades, B4..B8 arenas, B9 plateia). Quando a arte dele chegar, ela
## SUBSTITUI a gerada sem trocar uma linha do jogo — basta o PNG com o mesmo id e
## (re)entrar no manifesto.
##
## Fallback: se o manifesto não existir, o id estiver ausente ou o PNG faltar, as
## telas caem nos assets antigos de assets/sprites/arena/ (o jogo nunca fica sem
## fundo). Nada em assets/sprites/ é apagado ou sobrescrito.

const GEN_DIR := "res://assets/gen/"
const MANIFEST_PATH := GEN_DIR + "manifest.json"
const PLACEHOLDER_PREFIX := GEN_DIR

## Mapa faixa de rank -> cidade (uma por faixa: Areia/Pedra, Ferro/Aço, Prata+).
const CITY_IDS := {"areia": "B1", "ferro": "B2", "prata": "B3"}
## Mapa faixa de rank -> arenas candidatas (a luta sorteia dentro da faixa).
const ARENA_IDS := {"areia": ["B4", "B5"], "ferro": ["B6", "B5"], "prata": ["B7"]}
## Covil vermelho: sempre usado no COMBATE FINAL do torneio.
const BOSS_ARENA_ID := "B8"
const CROWD_ID := "B9"
## Ids que o gerador precisa produzir (usado pelo teste do manifesto).
const REQUIRED_IDS := ["B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8", "B9"]

static var _manifest: Dictionary = {}
static var _loaded := false

## Zera o cache (usado pelo teste do manifesto).
static func reload() -> void:
	_loaded = false
	_manifest = {}

static func manifest() -> Dictionary:
	if not _loaded:
		_loaded = true
		_manifest = _read_manifest()
	return _manifest

static func _read_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}

## Registro de um id no manifesto ({} se ausente).
static func entry(id: String) -> Dictionary:
	var images: Dictionary = manifest().get("images", {})
	var found: Variant = images.get(id, {})
	if found is Dictionary:
		return found
	return {}

## Caminho res:// do PNG de um id — "" quando não existe (a tela usa o fallback).
static func path_for(id: String) -> String:
	if id == "":
		return ""
	var info := entry(id)
	var file := str(info.get("file", ""))
	if file != "":
		var declared := file if file.begins_with("res://") else PLACEHOLDER_PREFIX + file
		if FileAccess.file_exists(declared):
			return declared
	# Sem manifesto (ou entrada ausente): aceita o PNG pelo id direto (é o nome
	# que o cortador do dono grava — <id>.png).
	var direct := PLACEHOLDER_PREFIX + id + ".png"
	if FileAccess.file_exists(direct):
		return direct
	return ""

## Textura de um id (null quando ausente). Funciona mesmo sem o --import ter
## rodado: cai no carregamento direto do PNG por Image.
static func texture(id: String) -> Texture2D:
	var path := path_for(id)
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Texture2D:
			return res
	var image: Image = Image.load_from_file(path)
	if image == null:
		return null
	return ImageTexture.create_from_image(image)

## Id da cidade da faixa de rank (Areia/Pedra, Ferro/Aço, Prata+).
static func city_id(band_id: String) -> String:
	var resolved: Variant = CITY_IDS.get(band_id, CITY_IDS["areia"])
	return str(resolved)

## Ids de arena candidatos para uma faixa.
static func arena_ids(band_id: String) -> Array:
	var resolved: Variant = ARENA_IDS.get(band_id, ARENA_IDS["areia"])
	var list: Array = (resolved as Array).duplicate()
	return list

## Arena de uma luta: o covil no COMBATE FINAL; senão a arena da faixa, escolhida
## por `roll` (estável por luta) para o cenário variar sem tela nova.
static func arena_id(band_id: String, is_final: bool, roll: int = 0) -> String:
	if is_final:
		return BOSS_ARENA_ID
	var list := arena_ids(band_id)
	if list.is_empty():
		return "B4"
	var index := absi(roll) % list.size()
	return str(list[index])
