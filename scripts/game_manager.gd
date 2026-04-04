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

	# 1. BFS Recolor
	var group = FloodFill.flood_fill(_grid, x, y)
	for c in group:
		_grid.set_cell_color(c.x, c.y, active_color)
	print("Recolor group size: ", group.size())
	_grid_view.refresh()

	# 2. ColorQueue advance
	_color_queue.advance()
	_color_queue_ui.refresh()

	# 3. Chain Combo
	var result = ChainComboScript.execute(_grid)
	_total_destroyed += result.total_destroyed

	# 4. Economy
	Economy.add_score(result.total_destroyed, result.chain_count)

	# 5. HUD 갱신
	_hud.update_destroyed(result.total_destroyed)
	if result.chain_count > 1:
		_hud.show_chain(result.chain_count)
	_grid_view.refresh()

	# 6. 모드에 위임
	_current_mode.on_action_performed(result.total_destroyed, result.chain_count)

	_processing = false
	if not _game_ended:
		_grid_view.unlock_input()

# ─────────────────────────────────────────
# 모드 시그널 핸들러
# ─────────────────────────────────────────

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
