extends Control

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("14111c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var panel := RichTextLabel.new()
	panel.bbcode_enabled = true
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 28
	panel.offset_top = 28
	panel.offset_right = -28
	panel.offset_bottom = -28
	panel.add_theme_font_size_override("normal_font_size", 17)
	add_child(panel)
	var player_text := "Sem campanha"
	var stage_text := "—"
	if GameState.player != null:
		player_text = "%s | nível %d | ouro %d" % [GameState.player.display_name, GameState.player.level, GameState.player.gold]
		stage_text = "Arena %d de %d" % [GameState.arena_number(), GameState.stage_total()]
	panel.text = "[color=#f5c451][font_size=30]PAINEL DE DEPURAÇÃO[/font_size][/color]\n\nJogador: %s\nCampanha: %s\n\n[color=#cdbfd5]Eventos recentes[/color]\n%s" % [player_text, stage_text, "\n".join(DebugLog.recent_entries())]
