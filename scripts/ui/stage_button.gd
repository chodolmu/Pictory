class_name StageButton
extends Control

signal stage_selected(stage_id: String)

@onready var _number_label: Label = $NumberLabel
@onready var _stars_container: HBoxContainer = $StarsContainer
@onready var _lock_overlay: ColorRect = $LockOverlay
@onready var _lock_label: Label = $LockOverlay/LockLabel

var stage_id: String = ""
var stage_number: int = 0
var is_locked: bool = false
var stars: int = 0

func setup(s_id: String, s_num: int, star_count: int, locked: bool) -> void:
	stage_id = s_id
	stage_number = s_num
	stars = star_count
	is_locked = locked

	_number_label.text = str(s_num)
	_lock_overlay.visible = locked

	var star_nodes = _stars_container.get_children()
	for i in range(star_nodes.size()):
		star_nodes[i].color = Color.YELLOW if i < star_count else Color(0.4, 0.4, 0.4)

func _gui_input(event: InputEvent) -> void:
	if is_locked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		stage_selected.emit(stage_id)
