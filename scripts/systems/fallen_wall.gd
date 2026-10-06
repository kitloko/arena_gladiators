class_name FallenWall
extends RefCounted

## MURAL DOS CAÍDOS (etapa 11 / §6.4): registro LOCAL (não na nuvem) dos
## personagens que morreram dentro de um torneio.
##
## Puro: só grava/lê um JSON em user:// (dentro do diretório do PRÓPRIO jogo).
## Guarda nome, rank/título, KD, torneios vencidos, o torneio, o carrasco (com
## apelido) e a data — é a estatística que sobrevive ao apagamento do save.
##
## A ORDEM é regra do GameState.apply_permadeath: o Mural é gravado ANTES de o
## save da campanha ser apagado; este módulo só sabe ler/gravar a lista.

const PATH := "user://mural.json"
const VERSION := 1
## Teto de registros guardados (o mais antigo sai) — o arquivo não cresce sem fim.
const MAX_ENTRIES := 200

## Lista de caídos (mais recente primeiro). Nunca nula.
static func entries(path: String = PATH) -> Array:
	var data := _read(path)
	var list: Variant = data.get("fallen", [])
	if list is Array:
		return list
	return []

static func count(path: String = PATH) -> int:
	return entries(path).size()

## Grava um registro no topo do Mural. Devolve true se o arquivo foi gravado —
## o GameState usa isso para só apagar o save DEPOIS do Mural confirmado.
static func add_entry(entry: Dictionary, path: String = PATH) -> bool:
	var data := _read(path)
	var list: Array = data.get("fallen", []) if data.get("fallen", []) is Array else []
	list.push_front(entry.duplicate(true))
	while list.size() > MAX_ENTRIES:
		list.pop_back()
	data["version"] = VERSION
	data["fallen"] = list
	return _write(data, path)

## Apaga o arquivo do Mural (usado só pelos testes; o jogo NÃO apaga o Mural).
static func clear(path: String = PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"version": VERSION, "fallen": []}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"version": VERSION, "fallen": []}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		var data: Dictionary = parsed
		if not (data.get("fallen", []) is Array):
			data["fallen"] = []
		return data
	return {"version": VERSION, "fallen": []}

static func _write(data: Dictionary, path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível gravar o Mural dos caídos: %s" % path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true
