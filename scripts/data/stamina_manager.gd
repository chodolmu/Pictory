extends Node
## StaminaManager — Autoload 싱글턴.
## 행동력(스태미나) 시스템: 소모/회복/저장/로드.

@export var max_stamina: int = 30
@export var recovery_interval: float = 300.0  # 5분 (초 단위)
@export var debug_unlimited: bool = false

signal stamina_changed(current: int, max: int)
signal stamina_depleted()

var current_stamina: int = 30
var last_recovery_time: int = 0

# 내부 회복 타이머 누적
var _recovery_accumulator: float = 0.0

const STORY_COST := 1
const INFINITY_COST := 2

func _ready() -> void:
	_load_stamina()
	_apply_offline_recovery()

func _process(delta: float) -> void:
	if current_stamina >= max_stamina:
		return
	_recovery_accumulator += delta
	if _recovery_accumulator >= recovery_interval:
		var ticks = int(_recovery_accumulator / recovery_interval)
		_recovery_accumulator = fmod(_recovery_accumulator, recovery_interval)
		_recover(ticks)

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func consume(amount: int) -> bool:
	if debug_unlimited:
		return true
	if current_stamina < amount:
		return false
	current_stamina -= amount
	_save_stamina()
	stamina_changed.emit(current_stamina, max_stamina)
	if current_stamina == 0:
		stamina_depleted.emit()
	return true

func add(amount: int) -> void:
	current_stamina = mini(current_stamina + amount, max_stamina)
	last_recovery_time = int(Time.get_unix_time_from_system())
	_save_stamina()
	stamina_changed.emit(current_stamina, max_stamina)

func can_play(mode: String) -> bool:
	if debug_unlimited:
		return true
	var cost = _get_cost(mode)
	return current_stamina >= cost

func get_time_to_next_recovery() -> int:
	if current_stamina >= max_stamina:
		return 0
	var now = int(Time.get_unix_time_from_system())
	var elapsed_since = now - last_recovery_time
	var remaining = int(recovery_interval) - (elapsed_since % int(recovery_interval))
	return remaining

func get_cost(mode: String) -> int:
	return _get_cost(mode)

# ─────────────────────────────────────────
# 내부
# ─────────────────────────────────────────

func _get_cost(mode: String) -> int:
	match mode:
		"infinity": return INFINITY_COST
		_: return STORY_COST

func _recover(amount: int) -> void:
	current_stamina = mini(current_stamina + amount, max_stamina)
	last_recovery_time = int(Time.get_unix_time_from_system())
	_save_stamina()
	stamina_changed.emit(current_stamina, max_stamina)

func _apply_offline_recovery() -> void:
	if current_stamina >= max_stamina:
		return
	var now = int(Time.get_unix_time_from_system())
	var elapsed = now - last_recovery_time
	if elapsed > 0 and last_recovery_time > 0:
		var recovered = int(elapsed / recovery_interval)
		if recovered > 0:
			current_stamina = mini(current_stamina + recovered, max_stamina)
			last_recovery_time = now
			_save_stamina()

func _save_stamina() -> void:
	SaveManager.save_stamina_data({
		"current_stamina": current_stamina,
		"last_recovery_time": last_recovery_time
	})

func _load_stamina() -> void:
	var data = SaveManager.get_stamina_data()
	current_stamina = data.get("current_stamina", max_stamina)
	last_recovery_time = data.get("last_recovery_time", int(Time.get_unix_time_from_system()))
