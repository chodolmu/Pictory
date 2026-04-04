class_name InfinityConfirmPopup
extends CanvasLayer

signal start_requested()

@onready var _dim_overlay: ColorRect = $DimOverlay
@onready var _panel: PanelContainer = $PanelContainer
@onready var _high_score_label: Label = $PanelContainer/VBox/HighScoreContainer/HighScoreLabel
@onready var _stamina_label: Label = $PanelContainer/VBox/StaminaLabel
@onready var _start_btn: Button = $PanelContainer/VBox/StartButton
@onready var _ad_btn: Button = $PanelContainer/VBox/AdBonusButton
@onready var _close_btn: Button = $PanelContainer/VBox/CloseButton

var _stamina_depleted_popup: StaminaDepletedPopup = null

func _ready() -> void:
	_start_btn.pressed.connect(_on_start_pressed)
	_ad_btn.pressed.connect(_on_ad_bonus_pressed)
	_close_btn.pressed.connect(_on_close_pressed)
	_dim_overlay.gui_input.connect(_on_dim_input)
	StaminaManager.stamina_changed.connect(_on_stamina_changed)
	visible = false

func show_popup() -> void:
	var high_score = SaveManager.get_infinity_high_score()
	_high_score_label.text = "최고 기록: %s점" % _format_number(high_score)
	_refresh_stamina_label()
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
	var tween = create_tween()
	tween.tween_property(_dim_overlay, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _refresh_stamina_label() -> void:
	var cur = StaminaManager.current_stamina
	var max_s = StaminaManager.max_stamina
	_stamina_label.text = "⚡ %d/%d  (행동력 2 소모)" % [cur, max_s]
	if cur < StaminaManager.INFINITY_COST:
		_stamina_label.modulate = Color.RED
	else:
		_stamina_label.modulate = Color.WHITE

func _on_start_pressed() -> void:
	if StaminaManager.can_play("infinity"):
		StaminaManager.consume(2)
		start_requested.emit()
		hide_popup()
		SceneManager.change_scene("res://scenes/game/game.tscn", {"mode": "infinity"})
	else:
		_show_stamina_depleted()

func _show_stamina_depleted() -> void:
	if _stamina_depleted_popup == null:
		_stamina_depleted_popup = load("res://scenes/ui/stamina_depleted_popup.tscn").instantiate()
		add_child(_stamina_depleted_popup)
		_stamina_depleted_popup.ad_reward_received.connect(_on_stamina_restored)
	_stamina_depleted_popup.show_popup("infinity")

func _on_stamina_restored() -> void:
	_refresh_stamina_label()
	if StaminaManager.can_play("infinity"):
		StaminaManager.consume(2)
		start_requested.emit()
		hide_popup()
		SceneManager.change_scene("res://scenes/game/game.tscn", {"mode": "infinity"})

func _on_ad_bonus_pressed() -> void:
	if _stamina_depleted_popup == null:
		_stamina_depleted_popup = load("res://scenes/ui/stamina_depleted_popup.tscn").instantiate()
		add_child(_stamina_depleted_popup)
		_stamina_depleted_popup.ad_reward_received.connect(_on_stamina_restored)
	_stamina_depleted_popup.show_popup("infinity")

func _on_close_pressed() -> void:
	hide_popup()

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_popup()

func _on_stamina_changed(_cur: int, _max: int) -> void:
	if visible:
		_refresh_stamina_label()

func _format_number(n: int) -> String:
	var s = str(n)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
