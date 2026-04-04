class_name StoryMode
extends Node

## 스토리 모드 규칙 관리.
## 턴 제한 + N블록 파괴 목표 + 별 시스템.

signal stage_cleared(stars: int, score: int, remaining_turns: int)
signal stage_failed()
signal turn_used(remaining: int)
signal blocks_destroyed(total: int, goal: int)

var remaining_turns: int = 0
var destroyed_count: int = 0
var goal_count: int = 0
var is_active: bool = false

var _star_thresholds: Array = []

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func initialize(stage_config) -> void:
	remaining_turns = stage_config.turn_limit
	goal_count = stage_config.goal_target_count
	destroyed_count = 0
	is_active = true
	_star_thresholds = stage_config.star_thresholds.duplicate()

func on_action_performed(destroyed_blocks: int, combo_level: int) -> void:
	if not is_active:
		return

	remaining_turns -= 1
	destroyed_count += destroyed_blocks

	turn_used.emit(remaining_turns)
	blocks_destroyed.emit(destroyed_count, goal_count)

	_check_clear_condition()
	if is_active:
		_check_fail_condition()

func get_progress() -> float:
	if goal_count <= 0:
		return 0.0
	return clampf(float(destroyed_count) / float(goal_count), 0.0, 1.0)

func reset() -> void:
	remaining_turns = 0
	destroyed_count = 0
	goal_count = 0
	is_active = false

# ─────────────────────────────────────────
# 내부 판정
# ─────────────────────────────────────────

func _check_clear_condition() -> void:
	if destroyed_count >= goal_count:
		is_active = false
		var stars = _calculate_stars(remaining_turns)
		stage_cleared.emit(stars, 0, remaining_turns)

func _check_fail_condition() -> void:
	if remaining_turns <= 0 and destroyed_count < goal_count:
		is_active = false
		stage_failed.emit()

func _calculate_stars(turns_left: int) -> int:
	## remaining_turns >= star_thresholds[i] 이면 해당 별 획득.
	## thresholds[0]=1성, [1]=2성, [2]=3성
	if _star_thresholds.size() < 3:
		return 0
	if turns_left >= _star_thresholds[2]:
		return 3
	if turns_left >= _star_thresholds[1]:
		return 2
	if turns_left >= _star_thresholds[0]:
		return 1
	return 0
