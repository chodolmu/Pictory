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
var _stamina_depleted_popup: StaminaDepletedPopup = null
var _ad_purchase_popup: AdPurchasePopup = null

func _ready() -> void:
	_start_btn.pressed.connect(_on_start_pressed)
	_ad_btn.pressed.connect(_on_ad_bonus_pressed)
	_close_btn.pressed.connect(_on_close_pressed)
	_dim_overlay.gui_input.connect(_on_dim_input)
	StaminaManager.stamina_changed.connect(_on_stamina_changed)
	visible = false

func show_popup(config) -> void:
	_current_config = config
	_title_label.text = "스테이지 %d" % config.stage_number
	_preview_label.text = "이 스테이지의 이야기가 여기에 표시됩니다..."
	_grid_size_label.text = "그리드: %d×%d" % [config.grid_size, config.grid_size]
	_goal_label.text = "목표: %d블록 파괴" % config.goal_target_count
	_turn_limit_label.text = "턴 제한: %d" % config.turn_limit
	_update_best_stars(config.stage_id)
	_refresh_stamina_label()

	var unlocked = ImagenDatabase.get_unlocked_list()
	if unlocked.is_empty():
		_party_select.visible = false
	else:
		_party_select.visible = true
		_party_select.setup("story")

	visible = true
	_animate_show()

func hide_popup() -> void:
	var tween = create_tween()
	tween.tween_property(_dim_overlay, "modulate:a", 0.0, 0.15)
	tween.parallel().tween_property(_panel, "scale", Vector2(0.8, 0.8), 0.15)
	tween.tween_callback(func(): visible = false)

func _animate_show() -> void:
	_dim_overlay.modulate.a = 0.0
	_panel.scale = Vector2(0.8, 0.8)
	_panel.pivot_offset = _panel.size / 2.0
	var tween = create_tween()
	tween.tween_property(_dim_overlay, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _refresh_stamina_label() -> void:
	var cur = StaminaManager.current_stamina
	var max_s = StaminaManager.max_stamina
	_stamina_label.text = "⚡ %d/%d  (행동력 1 소모)" % [cur, max_s]
	if cur < StaminaManager.STORY_COST:
		_stamina_label.modulate = Color.RED
	else:
		_stamina_label.modulate = Color.WHITE

func _on_start_pressed() -> void:
	if StaminaManager.can_play("story"):
		StaminaManager.consume(1)
		start_requested.emit(_current_config)
		hide_popup()
	else:
		_show_stamina_depleted()

func _show_stamina_depleted() -> void:
	if _stamina_depleted_popup == null:
		_stamina_depleted_popup = load("res://scenes/ui/stamina_depleted_popup.tscn").instantiate()
		add_child(_stamina_depleted_popup)
	_stamina_depleted_popup.show_popup("story")

func _on_ad_bonus_pressed() -> void:
	if _ad_purchase_popup == null:
		_ad_purchase_popup = load("res://scenes/ui/ad_purchase_popup.tscn").instantiate()
		add_child(_ad_purchase_popup)
	_ad_purchase_popup.show_popup(
		"행동력 5",
		func(): StaminaManager.add(5),
		{"cost": 50, "description": "재화 50개로 행동력 5 구매"}
	)

func _on_close_pressed() -> void:
	hide_popup()

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_popup()

func _on_stamina_changed(_cur: int, _max: int) -> void:
	if visible:
		_refresh_stamina_label()

func _update_best_stars(stage_id: String) -> void:
	var save = SaveManager.get_stage_data(stage_id)
	var stars = save.get("stars", 0) if not save.is_empty() else 0
	_best_stars_label.text = "최고 기록: " + _stars_to_string(stars)

func _stars_to_string(count: int) -> String:
	var s = ""
	for i in range(3):
		s += "★" if i < count else "☆"
	return s
