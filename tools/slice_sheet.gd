extends SceneTree
##
## slice_sheet.gd — corta uma FOLHA de sprites em PNGs separados.
##
## O que ele faz:
##   1. descobre a cor de fundo pelos 4 cantos e remove SÓ o fundo ligado às
##      bordas (flood fill) — assim branco/brilho DENTRO do desenho (lâmina da
##      espada, realce da armadura) fica preservado;
##   2. acha as figuras por componentes conexos (8 vizinhos);
##   3. figuras = blocos GRANDES; fragmento (pé solto, ponta de espada) se junta à
##      figura mais próxima, sem esticar o grupo (senão engole a figura vizinha);
##   4. salva um PNG por figura + uma tabela com id, caixa e tamanho.
##
## Uso:
##   godot --headless --path . -s res://tools/slice_sheet.gd -- \
##     --in art_in/folha.png --out art_out/heroi/pose [--tol 0.16] [--min 300] \
##     [--margin 8] [--cols 5] [--rename idle,ataque,defesa,levado,caido]
##
## --cols N   corta em N colunas iguais (caixa apertada ao pixel) — quando a folha
##            não tem respiro entre as figuras. Sem ele, o agrupamento é automático.
## --rename   renomeia as figuras na ordem para os nomes dados (ex.: as 5 poses do
##            herói), separados por vírgula. É assim que o jogo acha cada pose.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var path_in := ""
	var prefix := "res://art_out/slice"
	var tol := 0.16
	var min_area := 300
	var margin := 8
	var forced_cols := 0
	var rename: Array[String] = []
	var i := 0
	while i < args.size():
		match args[i]:
			"--in": path_in = args[i + 1]
			"--out": prefix = args[i + 1]
			"--tol": tol = float(args[i + 1])
			"--min": min_area = int(args[i + 1])
			"--margin": margin = int(args[i + 1])
			"--cols": forced_cols = int(args[i + 1])
			"--rename":
				for nm in args[i + 1].split(","):
					rename.append(nm.strip_edges())
		i += 2
	if path_in == "":
		print("ERRO: falta --in <arquivo.png>")
		quit(1)
		return
	var img := Image.load_from_file(path_in)
	if img == null:
		print("ERRO: nao consegui abrir %s" % path_in)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	print("FOLHA: %s (%dx%d)" % [path_in, w, h])

	# ---------- 1. fundo pela borda (flood fill) ----------
	var bg: Color = (img.get_pixel(0, 0) + img.get_pixel(w - 1, 0) + img.get_pixel(0, h - 1) + img.get_pixel(w - 1, h - 1)) / 4.0
	print("fundo estimado: #%s | tolerancia %.2f" % [bg.to_html(false), tol])
	var is_bg := PackedByteArray()
	is_bg.resize(w * h)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var d: float = max(absf(c.r - bg.r), max(absf(c.g - bg.g), absf(c.b - bg.b)))
			is_bg[y * w + x] = 1 if d <= tol else 0
	var bg_flag := PackedByteArray()
	bg_flag.resize(w * h)
	var stack: Array[int] = []
	for x in w:
		for y: int in [0, h - 1]:
			var idx: int = y * w + x
			if is_bg[idx] == 1 and bg_flag[idx] == 0:
				bg_flag[idx] = 1
				stack.append(idx)
	for y in h:
		for x: int in [0, w - 1]:
			var idx: int = y * w + x
			if is_bg[idx] == 1 and bg_flag[idx] == 0:
				bg_flag[idx] = 1
				stack.append(idx)
	while not stack.is_empty():
		var idx: int = stack.pop_back()
		var x: int = idx % w
		var y: int = idx / w
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var nx: int = x + dx
				var ny: int = y + dy
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				var nidx: int = ny * w + nx
				if bg_flag[nidx] == 1 or is_bg[nidx] == 0:
					continue
				bg_flag[nidx] = 1
				stack.append(nidx)
	var removed := 0
	for idx in w * h:
		if bg_flag[idx] == 1:
			img.set_pixel(idx % w, idx / w, Color(0, 0, 0, 0))
			removed += 1
	print("fundo removido: %d px (%.1f%% da folha)" % [removed, 100.0 * removed / float(w * h)])

	# ---------- 2. componentes conexos ----------
	var seen := PackedByteArray()
	seen.resize(w * h)
	var comps: Array[Dictionary] = []
	for idx in w * h:
		if seen[idx] == 1:
			continue
		var x0: int = idx % w
		var y0: int = idx / w
		if img.get_pixel(x0, y0).a < 0.1:
			continue
		var c := {"minx": x0, "miny": y0, "maxx": x0, "maxy": y0, "area": 0}
		seen[idx] = 1
		var st: Array[int] = [idx]
		while not st.is_empty():
			var i2: int = st.pop_back()
			var xx: int = i2 % w
			var yy: int = i2 / w
			c.minx = mini(c.minx, xx)
			c.maxx = maxi(c.maxx, xx)
			c.miny = mini(c.miny, yy)
			c.maxy = maxi(c.maxy, yy)
			c.area += 1
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var nx: int = xx + dx
					var ny: int = yy + dy
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue
					var nidx: int = ny * w + nx
					if seen[nidx] == 1 or img.get_pixel(nx, ny).a < 0.1:
						continue
					seen[nidx] = 1
					st.append(nidx)
		comps.append(c)
	var keep: Array[Dictionary] = []
	for c2 in comps:
		if int(c2.area) >= min_area:
			keep.append(c2)
	keep.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.minx) < int(b.minx))
	print("blocos com area >= %d: %d (de %d encontrados)" % [min_area, keep.size(), comps.size()])

	# ---------- 3. agrupar em figuras ----------
	var groups: Array[Dictionary] = []
	if forced_cols > 0:
		var cw := float(w) / float(forced_cols)
		for gi in forced_cols:
			groups.append({"minx": -1, "miny": -1, "maxx": -1, "maxy": -1, "area": 0})
		# caixa apertada de cada coluna: varre os pixels de frente que caem nela
		for y in h:
			for x in w:
				if img.get_pixel(x, y).a < 0.1:
					continue
				var gi2: int = mini(forced_cols - 1, int(x / cw))
				var g2: Dictionary = groups[gi2]
				if int(g2.area) == 0:
					g2.minx = x
					g2.maxx = x
					g2.miny = y
					g2.maxy = y
				else:
					g2.minx = mini(int(g2.minx), x)
					g2.maxx = maxi(int(g2.maxx), x)
					g2.miny = mini(int(g2.miny), y)
					g2.maxy = maxi(int(g2.maxy), y)
				g2.area = int(g2.area) + 1
		for g3 in groups:
			if int(g3.area) > 0 and int(g3.area) < min_area:
				g3.area = -1
	else:
		# Figuras = blocos GRANDES; o resto (pe solto, ponta de espada) sao
		# fragmentos que se juntam a figura mais PROXIMA. Assim um fragmento nunca
		# estica um grupo a ponto de engolir a figura vizinha.
		var biggest := 0
		for c0 in keep:
			biggest = maxi(biggest, int(c0.area))
		var big_thr: int = maxi(min_area, int(biggest * 0.08))
		var big: Array[Dictionary] = []
		var frags: Array[Dictionary] = []
		for c1 in keep:
			if int(c1.area) >= big_thr:
				big.append(c1)
			else:
				frags.append(c1)
		big.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.minx) < int(b.minx))
		for c2 in big:
			if groups.is_empty():
				groups.append({"minx": int(c2.minx), "miny": int(c2.miny), "maxx": int(c2.maxx), "maxy": int(c2.maxy), "area": int(c2.area)})
				continue
			var last: Dictionary = groups[groups.size() - 1]
			var overlap: int = mini(int(last.maxx), int(c2.maxx)) - maxi(int(last.minx), int(c2.minx))
			var smaller: int = mini(int(last.maxx) - int(last.minx), int(c2.maxx) - int(c2.minx)) + 1
			if overlap > smaller / 2:
				last.minx = mini(int(last.minx), int(c2.minx))
				last.maxx = maxi(int(last.maxx), int(c2.maxx))
				last.miny = mini(int(last.miny), int(c2.miny))
				last.maxy = maxi(int(last.maxy), int(c2.maxy))
				last.area = int(last.area) + int(c2.area)
			else:
				groups.append({"minx": int(c2.minx), "miny": int(c2.miny), "maxx": int(c2.maxx), "maxy": int(c2.maxy), "area": int(c2.area)})
		print("blocos grandes (figuras candidatas): %d | fragmentos: %d" % [big.size(), frags.size()])
		for f in frags:
			var cx := (int(f.minx) + int(f.maxx)) / 2
			var best := -1
			var best_d := 1 << 30
			for gi in groups.size():
				var g: Dictionary = groups[gi]
				var d: int = 0
				if cx < int(g.minx):
					d = int(g.minx) - cx
				elif cx > int(g.maxx):
					d = cx - int(g.maxx)
				if d < best_d:
					best_d = d
					best = gi
			if best >= 0:
				var gb: Dictionary = groups[best]
				gb.minx = mini(int(gb.minx), int(f.minx))
				gb.maxx = maxi(int(gb.maxx), int(f.maxx))
				gb.miny = mini(int(gb.miny), int(f.miny))
				gb.maxy = maxi(int(gb.maxy), int(f.maxy))
				gb.area = int(gb.area) + int(f.area)

	# ---------- 4. salvar ----------
	var dir := prefix.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	print("\n%-4s %-22s %-12s %s" % ["#", "caixa (x,y,w,h)", "tamanho", "area"])
	var n := 0
	for g in groups:
		if int(g.get("area", 0)) <= 0:
			print("%-4s %-22s %-12s %s" % ["-", "vazio", "-", "-"])
			continue
		n += 1
		var x := maxi(0, int(g.minx) - margin)
		var y := maxi(0, int(g.miny) - margin)
		var ww := mini(w - x, int(g.maxx) - int(g.minx) + 1 + margin * 2)
		var hh := mini(h - y, int(g.maxy) - int(g.miny) + 1 + margin * 2)
		var piece := img.get_region(Rect2i(x, y, ww, hh))
		var sufixo := ""
		if n - 1 < rename.size():
			sufixo = "_" + rename[n - 1]
		else:
			sufixo = "_%02d" % n
		var out := "%s%s.png" % [prefix, sufixo]
		var err := piece.save_png(out)
		print("%-4d (%d,%d,%d,%d) %-12s %d %s" % [n, x, y, ww, hh, "%dx%d" % [ww, hh], int(g.area), "SALVO " + out if err == OK else "FALHOU"])
	print("\nfiguras salvas: %d" % n)
	if not rename.is_empty() and rename.size() != n:
		push_warning("--rename tem %d nomes mas foram salvas %d figuras" % [rename.size(), n])
	quit(0)
