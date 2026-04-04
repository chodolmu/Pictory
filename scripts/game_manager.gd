class_name GameManager
extends Node2D

## 게임 전체 흐름을 조율하는 최상위 매니저.
## S01: GridView 초기화 + 터치 좌표 로그 출력만 담당.
## S02 이후: BFS 리컬러 → 라인 파괴 → 중력 → 연쇄 파이프라인 연결.

@export var grid_size: int = 7
@export var num_colors: int = 5

@onready var _grid_view: GridView = $GridView

var _grid: Grid

func _ready() -> void:
	_grid = Grid.new()
	_grid.init_grid(grid_size, num_colors)
	_grid_view.setup(_grid)
	_grid_view.cell_touched.connect(_on_cell_touched)

func _on_cell_touched(x: int, y: int) -> void:
	print("Touched: ", x, ", ", y)
	# S02에서 BFS 리컬러 로직 연결 예정
