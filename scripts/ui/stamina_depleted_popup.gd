class_name StaminaDepletedPopup
extends CanvasLayer
## 행동력 부족 팝업.

signal ad_reward_received()

@onready var _dim: ColorRect = $DimOverlay
@onready var _panel: PanelContainer = $PanelContainer
@onready var _status_label: Label = $PanelContainer/VBox/StatusLabel
@onready var _timer_label: Label = $PanelContainer/VBox/TimerLabel
@onready var _watch_ad_btn: Button = $PanelContainer/VBox/Buttons/WatchAdButton
@onready var _shop_btn: Button = $PanelContainer/VBox/Buttons/ShopButton
@onready var _close_btn: Button = $PanelContainer/VBox/Buttons/CloseButton
@onready var _ad_limit_label: Label = $PanelContainer/VBox/AdLimitLabel

var _mode: String = "story"
var _on_ad_success_callback: Callable = Callable()

func _ready() -> void:
	_watch_ad_btn.pressed.connect(_on_watch_ad_pressed)
	_shop_btn.pressed.connect(_on_shop_pressed)
	_close_btn.pressed.connect(_on_close_pressed)
	_dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: _on_close_pressed()
	)
	AdManager.ad_reward_granted.connect(_on_ad_reward)
	AdManager.ad_failed.connect(_on_ad_failed)
	visible = false

func show_popup(mode: String, on_success: Callable = Callable()) -> void:
	_mode = mode
	_on_ad_success_callback = on_success
	var needed = StaminaManager.get_cost(mode)
	var cur = StaminaManager.current_stamina
	_status_label.text = "현재: %d / 필요: %d" % [cur, needed]
	_update_timer()
	_update_ad_button()
	visible = true
	_animate_show()

func _update_timer() -> void:
	var secs = StaminaManager.get_time_to_next_recovery()
	var mins = secs / 60
	var s = secs % 60
	_timer_label.text = "다음 회복까지: %d분 %d초" % [mins, s]

func _update_ad_button() -> void:
	if not AdManager.can_show_ad():
		_watch_ad_btn.disabled = true
		_ad_limit_label.visible = true
		_ad_limit_label.text = "오늘 광고 시청 횟수를 모두 사용했습니다"
	else:
		_watch_ad_btn.disabled = false
		_ad_limit_label.visible = false

func _animate_show() -> void:
	_dim.modulate.a = 0.0
	_panel.scale = Vector2(0.8, 0.8)
	var tween = create_tween()
	tween.tween_property(_dim, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_watch_ad_pressed() -> void:
	_watch_ad_btn.disabled = true
	AdManager.show_rewarded_ad()

func _on_ad_reward(_reward_type: String) -> void:
	StaminaManager.add(5)
	if _on_ad_success_callback.is_valid():
		_on_ad_success_callback.call()
	ad_reward_received.emit()
	hide_popup()

func _on_ad_failed(reason: String) -> void:
	_watch_ad_btn.disabled = false
	_ad_limit_label.visible = true
	_ad_limit_label.text = "광고를 불러올 수 없습니다: %s" % reason

func _on_shop_pressed() -> void:
	hide_popup()
	SceneManager.change_scene("res://scenes/ui/shop.tscn")

func _on_close_pressed() -> void:
	hide_popup()

func hide_popup() -> void:
	var tween = create_tween()
	tween.tween_property(_dim, "modulate:a", 0.0, 0.15)
	tween.parallel().tween_property(_panel, "scale", Vector2(0.8, 0.8), 0.15)
	tween.tween_callback(func(): visible = false)
