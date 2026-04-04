class_name FloodFill
extends RefCounted

## BFS 기반 연결 그룹 탐색 유틸리티.
## S06: 기믹 훅(can_bfs_traverse, is_bfs_wildcard, can_recolor) 통합.
## S07: recolor_group 추가 (on_recolor 훅 호출 + grid 참조 주입).

static func flood_fill(grid: Grid, start_x: int, start_y: int) -> Array:
	var start_cell = grid.get_cell(start_x, start_y)
	if start_cell == null or start_cell.color == -1:
		return []

	var target_color = start_cell.color
	var visited: Dictionary = {}
	var result: Array = []
	var queue: Array = [Vector2i(start_x, start_y)]
	visited[Vector2i(start_x, start_y)] = true

	var directions = [
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
	]

	while queue.size() > 0:
		var pos = queue.pop_front()
		var cell = grid.get_cell(pos.x, pos.y)
		if cell == null:
			continue

		var handler = GimmickRegistry.get_handler(cell.gimmick_type)

		# 색 매칭 판정 (와일드카드 고려)
		if not _colors_match(cell, target_color, handler):
			continue

		result.append(cell)

		for dir in directions:
			var next = pos + dir
			if visited.has(next):
				continue
			if not grid.is_valid_coord(next.x, next.y):
				continue
			var neighbor = grid.get_cell(next.x, next.y)
			if neighbor == null:
				continue
			var n_handler = GimmickRegistry.get_handler(neighbor.gimmick_type)
			# BFS 진입 가능 여부 (돌 칸은 차단)
			if not n_handler.can_bfs_traverse(neighbor, cell):
				continue
			visited[next] = true
			queue.append(next)

	return result

## BFS 그룹을 new_color로 리컬러. can_recolor/on_recolor 훅 호출.
## 페인트통 기믹에는 grid 참조를 주입한다.
static func recolor_group(grid: Grid, group: Array, new_color: int) -> void:
	for cell in group:
		var handler = GimmickRegistry.get_handler(cell.gimmick_type)
		if not handler.can_recolor(cell, new_color):
			continue
		var old_color = cell.color
		cell.color = new_color
		# 페인트통에 grid 참조 주입 (on_recolor가 행/열 탐색에 사용)
		if cell.gimmick_type == GimmickBase.GimmickType.PAINT_BUCKET:
			cell.gimmick_data["_grid_ref"] = grid
		handler.on_recolor(cell, old_color, new_color, "bfs")

static func _colors_match(cell, target_color: int, handler) -> bool:
	if handler.is_bfs_wildcard(cell):
		return true
	return cell.color == target_color
