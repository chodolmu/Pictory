class_name TitleScreen
extends Control

@onready var _title_label: Label = $CenterContainer/VBox/GameTitleLabel
@onready var _start_button: Button = $CenterContainer/VBox/StartButton

func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_animate_title()

func _animate_title() -> void:
	_title_label.pivot_offset = _title_label.size / 2.0
	var tween = create_tween().set_loops()
	tween.tween_property(_title_label, "scale", Vector2(1.02, 1.02), 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_title_label, "scale", Vector2(0.98, 0.98), 1.0).set_trans(Tween.TRANS_SINE)

func _on_start_pressed() -> void:
	if PlayerProfile.is_first_launch():
		SceneManager.change_scene("res://scenes/main/nickname_input.tscn")
	else:
		SceneManager.change_scene("res://scenes/main/main_menu.tscn")
