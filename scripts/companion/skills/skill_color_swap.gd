extends SkillBase
## K3: 컬러스왑 — 필드 전체에서 두 색상을 서로 교환.

func _init() -> void:
	skill_id = "K3"
	skill_name = "컬러스왑"

# target: { "color_a": int, "color_b": int }
func execute(context: Dictionary, target) -> Dictionary:
	if target == null:
		return { "success": false, "actions": [] }
	var grid: Grid = context.get("grid")
	if grid == null:
		return { "success": false, "actions": [] }

	var ca: int = target.get("color_a", -1)
	var cb: int = target.get("color_b", -1)
	if ca < 0 or cb < 0 or ca == cb:
		return { "success": false, "actions": [] }

	# 전체 그리드(메인+버퍼) 스캔
	var all_cells: Array = grid.get_all_main_cells()
	# 버퍼도 포함
	for y in range(-1, -grid.grid_size - 1, -1):
		for x in range(grid.grid_size):
			var cell = grid.get_cell(x, y)
			if cell:
				all_cells.append(cell)

	var positions_a: Array = []
	var positions_b: Array = []
	for cell in all_cells:
		if cell.gimmick_type == 1 or cell.gimmick_type == 2:  # LOCKED, STONE
			continue
		if cell.color == ca:
			positions_a.append(cell)
		elif cell.color == cb:
			positions_b.append(cell)

	for cell in positions_a:
		cell.color = cb
	for cell in positions_b:
		cell.color = ca

	return {
		"success": true,
		"actions": [{ "type": "swap_done", "color_a": ca, "color_b": cb }]
	}

func get_description() -> String:
	return "필드 전체에서 두 색상을 서로 교환합니다."
