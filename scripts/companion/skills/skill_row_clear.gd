extends SkillBase
## K5: 행청소 — 지정 행 또는 열 전체를 즉시 파괴.

func _init() -> void:
	skill_id = "K5"
	skill_name = "행청소"

# target: { "is_row": bool, "index": int }
func execute(context: Dictionary, target) -> Dictionary:
	if target == null:
		return { "success": false, "actions": [] }
	var grid: Grid = context.get("grid")
	if grid == null:
		return { "success": false, "actions": [] }

	var is_row: bool = target.get("is_row", true)
	var index: int = target.get("index", 0)

	var cells: Array = []
	if is_row:
		cells = grid.get_row(index)
	else:
		cells = grid.get_column(index)

	var destroyed_positions: Array = []
	var destroyed_count: int = 0

	for cell in cells:
		if cell.gimmick_type == 2:  # STONE: 건너뜀
			continue
		# 얼음(ICE=3): 내구도 감소
		if cell.gimmick_type == 3:
			cell.gimmick_durability -= 1
			if cell.gimmick_durability <= 0:
				cell.clear_gimmick()
				cell.color = -1
				destroyed_positions.append(Vector2i(cell.x, cell.y))
				destroyed_count += 1
			continue
		var mult = 1
		if cell.gimmick_type == 8:  # CHAIN_MULT
			mult = 2
		cell.color = -1
		cell.clear_gimmick()
		destroyed_count += mult
		destroyed_positions.append(Vector2i(cell.x, cell.y))

	return {
		"success": true,
		"actions": [{
			"type": "destroy_done",
			"positions": destroyed_positions,
			"count": destroyed_count
		}]
	}

func get_description() -> String:
	return "지정 행 또는 열 전체를 즉시 파괴합니다."
