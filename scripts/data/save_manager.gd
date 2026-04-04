extends Node
## SaveManager — Autoload 싱글턴.
## 게임 진행 데이터를 user://save_data.json 에 저장/로드.

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1

var _data: Dictionary = {}

func _ready() -> void:
	_load()

# ─── Stage Data ───────────────────────────────────────────

func get_stage_data(stage_id: String) -> Dictionary:
	return _data.get("stages", {}).get(stage_id, {})

func save_stage_result(stage_id: String, stars: int, score: int) -> void:
	if not _data.has("stages"):
		_data["stages"] = {}
	var existing = _data["stages"].get(stage_id, {"cleared": false, "stars": 0, "best_score": 0})
	_data["stages"][stage_id] = {
		"cleared": true,
		"stars": maxi(existing.get("stars", 0), stars),
		"best_score": maxi(existing.get("best_score", 0), score)
	}
	_save()

func is_stage_cleared(stage_id: String) -> bool:
	return get_stage_data(stage_id).get("cleared", false)

func get_stage_stars(stage_id: String) -> int:
	return get_stage_data(stage_id).get("stars", 0)

# ─── Currency ─────────────────────────────────────────────

func get_currency() -> int:
	return _data.get("currency", 0)

func add_currency(amount: int) -> void:
	_data["currency"] = get_currency() + amount
	_save()

func spend_currency(amount: int) -> bool:
	if get_currency() >= amount:
		_data["currency"] = get_currency() - amount
		_save()
		return true
	return false

# ─── Chapter Unlock ───────────────────────────────────────

func get_unlocked_chapters() -> Array:
	return _data.get("chapters_unlocked", [1])

func is_chapter_unlocked(chapter: int) -> bool:
	return chapter in get_unlocked_chapters()

func unlock_chapter(chapter: int) -> void:
	var unlocked = get_unlocked_chapters()
	if chapter not in unlocked:
		unlocked.append(chapter)
		_data["chapters_unlocked"] = unlocked
		_save()

# ─── Infinity Mode ────────────────────────────────────────

func get_infinity_high_score() -> int:
	return _data.get("infinity", {}).get("high_score", 0)

func save_infinity_result(score: int) -> bool:
	if not _data.has("infinity"):
		_data["infinity"] = {"high_score": 0, "total_plays": 0}
	_data["infinity"]["total_plays"] = _data["infinity"].get("total_plays", 0) + 1
	var is_new_record = score > _data["infinity"].get("high_score", 0)
	if is_new_record:
		_data["infinity"]["high_score"] = score
	_save()
	return is_new_record

# ─── Settings ─────────────────────────────────────────────

func get_settings() -> Dictionary:
	return _data.get("settings", {"bgm_volume": 80, "se_volume": 80})

func save_settings(settings: Dictionary) -> void:
	_data["settings"] = settings
	_save()

# ─── PlayerProfile ────────────────────────────────────────

func get_player_profile() -> Dictionary:
	return _data.get("player_profile", {})

func save_player_profile(profile: Dictionary) -> void:
	_data["player_profile"] = profile
	_save()

# ─── Internal ─────────────────────────────────────────────

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_data = _create_default_data()
		_save()
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		_data = parsed
		_migrate_if_needed()
	else:
		push_error("SaveManager: 세이브 파일 파싱 실패, 기본값으로 초기화")
		_data = _create_default_data()
		_save()

func _save() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()

func _create_default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"currency": 0,
		"stages": {},
		"chapters_unlocked": [1],
		"infinity": {"high_score": 0, "total_plays": 0},
		"settings": {"bgm_volume": 80, "se_volume": 80},
		"player_profile": {"nickname": "", "selected_icon": "default", "first_launch": true}
	}

func _migrate_if_needed() -> void:
	var file_version = _data.get("version", 0)
	if file_version < SAVE_VERSION:
		_data["version"] = SAVE_VERSION
		_save()

func reset_all_data() -> void:
	_data = _create_default_data()
	_save()

# ─── Imagen / Party ───────────────────────────────────────────────

func get_unlocked_imagenes() -> Array[String]:
	var raw = _data.get("unlocked_imagenes", [])
	var result: Array[String] = []
	for v in raw:
		result.append(str(v))
	return result

func save_unlocked_imagenes(ids: Array[String]) -> void:
	_data["unlocked_imagenes"] = ids.duplicate()
	_save()

func get_last_party() -> Array[String]:
	var raw = _data.get("last_party", [])
	var result: Array[String] = []
	for v in raw:
		result.append(str(v))
	return result

func save_last_party(ids: Array[String]) -> void:
	_data["last_party"] = ids.duplicate()
	_save()

# ─── Collection ───────────────────────────────────────────────

func get_collection_data() -> Dictionary:
	return _data.get("collection", {})

func save_collection_data(data: Dictionary) -> void:
	_data["collection"] = data.duplicate(true)
	_save()

# ─── Achievement ──────────────────────────────────────────────

func get_achievement_data() -> Dictionary:
	return _data.get("achievements", {})

func save_achievement_data(data: Dictionary) -> void:
	_data["achievements"] = data.duplicate(true)
	_save()

# ─── Stats (업적 체크용) ──────────────────────────────────────

func get_stats() -> Dictionary:
	return _data.get("stats", {})

func save_stats(stats: Dictionary) -> void:
	_data["stats"] = stats.duplicate(true)
	_save()
