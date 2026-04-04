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

# UI
@onready var _grid_view: GridView = $GridView
@onready var _color_queue_ui = $ColorQueueUI
@onready var _hud = $HUD

# State
var _total_destroyed: int = 0
var _processing: bool = false
var _game_ended: bool = false

func _ready() -> void:
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

# ─────────────────────────────────────────
# 입력 처리
# ─────────────────────────────────────────

func _on_cell_touched(x: int, y: int) -> void:
	if _processing or _game_ended or _current_mode == null:
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

	# 7. 턴 종료 처리 (번짐/퇴색 on_turn, 퇴색 후 라인 재판정)
	_on_turn_end()

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

func _on_stage_cleared(stars: int, score: int, remaining_turns: int) -> void:
	_game_ended = true
	_grid_view.lock_input()
	var currency = Economy.finalize_and_earn_currency()
	print("Stage Clear! Stars: %d, Score: %d, Currency: +%d" % [stars, Economy.current_score, currency])
	game_cleared.emit()

func _on_stage_failed() -> void:
	_game_ended = true
	_grid_view.lock_input()
	print("Game Over (story)")
	game_over.emit()

func _on_time_updated(remaining: float, _max: float) -> void:
	_hud.update_timer(remaining)

func _on_infinity_game_over(final_score: int, total_dest: int) -> void:
	_game_ended = true
	_grid_view.lock_input()
	print("Game Over (infinity) Score: %d, Destroyed: %d" % [final_score, total_dest])
	game_over.emit()
