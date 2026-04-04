class_name GameManager
extends Node2D

## S04: 모드 위임 구조 통합.
## StoryMode / InfinityMode를 Strategy 패턴으로 교체.
## touch → same-color guard → recolor(BFS+queue) → chain combo → Economy → mode.on_action_performed()

const FloodFill = preload("res://scripts/core/flood_fill.gd")
const ColorQueueScript = preload("res://scripts/core/color_queue.gd")
const TurnManagerScript = preload("res://scripts/core/turn_manager.gd")
const ChainComboScript = preload("res://scripts/core/chain_combo.gd")
const StageConfigScript = preload("res://scripts/data/stage_config.gd")
const StoryModeScript = preload("res://scripts/modes/story_mode.gd")
const InfinityModeScript = preload("res://scripts/modes/infinity_mode.gd")
const GimmickRegistryScript = preload("res://scripts/gimmick/gimmick_registry.gd")
const SkillManagerScript = preload("res://scripts/companion/skill_manager.gd")
const SkillHUDScene = preload("res://scenes/ui/skill_hud.tscn")

signal game_cleared
signal game_over

# 기본 실행 설정 (씬 Inspector 또는 start_story/start_infinity로 오버라이드)
@export var mode: String = "story"
@export var grid_size: int = 7
@export var num_colors: int = 5
@export var max_turns: int = 30
@export var goal: int = 100
@export var time_limit: float = 60.0

# Core systems
var _grid: Grid
var _color_queue: Object
var _turn_manager: Object

# Mode (Strategy)
var _current_mode: Node = null

# Skill system
var _skill_manager: SkillManager = null
var _skill_hud: SkillHUD = null
var _is_target_selecting: bool = false
var _target_skill_slot: int = -1

# 스냅샷 시스템 (K6 되감기)
var _board_snapshots: Array[Dictionary] = []
const MAX_SNAPSHOTS := 10

# UI
@onready var _grid_view: GridView = $GridView
@onready var _color_queue_ui = $HUD/BottomBar/ColorQueueUI
@onready var _hud = $HUD

# State
var _total_destroyed: int = 0
var _processing: bool = false
var _game_ended: bool = false

var _flow_controlled: bool = false
var _stage_stars: int = 0

func _ready() -> void:
	var params = SceneManager.get_params()
	if not params.is_empty():
		_flow_controlled = params.get("flow_controlled", false)
		var stage_id = params.get("stage_id", "")
		if stage_id != "" and params.get("mode", "story") == "story":
			var config = LevelLoader.load_stage(stage_id)
			if config != null:
				start_story(config)
				return
	if mode == "story":
		_start_story_default()
	else:
		start_infinity()

# ─────────────────────────────────────────
# 공개 시작 API
# ─────────────────────────────────────────

func start_story(config) -> void:
	_cleanup_mode()
	grid_size = config.grid_size
	num_colors = config.num_colors
	max_turns = config.turn_limit
	goal = config.goal_target_count

	_initialize_core(grid_size, num_colors)
	_color_queue.stride_length = config.color_queue_stride
	_color_queue.offset_range = config.color_queue_random_offset

	# 기믹 배치
	if config.gimmick_placements.size() > 0:
		LevelLoader.apply_gimmicks_to_grid(config, _grid)

	var story = StoryModeScript.new()
	story.name = "StoryMode"
	add_child(story)
	story.initialize(config)
	story.stage_cleared.connect(_on_stage_cleared)
	story.stage_failed.connect(_on_stage_failed)
	_current_mode = story

	_hud.setup("story", config.stage_number, config.goal_target_count, config.turn_limit)
	_finish_init()

func start_infinity() -> void:
	_cleanup_mode()
	_initialize_core(grid_size, num_colors)

	var inf = InfinityModeScript.new()
	inf.name = "InfinityMode"
	inf.initial_time = time_limit
	add_child(inf)
	inf.initialize()
	inf.time_updated.connect(_on_time_updated)
	inf.game_over.connect(_on_infinity_game_over)
	_current_mode = inf
	# 독 칸 시간 가속을 위해 grid 참조 주입
	inf.set_grid(_grid)

	_hud.setup("infinity", 0, 0, 0)
	_hud.setup_infinity_timer(time_limit)
	_finish_init()

# ─────────────────────────────────────────
# 내부 초기화
# ─────────────────────────────────────────

func _start_story_default() -> void:
	## Inspector export 값으로 기본 스토리 모드 시작 (LevelLoader 없이 디버그용)
	var config = StageConfigScript.new()
	config.grid_size = grid_size
	config.num_colors = num_colors
	config.turn_limit = max_turns
	config.goal_target_count = goal
	config.star_thresholds = [3, 6, 10]
	config.color_queue_stride = 3
	config.color_queue_random_offset = 1
	start_story(config)

