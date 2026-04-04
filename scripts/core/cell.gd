class_name Cell
extends RefCounted

## Grid의 개별 셀을 표현하는 순수 데이터 클래스.
## 렌더링 로직 없이 데이터만 보유한다.
##
## 좌표 규약:
##   y >= 0  : main grid 영역 (y=0이 맨 위, y=grid_size-1이 맨 아래)
##   y < 0   : buffer 영역 (y=-1이 buffer 최하단, y=-grid_size가 buffer 최상단)

var x: int          # column index (0-based, left to right)
var y: int          # row index (0 = main grid top, negative = buffer)
var color: int      # color index (0 ~ num_colors-1), -1 = empty
var active: bool    # true = main grid area
var gimmick_type: int = 0         # GimmickBase.GimmickType enum (0 = NONE)
var gimmick_state: int = 0        # 기믹별 내부 상태 (예: 얼음 crack=1)
var gimmick_durability: int = 0   # 내구도 (예: 얼음=2)
var gimmick_data: Dictionary = {} # 기믹별 추가 데이터

func _init(p_x: int = 0, p_y: int = 0, p_color: int = -1, p_active: bool = true) -> void:
	x = p_x
	y = p_y
	color = p_color
	active = p_active

func duplicate() -> Cell:
	var c = Cell.new(x, y, color, active)
	c.gimmick_type = gimmick_type
	c.gimmick_state = gimmick_state
	c.gimmick_durability = gimmick_durability
	c.gimmick_data = gimmick_data.duplicate()
	return c

func equals(other: Cell) -> bool:
	return x == other.x and y == other.y and color == other.color

func has_gimmick() -> bool:
	return gimmick_type != 0  # 0 = GimmickType.NONE

func set_gimmick(type: int, durability: int = 0, data: Dictionary = {}) -> void:
	gimmick_type = type
	gimmick_durability = durability
	gimmick_state = 0
	gimmick_data = data

func clear_gimmick() -> void:
	gimmick_type = 0
	gimmick_state = 0
	gimmick_durability = 0
	gimmick_data = {}

func debug_string() -> String:
	return "Cell(%d,%d) color=%d active=%s gimmick=%d" % [x, y, color, active, gimmick_type]
