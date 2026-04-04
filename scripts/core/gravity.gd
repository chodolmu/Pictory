class_name Gravity
extends RefCounted

## 파괴 후 빈 셀을 채우는 중력 시스템.
## 열별로 독립적으로 bottom-up compaction 수행.
## buffer → main 방향으로 낙하, 빈 buffer는 랜덤 색상으로 refill.

static func apply(grid: Grid) -> void:
	for x in range(grid.grid_size):
		_compact_column(grid, x)
	_refill_buffer(grid)

static func _compact_column(grid: Grid, x: int) -> void:
	# 전체 column (main + buffer)을 아래→위 순으로 순회,
	# 비어있지 않은 셀의 색상을 수집
	var non_empty: Array = []  # color values, bottom-to-top 순

	for y in range(grid.grid_size - 1, -grid.grid_size - 1, -1):
		var cell = grid.get_cell(x, y)
		if cell != null and cell.color != -1:
			non_empty.append(cell.color)

	# main bottom부터 위로 채워 넣기
	var write_y = grid.grid_size - 1
	for color in non_empty:
		grid.set_cell_color(x, write_y, color)
		var cell = grid.get_cell(x, write_y)
		if cell:
			cell.active = (write_y >= 0)
		write_y -= 1

	# 나머지 빈 자리 -1로 마킹
	while write_y >= -grid.grid_size:
		grid.set_cell_color(x, write_y, -1)
		write_y -= 1

static func _refill_buffer(grid: Grid) -> void:
	## buffer 영역 빈 셀을 랜덤 색상으로 채움.
	## S03에서 ColorQueue 기반으로 교체 예정.
	for y in range(-1, -grid.grid_size - 1, -1):
		for x in range(grid.grid_size):
			var cell = grid.get_cell(x, y)
			if cell != null and cell.color == -1:
				cell.color = randi() % grid.num_colors
				cell.active = false