func _cleanup_mode() -> void:
	if _current_mode != null:
		_current_mode.queue_free()
		_current_mode = null

func _initialize_core(gs: int, nc: int) -> void:
	_total_destroyed = 0
	_game_ended = false

	_grid = Grid.new()
	_grid.init_grid(gs, nc)

	_color_queue = ColorQueueScript.new()
	_color_queue.num_colors = nc

	_turn_manager = TurnManagerScript.new()
	_turn_manager.mode = "story"
	_turn_manager.max_turns = max_turns

func _finish_init() -> void:
	_grid_view.setup(_grid)
	_color_queue_ui.setup(_color_queue)
	if _grid_view.cell_touched.is_connected(_on_cell_touched):
		_grid_view.cell_touched.disconnect(_on_cell_touched)
	_grid_view.cell_touched.connect(_on_cell_touched)
	_init_skill_system()

func _init_skill_system() -> void:
	# 기존 SkillManager 정리
	if _skill_manager != null:
		_skill_manager.queue_free()
		_skill_manager = null
	if _skill_hud != null:
		_skill_hud.queue_free()
		_skill_hud = null

	var party = PartyManager.get_party()
	if party.is_empty():
		return

	_skill_manager = SkillManagerScript.new()
	_skill_manager.name = "SkillManager"
	add_child(_skill_manager)
	_skill_manager.setup_context(_grid, _color_queue, _turn_manager, mode, self)
	_skill_manager.setup_party(party)
	_skill_manager.skill_result_ready.connect(_on_skill_result_ready)
	_skill_manager.skill_requires_target.connect(_on_skill_requires_target)

	_skill_hud = SkillHUDScene.instantiate()
	_hud.add_child(_skill_hud)
	_skill_hud.anchor_left = 0.0
	_skill_hud.anchor_right = 1.0
	_skill_hud.anchor_top = 1.0
	_skill_hud.anchor_bottom = 1.0
	_skill_hud.offset_left = 0.0
	_skill_hud.offset_top = -180.0
	_skill_hud.offset_right = 0.0
	_skill_hud.offset_bottom = -108.0
	_skill_hud.setup(_skill_manager)
	_skill_hud.skill_button_pressed.connect(_on_skill_button_pressed)

# ─────────────────────────────────────────
# 입력 처리
# ─────────────────────────────────────────

func _on_cell_touched(x: int, y: int) -> void:
	if _processing or _game_ended or _current_mode == null:
		return
	if _is_target_selecting:
		# 타겟 선택 모드: K2 셀 선택 처리
		if _skill_manager and _target_skill_slot >= 0:
			var info = _skill_manager.get_slot_info(_target_skill_slot)
			var skill_id = info.get("skill_id", "")
			if skill_id == "K2":
				# 다음 단계: 색상 선택 (여기서는 간단히 active_color 사용)
				var target = { "cx": x, "cy": y, "color": _color_queue.get_active_color() }
				_skill_manager.execute_skill_with_target(_target_skill_slot, target)
				_is_target_selecting = false
				_target_skill_slot = -1
		return
	if _skill_manager and _skill_manager.is_activating():
		return

	var cell = _grid.get_cell(x, y)
	if cell == null or cell.color == -1:
		return

	var active_color = _color_queue.get_active_color()

	if cell.color == active_color:
		print("Same color — no action")
		return

	_processing = true
	_grid_view.lock_input()

	# 1. BFS Recolor (on_recolor 훅 포함 — 페인트통/무지개/퇴색 대응)
	var group = FloodFill.flood_fill(_grid, x, y)
	FloodFill.recolor_group(_grid, group, active_color)
	print("Recolor group size: ", group.size())
	_grid_view.refresh()

	# 2. ColorQueue advance
	_color_queue.advance()
	_color_queue_ui.refresh()

	# 3. Chain Combo
	var result = ChainComboScript.execute(_grid)
	var effective = result.effective_destroyed if result.effective_destroyed > 0 else result.total_destroyed
	_total_destroyed += effective

	# 4. Economy — 기믹 보상 처리
	Economy.add_score(effective, result.chain_count)
	if not result.collected_rewards.is_empty():
		Economy.add_rewards(result.collected_rewards)
	# 기믹 효과 처리 (별/시간 등)
	_apply_gimmick_effects(result.collected_effects)

	# 5. HUD 갱신
	_hud.update_destroyed(effective)
	if result.chain_count > 1:
		_hud.show_chain(result.chain_count)
	_grid_view.refresh()

	# 6. 모드에 위임
	_current_mode.on_action_performed(effective, result.chain_count)

	# 7. 스냅샷 저장 (K6 되감기용)
	save_snapshot()

	# 8. 턴 종료 처리 (번짐/퇴색 on_turn, 퇴색 후 라인 재판정)
	_on_turn_end()

	# 9. 스킬 쿨타임 감소
	if _skill_manager:
		_skill_manager.on_turn_end()

	_processing = false
	if not _game_ended:
		_grid_view.unlock_input()

