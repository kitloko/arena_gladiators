extends Node

signal entry_created(entry: String)

const MAX_ENTRIES := 150
const LOG_PATH := "user://logs/development.log"
var entries: Array[String] = []

func info(message: String) -> void:
	var entry := "%s | %s" % [Time.get_datetime_string_from_system(), message]
	entries.append(entry)
	if entries.size() > MAX_ENTRIES:
		entries.pop_front()
	_write_to_disk(entry)
	entry_created.emit(entry)

func recent_entries() -> Array[String]:
	return entries.duplicate()

func _write_to_disk(entry: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://logs"))
	var file := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(entry)
	file.close()
