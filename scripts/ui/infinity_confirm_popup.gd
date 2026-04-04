class_name InfinityConfirmPopup
extends CanvasLayer

signal start_requested()

@onready var _dim_overlay: ColorRect = $DimOverlay
@onready var _panel: PanelContainer = $PanelContainer
@onready var _high_score_label: Label = $PanelContainer/VBox/HighScoreContainer/HighScoreLabel
@onready var _start_btn: Button = $PanelContainer/VBox/StartButton
@onready var _ad_btn: Button = $PanelContainer/VBox/AdBonusButton
@onready var _close_btn: Button = $PanelContainer/VBox/CloseButton

func _ready() -> void:
	_start_btn.pressed.connect(_on_start_pressed)
	_ad_btn.pressed.connect(_on_ad_bonus_pressed)
	_close_btn.pressed.connect(_on_close_pressed)
	_dim_overlay.gui_input.connect(_on_dim_input)
	visible = false

func show_popup() -> void:
	var high_score = SaveManager.get_infinity_high_score()
	_high_score_label.text = "최고 기록: %s점" % _format_number(high_score)
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

func _on_start_pressed() -> void:
	start_requested.emit()
	hide_popup()
	SceneManager.change_scene("res://scenes/game/game.tscn", {"mode": "infinity"})

func _on_ad_bonus_pressed() -> void:
	print("[stub] 광고/구매 행동력 추가 — S11에서 구현")

func _on_close_pressed() -> void:
	hide_popup()

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_popup()

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