# ─────────────────────────────────────────
# 모드 시그널 핸들러
# ─────────────────────────────────────────

func _on_turn_end() -> void:
	## 턴 종료: on_turn() 호출 (번짐 감염, 퇴색 카운터). 상태 변경 후 라인 재판정.
	var turn_number = _turn_manager.turns_used
	var state_changed = false

	for cell in _grid.get_all_main_cells():
		if cell.has_gimmick():
			# grid 참조 주입 (번짐/퇴색용)
			cell.gimmick_data["_grid_ref"] = _grid
			var handler = GimmickRegistry.get_handler(cell.gimmick_type)
			handler.on_turn(cell, turn_number)
			state_changed = true

	if state_changed:
		# 퇴색 색 복귀 등으로 라인이 완성될 수 있으므로 연쇄 재실행
		var post_result = ChainComboScript.execute(_grid)
		if post_result.total_destroyed > 0:
			var eff = post_result.effective_destroyed if post_result.effective_destroyed > 0 else post_result.total_destroyed
			_total_destroyed += eff
			Economy.add_score(eff, post_result.chain_count)
			if not post_result.collected_rewards.is_empty():
				Economy.add_rewards(post_result.collected_rewards)
			_apply_gimmick_effects(post_result.collected_effects)
			_hud.update_destroyed(eff)
			_grid_view.refresh()

func _apply_gimmick_effects(effects: Array) -> void:
	## 기믹 파괴 효과 적용 (별/시간/연쇄배율 등).
	for effect in effects:
		match effect.get("type", ""):
			"bonus_turn":
				# 스토리 모드에서만 의미 있음
				if _current_mode is StoryModeScript:
					_turn_manager.add_turns(effect.get("value", 1))
			"bonus_time":
				# 무한 모드에서만 의미 있음
				if _current_mode is InfinityModeScript:
					_current_mode.add_time(effect.get("value", 5.0))
			"multiply_count":
				pass  # chain_combo에서 이미 처리됨
			_:
				pass

# ─────────────────────────────────────────
# 스냅샷 시스템 (K6 되감기)
# ─────────────────────────────────────────

func save_snapshot() -> void:
	var snapshot = {
		"grid_colors": _serialize_grid(),
		"queue_state": _color_queue.peek_all().duplicate(),
		"destroyed_count": _total_destroyed
	}
	# 스토리 모드: turns_remaining 포함
	if _current_mode is StoryModeScript:
		snapshot["turns_remaining"] = _current_mode.remaining_turns
		snapshot["destroyed_story"] = _current_mode.destroyed_count

	_board_snapshots.push_back(snapshot)
	if _board_snapshots.size() > MAX_SNAPSHOTS:
		_board_snapshots.pop_front()

func restore_snapshot() -> bool:
	if _board_snapshots.is_empty():
		return false
	var snap = _board_snapshots.pop_back()
	_deserialize_grid(snap.get("grid_colors", {}))
	# 큐 복원
	var q_state = snap.get("queue_state", [])
	if not q_state.is_empty():
		_color_queue._queue = q_state.duplicate()
	# 파괴 카운트 복원
	_total_destroyed = snap.get("destroyed_count", _total_destroyed)
	if _current_mode is StoryModeScript:
		_current_mode.remaining_turns = snap.get("turns_remaining", _current_mode.remaining_turns)
		_current_mode.destroyed_count = snap.get("destroyed_story", _current_mode.destroyed_count)
	_grid_view.refresh()
	_color_queue_ui.refresh()
	return true

func has_snapshot() -> bool:
	return not _board_snapshots.is_empty()

func _serialize_grid() -> Dictionary:
	var data: Dictionary = {}
	for y in range(_grid.grid_size):
		for x in range(_grid.grid_size):
			var cell = _grid.get_cell(x, y)
			if cell:
				data[Vector2i(x, y)] = cell.color
	return data

func _deserialize_grid(data: Dictionary) -> void:
	for pos in data:
		_grid.set_cell_color(pos.x, pos.y, data[pos])

# ─────────────────────────────────────────
# 스킬 시그널 핸들러
# ─────────────────────────────────────────

