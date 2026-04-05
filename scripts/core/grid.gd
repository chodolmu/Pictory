class_name Grid
extends RefCounted

## N x N main grid + N-row buffer 데이터 모델.
## 내부 저장: Dictionary Vector2i(x,y) -> Cell
## y >= 0  : main grid
## y < 0   : buffer

var grid_size: int = 7
var num_colors: int = 5

var _cells: Dictionary = {}  # Vector2i(x, y) -> Cell

# ─────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────

func init_grid(p_size: int = 7, p_colors: int = 5) -> void:
	if p_size < 3:
		push_warning("grid_size < 3, gameplay may be broken")
	if p_colors < 2:
		push_error("num_colors < 2: cannot prevent completed lines")
		return

	grid_size = p_size
	num_colors = p_colors
	_cells.clear()

	# buffer 영역: y = -grid_size ~ -1
	for brow in range(grid_size):
		var y = -(grid_size - brow)  # -grid_size .. -1
		for x in range(grid_size):
			var c = Cell.new(x, y, randi() % num_colors, false)
			_cells[Vector2i(x, y)] = c

	# main grid 영역: y = 0 ~ grid_size-1
	for y in range(grid_size):
		for x in range(grid_size):
			var c = Cell.new(x, y, randi() % num_colors, true)
			_cells[Vector2i(x, y)] = c

	_ensure_all_colors_present()
	ensure_no_completed_lines()

# ─────────────────────────────────────────
# 셀 접근 (CRUD)
# ─────────────────────────────────────────

func get_cell(x: int, y: int) -> Cell:
	if not is_valid_coord(x, y):
		return null
	return _cells.get(Vector2i(x, y), null)

func set_cell_color(x: int, y: int, color: int) -> void:
	var cell = get_cell(x, y)
	if cell:
		cell.color = color

func is_valid_coord(x: int, y: int) -> bool:
	if x < 0 or x >= grid_size:
		return false
	if y < -grid_size or y >= grid_size:
		return false
	return true

func is_main_area(x: int, y: int) -> bool:
	return x >= 0 and x < grid_size and y >= 0 and y < grid_size

func get_row(y: int) -> Array:
	var row: Array = []
	for x in range(grid_size):
		var cell = get_cell(x, y)
		if cell:
			row.append(cell)
	return row

func get_column(x: int) -> Array:
	## main area 셀만 반환
	var col: Array = []
	for y in range(grid_size):
		var cell = get_cell(x, y)
		if cell:
			col.append(cell)
	return col

func get_all_main_cells() -> Array:
	var result: Array = []
	for y in range(grid_size):
		for x in range(grid_size):
			var cell = get_cell(x, y)
			if cell:
				result.append(cell)
	return result

func get_cells_with_gimmick(gimmick_type: int) -> Array:
	## 특정 기믹 타입을 가진 main area 셀 목록 반환.
	var result: Array = []
	for y in range(grid_size):
		for x in range(grid_size):
			var cell = get_cell(x, y)
			if cell and cell.gimmick_type == gimmick_type:
				result.append(cell)
	return result

func count_gimmick(gimmick_type: int) -> int:
	return get_cells_with_gimmick(gimmick_type).size()

# ─────────────────────────────────────────
# 완성 라인 방지
# ─────────────────────────────────────────

func _ensure_all_colors_present() -> void:
	## main grid에 모든 색상이 최소 1개씩 존재하도록 보장.
	var present: Array[bool] = []
	present.resize(num_colors)
	present.fill(false)

	for y in range(grid_size):
		for x in range(grid_size):
			var cell = get_cell(x, y)
			if cell and cell.color >= 0 and cell.color < num_colors:
				present[cell.color] = true

	var missing: Array[int] = []
	for c in range(num_colors):
		if not present[c]:
			missing.append(c)

	if missing.is_empty():
		return

	# 누락된 색상을 랜덤 위치의 셀에 배치 (중복 방지)
	var positions: Array[Vector2i] = []
	for y in range(grid_size):
		for x in range(grid_size):
			positions.append(Vector2i(x, y))
	positions.shuffle()

	for i in range(missing.size()):
		if i < positions.size():
			set_cell_color(positions[i].x, positions[i].y, missing[i])

func ensure_no_completed_lines() -> void:
	var max_iterations = 100
	var iterations = 0

	while iterations < max_iterations:
		var found = false

		# row 검사 (main area)
		for y in range(grid_size):
			if _is_row_completed(y):
				_break_line_row(y)
				found = true

		# column 검사 (main area)
		for x in range(grid_size):
			if _is_col_completed(x):
				_break_line_col(x)
				found = true

		if not found:
			break
		iterations += 1

	if iterations >= max_iterations:
		push_warning("ensure_no_completed_lines: max iterations reached")

func _is_row_completed(y: int) -> bool:
	if not is_main_area(0, y):
		return false
	var first_color = get_cell(0, y).color
	if first_color == -1:
		return false
	for x in range(1, grid_size):
		var cell = get_cell(x, y)
		if not cell or cell.color != first_color:
			return false
	return true

func _is_col_completed(x: int) -> bool:
	var first_color = get_cell(x, 0).color
	if first_color == -1:
		return false
	for y in range(1, grid_size):
		var cell = get_cell(x, y)
		if not cell or cell.color != first_color:
			return false
	return true

func _break_line_row(y: int) -> void:
	## row의 랜덤 셀 1개를 다른 색으로 변경
	var rx = randi() % grid_size
	var cell = get_cell(rx, y)
	if cell:
		var old_color = cell.color
		var new_color = (old_color + 1 + randi() % (num_colors - 1)) % num_colors
		cell.color = new_color

func _break_line_col(x: int) -> void:
	## column의 랜덤 셀 1개를 다른 색으로 변경
	var ry = randi() % grid_size
	var cell = get_cell(x, ry)
	if cell:
		var old_color = cell.color
		var new_color = (old_color + 1 + randi() % (num_colors - 1)) % num_colors
		cell.color = new_color

# ─────────────────────────────────────────
# 유틸
# ─────────────────────────────────────────

func is_row_single_color(y: int) -> bool:
	## 사용처: S02 row_destroy.gd
	return _is_row_completed(y)

func is_col_single_color(x: int) -> bool:
	return _is_col_completed(x)

func get_row_color(y: int) -> int:
	var cell = get_cell(0, y)
	return cell.color if cell else -1

func get_col_color(x: int) -> int:
	var cell = get_cell(x, 0)
	return cell.color if cell else -1
