class_name ProfilePopup
extends CanvasLayer

## 프로필 팝업 — 가입일, 최고 클리어, 닉네임/아이콘 변경.

@onready var _icon_panel: Panel = $PanelContainer/VBox/IconPanel
@onready var _nickname_label: Label = $PanelContainer/VBox/NicknameLabel
@onready var _created_label: Label = $PanelContainer/VBox/InfoContainer/CreatedLabel
@onready var _highest_label: Label = $PanelContainer/VBox/InfoContainer/HighestLabel
@onready var _edit_nickname_btn: Button = $PanelContainer/VBox/EditNicknameButton
@onready var _nickname_edit: LineEdit = $PanelContainer/VBox/NicknameEdit
@onready var _close_btn: Button = $PanelContainer/VBox/CloseButton

var _editing_nickname: bool = false

func _ready() -> void:
	_edit_nickname_btn.pressed.connect(_on_edit_nickname)
	_nickname_edit.text_submitted.connect(_on_nickname_submitted)
	_close_btn.pressed.connect(_on_close)
	_nickname_edit.visible = false
	_refresh()
	visible = true
	_animate_popup()

func _refresh() -> void:
	_nickname_label.text = PlayerProfile.get_nickname()

	# 가입일
	var created_at = PlayerProfile.get_created_at()
	if created_at > 0:
		var dt = Time.get_datetime_dict_from_unix_time(created_at)
		_created_label.text = "가입일: %d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]
	else:
		_created_label.text = "가입일: -"

	# 최고 클리어 스테이지
	var highest = SaveManager.get_highest_cleared_stage()
	if highest.is_empty():
		_highest_label.text = "최고 클리어: -"
	else:
		var parts = highest.split("_")
		if parts.size() >= 2:
			var ch = parts[0].substr(2).to_int()
			var s = parts[1].substr(1).to_int()
			_highest_label.text = "최고 클리어: Ch%d Stage %d" % [ch, s]
		else:
			_highest_label.text = "최고 클리어: " + highest

	# 아이콘
	var icon_id = CollectionManager.get_selected_icon()
	var icon_data = CollectionManager.get_icon_data(icon_id)
	var icon_color = Color("#E8A87C")
	if not icon_data.is_empty():
		icon_color = Color(icon_data.get("color", "#E8A87C"))
	var style = StyleBoxFlat.new()
	style.bg_color = icon_color
	style.corner_radius_top_left = 32
	style.corner_radius_top_right = 32
	style.corner_radius_bottom_left = 32
	style.corner_radius_bottom_right = 32
	_icon_panel.add_theme_stylebox_override("panel", style)

func _on_edit_nickname() -> void:
	_editing_nickname = not _editing_nickname
	_nickname_edit.visible = _editing_nickname
	if _editing_nickname:
		_nickname_edit.text = PlayerProfile.get_nickname()
		_nickname_edit.grab_focus()

func _on_nickname_submitted(new_name: String) -> void:
	if not new_name.strip_edges().is_empty():
		PlayerProfile.set_nickname(new_name.strip_edges())
		_nickname_label.text = new_name.strip_edges()
	_nickname_edit.visible = false
	_editing_nickname = false

func _animate_popup() -> void:
	var panel = $PanelContainer
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.3)

func _on_close() -> void:
	queue_free()
