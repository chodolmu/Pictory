class_name RowDestroy
extends RefCounted

## 행/열 완성 판정 + 파괴 대상 셀 집합 계산.
## main area 기준으로 완성 라인을 찾고,

const FloodFillScript = preload("res://scripts/core/flood_fill.gd")
## 해당 라인과 BFS로 연결된 동색 그룹까지 파괴 대상에 포함.

static func check_all(grid: Grid) -> Array:
	var destroy_set: Dictionary = {}

	# 행 검사
	for y in range(grid.grid_size):
		var row = grid.get_row(y)
		if _is_line_complete(row):
			_add_line_and_connected(grid, row, destroy_set)

	# 열 검사
	for x in range(grid.grid_size):
		var col = grid.get_column(x)
		if _is_line_complete(col):
			_add_line_and_connected(grid, col, destroy_set)

	return destroy_set.values()

static func check_rows(grid: Grid) -> Array:
	var destroy_set: Dictionary = {}
	for y in range(grid.grid_size):
		var row = grid.get_row(y)
		if _is_line_complete(row):
			_add_line_and_connected(grid, row, destroy_set)
	return destroy_set.values()

static func check_columns(grid: Grid) -> Array:
	var destroy_set: Dictionary = {}
	for x in range(grid.grid_size):
		var col = grid.get_column(x)
		if _is_line_complete(col):
			_add_line_and_connected(grid, col, destroy_set)
	return destroy_set.values()

static func has_completed_lines(grid: Grid) -> bool:
	## 빠른 체크 — chain combo(S03)에서 사용
	for y in range(grid.grid_size):
		if _is_line_complete(grid.get_row(y)):
			return true
	for x in range(grid.grid_size):
		if _is_line_complete(grid.get_column(x)):
			return true
	return false

# ─────────────────────────────────────────
# 내부 헬퍼
# ─────────────────────────────────────────

static func _is_line_complete(cells: Array) -> bool:
	if cells.size() == 0:
		return false
	var first_color = cells[0].color
	if first_color == -1:
		return false
	for cell in cells:
		if cell.color != first_color:
			return false
	return true

static func _add_line_and_connected(grid: Grid, line_cells: Array, destroy_set: Dictionary) -> void:
	for cell in line_cells:
		var key = Vector2i(cell.x, cell.y)
		if not destroy_set.has(key):
			destroy_set[key] = cell
		# BFS로 연결된 동색 그룹 추가 (buffer 포함)
		var connected = FloodFillScript.flood_fill(grid, cell.x, cell.y)
		for c in connected:
			var ckey = Vector2i(c.x, c.y)
			if not destroy_set.has(ckey):
				destroy_set[ckey] = c
