extends Node
## HeartManager — Autoload 싱글턴.
## 하트(체력) 시스템: 소모/회복/저장/로드.

const MAX_HEARTS: int = 5
const RECOVERY_SECONDS: float = 1800.0  # 30분

signal hearts_changed(current: int, max_hearts: int)
signal hearts_depleted()

var current_hearts: int = 5
var last_recovery_time: int = 0

var _recovery_accumulator: float = 0.0

func _ready() -> void:
	_load_hearts()
	_apply_offline_recovery()

func _process(delta: float) -> void:
	if current_hearts >= MAX_HEARTS:
		_recovery_accumulator = 0.0
		return
	_recovery_accumulator += delta
	if _recovery_accumulator >= RECOVERY_SECONDS:
		var ticks = int(_recovery_accumulator / RECOVERY_SECONDS)
		_recovery_accumulator = fmod(_recovery_accumulator, RECOVERY_SECONDS)
		_recover(ticks)

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func consume(amount: int = 1) -> bool:
	if current_hearts < amount:
		hearts_depleted.emit()
		return false
	current_hearts -= amount
	_save_hearts()
	hearts_changed.emit(current_hearts, MAX_HEARTS)
	if current_hearts == 0:
		hearts_depleted.emit()
	return true

func add(amount: int) -> void:
	current_hearts = mini(current_hearts + amount, MAX_HEARTS)
	_save_hearts()
	hearts_changed.emit(current_hearts, MAX_HEARTS)

func is_full() -> bool:
	return current_hearts >= MAX_HEARTS

func get_recovery_time_remaining() -> float:
	## 다음 1개 회복까지 남은 초.
	if current_hearts >= MAX_HEARTS:
		return 0.0
	return RECOVERY_SECONDS - _recovery_accumulator

# ─────────────────────────────────────────
# 내부
# ─────────────────────────────────────────

func _recover(ticks: int) -> void:
	if ticks <= 0:
		return
	current_hearts = mini(current_hearts + ticks, MAX_HEARTS)
	last_recovery_time = int(Time.get_unix_time_from_system())
	_save_hearts()
	hearts_changed.emit(current_hearts, MAX_HEARTS)

func _apply_offline_recovery() -> void:
	if current_hearts >= MAX_HEARTS:
		return
	if last_recovery_time <= 0:
		return
	var now = int(Time.get_unix_time_from_system())
	var elapsed = now - last_recovery_time
	if elapsed <= 0:
		return
	var ticks = int(elapsed / RECOVERY_SECONDS)
	if ticks > 0:
		_recover(ticks)
		_recovery_accumulator = fmod(float(elapsed), RECOVERY_SECONDS)

func _load_hearts() -> void:
	var data = SaveManager.get_hearts_data()
	current_hearts = data.get("current", MAX_HEARTS)
	last_recovery_time = data.get("last_recovery", int(Time.get_unix_time_from_system()))

func _save_hearts() -> void:
	last_recovery_time = int(Time.get_unix_time_from_system())
	SaveManager.save_hearts_data({
		"current": current_hearts,
		"last_recovery": last_recovery_time
	})
