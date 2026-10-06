class_name FighterVisuals
extends RefCounted

## Resolve a ARTE DE POSE dos lutadores (etapa 8 do PLANO_3.0).
##
## Duas responsabilidades, as duas sem depender de tempo real (testáveis):
##
## 1. EVENTO -> POSE SEMÂNTICA. `pose_for_event()` traduz o evento da luta
##    ("attack"/"defend"/"hit"/"fallen"...) para a pose semântica do contrato de
##    corte do dono (docs/ARTE.md §3-A): idle · ataque · defesa · levado · caido.
## 2. FOLHA DO DONO COM PRECEDÊNCIA. Lê o manifesto de personagens
##    (res://assets/gen/characters.json) e, para um char_id + pose, devolve o PNG
##    da arte DELE. Sem entrada no manifesto (ou sem o PNG no disco), cai nos
##    sprites atuais hero_*/enemy_* — o jogo nunca fica sem lutador.
##
## Mesmo padrão do AssetCatalog (manifesto + fallback): o manifesto é a fonte da
## verdade; a ausência dele NUNCA quebra a tela.

const GEN_DIR := "res://assets/gen/"
const CHARACTERS_PATH := GEN_DIR + "characters.json"

## Poses semânticas da folha do dono, na ORDEM da folha (docs/ARTE.md §3-A):
## 1 parado · 2 ataque · 3 defesa · 4 levando · 5 caído.
const POSES: Array[String] = ["idle", "ataque", "defesa", "levado", "caido"]
const IDLE_POSE := "idle"
const FALLEN_POSE := "caido"

## Caminho do manifesto de personagens. É uma variável (e não uma const) para o
## teste poder apontar para um manifesto temporário e provar a precedência sem
## precisar de arte de verdade no repositório.
static var manifest_path: String = CHARACTERS_PATH

static var _manifest: Dictionary = {}
static var _loaded := false
static var _loaded_path := ""

## Zera o cache (testes e recarga explícita).
static func reload() -> void:
	_loaded = false
	_manifest = {}
	_loaded_path = ""

## Aponta o manifesto para outro arquivo (usado pelo teste; em produção é o
## CHARACTERS_PATH).
static func set_manifest_path(path: String) -> void:
	manifest_path = path
	reload()

static func manifest() -> Dictionary:
	if not _loaded or _loaded_path != manifest_path:
		_loaded = true
		_loaded_path = manifest_path
		_manifest = _read_manifest()
	return _manifest

static func _read_manifest() -> Dictionary:
	if not FileAccess.file_exists(manifest_path):
		return {}
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}

## Mapeia o EVENTO da luta (ou um nome de pose já semântico) para a pose do
## contrato. É a função que o teste exercita — pura, sem tempo real.
static func pose_for_event(event_id: String) -> String:
	match event_id:
		"ataque", "attack", "swing", "strike", "shot", "tiro", "ranged", "melee", "investida":
			return "ataque"
		"defesa", "defend", "guard", "block", "blocked", "aparou", "parry", "dodge", "dodged", "esquiva", "sleep", "exhibit":
			return "defesa"
		"levado", "hit", "damage", "dano", "recoil", "taking_hit", "countered":
			return "levado"
		"caido", "fallen", "ko", "down", "defeated", "death":
			return "caido"
		_:
			return IDLE_POSE

## Pose semântica a partir do estado runtime da arena (idle/attack/defend/hit/
## fallen). Mantido separado só por clareza: hoje delega em pose_for_event.
static func semantic_pose(runtime_pose: String) -> String:
	return pose_for_event(runtime_pose)

## Um personagem do dono tem alguma entrada no manifesto?
static func has_character(char_id: String) -> bool:
	if char_id == "":
		return false
	var chars: Dictionary = manifest().get("characters", {})
	return chars.has(char_id)

## Caminho res:// do PNG de (char_id, pose). "" quando o manifesto não tem a
## entrada/arquivo — aí quem chama usa o fallback (hero_*/enemy_*).
static func path_for(char_id: String, pose: String) -> String:
	if char_id == "" or pose == "":
		return ""
	var chars: Dictionary = manifest().get("characters", {})
	var entry: Variant = chars.get(char_id, {})
	if not entry is Dictionary:
		return ""
	var file := str((entry as Dictionary).get(pose, ""))
	if file == "":
		return ""
	# A folha do dono é cortada em assets/gen/<char>/<nome>.png; aceitamos tanto o
	# caminho relativo ao GEN_DIR quanto um res:// absoluto.
	var declared := file if file.begins_with("res://") else GEN_DIR + file
	if FileAccess.file_exists(declared):
		return declared
	return ""

## Textura de (char_id, pose) ou null quando o dono ainda não entregou aquela pose.
## Funciona mesmo sem o --import ter rodado (carrega o PNG direto por Image),
## igual ao AssetCatalog.
static func texture_for(char_id: String, pose: String) -> Texture2D:
	var path := path_for(char_id, pose)
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

## Resolve a textura de uma pose com PRECEDÊNCIA do manifesto do dono:
##   1. characters.json[char_id][pose semântica]  (arte do dono);
##   2. o conjunto atual (fallback) pela chave runtime ("attack"/"defend"/"hit");
##   3. para "fallen", o sprite de "hit" (é o que a arena inclina/escurece);
##   4. por fim, o "idle" do conjunto atual.
## Nunca devolve null enquanto o fallback tiver o idle.
static func resolve(char_id: String, runtime_pose: String, fallback: Dictionary) -> Texture2D:
	var semantic := semantic_pose(runtime_pose)
	var from_manifest := texture_for(char_id, semantic)
	if from_manifest != null:
		return from_manifest
	var keys: Array[String] = [runtime_pose, semantic]
	if runtime_pose == "fallen":
		keys.append("hit")
	keys.append(IDLE_POSE)
	for key: String in keys:
		var candidate: Variant = fallback.get(key, null)
		if candidate is Texture2D:
			return candidate
	return null
