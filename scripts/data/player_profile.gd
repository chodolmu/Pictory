extends Node
## PlayerProfile — Autoload 싱글턴.
## 닉네임, 선택 아이콘, 최초 실행 여부 관리.

signal nickname_changed(new_name: String)

var _nickname: String = ""
var _selected_icon: String = "default"
var _first_launch: bool = true

func _ready() -> void:
	_load_from_save()

func get_nickname() -> String:
	return _nickname

func set_nickname(name: String) -> void:
	_nickname = name
	nickname_changed.emit(_nickname)
	_save_to_save_manager()

func get_selected_icon() -> String:
	return _selected_icon

func set_selected_icon(icon_id: String) -> void:
	_selected_icon = icon_id
	_save_to_save_manager()

func is_first_launch() -> bool:
	return _first_launch

func set_first_launch(value: bool) -> void:
	_first_launch = value
	_save_to_save_manager()

func to_save_data() -> Dictionary:
	return {
		"nickname": _nickname,
		"selected_icon": _selected_icon,
		"first_launch": _first_launch
	}

func from_save_data(data: Dictionary) -> void:
	_nickname = data.get("nickname", "")
	_selected_icon = data.get("selected_icon", "default")
	_first_launch = data.get("first_launch", true)

func _load_from_save() -> void:
	var data = SaveManager.get_player_profile()
	if not data.is_empty():
		from_save_data(data)

func _save_to_save_manager() -> void:
	SaveManager.save_player_profile(to_save_data())
