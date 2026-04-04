class_name GameManager
extends Node2D

## 게임 전체 흐름을 조율하는 최상위 매니저.
## S02: recolor → row/col destroy → gravity 1-cycle 파이프라인.

const FloodFillScript = preload("res://scripts/core/flood_fill.gd")
const RowDestroyScript = preload("res://scripts/core/row_destroy.gd")
const GravityScript = preload("res://scripts/core/gravity.gd")
## S03: chain combo + ColorQueue 연결 예정.

@export var grid_size: int = 7
@export var num_colors: int = 5

@onready var _grid_view: GridView = $GridView

var _grid: Grid
var _processing: bool = false
var _temp_color_index: int = 0  # S03에서 ColorQueue로 교체

func _ready() -> void:
	_grid = Grid.new()
	_grid.init_grid(grid_size, num_colors)
	_grid_view.setup(_grid)
	_grid_view.cell_touched.connect(_on_cell_touched)

# ─────────────────────────────────────────
# 입력 처리
# ─────────────────────────────────────────

func _on_cell_touched(x: int, y: int) -> void:
	if _processing:
		return

	var cell = _grid.get_cell(x, y)
	if cell == null or cell.color == -1:
		return

	var active_color = _get_next_color()

	# Same-color guard
	if cell.color == active_color:
		print("Same color — no action")
		return

	_processing = true
	_grid_view.lock_input()

	# 1. BFS recolor
	var group = FloodFillScript.flood_fill(_grid, x, y)
	for c in group:
		_grid.set_cell_color(c.x, c.y, active_color)
	print("Recolor group size: ", group.size())

	_grid_view.refresh()

	# 2. Destroy + Gravity 1-cycle
	_do_destroy_gravity_cycle()

	_processing = false
	_grid_view.unlock_input()

# ─────────────────────────────────────────
# 코어 파이프라인
# ─────────────────────────────────────────

func _do_destroy_gravity_cycle() -> void:
	var destroy_set = RowDestroyScript.check_all(_grid)

	if destroy_set.size() == 0:
		print("No completed lines")
		return

	print("Completed lines found — destroying ", destroy_set.size(), " cells")

	# 파괴 (color → -1)
	for cell in destroy_set:
		_grid.set_cell_color(cell.x, cell.y, -1)

	_grid_view.refresh()

	# Gravity
	GravityScript.apply(_grid)

	_grid_view.refresh()
	print("Cycle complete")

# ─────────────────────────────────────────
# 임시 색상 (S03에서 ColorQueue로 교체)
# ─────────────────────────────────────────

func _get_next_color() -> int:
	_temp_color_index = (_temp_color_index + 1) % _grid.num_colors
	return _temp_color_index

# ─────────────────────────────────────────
# 디버그 헬퍼
# ─────────────────────────────────────────

func _debug_set_row(y: int, color: int) -> void:
	for x in range(_grid.grid_size):
		_grid.set_cell_color(x, y, color)
	# 마지막 셀만 다른 색 (완성 직전 상태)
	_grid.set_cell_color(_grid.grid_size - 1, y, (color + 1) % _grid.num_colors)
	_grid_view.refresh()
