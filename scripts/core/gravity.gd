class_name Gravity
extends RefCounted

## 파괴 후 빈 셀을 채우는 중력 시스템.
## S06: 기믹 on_gravity() 훅 통합. 돌/앵커 기준 세그먼트 분할.

static func apply(grid: Grid) -> void:
	for x in range(grid.grid_size):
		_compact_column(grid, x)
	_refill_buffer(grid)

static func _compact_column(grid: Grid, x: int) -> void:
	# 전체 column (main + buffer)을 세그먼트로 분할.
	# on_gravity()=false 셀(돌/앵커)이 경계가 됨.
	var segments = _split_into_segments(grid, x)

	for segment in segments:
		_compact_segment(grid, x, segment)

	_refill_empty_in_buffer(grid, x)

static func _split_into_segments(grid: Grid, x: int) -> Array:
	## 열을 고정 셀(on_gravity=false) 기준으로 세그먼트 배열로 분할.
	## 각 세그먼트는 [y_start, y_end] 범위 (inclusive, bottom→top 방향).
	var segments: Array = []
	var seg_start: int = grid.grid_size - 1  # 최하단부터
	var min_y = -grid.grid_size  # buffer 최상단

	# y = grid_size-1 (bottom) → y = min_y (top) 순으로 스캔
	var y = grid.grid_size - 1
	while y >= min_y:
		var cell = grid.get_cell(x, y)
		if cell == null:
			y -= 1
			continue
		var handler = GimmickRegistry.get_handler(cell.gimmick_type)
		if not handler.on_gravity(cell, grid):
			# 고정 셀 → 현재 세그먼트를 [y+1, seg_start]로 저장
			if y + 1 <= seg_start:
				segments.append([y + 1, seg_start])
			seg_start = y - 1  # 다음 세그먼트 시작은 고정 셀 위부터
		y -= 1

	# 마지막 세그먼트 (buffer 최상단까지)
	if min_y <= seg_start:
		segments.append([min_y, seg_start])

	return segments

static func _compact_segment(grid: Grid, x: int, segment: Array) -> void:
	## 세그먼트 [y_start, y_end] 내에서 아래→위 압축.
	## 비어있지 않은 셀 색상을 모아 아래부터 채운다.
	var y_start = segment[0]  # 세그먼트 최상단 (작은 y)
	var y_end = segment[1]    # 세그먼트 최하단 (큰 y)

	# 아래→위로 비어있지 않은 셀 수집
	var non_empty: Array = []
	for y in range(y_end, y_start - 1, -1):
		var cell = grid.get_cell(x, y)
		if cell != null and cell.color != -1:
			# gimmick 상태도 함께 보존
			non_empty.append({
				"color": cell.color,
				"gimmick_type": cell.gimmick_type,
				"gimmick_state": cell.gimmick_state,
				"gimmick_durability": cell.gimmick_durability,
				"gimmick_data": cell.gimmick_data.duplicate()
			})

	# 아래부터 채우기
	var write_y = y_end
	for data in non_empty:
		var cell = grid.get_cell(x, write_y)
		if cell:
			cell.color = data["color"]
			cell.gimmick_type = data["gimmick_type"]
			cell.gimmick_state = data["gimmick_state"]
			cell.gimmick_durability = data["gimmick_durability"]
			cell.gimmick_data = data["gimmick_data"]
			cell.active = (write_y >= 0)
		write_y -= 1

	# 나머지 빈 자리
	while write_y >= y_start:
		var cell = grid.get_cell(x, write_y)
		if cell:
			cell.color = -1
			cell.clear_gimmick()
		write_y -= 1

static func _refill_buffer(grid: Grid) -> void:
	## buffer 영역의 빈 셀 전체를 랜덤 색상으로 채운다.
	for y in range(-1, -grid.grid_size - 1, -1):
		for x in range(grid.grid_size):
			var cell = grid.get_cell(x, y)
			if cell != null and cell.color == -1 and not cell.has_gimmick():
				cell.color = randi() % grid.num_colors
				cell.active = false

static func _refill_empty_in_buffer(grid: Grid, x: int) -> void:
	## 특정 열의 buffer 빈 셀만 채운다.
	for y in range(-1, -grid.grid_size - 1, -1):
		var cell = grid.get_cell(x, y)
		if cell != null and cell.color == -1 and not cell.has_gimmick():
			cell.color = randi() % grid.num_colors
			cell.active = false
