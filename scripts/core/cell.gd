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
var gimmick_type: int = -1  # reserved for future gimmick system (-1 = none)
var gimmick_hp: int = 0     # gimmick durability (e.g. ice needs 2 hits)

func _init(p_x: int = 0, p_y: int = 0, p_color: int = -1, p_active: bool = true) -> void:
	x = p_x
	y = p_y
	color = p_color
	active = p_active

func duplicate() -> Cell:
	var c = Cell.new(x, y, color, active)
	c.gimmick_type = gimmick_type
	c.gimmick_hp = gimmick_hp
	return c

func equals(other: Cell) -> bool:
	return x == other.x and y == other.y and color == other.color

func to_string() -> String:
	return "Cell(%d,%d) color=%d active=%s gimmick=%d" % [x, y, color, active, gimmick_type]
