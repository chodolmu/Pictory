extends Node
## SaveManager — Autoload 싱글턴.
## 게임 진행 데이터를 user://save_data.json 에 저장/로드.

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 2

var _data: Dictionary = {}

func _ready() -> void:
	_load()

# ─── Stage Data ───────────────────────────────────────────

func get_stage_data(stage_id: String) -> Dictionary:
	return _data.get("stages", {}).get(stage_id, {})

func save_stage_result(stage_id: String) -> void:
	if not _data.has("stages"):
		_data["stages"] = {}
	_data["stages"][stage_id] = {"cleared": true}
	_save()

func is_stage_cleared(stage_id: String) -> bool:
	return get_stage_data(stage_id).get("cleared", false)

func get_highest_cleared_stage() -> String:
	## 가장 높은 클리어 스테이지 ID 반환 (예: "ch03_s07")
	var stages: Dictionary = _data.get("stages", {})
	var best_id: String = ""
	var best_ch: int = 0
	var best_s: int = 0
	for stage_id in stages:
		if not stages[stage_id].get("cleared", false):
			continue
		var parts = str(stage_id).split("_")
		if parts.size() < 2:
			continue
		var ch = parts[0].substr(2).to_int()
		var s = parts[1].substr(1).to_int()
		if ch > best_ch or (ch == best_ch and s > best_s):
			best_ch = ch
			best_s = s
			best_id = stage_id
	return best_id

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


# ─── Stars (스티커북 재화) ────────────────────────────────

func get_stars() -> int:
	return _data.get("stars", 0)

func save_stars(amount: int) -> void:
	_data["stars"] = amount
	_save()

# ─── Sticker Progress ────────────────────────────────────

func get_sticker_progress(chapter: int) -> Array:
	## 챕터별 컬러 복구된 오브젝트 인덱스 배열 반환.
	return _data.get("sticker_progress", {}).get(str(chapter), [])

func save_sticker_progress(chapter: int, indices: Array) -> void:
	if not _data.has("sticker_progress"):
		_data["sticker_progress"] = {}
	_data["sticker_progress"][str(chapter)] = indices
	_save()

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
		"stages": {},
		"chapters_unlocked": [1],
		"gems": 0,
		"stars": 0,
		"sticker_progress": {},
		"hearts": {"current": 5, "last_recovery": Time.get_unix_time_from_system()},
		"settings": {"bgm_volume": 80, "se_volume": 80},
		"player_profile": {"nickname": "", "selected_icon": "default", "first_launch": true, "created_at": Time.get_unix_time_from_system()}
	}

func _migrate_if_needed() -> void:
	var file_version = _data.get("version", 0)
	if file_version < 2:
		# v1 → v2: currency→gems 이관, 불필요 필드 제거
		if _data.has("currency"):
			_data["gems"] = _data.get("gems", 0) + _data.get("currency", 0)
			_data.erase("currency")
		_data.erase("infinity")
		_data.erase("stamina")
		_data.erase("ad")
		_data.erase("shop_history")
		# stages에서 stars/best_score 제거
		var stages = _data.get("stages", {})
		for stage_id in stages:
			var s = stages[stage_id]
			if s is Dictionary:
				stages[stage_id] = {"cleared": s.get("cleared", s.get("stars", 0) > 0)}
		# hearts 초기화
		if not _data.has("hearts"):
			_data["hearts"] = {"current": 5, "last_recovery": Time.get_unix_time_from_system()}
		# player_profile에 created_at 추가
		var profile = _data.get("player_profile", {})
		if not profile.has("created_at"):
			profile["created_at"] = Time.get_unix_time_from_system()
			_data["player_profile"] = profile
		_data["version"] = 2
	# 클리어 기록 기반 챕터 자동 해금
	_sync_chapters_from_clears()
	_save()

func _sync_chapters_from_clears() -> void:
	## 스테이지 클리어 기록이 있으면 해당 챕터와 이전 챕터를 자동 해금.
	var unlocked = get_unlocked_chapters()
	var changed = false
	var stages: Dictionary = _data.get("stages", {})
	for stage_id in stages:
		var save = stages[stage_id]
		if save is Dictionary and save.get("cleared", false):
			var parts = str(stage_id).split("_")
			if parts.size() >= 1 and parts[0].begins_with("ch"):
				var ch_num = parts[0].substr(2).to_int()
				if ch_num > 0 and ch_num not in unlocked:
					unlocked.append(ch_num)
					changed = true
				for c in range(1, ch_num):
					if c not in unlocked:
						unlocked.append(c)
						changed = true
	if changed:
		unlocked.sort()
		_data["chapters_unlocked"] = unlocked

func reset_all_data() -> void:
	_data = _create_default_data()
	_save()

# ─── Gems ─────────────────────────────────────────────────

func get_gems() -> int:
	return _data.get("gems", 0)

func save_gems(amount: int) -> void:
	_data["gems"] = amount
	_save()

# ─── Hearts ───────────────────────────────────────────────

func get_hearts_data() -> Dictionary:
	return _data.get("hearts", {"current": 5, "last_recovery": Time.get_unix_time_from_system()})

func save_hearts_data(data: Dictionary) -> void:
	_data["hearts"] = data.duplicate()
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
