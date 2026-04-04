extends Control
## AchievementBanner — 인게임 중 업적 달성 시 상단 배너 간략 알림.

@onready var _label: Label = $BannerPanel/HBox/Label
@onready var _panel: PanelContainer = $BannerPanel

var _queue: Array[String] = []
var _showing: bool = false

func _ready() -> void:
	visible = false
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(achievement_id: String) -> void:
	_queue.append(achievement_id)
	if not _showing:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	var id = _queue[0]
	_queue.remove_at(0)
	var a = AchievementManager.get_achievement(id)
	if a.is_empty():
		_showing = false
		_show_next()
		return
	_label.text = "업적 달성! " + a.get("name", "")
	visible = true
	_animate_banner()

func _animate_banner() -> void:
	_panel.position.y = -60
	var tween = create_tween()
	tween.tween_property(_panel, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(2.0)
	tween.tween_property(_panel, "position:y", -60.0, 0.3)
	tween.tween_callback(func():
		visible = false
		_show_next()
	)
