class_name RowDestroy
extends RefCounted

## 행/열 완성 판정 + 파괴 대상 셀 집합 계산.
## check_all은 파괴 대상만 수집하고, on_destroy는 호출하지 않음.
## on_destroy는 chain executor에서 1회만 호출해야 함.

static func check_all(grid: Grid) -> Array:
	var destroy_set: Dictionary = {}  # Vector2i -> Cell (실제 비워질 셀)

	for y in range(grid.grid_size):
		var row = grid.get_row(y)
		if _is_line_complete(row):
			_collect_line(grid, row, destroy_set)

	for x in range(grid.grid_size):
		var col = grid.get_column(x)
		if _is_line_complete(col):
			_collect_line(grid, col, destroy_set)

	return destroy_set.values()

static func check_rows(grid: Grid) -> Array:
	var destroy_set: Dictionary = {}
	for y in range(grid.grid_size):
		var row = grid.get_row(y)
		if _is_line_complete(row):
			_collect_line(grid, row, destroy_set)
	return destroy_set.values()

static func check_columns(grid: Grid) -> Array:
	var destroy_set: Dictionary = {}
	for x in range(grid.grid_size):
		var col = grid.get_column(x)
		if _is_line_complete(col):
			_collect_line(grid, col, destroy_set)
	return destroy_set.values()

static func has_completed_lines(grid: Grid) -> bool:
	for y in range(grid.grid_size):
		if _is_line_complete(grid.get_row(y)):
			return true
	for x in range(grid.grid_size):
		if _is_line_complete(grid.get_column(x)):
			return true
	return false

# ─────────────────────────────────────────
# 라인 완성 판정 (기믹 훅 통합)
# ─────────────────────────────────────────

static func _is_line_complete(cells: Array) -> bool:
	if cells.size() == 0:
		return false

	var base_color: int = -1
	var all_wildcard: bool = true

	for cell in cells:
		var handler = GimmickRegistry.get_handler(cell.gimmick_type)

		# 파괴 불가 셀(돌) 포함 → 절대 완성 불가
		if not handler.can_destroy(cell):
			return false

		# 와일드카드(무지개)는 스킵
		if handler.is_bfs_wildcard(cell):
			continue

		all_wildcard = false

		if cell.color == -1:
			return false  # 빈 셀
		if base_color == -1:
			base_color = cell.color
		elif cell.color != base_color:
			return false

	# 모두 와일드카드거나 base_color가 결정됐으면 완성
	return all_wildcard or base_color != -1

# ─────────────────────────────────────────
# 라인 파괴 대상 수집 (on_destroy 호출하지 않음)
# ─────────────────────────────────────────

static func _collect_line(_grid: Grid, line_cells: Array, destroy_set: Dictionary) -> void:
	## 완성된 라인의 셀 중 파괴 가능한 셀만 destroy_set에 추가.
	## on_destroy는 호출하지 않음 — chain executor에서 1회만 호출.
	for cell in line_cells:
		var key = Vector2i(cell.x, cell.y)
		if destroy_set.has(key):
			continue
		var handler = GimmickRegistry.get_handler(cell.gimmick_type)
		if handler.can_destroy(cell):
			destroy_set[key] = cell
