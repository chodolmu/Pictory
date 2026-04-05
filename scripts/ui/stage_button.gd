class_name StageButton
extends Control

signal stage_selected(stage_id: String)

@onready var _number_label: Label = $NumberLabel
@onready var _lock_overlay: ColorRect = $LockOverlay
@onready var _lock_label: Label = $LockOverlay/LockLabel

var stage_id: String = ""
var stage_number: int = 0
var is_locked: bool = false
var is_cleared: bool = false

func setup(s_id: String, s_num: int, cleared: bool, locked: bool) -> void:
	stage_id = s_id
	stage_number = s_num
	is_cleared = cleared
	is_locked = locked

	_number_label.text = str(s_num)
	_lock_overlay.visible = locked

func _gui_input(event: InputEvent) -> void:
	if is_locked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		stage_selected.emit(stage_id)
