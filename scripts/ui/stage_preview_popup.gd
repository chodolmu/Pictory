class_name StagePreviewPopup
extends CanvasLayer

## 스테이지 프리뷰 팝업 — 스테이지 정보 + 파티 선택 + 시작.

signal start_requested(stage_id: String)
signal cancelled()

@onready var _stage_label: Label = $PanelContainer/VBox/StageLabel
@onready var _goal_label: Label = $PanelContainer/VBox/InfoContainer/GoalLabel
@onready var _turns_label: Label = $PanelContainer/VBox/InfoContainer/TurnsLabel
@onready var _colors_label: Label = $PanelContainer/VBox/InfoContainer/ColorsLabel
@onready var _gimmicks_label: Label = $PanelContainer/VBox/InfoContainer/GimmicksLabel
@onready var _party_select: PartySelect = $PanelContainer/VBox/PartySelect
@onready var _start_btn: Button = $PanelContainer/VBox/ButtonContainer/StartButton
@onready var _cancel_btn: Button = $PanelContainer/VBox/ButtonContainer/CancelButton

var _current_stage_id: String = ""

func _ready() -> void:
	visible = false
	_start_btn.pressed.connect(_on_start)
	_cancel_btn.pressed.connect(_on_cancel)

func show_preview(stage_id: String) -> void:
	_current_stage_id = stage_id
	var config = LevelLoader.load_stage(stage_id)
	if config == null:
		push_error("StagePreviewPopup: 스테이지 로드 실패: " + stage_id)
		cancelled.emit()
		return

	_stage_label.text = "Chapter %d - Stage %d" % [config.chapter, config.stage_number]
	_goal_label.text = "목표: 블록 %d개 파괴" % config.goal_target_count
	_turns_label.text = "턴: %d턴" % config.turn_limit
	_colors_label.text = "색상: %d색" % config.num_colors
	_gimmicks_label.text = _format_gimmicks(config.gimmick_placements)
	_party_select.setup("story")

	visible = true
	_animate_popup()

func _format_gimmicks(placements: Array) -> String:
	if placements.is_empty():
		return "기믹: 없음"
	var types: Dictionary = {}
	for p in placements:
		var t = p.get("type", "unknown")
		types[t] = types.get(t, 0) + 1
	var parts: Array = []
	for t in types:
		parts.append("%s x%d" % [t, types[t]])
	return "기믹: " + ", ".join(parts)

func _animate_popup() -> void:
	var panel = $PanelContainer
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.3)

func _on_start() -> void:
	start_requested.emit(_current_stage_id)

func _on_cancel() -> void:
	cancelled.emit()
