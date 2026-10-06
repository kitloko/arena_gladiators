extends SceneTree

## Gerador de arte procedural (etapa 7 do PLANO_3.0).
##
## Roda HEADLESS, sem dependência externa:
##   GODOT_SILENCE_ROOT_WARNING=1 <godot> --headless --path . -s res://tools/gen_assets.gd -- --seed 1307
##
## Desenha as imagens com a API Image do próprio engine e salva PNG em
## res://assets/gen/, junto do manifesto res://assets/gen/manifest.json.
##
## - Determinístico por seed: o mesmo seed produz SEMPRE os mesmos bytes.
## - Idempotente: rodar de novo com os mesmos argumentos reescreve os mesmos
##   arquivos (nada quebra, nada acumula).
## - Arte estilizada/geométrica gerada por código (paletas + sombreamento por
##   procedimento), não ilustração pintada — ver docs/PLANO_3.0.md §4.1.
##
## IDs alinhados ao CONTRATO DE CORTE do dono (docs/ARTE.md §3), para que as
## folhas dele depois SUBSTITUAM estas imagens sem trocar uma linha do jogo:
##   B1/B2/B3  cidades (Areia-Pedra / Ferro-Aço / Prata+)      1536x1024
##   B4..B8    arenas (areia/cascalho/noturna/nobre/covil)     1536x1024
##   B9        plateia (transparente, 8 silhuetas)              1536x256
##   F1/F2     painel e botão 9-slice (fundo escuro, borda dourada) 256x256 / 256x96

const GEN_DIR := "res://assets/gen/"
const MANIFEST_PATH := GEN_DIR + "manifest.json"
const DEFAULT_SEED := 1307

const W := 1536
const H := 1024
const CROWD_W := 1536
const CROWD_H := 256

var _seed: int = DEFAULT_SEED
var _images: Dictionary = {}

func _initialize() -> void:
	_seed = _parse_seed()
	var out_dir := ProjectSettings.globalize_path(GEN_DIR)
	DirAccess.make_dir_recursive_absolute(out_dir)
	_images = {}
	print("Gerador de arte — seed %d" % _seed)
	_emit("B1", "cidade", "areia", W, H, func() -> Image: return _draw_city("B1", "areia"))
	_emit("B2", "cidade", "ferro", W, H, func() -> Image: return _draw_city("B2", "ferro"))
	_emit("B3", "cidade", "prata", W, H, func() -> Image: return _draw_city("B3", "prata"))
	_emit("B4", "arena", "areia", W, H, func() -> Image: return _draw_arena("B4", "areia"))
	_emit("B5", "arena", "cascalho", W, H, func() -> Image: return _draw_arena("B5", "cascalho"))
	_emit("B6", "arena", "noturna", W, H, func() -> Image: return _draw_arena("B6", "noturna"))
	_emit("B7", "arena", "nobre", W, H, func() -> Image: return _draw_arena("B7", "nobre"))
	_emit("B8", "arena", "covil", W, H, func() -> Image: return _draw_arena("B8", "covil"))
	_emit("B9", "plateia", "todas", CROWD_W, CROWD_H, func() -> Image: return _draw_crowd_strip("B9"))
	_emit("F1", "painel", "todas", 256, 256, func() -> Image: return _draw_panel("F1"))
	_emit("F2", "botao", "todas", 256, 96, func() -> Image: return _draw_button("F2"))
	_write_manifest()
	print("Pronto: %d imagens + manifesto em %s" % [_images.size(), GEN_DIR])
	quit(0)

func _parse_seed() -> int:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		var arg := str(args[i])
		if arg == "--seed" and i + 1 < args.size():
			return int(args[i + 1])
		if arg.begins_with("--seed="):
			return int(arg.substr(7))
		i += 1
	return DEFAULT_SEED

func _emit(id: String, type: String, band: String, width: int, height: int, draw: Callable) -> void:
	var image: Image = draw.call()
	if image == null:
		printerr("FALHOU ao desenhar %s" % id)
		return
	if image.get_width() != width or image.get_height() != height:
		printerr("DIMENSÃO errada em %s: %dx%d (esperado %dx%d)" % [id, image.get_width(), image.get_height(), width, height])
	var file := "%s.png" % id
	var path := GEN_DIR + file
	var err := image.save_png(path)
	if err != OK:
		printerr("FALHOU ao salvar %s (err %d)" % [path, err])
		return
	var bytes := 0
	var f := FileAccess.open(path, FileAccess.READ)
	if f != null:
		bytes = f.get_length()
		f.close()
	_images[id] = {
		"file": file, "type": type, "band": band,
		"width": width, "height": height, "seed": _seed,
	}
	print("  %-3s %-9s %-9s %dx%d  %7d bytes  %s" % [id, type, band, width, height, bytes, file])

