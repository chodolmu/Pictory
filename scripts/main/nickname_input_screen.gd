class_name NicknameInputScreen
extends Control

@onready var _nickname_edit: LineEdit = $CenterContainer/VBox/NicknameLineEdit
@onready var _validation_label: Label = $CenterContainer/VBox/ValidationLabel
@onready var _confirm_btn: Button = $CenterContainer/VBox/ConfirmButton

func _ready() -> void:
	_confirm_btn.pressed.connect(_on_confirm)
	_nickname_edit.text_changed.connect(_on_text_changed)
	_confirm_btn.disabled = true
	_validation_label.text = "2~12자로 입력해주세요"

func _on_text_changed(new_text: String) -> void:
	var trimmed = new_text.strip_edges()
	var valid = trimmed.length() >= 2 and trimmed.length() <= 12
	_confirm_btn.disabled = not valid
	_validation_label.text = "" if valid else "2~12자로 입력해주세요"
	_validation_label.add_theme_color_override("font_color", Color.RED if not valid else Color.WHITE)

func _on_confirm() -> void:
	var nickname = _nickname_edit.text.strip_edges()
	PlayerProfile.set_nickname(nickname)
	PlayerProfile.set_first_launch(false)
	SceneManager.change_scene("res://scenes/main/main_menu.tscn")