func _on_skill_button_pressed(slot: int) -> void:
	var info = _skill_manager.get_slot_info(slot)
	var skill_id = info.get("skill_id", "")
	var target_type = _skill_manager._get_target_type(skill_id)

	if target_type == SkillManager.TargetType.NONE:
		_skill_manager.activate_skill(slot)
		_apply_skill_aftermath()
	elif target_type == SkillManager.TargetType.CELL_AND_COLOR:
		_is_target_selecting = true
		_target_skill_slot = slot
	elif target_type == SkillManager.TargetType.COLOR or target_type == SkillManager.TargetType.COLOR_PAIR:
		# 색상 선택은 색상 팔레트 팝업 (간단 구현: active_color 자동 사용)
		# 실제 타겟 선택 UI는 SkillHUD에서 처리하나, 여기서는 fallback
		_skill_manager.activate_skill(slot)
		_apply_skill_aftermath()
	elif target_type == SkillManager.TargetType.ROW_OR_COL:
		# 행/열 선택 — 중앙 행을 기본으로
		var target = { "is_row": true, "index": _grid.grid_size / 2 }
		_skill_manager.execute_skill_with_target(slot, target)
		_apply_skill_aftermath()

func _on_skill_requires_target(skill_id: String, target_type: int) -> void:
	# 기본 처리: K1/K3/K4는 색상 팔레트 필요하지만 여기서는 간단히 처리
	# 실제 팔레트 UI는 추후 확장
	pass

func _on_skill_result_ready(actions: Array) -> void:
	for action in actions:
		match action.get("type", ""):
			"destroy_done":
				var count = action.get("count", 0)
				if count > 0:
					_total_destroyed += count
					_current_mode.on_action_performed(count, 0)
					Gravity.apply(_grid)
					var result = ChainComboScript.execute(_grid)
					_total_destroyed += result.total_destroyed
					_hud.update_destroyed(count + result.total_destroyed)
					_grid_view.refresh()
					_color_queue_ui.refresh()
			"undo_done":
				_hud.update_destroyed(0)
				_grid_view.refresh()
				_color_queue_ui.refresh()
			_:
				_grid_view.refresh()
				_color_queue_ui.refresh()

func _apply_skill_aftermath() -> void:
	## 스킬 실행 후 라인 재판정 + 렌더링
	var result = ChainComboScript.execute(_grid)
	if result.total_destroyed > 0:
		var eff = result.effective_destroyed if result.effective_destroyed > 0 else result.total_destroyed
		_total_destroyed += eff
		_current_mode.on_action_performed(eff, result.chain_count)
		_hud.update_destroyed(eff)
	_grid_view.refresh()
	_color_queue_ui.refresh()

func _on_stage_cleared(stars: int, score: int, remaining_turns: int) -> void:
	_game_ended = true
	_stage_stars = stars
	_grid_view.lock_input()

	# 세이브 + 재화 계산
	var params = SceneManager.get_params()
	var stage_id = params.get("stage_id", "")
	var is_first_clear = true
	if stage_id != "":
		is_first_clear = not SaveManager.is_stage_cleared(stage_id)
		SaveManager.save_stage_result(stage_id, stars, Economy.current_score)
	var currency = CurrencyConverter.calculate_story_reward(stars, is_first_clear)
	SaveManager.add_currency(currency)
	print("Stage Clear! Stars: %d, Score: %d, Currency: +%d" % [stars, Economy.current_score, currency])

	if _flow_controlled:
		var result = {
			"is_clear": true,
			"stars": stars,
			"score": Economy.current_score,
			"currency": currency,
			"destroyed": _total_destroyed,
			"stage_id": stage_id
		}
		StoryFlowController.on_game_finished(result)
	else:
		game_cleared.emit()

func _on_stage_failed() -> void:
	_game_ended = true
	_grid_view.lock_input()
	print("Game Over (story)")

	if _flow_controlled:
		var params = SceneManager.get_params()
		var stage_id = params.get("stage_id", "")
		var result = {
			"is_clear": false,
			"stars": 0,
			"score": Economy.current_score,
			"destroyed": _total_destroyed,
			"stage_id": stage_id
		}
		StoryFlowController.on_game_finished(result)
	else:
		game_over.emit()

func _on_time_updated(remaining: float, _max: float) -> void:
	_hud.update_timer(remaining)

func _on_infinity_game_over(final_score: int, total_dest: int) -> void:
	_game_ended = true
	_grid_view.lock_input()
	var is_new_record = SaveManager.save_infinity_result(final_score)
	var currency = CurrencyConverter.calculate_infinity_reward(final_score, is_new_record)
	SaveManager.add_currency(currency)
	print("Game Over (infinity) Score: %d, Destroyed: %d, Currency: +%d" % [final_score, total_dest, currency])
	game_over.emit()
