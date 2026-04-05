class_name StageConfirmPopup
extends CanvasLayer

signal start_requested(stage_config: Object)

@onready var _dim_overlay: ColorRect = $DimOverlay
@onready var _panel: PanelContainer = $PanelContainer
@onready var _title_label: Label = $PanelContainer/VBox/TitleLabel
@onready var _preview_label: RichTextLabel = $PanelContainer/VBox/PreviewLabel
@onready var _grid_size_label: Label = $PanelContainer/VBox/InfoContainer/GridSizeLabel
@onready var _goal_label: Label = $PanelContainer/VBox/InfoContainer/GoalLabel
@onready var _turn_limit_label: Label = $PanelContainer/VBox/InfoContainer/TurnLimitLabel
@onready var _best_stars_label: Label = $PanelContainer/VBox/InfoContainer/BestStarsLabel
@onready var _stamina_label: Label = $PanelContainer/VBox/StaminaLabel
@onready var _start_btn: Button = $PanelContainer/VBox/StartButton
@onready var _ad_btn: Button = $PanelContainer/VBox/AdBonusButton
@onready var _close_btn: Button = $PanelContainer/VBox/CloseButton
@onready var _party_select: PartySelect = $PanelContainer/VBox/PartySelect

var _current_config = null
func _ready() -> void:
	_start_btn.pressed.connect(_on_start_pressed)
	_ad_btn.pressed.connect(_on_ad_bonus_pressed)
	_close_btn.pressed.connect(_on_close_pressed)
	_dim_overlay.gui_input.connect(_on_dim_input)
	visible = false
	_dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_popup(config) -> void:
	_current_config = config
	_title_label.text = "스테이지 %d" % config.stage_number
	_preview_label.text = "이 스테이지의 이야기가 여기에 표시됩니다..."
	_grid_size_label.text = "그리드: %d×%d" % [config.grid_size, config.grid_size]
	_goal_label.text = "목표: %d블록 파괴" % config.goal_target_count
	_turn_limit_label.text = "턴 제한: %d" % config.turn_limit
	_update_best_stars(config.stage_id)
	_stamina_label.visible = false

	var unlocked = ImagenDatabase.get_unlocked_list()
	if unlocked.is_empty():
		_party_select.visible = false
	else:
		_party_select.visible = true
		_party_select.setup("story")

	_dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	_animate_show()

func hide_popup() -> void:
	var tween = create_tween()
	tween.tween_property(_dim_overlay, "modulate:a", 0.0, 0.15)
	tween.parallel().tween_property(_panel, "scale", Vector2(0.8, 0.8), 0.15)
	tween.tween_callback(func():
		visible = false
		_dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)

func _animate_show() -> void:
	_dim_overlay.modulate.a = 0.0
	_panel.scale = Vector2(0.8, 0.8)
	_panel.pivot_offset = _panel.size / 2.0
	var tween = create_tween()
	tween.tween_property(_dim_overlay, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_start_pressed() -> void:
	start_requested.emit(_current_config)
	queue_free()

func _on_ad_bonus_pressed() -> void:
	# 스토리모드는 행동력 소모 없음 — 광고 보고 보너스 턴 획득 등 추후 확장
	pass

func _on_close_pressed() -> void:
	hide_popup()

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_popup()

func _update_best_stars(stage_id: String) -> void:
	var cleared = SaveManager.is_stage_cleared(stage_id)
	_best_stars_label.text = "클리어 완료" if cleared else "미클리어"
