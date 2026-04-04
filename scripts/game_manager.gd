class_name GameManager
extends Node2D

## S03: 전체 게임 루프 통합.
## touch → same-color guard → use_turn → recolor(BFS+queue) → chain combo → HUD → clear/gameover

const FloodFill = preload("res://scripts/core/flood_fill.gd")
const ColorQueueScript = preload("res://scripts/core/color_queue.gd")
const TurnManagerScript = preload("res://scripts/core/turn_manager.gd")
const ChainComboScript = preload("res://scripts/core/chain_combo.gd")

signal game_cleared
signal game_over

@export var mode: String = "story"
@export var grid_size: int = 7
@export var num_colors: int = 5
@export var max_turns: int = 30
@export var goal: int = 100
@export var time_limit: float = 120.0

# Core systems
var _grid: Grid
var _color_queue: Object
var _turn_manager: Object

# UI
@onready var _grid_view: GridView = $GridView
@onready var _color_queue_ui = $ColorQueueUI
@onready var _hud = $HUD

# State
var _total_destroyed: int = 0
var _processing: bool = false
var _game_ended: bool = false

# Infinity mode timer
var _time_remaining: float = 0.0

func _ready() -> void:
	_initialize_game()

func _process(delta: float) -> void:
	if mode == "infinity" and not _game_ended:
		_time_remaining -= delta
		if _time_remaining <= 0.0:
			_time_remaining = 0.0
			_hud.update_timer(_time_remaining)
			if not _processing:
				_show_result("Game Over")
				game_over.emit()
		else:
			_hud.update_timer(_time_remaining)

# ─────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────

func _initialize_game() -> void:
	_total_destroyed = 0
	_game_ended = false

	# Grid
	_grid = Grid.new()
	_grid.init_grid(grid_size, num_colors)

	# ColorQueue
	_color_queue = ColorQueueScript.new()
	_color_queue.num_colors = num_colors

	# TurnManager
	_turn_manager = TurnManagerScript.new()
	_turn_manager.mode = mode
	_turn_manager.max_turns = max_turns

	# UI setup
	_grid_view.setup(_grid)
	_color_queue_ui.setup(_color_queue)
	_hud.setup(mode, 1, goal, max_turns)

	if mode == "infinity":
		_time_remaining = time_limit
		_hud.setup_infinity_timer(time_limit)

	# Signal connections
	_grid_view.cell_touched.connect(_on_cell_touched)
	_turn_manager.turn_changed.connect(_hud.update_turns)

# ─────────────────────────────────────────
# 입력 처리
# ─────────────────────────────────────────

func _on_cell_touched(x: int, y: int) -> void:
	if _processing or _game_ended:
		return

	var cell = _grid.get_cell(x, y)
	if cell == null or cell.color == -1:
		return

	var active_color = _color_queue.get_active_color()

	# Same-color guard
	if cell.color == active_color:
		print("Same color — no action")
		return

	# === 유효한 액션 시작 ===
	_processing = true
	_grid_view.lock_input()

	# 1. Turn
	_turn_manager.use_turn()

	# 2. BFS Recolor
	var group = FloodFill.flood_fill(_grid, x, y)
	for c in group:
		_grid.set_cell_color(c.x, c.y, active_color)
	print("Recolor group size: ", group.size())
	_grid_view.refresh()

	# 3. ColorQueue advance
	_color_queue.advance()
	_color_queue_ui.refresh()

	# 4. Chain Combo
	var result = ChainComboScript.execute(_grid)
	_total_destroyed += result.total_destroyed

	# 5. HUD 갱신
	_hud.update_destroyed(result.total_destroyed)
	if result.chain_count > 1:
		_hud.show_chain(result.chain_count)
	_grid_view.refresh()

	# 6. Clear/GameOver 판정
	_check_game_state()

	_processing = false
	if not _game_ended:
		_grid_view.unlock_input()

# ─────────────────────────────────────────
# 게임 상태 판정 (T7)
# ─────────────────────────────────────────

func _check_game_state() -> void:
	if mode == "story":
		if _total_destroyed >= goal:
			_show_result("Stage Clear!")
			game_cleared.emit()
		elif _turn_manager.turns_remaining <= 0:
			_show_result("Game Over")
			game_over.emit()
	# infinity mode: _process에서 타이머 체크

func _show_result(text: String) -> void:
	_game_ended = true
	_grid_view.lock_input()

	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 스타일
	var settings = LabelSettings.new()
	settings.font_size = 48
	settings.font_color = Color.WHITE
	settings.shadow_color = Color(0.0, 0.0, 0.0, 0.8)
	settings.shadow_size = 4
	label.label_settings = settings

	# 화면 중앙 배치
	var vp_size = get_viewport_rect().size
	label.position = Vector2(0.0, 0.0)
	label.size = vp_size
	label.z_index = 100

	add_child(label)
	print("Game result: ", text)
