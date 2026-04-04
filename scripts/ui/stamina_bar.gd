class_name StaminaBar
extends HBoxContainer
## 행동력 표시 UI 컴포넌트.
## 여러 화면에서 재사용 가능한 씬으로 인스턴스화.

@onready var _icon_label: Label = $IconLabel
@onready var _stamina_label: Label = $StaminaLabel
@onready var _timer_label: Label = $TimerLabel

var _timer_update_acc: float = 0.0

func _ready() -> void:
	StaminaManager.stamina_changed.connect(_on_stamina_changed)
	_refresh()

func _process(delta: float) -> void:
	_timer_update_acc += delta
	if _timer_update_acc >= 1.0:
		_timer_update_acc = 0.0
		_update_timer_label()

# ─────────────────────────────────────────
# 내부
# ─────────────────────────────────────────

func _refresh() -> void:
	_update_stamina_label()
	_update_timer_label()

func _update_stamina_label() -> void:
	var cur = StaminaManager.current_stamina
	var max_s = StaminaManager.max_stamina
	_stamina_label.text = "%d/%d" % [cur, max_s]
	if cur <= 5:
		_stamina_label.modulate = Color.RED
	elif cur >= max_s:
		_stamina_label.modulate = Color.GREEN
	else:
		_stamina_label.modulate = Color.WHITE

func _update_timer_label() -> void:
	var cur = StaminaManager.current_stamina
	var max_s = StaminaManager.max_stamina
	if cur >= max_s:
		_timer_label.text = "충전 완료"
		_timer_label.modulate = Color.GREEN
		_timer_label.visible = true
	else:
		var secs = StaminaManager.get_time_to_next_recovery()
		var mins = secs / 60
		var s = secs % 60
		_timer_label.text = "다음 회복: %d:%02d" % [mins, s]
		_timer_label.modulate = Color.LIGHT_GRAY
		_timer_label.visible = true

func _on_stamina_changed(_cur: int, _max: int) -> void:
	_refresh()
