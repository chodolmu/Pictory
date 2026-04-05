extends Node
## AchievementManager — Autoload 싱글턴.
## 업적 조건 정의, 달성 체크, 보상 지급, 칭호 관리.

signal achievement_unlocked(achievement_id: String)

const ACHIEVEMENTS_PATH := "res://resources/collection/achievements.json"

var _all_achievements: Array = []          # 전체 업적 정의
var _completed: Array[String] = []         # 달성된 업적 id
var _claimed: Array[String] = []           # 보상 수령된 업적 id
var _selected_title: String = ""           # 대표 칭호
var _pending_popup: Array[String] = []     # 팝업 미처리 업적 큐

# 누적 통계 (업적 체크용)
var _stats: Dictionary = {
	"stage_clear_count": 0,
	"total_destroyed": 0,
	"max_chain": 0,
	"imagen_count": 0,
	"combo_count": 0,
	"cleared_chapters": [],
	"achievement_count": 0,
	"rainbow_destroyed": 0
}

func _ready() -> void:
	_load_achievements()
	_load_from_save()

# ─────────────────────────────────────────
# 데이터 로드
# ─────────────────────────────────────────

func _load_achievements() -> void:
	var file = FileAccess.open(ACHIEVEMENTS_PATH, FileAccess.READ)
	if file == null:
		push_error("AchievementManager: 파일 없음: " + ACHIEVEMENTS_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_all_achievements = parsed.get("achievements", [])

# ─────────────────────────────────────────
# 업적 공개 API
# ─────────────────────────────────────────

func get_all_achievements() -> Array:
	return _all_achievements.duplicate()

func is_completed(achievement_id: String) -> bool:
	return achievement_id in _completed

func is_claimed(achievement_id: String) -> bool:
	return achievement_id in _claimed

func get_achievement(achievement_id: String) -> Dictionary:
	for a in _all_achievements:
		if a.get("id", "") == achievement_id:
			return a
	return {}

func get_unclaimed_count() -> int:
	var count = 0
	for id in _completed:
		if id not in _claimed:
			count += 1
	return count

func get_pending_popup() -> String:
	if _pending_popup.is_empty():
		return ""
	return _pending_popup[0]

func pop_pending_popup() -> String:
	if _pending_popup.is_empty():
		return ""
	var id = _pending_popup[0]
	_pending_popup.remove_at(0)
	return id

func has_pending_popups() -> bool:
	return not _pending_popup.is_empty()

# ─────────────────────────────────────────
# 통계 업데이트 → 업적 체크
# ─────────────────────────────────────────

func on_stage_cleared(stage_id: String) -> void:
	_stats["stage_clear_count"] += 1
	_save_stats()
	_check_by_type("stage_clear_count")
	_check_by_type("achievement_count")

func on_chapter_cleared(chapter: int) -> void:
	if chapter not in _stats["cleared_chapters"]:
		_stats["cleared_chapters"].append(chapter)
	_save_stats()
	_check_by_type("chapter_clear")
	_check_by_type("achievement_count")
	CollectionManager.check_chapter_clear(chapter)

func on_blocks_destroyed(count: int, chain: int) -> void:
	_stats["total_destroyed"] += count
	if chain > _stats["max_chain"]:
		_stats["max_chain"] = chain
	_save_stats()
	_check_by_type("total_destroyed")
	_check_by_type("max_chain")

func on_imagen_unlocked() -> void:
	_stats["imagen_count"] = ImagenDatabase.get_unlocked_list().size()
	_save_stats()
	_check_by_type("imagen_count")

func on_combo(count: int) -> void:
	_stats["combo_count"] += count
	_save_stats()
	_check_by_type("combo_count")

func on_speed_clear(seconds: float) -> void:
	_stats["last_clear_seconds"] = seconds
	_check_by_type("speed_clear")

# ─────────────────────────────────────────
# 조건 체크
# ─────────────────────────────────────────

func check_all() -> void:
	for a in _all_achievements:
		check_specific(a.get("id", ""))

func check_specific(achievement_id: String) -> void:
	if achievement_id in _completed:
		return
	var a = get_achievement(achievement_id)
	if a.is_empty():
		return
	if _check_condition(a.get("condition", {})):
		_unlock(achievement_id)

func _check_by_type(condition_type: String) -> void:
	for a in _all_achievements:
		var cond = a.get("condition", {})
		if cond.get("type", "") == condition_type:
			check_specific(a.get("id", ""))

func _check_condition(condition: Dictionary) -> bool:
	var ctype = condition.get("type", "")
	match ctype:
		"stage_clear_count":
			return _stats["stage_clear_count"] >= condition.get("count", 0)
		"chapter_clear":
			return condition.get("chapter", -1) in _stats["cleared_chapters"]
		"total_destroyed":
			return _stats["total_destroyed"] >= condition.get("count", 0)
		"max_chain":
			return _stats["max_chain"] >= condition.get("count", 0)
		"imagen_count":
			return _stats["imagen_count"] >= condition.get("count", 0)
		"combo_count":
			return _stats["combo_count"] >= condition.get("count", 0)
		"speed_clear":
			var last = _stats.get("last_clear_seconds", 9999.0)
			return last <= condition.get("seconds", 30)
		"achievement_count":
			return _completed.size() >= condition.get("count", 0)
	return false

# ─────────────────────────────────────────
# 업적 달성
# ─────────────────────────────────────────

func _unlock(achievement_id: String) -> void:
	if achievement_id in _completed:
		return
	_completed.append(achievement_id)
	_stats["achievement_count"] = _completed.size()
	_pending_popup.append(achievement_id)
	achievement_unlocked.emit(achievement_id)
	_save()

# ─────────────────────────────────────────
# 보상 지급
# ─────────────────────────────────────────

func grant_reward(achievement_id: String) -> void:
	if achievement_id not in _completed:
		return
	if achievement_id in _claimed:
		return
	_claimed.append(achievement_id)
	var a = get_achievement(achievement_id)
	var reward = a.get("reward", {})
	# 재화 지급
	if reward.has("currency"):
		SaveManager.add_currency(reward["currency"])
	# 칭호
	if reward.has("title"):
		_unlock_title(reward["title"])
	# 후냐 아이템 해금
	if reward.has("hunya_item_id"):
		CollectionManager.unlock_hunya_item(reward["hunya_item_id"])
	if reward.has("hunya_item_id2"):
		CollectionManager.unlock_hunya_item(reward["hunya_item_id2"])
	# 아이콘 해금
	if reward.has("icon_id"):
		CollectionManager.unlock_icon(reward["icon_id"])
	CollectionManager.check_achievement_reward(achievement_id)
	_save()

# ─────────────────────────────────────────
# 칭호
# ─────────────────────────────────────────

var _unlocked_titles: Array[String] = []

func _unlock_title(title: String) -> void:
	if title not in _unlocked_titles:
		_unlocked_titles.append(title)

func get_unlocked_titles() -> Array[String]:
	return _unlocked_titles.duplicate()

func set_selected_title(title: String) -> void:
	if title in _unlocked_titles:
		_selected_title = title
		_save()

func get_selected_title() -> String:
	return _selected_title

# ─────────────────────────────────────────
# SaveManager 연동
# ─────────────────────────────────────────

func to_save_data() -> Dictionary:
	return {
		"completed": _completed.duplicate(),
		"claimed": _claimed.duplicate(),
		"selected_title": _selected_title,
		"unlocked_titles": _unlocked_titles.duplicate()
	}

func from_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	var raw = data.get("completed", [])
	_completed.clear()
	for v in raw:
		_completed.append(str(v))
	var raw_claimed = data.get("claimed", [])
	_claimed.clear()
	for v in raw_claimed:
		_claimed.append(str(v))
	_selected_title = data.get("selected_title", "")
	var raw_titles = data.get("unlocked_titles", [])
	_unlocked_titles.clear()
	for v in raw_titles:
		_unlocked_titles.append(str(v))

func _load_from_save() -> void:
	var data = SaveManager.get_achievement_data()
	from_save_data(data)
	var stats = SaveManager.get_stats()
	if not stats.is_empty():
		for key in _stats.keys():
			if stats.has(key):
				_stats[key] = stats[key]

func _save() -> void:
	SaveManager.save_achievement_data(to_save_data())

func _save_stats() -> void:
	SaveManager.save_stats(_stats)
