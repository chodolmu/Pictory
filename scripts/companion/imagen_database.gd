extends Node
## ImagenDatabase — Autoload 싱글턴.
## JSON에서 이마젠 목록 로드 + 해금 상태 관리.

const ImagenDataScript = preload("res://scripts/companion/imagen.gd")
const DB_PATH := "res://resources/imagenes/imagen_database.json"

var all_imagenes: Dictionary = {}   # id -> ImagenData
var unlocked_ids: Array[String] = []

func _ready() -> void:
	load_database()
	_load_unlocked()

# ─────────────────────────────────────────
# DB 로드
# ─────────────────────────────────────────

func load_database() -> void:
	if not FileAccess.file_exists(DB_PATH):
		push_error("ImagenDatabase: 파일 없음: " + DB_PATH)
		return
	var file = FileAccess.open(DB_PATH, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if json == null or not json is Dictionary:
		push_error("ImagenDatabase: JSON 파싱 실패")
		return
	all_imagenes.clear()
	for entry in json.get("imagenes", []):
		var data = _parse_entry(entry)
		if data:
			all_imagenes[data.id] = data

func _parse_entry(e: Dictionary):
	if not e.has("id") or not e.has("skill_id"):
		push_error("ImagenDatabase: 필수 필드 누락")
		return null
	var d = ImagenDataScript.new()
	d.id = e.get("id", "")
	d.display_name = e.get("display_name", d.id)
	d.attribute = e.get("attribute", "fire")
	d.description = e.get("description", "")
	d.skill_id = e.get("skill_id", "K1")
	d.cooldown = e.get("cooldown", 4)
	d.unlock_condition = e.get("unlock_condition", {})
	return d

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func get_imagen(id: String):
	return all_imagenes.get(id, null)

func is_unlocked(id: String) -> bool:
	return id in unlocked_ids

func unlock(id: String) -> void:
	if id not in unlocked_ids:
		unlocked_ids.append(id)
		SaveManager.save_unlocked_imagenes(unlocked_ids)

func get_unlocked_list() -> Array:
	var result: Array = []
	for id in unlocked_ids:
		var d = get_imagen(id)
		if d:
			result.append(d)
	return result

func get_all_list() -> Array:
	return all_imagenes.values()

# ─────────────────────────────────────────
# SaveManager 연동
# ─────────────────────────────────────────

func _load_unlocked() -> void:
	unlocked_ids = SaveManager.get_unlocked_imagenes()