func _write_manifest() -> void:
	var data := {
		"version": 1,
		"generator": "tools/gen_assets.gd",
		"seed": _seed,
		"comment": "Manifesto da arte gerada. O jogo lê daqui (AssetCatalog). Mesmos ids do contrato de corte do dono (docs/ARTE.md §3).",
		"images": _images,
		"map": {
			"cities": {"areia": "B1", "ferro": "B2", "prata": "B3"},
			"arenas": {"areia": ["B4", "B5"], "ferro": ["B6", "B5"], "prata": ["B7"]},
			"boss_arena": "B8",
			"crowd": "B9",
			"panel": "F1",
			"button": "F2",
		},
	}
	var text := JSON.stringify(data, "\t")
	var f := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if f == null:
		printerr("FALHOU ao escrever o manifesto %s" % MANIFEST_PATH)
		return
	f.store_string(text)
	f.close()

# ===========================================================================
# Utilidades de desenho (tudo por pixel, na API Image)
# ===========================================================================

func _rng_for(id: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed ^ _hash_id(id)
	return rng

## Hash estável (não depende de String.hash, que pode variar entre versões).
func _hash_id(id: String) -> int:
	var h := 2166136261
	for i in id.length():
		h = (h ^ id.unicode_at(i)) * 16777619
		h = h & 0x7fffffff
	return h

## Imagem opaca com gradiente vertical (rápido: coluna 1px esticada).
func _new_opaque(w: int, h: int, top: Color, bottom: Color) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var col := Image.create_empty(1, h, false, Image.FORMAT_RGBA8)
	for y in h:
		col.set_pixel(0, y, top.lerp(bottom, float(y) / float(maxi(1, h - 1))))
	col.resize(w, h, Image.INTERPOLATE_BILINEAR)
	img.blit_rect(col, Rect2i(0, 0, w, h), Vector2i(0, 0))
	return img

func _new_transparent(w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

## Gradiente vertical dentro de um retângulo (estica uma coluna de 1px).
func _vgrad(img: Image, x: int, y: int, w: int, h: int, top: Color, bottom: Color) -> void:
	if w <= 0 or h <= 0:
		return
	var col := Image.create_empty(1, h, false, Image.FORMAT_RGBA8)
	for j in h:
		col.set_pixel(0, j, top.lerp(bottom, float(j) / float(maxi(1, h - 1))))
	col.resize(w, h, Image.INTERPOLATE_BILINEAR)
	img.blit_rect(col, Rect2i(0, 0, w, h), Vector2i(x, y))

func _blend(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	if c.a >= 0.996:
		img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
		return
	if c.a <= 0.004:
		return
	var base := img.get_pixel(x, y)
	var a := c.a
	var out := Color(
		base.r + (c.r - base.r) * a,
		base.g + (c.g - base.g) * a,
		base.b + (c.b - base.b) * a,
		base.a + (1.0 - base.a) * a)
	img.set_pixel(x, y, out)

## Retângulo opaco (sobrescreve).
func _fill(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var x0 := maxi(0, x)
	var y0 := maxi(0, y)
	var x1 := mini(img.get_width(), x + w)
	var y1 := mini(img.get_height(), y + h)
	for py in range(y0, y1):
		for px in range(x0, x1):
			img.set_pixel(px, py, c)

## Retângulo com mistura (para sombras e brilhos translúcidos).
func _fill_blend(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var x0 := maxi(0, x)
	var y0 := maxi(0, y)
	var x1 := mini(img.get_width(), x + w)
	var y1 := mini(img.get_height(), y + h)
	for py in range(y0, y1):
		for px in range(x0, x1):
			_blend(img, px, py, c)

func _outline(img: Image, x: int, y: int, w: int, h: int, c: Color, t: int) -> void:
	_fill(img, x, y, w, t, c)
	_fill(img, x, y + h - t, w, t, c)
	_fill(img, x, y, t, h, c)
	_fill(img, x + w - t, y, t, h, c)

func _circle(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	var y0 := maxi(0, int(floor(cy - r)))
	var y1 := mini(img.get_height() - 1, int(ceil(cy + r)))
	for py in range(y0, y1 + 1):
		var dy := float(py) - cy
		var dx := sqrt(maxf(0.0, r * r - dy * dy))
		var xa := int(ceil(cx - dx))
		var xb := int(floor(cx + dx))
		for px in range(xa, xb + 1):
			_blend(img, px, py, c)

## Brilho radial (tocha/lava): a cor vai sumindo do centro para a borda.
func _glow(img: Image, cx: float, cy: float, r: float, c: Color, strength: float) -> void:
	var y0 := maxi(0, int(floor(cy - r)))
	var y1 := mini(img.get_height() - 1, int(ceil(cy + r)))
	var x0 := maxi(0, int(floor(cx - r)))
	var x1 := mini(img.get_width() - 1, int(ceil(cx + r)))
	for py in range(y0, y1 + 1):
		var dy := float(py) - cy
		for px in range(x0, x1 + 1):
			var dx := float(px) - cx
			var d := sqrt(dx * dx + dy * dy)
			if d > r:
				continue
			var t := 1.0 - d / r
			var a := c.a * strength * t * t
			_blend(img, px, py, Color(c.r, c.g, c.b, a))

func _line(img: Image, a: Vector2, b: Vector2, c: Color, thickness: int = 1) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in range(steps + 1):
		var t := float(i) / float(maxi(1, steps))
		var p := a.lerp(b, t)
		if thickness <= 1:
			_blend(img, int(round(p.x)), int(round(p.y)), c)
		else:
			_circle(img, p.x, p.y, float(thickness) * 0.5, c)

## Preenchimento de polígono por varredura (scanline).
func _poly(img: Image, pts: PackedVector2Array, c: Color) -> void:
	var n := pts.size()
	if n < 3:
		return
	var min_y := INF
	var max_y := -INF
	for p in pts:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	var y0 := maxi(0, int(floor(min_y)))
	var y1 := mini(img.get_height() - 1, int(ceil(max_y)))
	for py in range(y0, y1 + 1):
		var xs: Array[float] = []
		for i in n:
			var p0 := pts[i]
			var p1 := pts[(i + 1) % n]
			var yf := float(py)
			if (p0.y <= yf and p1.y > yf) or (p1.y <= yf and p0.y > yf):
				var t := (yf - p0.y) / (p1.y - p0.y)
				xs.append(p0.x + (p1.x - p0.x) * t)
		xs.sort()
		var k := 0
		while k + 1 < xs.size():
			var xa := int(ceil(xs[k]))
			var xb := int(floor(xs[k + 1]))
			for px in range(xa, xb + 1):
				_blend(img, px, py, c)
			k += 2

## Salpica pontos (poeira/areia/estrelas) num retângulo.
func _speckle(img: Image, x: int, y: int, w: int, h: int, c: Color, count: int, rng: RandomNumberGenerator, rmin: float, rmax: float) -> void:
	for i in count:
		var px := x + int(rng.randf() * float(w))
		var py := y + int(rng.randf() * float(h))
		var r := rng.randf_range(rmin, rmax)
		var a := c.a * rng.randf_range(0.4, 1.0)
		_circle(img, float(px), float(py), r, Color(c.r, c.g, c.b, a))

func _jitter(c: Color, rng: RandomNumberGenerator, amount: float) -> Color:
	var d := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0.0, 1.0), clampf(c.g + d, 0.0, 1.0), clampf(c.b + d, 0.0, 1.0), c.a)

# ===========================================================================
# CIDADES
# ===========================================================================

func _city_palette(band: String) -> Dictionary:
	match band:
		"ferro":
			return {
				"sky_top": Color("3f5266"), "sky_bottom": Color("aab6bf"),
				"sun": Color("f0e2c0"), "hill": Color("5f6b74"),
				"wall": Color("6d7681"), "wall_dark": Color("454d57"), "wall_light": Color("97a1ab"),
				"building": Color("7a838d"), "building_dark": Color("4e565f"), "roof": Color("3d444c"),
				"window": Color("f2c46a"), "banner": Color("8a2f2f"), "banner2": Color("3f5f8a"),
				"ground_top": Color("8b8577"), "ground_bottom": Color("121316"),
				"torch": Color("ffc461"), "glow": Color("ff8a2e"),
				"prop": Color("ff7a2a"),
			}
		"prata":
			return {
				"sky_top": Color("241f42"), "sky_bottom": Color("b39ddb"),
				"sun": Color("f6e6f5"), "hill": Color("5a5378"),
				"wall": Color("cfc6d8"), "wall_dark": Color("9a90a8"), "wall_light": Color("efe9f2"),
				"building": Color("ded6e4"), "building_dark": Color("a89fb4"), "roof": Color("6b4b8a"),
				"window": Color("ffd98a"), "banner": Color("7b4fa0"), "banner2": Color("c9a83a"),
				"ground_top": Color("b7accc"), "ground_bottom": Color("171430"),
				"torch": Color("ffd76a"), "glow": Color("ffb24a"),
				"prop": Color("c9a83a"),
			}
		_:
			return {
				"sky_top": Color("4f8fbf"), "sky_bottom": Color("e8d6a8"),
				"sun": Color("fff3d0"), "hill": Color("a98a58"),
				"wall": Color("b79457"), "wall_dark": Color("7d6136"), "wall_light": Color("d8b877"),
				"building": Color("c9a86a"), "building_dark": Color("8f7340"), "roof": Color("8a5a3a"),
				"window": Color("ffd27a"), "banner": Color("b83a3a"), "banner2": Color("3a6ea5"),
				"ground_top": Color("c2a26a"), "ground_bottom": Color("241a12"),
				"torch": Color("ffb84a"), "glow": Color("ff9a2e"),
				"prop": Color("d9a45b"),
			}

func _draw_city(id: String, band: String) -> Image:
	var cfg := _city_palette(band)
	var rng := _rng_for(id)
	var img := _new_opaque(W, H, cfg["sky_top"], cfg["sky_bottom"])
	var base_y := 690  # linha do chão (praça começa aqui)
	# Sol/lua distante + brilho.
	var sun_x := rng.randf_range(W * 0.18, W * 0.82)
	_glow(img, sun_x, 120.0, 220.0, Color(cfg["sun"].r, cfg["sun"].g, cfg["sun"].b, 0.5), 0.5)
	_circle(img, sun_x, 120.0, 54.0, Color(cfg["sun"].r, cfg["sun"].g, cfg["sun"].b, 0.9))
	# Colinas distantes.
	var pts := PackedVector2Array()
	pts.append(Vector2(0, base_y))
	var x := 0.0
	while x <= W:
		pts.append(Vector2(x, 560.0 - rng.randf_range(20.0, 90.0)))
		x += rng.randf_range(60.0, 130.0)
	pts.append(Vector2(W, 560.0))
	pts.append(Vector2(W, base_y))
	pts.append(Vector2(0, base_y))
	_poly(img, pts, cfg["hill"])
	# Névoa do horizonte: clareia o pé das colinas.
	_fill_blend(img, 0, 520, W, 60, Color(cfg["sky_bottom"].r, cfg["sky_bottom"].g, cfg["sky_bottom"].b, 0.25))
	# Prédios e torres atrás da muralha (silhuetas médias).
	var bx := -40.0
	while bx < W:
		var bw := rng.randf_range(90.0, 190.0)
		var bh := rng.randf_range(120.0, 300.0)
		_draw_building(img, int(bx), base_y, int(bw), int(bh), cfg, rng, false)
		bx += bw + rng.randf_range(6.0, 34.0)
	# Torres mais altas, uma de cada lado, com estandarte.
	_draw_tower(img, int(W * 0.14), base_y, 132, rng.randf_range(300.0, 380.0), cfg, rng)
	_draw_tower(img, int(W * 0.84), base_y, 120, rng.randf_range(280.0, 360.0), cfg, rng)
	# Praça: piso tateado (gradiente + ladrilhos em perspectiva).
	_vgrad(img, 0, base_y, W, H - base_y, cfg["ground_top"], cfg["ground_bottom"])
	_draw_plaza_tiles(img, base_y, cfg)
	# Muralha com ameias (cobre a base dos prédios).
	var wall_top := base_y - 118
	_fill(img, 0, wall_top, W, 118, cfg["wall"])
	_fill_blend(img, 0, wall_top, W, 30, Color(1, 1, 1, 0.06))
	# Tijolos.
	for row in range(wall_top + 26, base_y, 18):
		_fill(img, 0, row, W, 2, cfg["wall_dark"])
	for row in range(wall_top + 26, base_y, 18):
		var shift := 0 if (row / 18) % 2 == 0 else 32
		var cx := shift
		while cx < W:
			_fill(img, cx, row, 2, 18, cfg["wall_dark"])
			cx += 64
	# Ameias.
	var merlon := 0
	while merlon * 46 < W:
		_fill(img, merlon * 46 + 6, wall_top - 22, 30, 24, cfg["wall_light"])
		_fill(img, merlon * 46 + 6, wall_top - 22, 30, 4, cfg["wall_dark"])
		merlon += 1
	_draw_gate(img, base_y, wall_top, cfg)
	# Tochas com brilho ao longo da muralha.
	var torch_x := 150
	while torch_x < W - 60:
		_draw_torch(img, torch_x, wall_top + 6, cfg)
		torch_x += 300
	# Bandeiras/estandartes pendurados.
	var flag_colors := [cfg["banner"], cfg["banner2"], cfg["prop"]]
	var flag_i := 0
	var fx := 210
	while fx < W - 120:
		_draw_banner(img, fx, wall_top + 4, 54, 96, flag_colors[flag_i % flag_colors.size()], cfg)
		flag_i += 1
		fx += 330
	# Bancas na base da muralha (no piso, atrás dos botões).
	var sx := 190
	while sx < W - 180:
		_draw_stall(img, sx, base_y + 6, 150, cfg, rng)
		sx += rng.randf_range(360.0, 520.0)
	# Escurece a faixa de baixo (os botões de local são desenhados ali).
	_fill_blend(img, 0, base_y + 118, W, H - base_y - 118, Color(0, 0, 0, 0.55))
	_vgrad_blend(img, 0, base_y + 40, W, 90, Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.6))
	# Poeira no ar.
	_speckle(img, 0, 380, W, 320, Color(1, 0.92, 0.75, 0.16), 260, rng, 0.6, 2.0)
	return img

func _vgrad_blend(img: Image, x: int, y: int, w: int, h: int, top: Color, bottom: Color) -> void:
	for j in h:
		var t := float(j) / float(maxi(1, h - 1))
		var c := top.lerp(bottom, t)
		_fill_blend(img, x, y + j, w, 1, c)

func _draw_building(img: Image, x: int, base_y: int, w: int, h: int, cfg: Dictionary, rng: RandomNumberGenerator, lit: bool) -> void:
	var top := base_y - h
	var shade := rng.randf_range(0.82, 1.0)
	var body: Color = cfg["building"]
	if rng.randf() < 0.45:
		body = cfg["building_dark"]
	body = Color(body.r * shade, body.g * shade, body.b * shade)
	_fill(img, x, top, w, h, body)
	_fill_blend(img, x, top, 8, h, Color(0, 0, 0, 0.22))
	_fill_blend(img, x + w - 8, top, 8, h, Color(1, 1, 1, 0.05))
	# Telhado.
	var roof: Color = cfg["roof"]
	_poly(img, PackedVector2Array([Vector2(x - 8, top), Vector2(x + w + 8, top), Vector2(x + w * 0.5, top - 34)]), roof)
	# Janelas acesas.
	var cols := maxi(1, w / 34)
	var rows := maxi(1, h / 46)
	for r in rows:
		for c in cols:
			if rng.randf() < 0.55:
				var wx := x + 12 + c * 34
				var wy := top + 24 + r * 46
				if wx + 14 < x + w - 6 and wy + 20 < base_y - 4:
					var wc: Color = cfg["window"]
					if rng.randf() < 0.3:
						wc = Color(wc.r * 0.4, wc.g * 0.4, wc.b * 0.4)
					_fill(img, wx, wy, 14, 20, wc)

func _draw_tower(img: Image, x: int, base_y: int, w: int, h: float, cfg: Dictionary, rng: RandomNumberGenerator) -> void:
	var top := base_y - int(h)
	_fill(img, x, top, w, int(h), cfg["building"])
	_fill_blend(img, x, top, 10, int(h), Color(0, 0, 0, 0.25))
	# Teto cônico.
	_poly(img, PackedVector2Array([Vector2(x - 12, top), Vector2(x + w + 12, top), Vector2(x + w * 0.5, top - 70)]), cfg["roof"])
	# Ameias do topo.
	_fill(img, x - 8, top - 6, w + 16, 14, cfg["wall_light"])
	# Janelas altas.
	for r in 2:
		var wy := top + 30 + r * 60
		if wy + 26 < base_y:
			_fill(img, x + w / 2 - 9, wy, 18, 26, cfg["window"])
			_fill(img, x + w / 2 - 9, wy, 18, 4, cfg["wall_dark"])
	# Mastro + estandarte no topo.
	_line(img, Vector2(x + w * 0.5, top - 70), Vector2(x + w * 0.5, top - 130), cfg["wall_dark"], 3)
	_poly(img, PackedVector2Array([
		Vector2(x + w * 0.5, top - 128), Vector2(x + w * 0.5 + 44, top - 112),
		Vector2(x + w * 0.5, top - 96)]), cfg["banner"])

func _draw_gate(img: Image, base_y: int, wall_top: int, cfg: Dictionary) -> void:
	var gw := 150
	var gh := 150
	var gx := W / 2 - gw / 2
	var gy := base_y - gh
	_fill(img, gx, gy, gw, gh, cfg["wall_dark"])
	# Arco superior.
	_circle(img, float(gx + gw / 2), float(gy) + 10.0, float(gw / 2), cfg["wall_dark"])
	# Portão de madeira.
	_fill(img, gx + 12, gy + 22, gw - 24, gh - 22, Color("3a2a1c"))
	for i in 6:
		_fill(img, gx + 12 + i * 22, gy + 22, 3, gh - 22, Color("241a10"))
	# Dobradiças de ferro.
	_fill(img, gx + 12, gy + 60, gw - 24, 6, Color("20180f"))
	_fill(img, gx + 12, gy + 110, gw - 24, 6, Color("20180f"))

func _draw_torch(img: Image, x: int, y: int, cfg: Dictionary) -> void:
	# Suporte + chama + brilho forte.
	_fill(img, x - 3, y, 7, 26, Color("3a2a1c"))
	_glow(img, float(x), float(y - 6), 70.0, Color(cfg["glow"].r, cfg["glow"].g, cfg["glow"].b, 0.7), 0.55)
	_circle(img, float(x), float(y - 8), 11.0, cfg["torch"])
	_circle(img, float(x), float(y - 16), 7.0, Color(1.0, 0.99, 0.8, 0.95))

func _draw_banner(img: Image, x: int, y: int, w: int, h: int, color: Color, cfg: Dictionary) -> void:
	_fill(img, x, y, w, h, color)
	_poly(img, PackedVector2Array([
		Vector2(x, y + h), Vector2(x + w, y + h), Vector2(x + w / 2.0, y + h + 24)]), color)
	# Faixa dourada e brasão simples.
	_fill(img, x, y + 10, w, 6, cfg["prop"])
	_circle(img, float(x + w / 2), float(y + h / 2), 12.0, cfg["prop"])
	_circle(img, float(x + w / 2), float(y + h / 2), 7.0, Color(color.r * 0.6, color.g * 0.6, color.b * 0.6))

func _draw_stall(img: Image, x: int, y: int, w: int, cfg: Dictionary, rng: RandomNumberGenerator) -> void:
	var h := 74
	# Postes.
	_fill(img, x + 6, y - h, 6, h, Color("4a3520"))
	_fill(img, x + w - 12, y - h, 6, h, Color("4a3520"))
	# Balcão.
	_fill(img, x, y - 20, w, 20, Color("5a4028"))
	_fill_blend(img, x, y - 20, w, 5, Color(1, 1, 1, 0.08))
	# Toldo listrado.
	var stripe: Color = cfg["banner"]
	var stripe2: Color = cfg["wall_light"]
	var sw := 18
	var i := 0
	while i * sw < w:
		var c: Color = stripe if i % 2 == 0 else stripe2
		_poly(img, PackedVector2Array([
			Vector2(x + i * sw, y - h), Vector2(x + i * sw + sw, y - h),
			Vector2(x + i * sw + sw, y - h + 22), Vector2(x + i * sw, y - h + 22)]), c)
		i += 1
	_fill(img, x, y - h + 22, w, 5, Color(0, 0, 0, 0.35))
	# Mercadorias.
	for k in 5:
		var px := x + 14 + int(rng.randf() * float(w - 28))
		_circle(img, float(px), float(y - 26), rng.randf_range(4.0, 8.0), _jitter(cfg["prop"], rng, 0.12))

func _draw_plaza_tiles(img: Image, base_y: int, cfg: Dictionary) -> void:
	var span := H - base_y
	# Linhas horizontais em perspectiva (mais espaçadas conforme desce).
	var y := base_y + 10.0
	var gap := 10.0
	while y < H:
		_fill_blend(img, 0, int(y), W, 2, Color(0, 0, 0, 0.18))
		y += gap
		gap *= 1.28
	# Linhas verticais convergindo para o centro do horizonte.
	var vanish_x := W * 0.5
	for k in range(-9, 10):
		var foot_x := vanish_x + k * 92.0
		_line(img, Vector2(vanish_x, float(base_y)), Vector2(foot_x, float(H)), Color(0, 0, 0, 0.14), 2)

# ===========================================================================
# ARENAS
# ===========================================================================

func _arena_palette(kind: String) -> Dictionary:
	match kind:
		"cascalho":
			return {
				"sky_top": Color("6b7686"), "sky_bottom": Color("c9c2b0"),
				"stand_back": Color("8a7a5c"), "stand_front": Color("6b5c44"),
				"crowd": Color("2a2620"), "barrier": Color("5a4c38"), "barrier_top": Color("8a7856"),
				"floor_top": Color("a3906f"), "floor_bottom": Color("453a29"),
				"grain": Color("6f6250"), "torch": Color("ffc461"), "glow": Color("ff9a3a"),
				"night": false,
			}
		"noturna":
			return {
				"sky_top": Color("0c1018"), "sky_bottom": Color("1d2536"),
				"stand_back": Color("2b3040"), "stand_front": Color("1a1d28"),
				"crowd": Color("090a0f"), "barrier": Color("23262f"), "barrier_top": Color("3a3f4d"),
				"floor_top": Color("3a3428"), "floor_bottom": Color("100d08"),
				"grain": Color("5a5140"), "torch": Color("ffcf6a"), "glow": Color("ff8a2e"),
				"night": true,
			}
		"nobre":
			return {
				"sky_top": Color("2a2145"), "sky_bottom": Color("c9b6e0"),
				"stand_back": Color("ded6e4"), "stand_front": Color("b3a7c4"),
				"crowd": Color("231d33"), "barrier": Color("cfc6d8"), "barrier_top": Color("f0eaf4"),
				"floor_top": Color("cfc3dc"), "floor_bottom": Color("4a3f66"),
				"grain": Color("9a8fb4"), "torch": Color("ffd76a"), "glow": Color("ffb24a"),
				"night": false, "gold": Color("e6c76a"), "accent": Color("7b4fa0"),
			}
		"covil":
			return {
				"sky_top": Color("160404"), "sky_bottom": Color("3a0a0a"),
				"stand_back": Color("3a1212"), "stand_front": Color("240a0a"),
				"crowd": Color("120303"), "barrier": Color("4a1414"), "barrier_top": Color("6a1e1e"),
				"floor_top": Color("3a1512"), "floor_bottom": Color("120404"),
				"grain": Color("5c1c14"), "torch": Color("ff8a3a"), "glow": Color("ff3a12"),
				"night": true, "lava": Color("ff5a1e"),
			}
		_:
			return {
				"sky_top": Color("6ba3cf"), "sky_bottom": Color("e9d6a8"),
				"stand_back": Color("b79b6a"), "stand_front": Color("8f7750"),
				"crowd": Color("2e2820"), "barrier": Color("a98d5e"), "barrier_top": Color("d8b877"),
				"floor_top": Color("d8bc82"), "floor_bottom": Color("5a4a30"),
				"grain": Color("a98f60"), "torch": Color("ffc461"), "glow": Color("ff9a2e"),
				"night": false,
			}

func _draw_arena(id: String, kind: String) -> Image:
	var cfg := _arena_palette(kind)
	var rng := _rng_for(id)
	var img := _new_opaque(W, H, cfg["sky_top"], cfg["sky_bottom"])
	var stands_top := 170
	var stands_bottom := 480
	# Céu/teto com brilho.
	if bool(cfg.get("night", false)):
		_speckle(img, 0, 0, W, stands_top, Color(1, 1, 1, 0.5), 90, rng, 0.7, 1.8)
	else:
		_glow(img, W * 0.5, 60.0, 300.0, Color(cfg["sky_bottom"].r, cfg["sky_bottom"].g, cfg["sky_bottom"].b, 0.5), 0.5)
	# Arquibancada: degraus com plateia (silhuetas menores e mais escuras ao fundo).
	var tiers := 6
	var tier_h := float(stands_bottom - stands_top) / float(tiers)
	for tier in tiers:
		var depth := float(tier) / float(maxi(1, tiers - 1))
		var ty := stands_top + int(tier * tier_h)
		var back: Color = cfg["stand_back"]
		var front: Color = cfg["stand_front"]
		var band_color := back.lerp(front, depth)
		_fill(img, 0, ty, W, int(tier_h) + 2, band_color)
		_fill_blend(img, 0, ty, W, 3, Color(1, 1, 1, 0.06))
		# Silhuetas de expectadores na borda de cada degrau.
		var hr_base := lerpf(7.0, 15.0, depth)
		var darkness := 0.45 * (1.0 - depth)
		var cx := 10.0 + rng.randf() * 12.0
		while cx < W:
			var hr := hr_base * rng.randf_range(0.8, 1.15)
			var head_y := float(ty) + hr * 0.25
			var c := _jitter(cfg["crowd"], rng, 0.05).lerp(Color.BLACK, darkness)
			_circle(img, cx, head_y, hr, c)
			_fill(img, int(cx - hr * 1.45), int(head_y + hr * 0.6), int(hr * 2.9), int(hr * 1.2), c)
			cx += hr * 2.2 + rng.randf_range(2.0, 9.0)
		# Corrimão da frente do degrau.
		_fill(img, 0, ty + int(tier_h) - 3, W, 3, Color(0, 0, 0, 0.25))
	# Barreira/muro de fundo da arena.
	var barrier_top := stands_bottom
	_fill(img, 0, barrier_top, W, 34, cfg["barrier"])
	_fill(img, 0, barrier_top, W, 6, cfg["barrier_top"])
	_fill_blend(img, 0, barrier_top + 34, W, 16, Color(0, 0, 0, 0.4))
	_draw_arena_floor(img, barrier_top + 34, cfg, rng)
	# Tochas na barreira.
	var tcount := 8 if not bool(cfg.get("night", false)) else 10
	for i in tcount:
		var tx := int((float(i) + 0.5) * float(W) / float(tcount))
		_draw_arena_torch(img, tx, barrier_top + 4, cfg)
	# Elementos próprios de cada arena.
	match kind:
		"nobre":
			_draw_noble_columns(img, barrier_top)
		"covil":
			_draw_lair(img, barrier_top, rng)
		"noturna":
			_glow(img, W * 0.5, float(barrier_top) - 40.0, 420.0, Color(cfg["glow"].r, cfg["glow"].g, cfg["glow"].b, 0.35), 0.4)
		_:
			pass
	return img

func _draw_arena_floor(img: Image, top: int, cfg: Dictionary, rng: RandomNumberGenerator) -> void:
	_vgrad(img, 0, top, W, H - top, cfg["floor_top"], cfg["floor_bottom"])
	# Grãos/pedras.
	_speckle(img, 0, top, W, H - top, Color(cfg["grain"].r, cfg["grain"].g, cfg["grain"].b, 0.35), 900, rng, 0.8, 2.6)
	if bool(cfg.get("night", false)):
		_fill_blend(img, 0, top, W, H - top, Color(0, 0, 0, 0.35))
	# Faixa clara junto da barreira (luz de tocha no chão).
	_vgrad_blend(img, 0, top, W, 120, Color(cfg["glow"].r, cfg["glow"].g, cfg["glow"].b, 0.12), Color(0, 0, 0, 0))

func _draw_arena_torch(img: Image, x: int, y: int, cfg: Dictionary) -> void:
	_fill(img, x - 3, y - 30, 7, 34, Color("3a2a1c"))
	_glow(img, float(x), float(y - 34), 90.0, Color(cfg["glow"].r, cfg["glow"].g, cfg["glow"].b, 0.7), 0.6)
	_circle(img, float(x), float(y - 36), 12.0, cfg["torch"])
	_circle(img, float(x), float(y - 46), 7.0, Color(1.0, 0.98, 0.8, 0.95))

func _draw_noble_columns(img: Image, barrier_top: int) -> void:
	var gold := Color("e6c76a")
	var marble := Color("efe9f2")
	var shade := Color("b3a7c4")
	for side in 2:
		var x := 90 if side == 0 else W - 190
		# Coluna: base, fuste, capitel.
		_fill(img, x, 120, 100, barrier_top - 120, marble)
		_fill_blend(img, x, 120, 16, barrier_top - 120, Color(0, 0, 0, 0.18))
		_fill_blend(img, x + 84, 120, 16, barrier_top - 120, Color(1, 1, 1, 0.08))
		_fill(img, x - 12, 100, 124, 26, gold)
		_fill(img, x - 16, barrier_top - 40, 132, 40, gold)
		_fill(img, x - 16, barrier_top - 40, 132, 8, Color(1, 1, 1, 0.2))
		# Sulcos do fuste.
		for i in 3:
			_fill_blend(img, x + 24 + i * 22, 130, 3, barrier_top - 190, Color(0, 0, 0, 0.12))
	# Aros/arcos ao fundo.
	for i in 4:
		var ax := 300 + i * 250
		_poly(img, PackedVector2Array([
			Vector2(ax, barrier_top), Vector2(ax, barrier_top - 150),
			Vector2(ax + 140, barrier_top - 150), Vector2(ax + 140, barrier_top)]), shade)
		_circle(img, float(ax + 70), float(barrier_top - 150), 70.0, shade)
		_fill(img, ax + 20, barrier_top - 130, 100, 130, Color("2a2145"))

func _draw_lair(img: Image, barrier_top: int, rng: RandomNumberGenerator) -> void:
	var spike := Color("6a1e1e")
	var dark := Color("240a0a")
	# Espigões irregulares na barreira.
	var x := 0.0
	while x < W:
		var sw := rng.randf_range(30.0, 70.0)
		var sh := rng.randf_range(40.0, 130.0)
		_poly(img, PackedVector2Array([
			Vector2(x, float(barrier_top)), Vector2(x + sw, float(barrier_top)),
			Vector2(x + sw * 0.5, float(barrier_top) - sh)]), spike)
		x += sw
	# Rachaduras de lava no chão (brilho vermelho).
	for i in 7:
		var y := barrier_top + 40 + int(rng.randf() * float(H - barrier_top - 60))
		var x0 := rng.randf_range(0.0, float(W) * 0.6)
		var x1 := x0 + rng.randf_range(160.0, 460.0)
		_glow(img, (x0 + x1) * 0.5, float(y), 60.0, Color(1.0, 0.4, 0.12, 0.7), 0.6)
		_line(img, Vector2(x0, float(y)), Vector2(x1, float(y) + rng.randf_range(-24.0, 24.0)), Color(1.0, 0.45, 0.15, 0.9), 4)
	# Ossada: crânio e ossos.
	var skx := 260.0
	var sky := float(H - 120)
	_circle(img, skx, sky, 26.0, Color("d8cfc0"))
	_fill(img, int(skx) - 16, int(sky) + 18, 32, 18, Color("d8cfc0"))
	_circle(img, skx - 9, sky - 4, 6.0, dark)
	_circle(img, skx + 9, sky - 4, 6.0, dark)
	for i in 5:
		var bx := 520.0 + i * 34.0
		_line(img, Vector2(bx, float(H - 80)), Vector2(bx + 60, float(H - 60)), Color("c9bda8"), 6)

# ===========================================================================
# PLATEIA (faixa transparente de silhuetas)
# ===========================================================================

func _draw_crowd_strip(id: String) -> Image:
	var rng := _rng_for(id)
	var img := _new_transparent(CROWD_W, CROWD_H)
	var cells := 8
	var cw := float(CROWD_W) / float(cells)
	for c in cells:
		var cx := (float(c) + 0.5) * cw
		var base := float(CROWD_H) - 26.0
		var scale := rng.randf_range(0.85, 1.15)
		var body := _jitter(Color("17131c"), rng, 0.05)
		# Corpo (tronco) e ombros.
		var shoulder_w := 74.0 * scale
		_fill(img, int(cx - shoulder_w * 0.5), int(base - 96.0 * scale), int(shoulder_w), int(96.0 * scale), body)
		_poly(img, PackedVector2Array([
			Vector2(cx - shoulder_w * 0.5, base - 60.0 * scale),
			Vector2(cx + shoulder_w * 0.5, base - 60.0 * scale),
			Vector2(cx + shoulder_w * 0.7, base), Vector2(cx - shoulder_w * 0.7, base)]), body)
		# Cabeça.
		_circle(img, cx, base - 118.0 * scale, 30.0 * scale, body)
		# Braços erguidos em algumas silhuetas.
		if rng.randf() < 0.4:
			_line(img, Vector2(cx - shoulder_w * 0.45, base - 70.0 * scale),
				Vector2(cx - shoulder_w * 0.9, base - 140.0 * scale), body, 12)
		if rng.randf() < 0.4:
			_line(img, Vector2(cx + shoulder_w * 0.45, base - 70.0 * scale),
				Vector2(cx + shoulder_w * 0.9, base - 140.0 * scale), body, 12)
	return img

# ===========================================================================
# PAINÉIS E BOTÕES 9-SLICE (optional)
# ===========================================================================

func _draw_panel(id: String) -> Image:
	var img := Image.create_empty(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Fundo escuro (couro) com borda dourada CONTÍNUA e uniforme (9-slice).
	_fill(img, 0, 0, 256, 256, Color("241c30"))
	_fill_blend(img, 0, 0, 256, 256, Color(1, 1, 1, 0.03))
	_outline(img, 0, 0, 256, 256, Color("f5c451"), 14)
	_outline(img, 14, 14, 228, 228, Color("8a6a24"), 4)
	return img

func _draw_button(id: String) -> Image:
	var img := Image.create_empty(256, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill(img, 0, 0, 256, 96, Color("2e2438"))
	_fill_blend(img, 0, 0, 256, 48, Color(1, 1, 1, 0.06))
	_outline(img, 0, 0, 256, 96, Color("f5c451"), 10)
	_outline(img, 10, 10, 236, 76, Color("8a6a24"), 3)
	return img
