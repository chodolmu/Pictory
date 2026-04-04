class_name SplashScreen
extends Control

@export var fade_in_duration: float = 0.8
@export var hold_duration: float = 1.5
@export var fade_out_duration: float = 0.8

@onready var _logo_label: Label = $CenterContainer/LogoLabel

var _skipped: bool = false

func _ready() -> void:
	_logo_label.modulate.a = 0.0
	_play_sequence()

func _play_sequence() -> void:
	var tween = create_tween()
	tween.tween_property(_logo_label, "modulate:a", 1.0, fade_in_duration)
	tween.tween_interval(hold_duration)
	tween.tween_property(_logo_label, "modulate:a", 0.0, fade_out_duration)
	tween.tween_callback(_go_to_title)

func _go_to_title() -> void:
	if _skipped:
		return
	_skipped = true
	SceneManager.change_scene("res://scenes/main/title.tscn")

func _input(event: InputEvent) -> void:
	if _skipped:
		return
	if event is InputEventMouseButton and event.pressed:
		_skipped = true
		_go_to_title()
	elif event is InputEventScreenTouch and event.pressed:
		_skipped = true
		_go_to_title()
