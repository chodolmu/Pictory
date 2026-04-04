class_name FloodFill
extends RefCounted

## BFS 기반 연결 그룹 탐색 유틸리티.
## main grid + buffer 영역 전체를 탐색 범위로 한다.
## static 함수로 구현하여 stateless 유틸리티로 사용.

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
		Vector2i(0, -1),  # 상
		Vector2i(0, 1),   # 하
		Vector2i(-1, 0),  # 좌
		Vector2i(1, 0),   # 우
	]

	while queue.size() > 0:
		var pos = queue.pop_front()
		var cell = grid.get_cell(pos.x, pos.y)
		if cell != null and cell.color == target_color:
			result.append(cell)
			for dir in directions:
				var next = pos + dir
				if not visited.has(next) and grid.is_valid_coord(next.x, next.y):
					visited[next] = true
					queue.append(next)

	return result
