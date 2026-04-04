class_name RowDestroy
extends RefCounted

## 행/열 완성 판정 + 파괴 대상 셀 집합 계산.
## S06: 기믹 훅(can_destroy, on_destroy, is_bfs_wildcard) 통합.

static func check_all(grid: Grid) -> Array:
	var destroy_set: Dictionary = {}  # Vector2i -> Cell (실제 비워질 셀)

	for y in range(grid.grid_size):
		var row = grid.get_row(y)
		if _is_line_complete(row):
			_process_line(grid, row, destroy_set)

	for x in range(grid.grid_size):
		var col = grid.get_column(x)
		if _is_line_complete(col):
			_process_line(grid, col, destroy_set)

	return destroy_set.values()

static func check_rows(grid: Grid) -> Array:
	var destroy_set: Dictionary = {}
	for y in range(grid.grid_size):
		var row = grid.get_row(y)
		if _is_line_complete(row):
			_process_line(grid, row, destroy_set)
	return destroy_set.values()

static func check_columns(grid: Grid) -> Array:
	var destroy_set: Dictionary = {}
	for x in range(grid.grid_size):
		var col = grid.get_column(x)
		if _is_line_complete(col):
			_process_line(grid, col, destroy_set)
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
# 라인 파괴 처리 (기믹 on_destroy 호출)
# ─────────────────────────────────────────

static func _process_line(grid: Grid, line_cells: Array, destroy_set: Dictionary) -> void:
	for cell in line_cells:
		var key = Vector2i(cell.x, cell.y)
		var handler = GimmickRegistry.get_handler(cell.gimmick_type)

		if not handler.can_destroy(cell):
			continue

		var result = handler.on_destroy(cell)

		if result.get("destroyed", true):
			# 실제로 비워질 셀
			if not destroy_set.has(key):
				destroy_set[key] = cell
			# BFS로 연결된 동색 그룹도 추가 (기믹 없는 일반 셀만)
			var connected = FloodFill.flood_fill(grid, cell.x, cell.y)
			for c in connected:
				var ckey = Vector2i(c.x, c.y)
				if not destroy_set.has(ckey):
					var c_handler = GimmickRegistry.get_handler(c.gimmick_type)
					if c_handler.can_destroy(c):
						var c_result = c_handler.on_destroy(c)
						if c_result.get("destroyed", true):
							destroy_set[ckey] = c
		# destroyed=false인 경우(얼음 첫 타): on_destroy에서 이미 상태 변경됨, destroy_set에 추가 안 함
