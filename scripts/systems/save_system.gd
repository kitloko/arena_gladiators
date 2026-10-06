class_name SaveSystem
extends RefCounted

## Persistência da campanha em user://savegame.json.
## Puro: apenas grava/lê dicionários; não conhece GameState nem regras.

const SAVE_PATH := "user://savegame.json"

static func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)

static func save_game(data: Dictionary, path: String = SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível gravar o save: %s" % path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

static func load_game(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	return {}

static func delete_save(path: String = SAVE_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
