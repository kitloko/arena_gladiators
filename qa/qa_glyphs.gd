extends Control
##
## qa_glyphs.gd — probe de GLIFOS: renderiza candidatos de símbolo na fonte real
## do jogo e salva um PNG. Serve porque `Font.has_char()` mente: o jeito honesto de
## saber se um símbolo aparece é olhar o pixel renderizado.
##
## Rodar: xvfb-run -a -s "-screen 0 1100x300x24" godot --path . res://qa/qa_glyphs.tscn

const OUT := "user://glyphs.png"
const CANDIDATOS := "⭐ ☆ ★ ✦ ✧ ✪ ✰ ● ○ ◉ ▪ ▫ ■ □ ◆ ◇ ▲ ▼ ▮ ▯ ✚ ✖ ✱ ※ ° • · × − – — ➜ ⚔ ☠ ♥ ♦ ✿ ♛"

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.07, 0.10)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var titulo := Label.new()
	titulo.text = "GLIFOS NA FONTE PADRAO DO GODOT (cada linha: simbolo + o que ele virou)"
	titulo.position = Vector2(16, 8)
	titulo.add_theme_font_size_override("font_size", 15)
	titulo.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	add_child(titulo)

	var y := 40.0
	for size in [34, 22]:
		var linha := Label.new()
		linha.text = "size %d: %s" % [size, CANDIDATOS]
		linha.position = Vector2(16, y)
		linha.add_theme_font_size_override("font_size", size)
		linha.add_theme_color_override("font_color", Color(1, 1, 1))
		add_child(linha)
		y += float(size) + 18.0

	var legenda := Label.new()
	legenda.text = "Se o simbolo virou um retangulo vazio, a fonte nao tem o glifo.\nEstrelas candidatas para o grau do boss: ★ ☆ ✦ ✧ ✪ ✰ * +"
	legenda.position = Vector2(16, y + 10)
	legenda.add_theme_font_size_override("font_size", 14)
	legenda.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	add_child(legenda)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(OUT)
	print("glyphs: %s (%dx%d) -> %s" % [OUT, img.get_width(), img.get_height(), "OK" if err == OK else "FALHOU"])
	print("no disco: %s" % ProjectSettings.globalize_path(OUT))
	get_tree().quit(0)
