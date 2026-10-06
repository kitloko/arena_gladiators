extends SceneTree

## Teste do MANIFESTO da arte gerada (etapa 7 do PLANO_3.0).
## Executar com:
##   Godot --headless --path . -s res://tests/run_assets_test.gd
##
## Valida que o gerador rodou e produziu a arte que o jogo consome:
##   - assets/gen/manifest.json existe e é JSON válido;
##   - TODO id necessário (B1..B9) tem registro, arquivo no disco e as dimensões
##     declaradas batem com o PNG real;
##   - o mapa faixa->cidade/arena cobre as três faixas e o covil do boss final;
##   - o fallback funciona (id inexistente resolve para "").
##
## Se o gerador não tiver rodado, o teste FALHA com a mensagem do comando.

const AssetCatalogScript := preload("res://scripts/systems/asset_catalog.gd")

const EXPECTED_SIZE := {
	"B1": Vector2i(1536, 1024), "B2": Vector2i(1536, 1024), "B3": Vector2i(1536, 1024),
	"B4": Vector2i(1536, 1024), "B5": Vector2i(1536, 1024), "B6": Vector2i(1536, 1024),
	"B7": Vector2i(1536, 1024), "B8": Vector2i(1536, 1024), "B9": Vector2i(1536, 256),
}

var _failures: int = 0

func _initialize() -> void:
	AssetCatalogScript.reload()
	_test_manifest_present()
	_test_required_ids_have_entries()
	_test_files_exist_with_declared_dimensions()
	_test_entry_metadata()
	_test_band_mapping()
	_test_fallback_for_missing_id()
	_test_city_and_arena_resolve_to_real_files()
	if _failures == 0:
		print("PASS: manifesto da arte gerada válido (B1..B9 no disco com as dimensões certas).")
		quit(0)
	else:
		print("FAIL: %d verificacao(oes) da arte falharam." % _failures)
		quit(1)

func _test_manifest_present() -> void:
	var exists := FileAccess.file_exists(AssetCatalogScript.MANIFEST_PATH)
	_check(exists, "manifesto existe (%s)" % AssetCatalogScript.MANIFEST_PATH)
	if not exists:
		printerr("  FALHOU - manifesto ausente: rode o gerador antes do teste:")
		printerr("    GODOT_SILENCE_ROOT_WARNING=1 <godot> --headless --path . -s res://tools/gen_assets.gd -- --seed 1307")
		return
	var data: Dictionary = AssetCatalogScript.manifest()
	_check(not data.is_empty(), "manifesto é um JSON válido (não vazio)")
	_check(int(data.get("version", 0)) >= 1, "manifesto tem versão declarada")
	var images: Dictionary = data.get("images", {})
	_check(not images.is_empty(), "manifesto lista as imagens (%d)" % images.size())

func _test_required_ids_have_entries() -> void:
	for id: String in AssetCatalogScript.REQUIRED_IDS:
		var info: Dictionary = AssetCatalogScript.entry(id)
		_check(not info.is_empty(), "id necessário %s está no manifesto" % id)

func _test_files_exist_with_declared_dimensions() -> void:
	for id: String in AssetCatalogScript.REQUIRED_IDS:
		var info: Dictionary = AssetCatalogScript.entry(id)
		if info.is_empty():
			continue
		var declared_file := str(info.get("file", ""))
		_check(declared_file != "", "id %s declara o arquivo" % id)
		var path := AssetCatalogScript.path_for(id)
		_check(path != "", "arquivo do id %s existe no disco (%s)" % [id, declared_file])
		if path == "":
			continue
		# As dimensões DECLARADAS batem com o PNG real.
		var image: Image = Image.load_from_file(path)
		if image == null:
			_check(false, "PNG de %s carrega" % id)
			continue
		var declared_w := int(info.get("width", 0))
		var declared_h := int(info.get("height", 0))
		_check(image.get_width() == declared_w and image.get_height() == declared_h,
			"%s: dimensões do PNG (%dx%d) batem com o declarado (%dx%d)" % [id, image.get_width(), image.get_height(), declared_w, declared_h])
		if EXPECTED_SIZE.has(id):
			var want: Vector2i = EXPECTED_SIZE[id]
			_check(image.get_width() == want.x and image.get_height() == want.y,
				"%s: dimensão esperada %dx%d" % [id, want.x, want.y])

func _test_entry_metadata() -> void:
	for id: String in AssetCatalogScript.REQUIRED_IDS:
		var info: Dictionary = AssetCatalogScript.entry(id)
		if info.is_empty():
			continue
		_check(str(info.get("type", "")) != "", "id %s declara o tipo (cidade/arena/plateia)" % id)
		_check(str(info.get("band", "")) != "", "id %s declara a faixa/banda" % id)
		_check(int(info.get("seed", -1)) >= 0, "id %s declara o seed" % id)

func _test_band_mapping() -> void:
	for band: String in ["areia", "ferro", "prata"]:
		var city_id: String = AssetCatalogScript.city_id(band)
		_check(not AssetCatalogScript.entry(city_id).is_empty(), "faixa %s tem cidade no manifesto (%s)" % [band, city_id])
		var arenas: Array = AssetCatalogScript.arena_ids(band)
		_check(not arenas.is_empty(), "faixa %s tem ao menos uma arena" % band)
		var all_present := true
		for arena_id: Variant in arenas:
			if AssetCatalogScript.entry(str(arena_id)).is_empty():
				all_present = false
		_check(all_present, "todas as arenas da faixa %s existem no manifesto" % band)
	# As três cidades são DISTINTAS (uma por faixa).
	var cities := [AssetCatalogScript.city_id("areia"), AssetCatalogScript.city_id("ferro"), AssetCatalogScript.city_id("prata")]
	_check(cities[0] != cities[1] and cities[1] != cities[2] and cities[0] != cities[2], "as 3 faixas usam cidades distintas")
	# COMBATE FINAL -> covil, e a plateia existe.
	var boss := AssetCatalogScript.arena_id("areia", true, 0)
	_check(boss == AssetCatalogScript.BOSS_ARENA_ID, "COMBATE FINAL usa o covil (%s)" % boss)
	_check(not AssetCatalogScript.entry(boss).is_empty(), "covil do boss existe no manifesto")
	_check(not AssetCatalogScript.entry(AssetCatalogScript.CROWD_ID).is_empty(), "faixa de plateia existe no manifesto")

func _test_fallback_for_missing_id() -> void:
	_check(AssetCatalogScript.path_for("ZZZ_nao_existe") == "", "id inexistente resolve para vazio (aciona o fallback da tela)")
	_check(AssetCatalogScript.texture("ZZZ_nao_existe") == null, "texture de id inexistente é null (a tela cai nos assets antigos)")
	# Mesmo sem entrada no manifesto, a regra devolve um id válido por faixa.
	_check(AssetCatalogScript.arena_id("desconhecida", false, 0) == "B4", "faixa desconhecida cai numa arena padrão (B4)")

func _test_city_and_arena_resolve_to_real_files() -> void:
	var city_path: String = AssetCatalogScript.path_for(AssetCatalogScript.city_id("areia"))
	_check(city_path != "", "a cidade da faixa Areia resolve para um PNG real (%s)" % city_path)
	var arena_path: String = AssetCatalogScript.path_for(AssetCatalogScript.arena_id("prata", false, 0))
	_check(arena_path != "", "a arena da faixa Prata resolve para um PNG real (%s)" % arena_path)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok - %s" % label)
	else:
		_failures += 1
		printerr("  FALHOU - %s" % label)
