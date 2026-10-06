extends SceneTree
##
## montage.gd — junta varios PNGs num unico "contato" sobre xadrez, para conferir
## a olho o resultado do corte (se sobrou fundo, se mutilou peca).
##
## Uso: godot --headless --path . -s res://tools/montage.gd -- \
##   --out res://art_out/contato.png --h 360 --files a.png,b.png,c.png

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out := "res://art_out/contato.png"
	var hh := 360
	var files: Array[String] = []
	var i := 0
	while i < args.size():
		match args[i]:
			"--out": out = args[i + 1]
			"--h": hh = int(args[i + 1])
			"--files":
				for f in args[i + 1].split(","):
					if f.strip_edges() != "":
						files.append(f.strip_edges())
		i += 2
	if files.is_empty():
		print("ERRO: falta --files a.png,b.png")
		quit(1)
		return
	var pad := 12
	var imgs: Array[Image] = []
	var total_w := pad
	for f in files:
		var im := Image.load_from_file(f)
		if im == null:
			print("AVISO: nao abriu %s" % f)
			continue
		im.convert(Image.FORMAT_RGBA8)
		var nw: int = int(round(float(im.get_width()) * (float(hh) / float(im.get_height()))))
		im.resize(nw, hh, Image.INTERPOLATE_LANCZOS)
		imgs.append(im)
		total_w += nw + pad
	if imgs.is_empty():
		print("ERRO: nenhuma imagem")
		quit(1)
		return
	var canvas := Image.create(total_w, hh + pad * 2, false, Image.FORMAT_RGBA8)
	# xadrez para enxergar a transparencia
	var c1 := Color(0.55, 0.55, 0.58)
	var c2 := Color(0.45, 0.45, 0.48)
	for y in canvas.get_height():
		for x in canvas.get_width():
			canvas.set_pixel(x, y, c1 if ((x / 14 + y / 14) % 2 == 0) else c2)
	var x0 := pad
	for im2 in imgs:
		canvas.blit_rect(im2, Rect2i(0, 0, im2.get_width(), im2.get_height()), Vector2i(x0, pad))
		x0 += im2.get_width() + pad
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var err := canvas.save_png(out)
	print("contato: %s (%dx%d) com %d figuras -> %s" % [out, canvas.get_width(), canvas.get_height(), imgs.size(), "OK" if err == OK else "FALHOU"])
	quit(0)
