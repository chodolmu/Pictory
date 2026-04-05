class_name InfinityMode
extends Node

## 무한 모드 규칙 관리.
## 시간 제한 + 대량 파괴 시 보너스 시간 + 난이도 스케일링.

signal time_updated(remaining: float, max_time: float)
signal bonus_time_added(amount: float, reason: String)
signal game_over(final_score: int, total_destroyed: int)
signal difficulty_scaled(level: int)

@export var initial_time: float = 30.0
@export var max_time: float = 45.0
@export var bonus_threshold: int = 7
@export var bonus_coefficient: float = 0.2
@export var combo_time_multiplier: float = 1.05

@export var scaling_enabled: bool = true
@export var scaling_intervals: Array[float] = [60.0, 120.0, 180.0]

var remaining_time: float = 0.0
var total_destroyed: int = 0
var total_score: int = 0
var is_active: bool = false

var elapsed_time: float = 0.0
var current_scale_level: int = 0
var _timer_paused: bool = false
var _pause_remaining: float = 0.0

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

## 독 칸 시간 가속 처리 (grid 참조 필요, GameManager에서 주입)
var _grid_ref = null

func set_grid(grid) -> void:
	_grid_ref = grid

func on_action_performed(destroyed_blocks: int, combo_level: int) -> void:
	if not is_active:
		return

	total_destroyed += destroyed_blocks

	if destroyed_blocks >= bonus_threshold:
		var bonus = _calculate_bonus_time(destroyed_blocks, combo_level)
		remaining_time = minf(remaining_time + bonus, max_time)
		bonus_time_added.emit(bonus, "destroy_%d_combo_%d" % [destroyed_blocks, combo_level])

	# 독 칸 시간 가속 처리
	if _grid_ref != null:
		_apply_poison_penalty()

func add_time(amount: float) -> void:
	## 시간 칸 등의 보너스 시간 추가.
	remaining_time = minf(remaining_time + amount, max_time)
	bonus_time_added.emit(amount, "gimmick_bonus")

func pause_timer(duration: float = -1.0) -> void:
	_timer_paused = true
	if duration > 0:
		_pause_remaining = duration

func resume_timer() -> void:
	_timer_paused = false
	_pause_remaining = 0.0

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

	# 시간정지(K11) 처리
	if _timer_paused:
		if _pause_remaining > 0:
			_pause_remaining -= delta
			if _pause_remaining <= 0:
				_timer_paused = false
				_pause_remaining = 0.0
		return

	elapsed_time += delta
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

func _apply_poison_penalty() -> void:
	## 독 칸 존재 시 액션당 추가 시간 차감.
	const BASE_TIME_COST: float = 0.5
	var poison_cells = _grid_ref.get_cells_with_gimmick(GimmickBase.GimmickType.POISON)
	if poison_cells.is_empty():
		return
	var extra_multiplier = 0.0
	for cell in poison_cells:
		extra_multiplier += cell.gimmick_data.get("speed_multiplier", 1.5) - 1.0
	var penalty = BASE_TIME_COST * extra_multiplier
	remaining_time = maxf(0.0, remaining_time - penalty)

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
