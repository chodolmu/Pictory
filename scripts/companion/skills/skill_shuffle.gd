extends SkillBase
## K8: 셔플 — 필드 전체 블록을 랜덤 재배치 (색 비율 유지).

func _init() -> void:
	skill_id = "K8"
	skill_name = "셔플"

func execute(context: Dictionary, _target) -> Dictionary:
	var grid: Grid = context.get("grid")
	if grid == null:
		return { "success": false, "actions": [] }

	# 셔플 가능한 셀 수집
	var shuffleable_cells: Array = []
	var colors: Array[int] = []

	for cell in grid.get_all_main_cells():
		# 잠긴/돌/무지개/앵커(위치 고정)는 제외
		if cell.gimmick_type == 1 or cell.gimmick_type == 2 or cell.gimmick_type == 4:
			continue
		if cell.color < 0:
			continue
		shuffleable_cells.append(cell)
		colors.append(cell.color)

	if shuffleable_cells.size() < 2:
		return { "success": true, "actions": [{ "type": "shuffle_done" }] }

	# 완성 라인 방지 셔플 (최대 10회 시도)
	var attempt = 0
	var shuffled_colors: Array[int] = []
	while attempt < 10:
		shuffled_colors = colors.duplicate()
		shuffled_colors.shuffle()

		# 완성 라인 체크
		var temp_map: Dictionary = {}
		for i in range(shuffleable_cells.size()):
			var cell = shuffleable_cells[i]
			temp_map[Vector2i(cell.x, cell.y)] = shuffled_colors[i]

		if not _has_completed_line(grid, temp_map, shuffleable_cells):
			break
		attempt += 1

	# 색상 적용
	for i in range(shuffleable_cells.size()):
		shuffleable_cells[i].color = shuffled_colors[i]

	return {
		"success": true,
		"actions": [{ "type": "shuffle_done" }]
	}

func _has_completed_line(grid: Grid, temp_map: Dictionary, cells: Array) -> bool:
	# 임시 색상 기준으로 완성 행/열 확인
	for y in range(grid.grid_size):
		var row = grid.get_row(y)
		if row.is_empty():
			continue
		var first_color = temp_map.get(Vector2i(row[0].x, row[0].y), row[0].color)
		if first_color < 0:
			continue
		var all_same = true
		for cell in row:
			var c = temp_map.get(Vector2i(cell.x, cell.y), cell.color)
			if c != first_color:
				all_same = false
				break
		if all_same:
			return true
	return false

func get_description() -> String:
	return "필드 블록을 랜덤으로 재배치합니다."
