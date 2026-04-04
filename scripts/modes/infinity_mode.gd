class_name InfinityMode
extends Node

## 무한 모드 규칙 관리.
## 시간 제한 + 대량 파괴 시 보너스 시간 + 난이도 스케일링.

signal time_updated(remaining: float, max_time: float)
signal bonus_time_added(amount: float, reason: String)
signal game_over(final_score: int, total_destroyed: int)
signal difficulty_scaled(level: int)

@export var initial_time: float = 60.0
@export var max_time: float = 90.0
@export var bonus_threshold: int = 5
@export var bonus_coefficient: float = 0.5
@export var combo_time_multiplier: float = 1.2

@export var scaling_enabled: bool = true
@export var scaling_intervals: Array[float] = [60.0, 120.0, 180.0]

var remaining_time: float = 0.0
var total_destroyed: int = 0
var total_score: int = 0
var is_active: bool = false

var elapsed_time: float = 0.0
var current_scale_level: int = 0
var _timer_paused: bool = false

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func initialize() -> void:
	remaining_time = initial_time
	total_destroyed = 0
	total_score = 0
	elapsed_time = 0.0
	current_scale_level = 0
	is_active = true
	_timer_paused = false

func on_action_performed(destroyed_blocks: int, combo_level: int) -> void:
	if not is_active:
		return

	total_destroyed += destroyed_blocks

	if destroyed_blocks >= bonus_threshold:
		var bonus = _calculate_bonus_time(destroyed_blocks, combo_level)
		remaining_time = minf(remaining_time + bonus, max_time)
		bonus_time_added.emit(bonus, "destroy_%d_combo_%d" % [destroyed_blocks, combo_level])

func pause_timer() -> void:
	_timer_paused = true

func resume_timer() -> void:
	_timer_paused = false

func get_time_ratio() -> float:
	if max_time <= 0.0:
		return 0.0
	return clampf(remaining_time / max_time, 0.0, 1.0)

# ─────────────────────────────────────────
# 프레임 처리
# ─────────────────────────────────────────

func _process(delta: float) -> void:
	if not is_active:
		return

	elapsed_time += delta

	if not _timer_paused:
		remaining_time -= delta
		time_updated.emit(remaining_time, max_time)

		if remaining_time <= 0.0:
			remaining_time = 0.0
			is_active = false
			game_over.emit(total_score, total_destroyed)
			return

	if scaling_enabled:
		_check_scaling()

# ─────────────────────────────────────────
# 내부 계산
# ─────────────────────────────────────────

func _calculate_bonus_time(destroyed_blocks: int, combo_level: int) -> float:
	var excess = destroyed_blocks - bonus_threshold + 1
	var multiplier = pow(combo_time_multiplier, combo_level)
	return excess * bonus_coefficient * multiplier

func _check_scaling() -> void:
	var new_level = 0
	for i in range(scaling_intervals.size()):
		if elapsed_time >= scaling_intervals[i]:
			new_level = i + 1
	if new_level > current_scale_level:
		current_scale_level = new_level
		difficulty_scaled.emit(current_scale_level)
