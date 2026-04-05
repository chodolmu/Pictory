extends Control
## CollectionTabIcon — 플레이어 아이콘 탭.

@onready var _back_btn: Button = $MarginContainer/VBox/TopBar/BackButton
@onready var _grid: GridContainer = $MarginContainer/VBox/Scroll/Grid
@onready var _detail_name: Label = $MarginContainer/VBox/DetailPanel/VBox/NameLabel
@onready var _detail_unlock: Label = $MarginContainer/VBox/DetailPanel/VBox/UnlockLabel
@onready var _apply_btn: Button = $MarginContainer/VBox/DetailPanel/VBox/ApplyButton

var _selected_icon_id: String = ""

func _ready() -> void:
	_back_btn.pressed.connect(_on_back)
	_apply_btn.pressed.connect(_on_apply)
	_apply_btn.disabled = true
	_refresh_grid()

func _on_back() -> void:
	SceneManager.change_scene("res://scenes/main/main_menu.tscn")

func _refresh_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var all_icons = CollectionManager.get_all_icons()
	for icon in all_icons:
		var btn = _make_icon_button(icon)
		_grid.add_child(btn)

func _make_icon_button(icon: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(90, 90)
	btn.toggle_mode = true
	var icon_id = icon.get("id", "")
	var is_unlocked = CollectionManager.is_icon_unlocked(icon_id)
	var selected = CollectionManager.get_selected_icon()
	if is_unlocked:
		btn.modulate = Color.WHITE
		btn.text = icon.get("name", "")
		if selected == icon_id:
			btn.text += "\n✓"
	else:
		btn.modulate = Color(0.2, 0.2, 0.2, 0.5)
		btn.text = "?"
	btn.pressed.connect(_on_icon_selected.bind(icon_id, is_unlocked))
	return btn

func _on_icon_selected(icon_id: String, is_unlocked: bool) -> void:
	if not is_unlocked:
		var icon_data = CollectionManager.get_icon_data(icon_id)
		_detail_name.text = "미해금"
		_detail_unlock.text = _format_condition(icon_data.get("unlock_condition", {}))
		_apply_btn.disabled = true
		return
	_selected_icon_id = icon_id
	var icon_data = CollectionManager.get_icon_data(icon_id)
	_detail_name.text = icon_data.get("name", "")
	_detail_unlock.text = _format_condition(icon_data.get("unlock_condition", {}))
	var current = CollectionManager.get_selected_icon()
	if current == icon_id:
		_apply_btn.text = "적용 중"
		_apply_btn.disabled = true
	else:
		_apply_btn.text = "적용"
		_apply_btn.disabled = false

func _on_apply() -> void:
	if _selected_icon_id == "":
		return
	CollectionManager.select_icon(_selected_icon_id)
	_apply_btn.text = "적용 중"
	_apply_btn.disabled = true
	_refresh_grid()

func _format_condition(cond: Dictionary) -> String:
	match cond.get("type", "default"):
		"default":
			return "기본 해금"
		"chapter_clear":
			return "챕터 %d 클리어 시 해금" % cond.get("chapter", 0)
		"achievement":
			return "업적 달성 시 해금"
		"story_progress":
			return "스토리 진행 시 해금"
	return "조건 불명"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		SceneManager.change_scene("res://scenes/main/main_menu.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		SceneManager.change_scene("res://scenes/main/main_menu.tscn")
