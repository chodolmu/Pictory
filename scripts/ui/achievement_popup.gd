extends Control
## AchievementPopup — 업적 달성 시 전체 팝업.
## 동시 달성 업적 큐를 순차 표시.

signal popup_closed

@onready var _overlay: ColorRect = $Overlay
@onready var _panel: PanelContainer = $Center/Panel
@onready var _title_label: Label = $Center/Panel/VBox/TitleLabel
@onready var _name_label: Label = $Center/Panel/VBox/NameLabel
@onready var _desc_label: Label = $Center/Panel/VBox/DescLabel
@onready var _reward_label: Label = $Center/Panel/VBox/RewardLabel
@onready var _claim_btn: Button = $Center/Panel/VBox/Buttons/ClaimButton
@onready var _close_btn: Button = $Center/Panel/VBox/Buttons/CloseButton

var _queue: Array[String] = []
var _current_id: String = ""

func _ready() -> void:
	visible = false
	_claim_btn.pressed.connect(_on_claim)
	_close_btn.pressed.connect(_on_close)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(achievement_id: String) -> void:
	_queue.append(achievement_id)
	if not visible:
		_show_next()

func show_achievement(achievement_id: String) -> void:
	_queue.append(achievement_id)
	if not visible:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		visible = false
		popup_closed.emit()
		return
	_current_id = _queue[0]
	_queue.remove_at(0)
	var a = AchievementManager.get_achievement(_current_id)
	if a.is_empty():
		_show_next()
		return
	_title_label.text = "업적 달성!"
	_name_label.text = a.get("name", "")
	_desc_label.text = a.get("description", "")
	_reward_label.text = _format_reward(a.get("reward", {}))
	var already_claimed = AchievementManager.is_claimed(_current_id)
	_claim_btn.visible = not already_claimed
	visible = true
	_animate_in()

func _format_reward(reward: Dictionary) -> String:
	var parts: Array = []
	if reward.has("currency"):
		parts.append("코인 +%d" % reward["currency"])
	if reward.has("title"):
		parts.append("칭호: %s" % reward["title"])
	if reward.has("hunya_item_id"):
		parts.append("후냐 아이템 해금")
	if reward.has("icon_id"):
		parts.append("아이콘 해금")
	if parts.is_empty():
		return "보상 없음"
	return "보상: " + ", ".join(parts)

func _on_claim() -> void:
	if _current_id != "":
		AchievementManager.grant_reward(_current_id)
	_show_next()

func _on_close() -> void:
	_show_next()

func _animate_in() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.8, 0.8)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK)
