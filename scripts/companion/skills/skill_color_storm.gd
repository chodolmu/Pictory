extends SkillBase
## K1: 단색폭풍 — 지정 색상 N개를 다른 색으로 변환.

const N := 5

func _init() -> void:
	skill_id = "K1"
	skill_name = "단색폭풍"

# target: { "from_color": int, "to_color": int }
func execute(context: Dictionary, target) -> Dictionary:
	if target == null:
		return { "success": false, "actions": [] }
	var grid: Grid = context.get("grid")
	if grid == null:
		return { "success": false, "actions": [] }

	var from_color: int = target.get("from_color", -1)
	var to_color: int = target.get("to_color", -1)
	if from_color < 0 or to_color < 0 or from_color == to_color:
		return { "success": false, "actions": [] }

	# 대상 셀 수집 (잠긴/돌 제외)
	var candidates: Array = []
	for cell in grid.get_all_main_cells():
		if cell.color != from_color:
			continue
		if cell.gimmick_type == 1 or cell.gimmick_type == 2:  # LOCKED, STONE
			continue
		candidates.append(cell)

	# 랜덤 N개 선택
	candidates.shuffle()
	var targets = candidates.slice(0, mini(N, candidates.size()))

	# 색상 변환
	var positions: Array = []
	for cell in targets:
		cell.color = to_color
		positions.append(Vector2i(cell.x, cell.y))

	return {
		"success": true,
		"actions": [{ "type": "recolor_done", "positions": positions, "color": to_color }]
	}

func get_description() -> String:
	return "지정 색상 블록 %d개를 다른 색으로 변환합니다." % N
