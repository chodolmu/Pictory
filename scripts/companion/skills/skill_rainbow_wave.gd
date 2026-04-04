extends SkillBase
## K2: 무지개파동 — 지정 셀 기준 3×3 영역을 지정 색으로 통일.

func _init() -> void:
	skill_id = "K2"
	skill_name = "무지개파동"

# target: { "cx": int, "cy": int, "color": int }
func execute(context: Dictionary, target) -> Dictionary:
	if target == null:
		return { "success": false, "actions": [] }
	var grid: Grid = context.get("grid")
	if grid == null:
		return { "success": false, "actions": [] }

	var cx: int = target.get("cx", 0)
	var cy: int = target.get("cy", 0)
	var color: int = target.get("color", 0)

	var positions: Array = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var nx = cx + dx
			var ny = cy + dy
			if not grid.is_main_area(nx, ny):
				continue
			var cell = grid.get_cell(nx, ny)
			if cell == null:
				continue
			# 잠긴/돌 건너뜀
			if cell.gimmick_type == 1 or cell.gimmick_type == 2:
				continue
			cell.color = color
			positions.append(Vector2i(nx, ny))

	return {
		"success": true,
		"actions": [{ "type": "recolor_done", "positions": positions, "color": color }]
	}

func get_description() -> String:
	return "지정 위치 3×3 영역을 선택한 색으로 통일합니다."
