extends Node
## CollectionManager — Autoload 싱글턴.
## 후냐 커스터마이징 아이템, 플레이어 아이콘의 해금/적용 상태를 관리.

signal item_unlocked(category: String, item_id: String)

const HUNYA_ITEMS_PATH := "res://resources/collection/hunya_items.json"
const PLAYER_ICONS_PATH := "res://resources/collection/player_icons.json"

var _hunya_items: Array = []       # 전체 후냐 아이템 데이터
var _player_icons: Array = []      # 전체 아이콘 데이터

var _unlocked_hunya: Array[String] = []    # 해금된 후냐 아이템 id
var _equipped_hunya: Dictionary = {}       # 카테고리 → 장착 아이템 id

var _unlocked_icons: Array[String] = []    # 해금된 아이콘 id
var _selected_icon: String = "default"

func _ready() -> void:
	_load_data()
	_load_from_save()

# ─────────────────────────────────────────
# 데이터 로드
# ─────────────────────────────────────────

func _load_data() -> void:
	_hunya_items = _load_json(HUNYA_ITEMS_PATH).get("items", [])
	_player_icons = _load_json(PLAYER_ICONS_PATH).get("icons", [])
	# default 아이템 자동 해금
	for item in _hunya_items:
		if item.get("unlock_condition", {}).get("type") == "default":
			var id = item["id"]
			if id not in _unlocked_hunya:
				_unlocked_hunya.append(id)
	for icon in _player_icons:
		if icon.get("unlock_condition", {}).get("type") == "default":
			var id = icon["id"]
			if id not in _unlocked_icons:
				_unlocked_icons.append(id)
	# 기본 장착 설정
	if not _equipped_hunya.has("costume"):
		_equipped_hunya["costume"] = "costume_default"
	if not _equipped_hunya.has("accessory"):
		_equipped_hunya["accessory"] = "acc_none"

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("CollectionManager: 파일 없음: " + path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	return {}

# ─────────────────────────────────────────
# 후냐 커스터마이징 API
# ─────────────────────────────────────────

func unlock_hunya_item(item_id: String) -> void:
	if item_id not in _unlocked_hunya:
		_unlocked_hunya.append(item_id)
		var item = _get_hunya_item(item_id)
		var category = item.get("type", "costume") if item else "costume"
		item_unlocked.emit(category, item_id)
		_save()

func equip_hunya_item(item_id: String) -> void:
	var item = _get_hunya_item(item_id)
	if item and item_id in _unlocked_hunya:
		var category = item.get("type", "costume")
		_equipped_hunya[category] = item_id
		_save()

func get_equipped_hunya() -> Dictionary:
	return _equipped_hunya.duplicate()

func get_unlocked_items(category: String) -> Array:
	var result: Array = []
	for item in _hunya_items:
		if item.get("type", "") == category and item.get("id", "") in _unlocked_hunya:
			result.append(item)
	return result

func get_all_hunya_items(category: String) -> Array:
	var result: Array = []
	for item in _hunya_items:
		if item.get("type", "") == category:
			result.append(item)
	return result

func is_hunya_item_unlocked(item_id: String) -> bool:
	return item_id in _unlocked_hunya

func _get_hunya_item(item_id: String) -> Dictionary:
	for item in _hunya_items:
		if item.get("id", "") == item_id:
			return item
	return {}

# ─────────────────────────────────────────
# 플레이어 아이콘 API
# ─────────────────────────────────────────

func unlock_icon(icon_id: String) -> void:
	if icon_id not in _unlocked_icons:
		_unlocked_icons.append(icon_id)
		item_unlocked.emit("icon", icon_id)
		_save()

func select_icon(icon_id: String) -> void:
	if icon_id in _unlocked_icons:
		_selected_icon = icon_id
		PlayerProfile.set_selected_icon(icon_id)
		_save()

func get_selected_icon() -> String:
	return _selected_icon

func get_all_icons() -> Array:
	return _player_icons.duplicate()

func is_icon_unlocked(icon_id: String) -> bool:
	return icon_id in _unlocked_icons

func get_icon_data(icon_id: String) -> Dictionary:
	for icon in _player_icons:
		if icon.get("id", "") == icon_id:
			return icon
	return {}

# ─────────────────────────────────────────
# 조건 기반 해금
# ─────────────────────────────────────────

func check_chapter_clear(chapter: int) -> void:
	for item in _hunya_items:
		var cond = item.get("unlock_condition", {})
		if cond.get("type") == "chapter_clear" and cond.get("chapter") == chapter:
			unlock_hunya_item(item["id"])
	for icon in _player_icons:
		var cond = icon.get("unlock_condition", {})
		if cond.get("type") == "chapter_clear" and cond.get("chapter") == chapter:
			unlock_icon(icon["id"])

func check_achievement_reward(achievement_id: String) -> void:
	for item in _hunya_items:
		var cond = item.get("unlock_condition", {})
		if cond.get("type") == "achievement" and cond.get("achievement_id") == achievement_id:
			unlock_hunya_item(item["id"])
	for icon in _player_icons:
		var cond = icon.get("unlock_condition", {})
		if cond.get("type") == "achievement" and cond.get("achievement_id") == achievement_id:
			unlock_icon(icon["id"])

# ─────────────────────────────────────────
# SaveManager 연동
# ─────────────────────────────────────────

func to_save_data() -> Dictionary:
	return {
		"unlocked_hunya": _unlocked_hunya.duplicate(),
		"equipped_hunya": _equipped_hunya.duplicate(),
		"unlocked_icons": _unlocked_icons.duplicate(),
		"selected_icon": _selected_icon
	}

func from_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	var raw_hunya = data.get("unlocked_hunya", [])
	_unlocked_hunya.clear()
	for v in raw_hunya:
		_unlocked_hunya.append(str(v))
	var raw_equipped = data.get("equipped_hunya", {})
	for k in raw_equipped:
		_equipped_hunya[k] = str(raw_equipped[k])
	var raw_icons = data.get("unlocked_icons", [])
	_unlocked_icons.clear()
	for v in raw_icons:
		_unlocked_icons.append(str(v))
	_selected_icon = data.get("selected_icon", "default")

func _load_from_save() -> void:
	var data = SaveManager.get_collection_data()
	from_save_data(data)
	# 기본값 보정
	if _unlocked_hunya.is_empty():
		for item in _hunya_items:
			if item.get("unlock_condition", {}).get("type") == "default":
				_unlocked_hunya.append(item["id"])
	if _unlocked_icons.is_empty():
		for icon in _player_icons:
			if icon.get("unlock_condition", {}).get("type") == "default":
				_unlocked_icons.append(icon["id"])
	if not _equipped_hunya.has("costume"):
		_equipped_hunya["costume"] = "costume_default"
	if not _equipped_hunya.has("accessory"):
		_equipped_hunya["accessory"] = "acc_none"
	if _selected_icon == "default" and PlayerProfile.get_selected_icon() != "":
		_selected_icon = PlayerProfile.get_selected_icon()

func _save() -> void:
	SaveManager.save_collection_data(to_save_data())
