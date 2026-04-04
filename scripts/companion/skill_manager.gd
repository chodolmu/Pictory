class_name SkillManager
extends Node

## 이마젠 스킬 슬롯 관리, 쿨타임, 발동 중재.
## GameManager의 자식 노드로 배치.

signal skill_activated(skill_id: String)
signal skill_cooldown_updated(slot: int, remaining: int)
signal skill_ready(slot: int)
signal skill_requires_target(skill_id: String, target_type: int)
signal skill_result_ready(actions: Array)

enum TargetType {
	NONE,
	COLOR,
	COLOR_PAIR,
	CELL,
	ROW_OR_COL,
	CELL_AND_COLOR,
}

# 슬롯 구조: { imagen_id, skill_id, cooldown_max, cooldown_remaining, is_ready }
var skill_slots: Array[Dictionary] = []

# 게임 컨텍스트 참조 (GameManager에서 주입)
var _grid = null
var _color_queue = null
var _turn_manager = null
var _current_mode = null  # "story" | "infinity"
var _game_manager = null

var _is_activating: bool = false

# ─────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────

func setup_context(grid, color_queue, turn_manager, mode: String, gm) -> void:
	_grid = grid
	_color_queue = color_queue
	_turn_manager = turn_manager
	_current_mode = mode
	_game_manager = gm

func setup_party(imagenes: Array) -> void:
	skill_slots.clear()
	for img in imagenes:
		if img == null:
			continue
		skill_slots.append({
			"imagen_id": img.id,
			"skill_id": img.skill_id,
			"cooldown_max": img.cooldown,
			"cooldown_remaining": 0,
			"is_ready": true,
			"display_name": img.display_name,
			"attribute": img.attribute
		})

# ─────────────────────────────────────────
# 스킬 발동
# ─────────────────────────────────────────

func activate_skill(slot: int) -> bool:
	if slot < 0 or slot >= skill_slots.size():
		return false
	var s = skill_slots[slot]
	if not s.is_ready or _is_activating:
		return false

	var skill_id: String = s.skill_id
	var target_type = _get_target_type(skill_id)

	if target_type != TargetType.NONE:
		_is_activating = true
		skill_requires_target.emit(skill_id, target_type)
		return false  # 타겟 선택 후 execute_skill 호출 필요

	return _execute_skill(slot, null)

func execute_skill_with_target(slot: int, target) -> bool:
	_is_activating = false
	return _execute_skill(slot, target)

func cancel_skill() -> void:
	_is_activating = false

func _execute_skill(slot: int, target) -> bool:
	var s = skill_slots[slot]
	var skill_id: String = s.skill_id

	var context = {
		"grid": _grid,
		"color_queue": _color_queue,
		"turn_manager": _turn_manager,
		"mode": _current_mode,
		"game_manager": _game_manager
	}

	var skill = _create_skill(skill_id)
	if skill == null:
		push_error("SkillManager: 알 수 없는 스킬 ID: " + skill_id)
		return false

	if not skill.can_use(context):
		return false

	var result = skill.execute(context, target)
	if not result.get("success", false):
		return false

	# 쿨타임 설정
	s.cooldown_remaining = s.cooldown_max
	s.is_ready = false
	skill_slots[slot] = s
	skill_activated.emit(skill_id)
	skill_cooldown_updated.emit(slot, s.cooldown_remaining)

	# 그리드 액션 처리
	var actions = result.get("actions", [])
	if not actions.is_empty():
		skill_result_ready.emit(actions)

	return true

# ─────────────────────────────────────────
# 턴 종료 처리
# ─────────────────────────────────────────

func on_turn_end() -> void:
	for i in range(skill_slots.size()):
		var s = skill_slots[i]
		if s.cooldown_remaining > 0:
			s.cooldown_remaining -= 1
			skill_slots[i] = s
			skill_cooldown_updated.emit(i, s.cooldown_remaining)
			if s.cooldown_remaining == 0:
				s.is_ready = true
				skill_slots[i] = s
				skill_ready.emit(i)

# ─────────────────────────────────────────
# 조회
# ─────────────────────────────────────────

func is_skill_ready(slot: int) -> bool:
	if slot < 0 or slot >= skill_slots.size():
		return false
	return skill_slots[slot].is_ready

func get_slot_info(slot: int) -> Dictionary:
	if slot < 0 or slot >= skill_slots.size():
		return {}
	return skill_slots[slot].duplicate()

func get_slot_count() -> int:
	return skill_slots.size()

func is_activating() -> bool:
	return _is_activating

# ─────────────────────────────────────────
# 스킬 팩토리
# ─────────────────────────────────────────

func _get_target_type(skill_id: String) -> int:
	match skill_id:
		"K1": return TargetType.COLOR_PAIR
		"K2": return TargetType.CELL_AND_COLOR
		"K3": return TargetType.COLOR_PAIR
		"K4": return TargetType.COLOR
		"K5": return TargetType.ROW_OR_COL
		_:    return TargetType.NONE

func _create_skill(skill_id: String):
	match skill_id:
		"K1": return preload("res://scripts/companion/skills/skill_color_storm.gd").new()
		"K2": return preload("res://scripts/companion/skills/skill_rainbow_wave.gd").new()
		"K3": return preload("res://scripts/companion/skills/skill_color_swap.gd").new()
		"K4": return preload("res://scripts/companion/skills/skill_color_bomb.gd").new()
		"K5": return preload("res://scripts/companion/skills/skill_row_clear.gd").new()
		"K6": return preload("res://scripts/companion/skills/skill_undo.gd").new()
		"K7": return preload("res://scripts/companion/skills/skill_future_eye.gd").new()
		"K8": return preload("res://scripts/companion/skills/skill_shuffle.gd").new()
		"K9": return preload("res://scripts/companion/skills/skill_queue_flip.gd").new()
		"K10": return preload("res://scripts/companion/skills/skill_times_breath.gd").new()
		"K11": return preload("res://scripts/companion/skills/skill_time_stop.gd").new()
		_: return null
