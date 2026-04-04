class_name AdPurchasePopup
extends CanvasLayer
## 광고/구매 전용 범용 팝업.
## show()로 보상 내용과 콜백을 외부에서 주입.

@onready var _dim: ColorRect = $DimOverlay
@onready var _panel: PanelContainer = $PanelContainer
@onready var _desc_label: Label = $PanelContainer/VBox/DescLabel
@onready var _watch_ad_btn: Button = $PanelContainer/VBox/Buttons/WatchAdButton
@onready var _buy_btn: Button = $PanelContainer/VBox/Buttons/BuyButton
@onready var _close_btn: Button = $PanelContainer/VBox/Buttons/CloseButton
@onready var _msg_label: Label = $PanelContainer/VBox/MsgLabel

var _reward_callback: Callable = Callable()
var _purchase_option: Dictionary = {}

func _ready() -> void:
	_watch_ad_btn.pressed.connect(_on_watch_ad_pressed)
	_buy_btn.pressed.connect(_on_buy_pressed)
	_close_btn.pressed.connect(_on_close_pressed)
	_dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: _on_close_pressed()
	)
	AdManager.ad_reward_granted.connect(_on_ad_reward)
	AdManager.ad_failed.connect(_on_ad_failed)
	visible = false

func show_popup(reward_description: String, reward_callback: Callable, purchase_option: Dictionary = {}) -> void:
	_reward_callback = reward_callback
	_purchase_option = purchase_option
	_desc_label.text = "광고를 시청하면 %s을 받습니다" % reward_description
	_msg_label.text = ""
	_msg_label.visible = false

	# 광고 버튼
	_watch_ad_btn.disabled = not AdManager.can_show_ad()

	# 구매 버튼
	if purchase_option.is_empty():
		_buy_btn.visible = false
	else:
		_buy_btn.visible = true
		var cost = purchase_option.get("cost", 0)
		var desc = purchase_option.get("description", "구매")
		_buy_btn.text = desc
		_buy_btn.disabled = SaveManager.get_currency() < cost

	visible = true
	_animate_show()

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
	if _reward_callback.is_valid():
		_reward_callback.call()
	_hide_popup()

func _on_ad_failed(reason: String) -> void:
	_watch_ad_btn.disabled = false
	_msg_label.text = "광고를 불러올 수 없습니다. 잠시 후 다시 시도해주세요"
	_msg_label.visible = true

func _on_buy_pressed() -> void:
	var cost = _purchase_option.get("cost", 0)
	if SaveManager.get_currency() < cost:
		_buy_btn.disabled = true
		_msg_label.text = "재화가 부족합니다"
		_msg_label.visible = true
		return
	SaveManager.spend_currency(cost)
	if _reward_callback.is_valid():
		_reward_callback.call()
	_hide_popup()

func _on_close_pressed() -> void:
	_hide_popup()

func _hide_popup() -> void:
	var tween = create_tween()
	tween.tween_property(_dim, "modulate:a", 0.0, 0.15)
	tween.parallel().tween_property(_panel, "scale", Vector2(0.8, 0.8), 0.15)
	tween.tween_callback(func(): visible = false)
