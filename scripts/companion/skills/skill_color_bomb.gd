extends SkillBase
## K4: 컬러봄 — 특정 색 블록 N개를 즉시 제거.

const N := 5

func _init() -> void:
	skill_id = "K4"
	skill_name = "컬러봄"

# target: { "color": int }
func execute(context: Dictionary, target) -> Dictionary:
	if target == null:
		return { "success": false, "actions": [] }
	var grid: Grid = context.get("grid")
	if grid == null:
		return { "success": false, "actions": [] }

	var color: int = target.get("color", -1)
	if color < 0:
		return { "success": false, "actions": [] }

	var candidates: Array = []
	for cell in grid.get_all_main_cells():
		if cell.color != color:
			continue
		if cell.gimmick_type == 1 or cell.gimmick_type == 2:  # LOCKED, STONE
			continue
		# 얼음(ICE=3): 내구도 감소만 (완전 파괴 아님)
		if cell.gimmick_type == 3:
			candidates.append({"cell": cell, "ice": true})
		else:
			candidates.append({"cell": cell, "ice": false})

	candidates.shuffle()
	var targets = candidates.slice(0, mini(N, candidates.size()))

	var destroyed_positions: Array = []
	var destroyed_count: int = 0
	for t in targets:
		var cell: Cell = t["cell"]
		if t["ice"]:
			# 얼음 내구도 감소
			cell.gimmick_durability -= 1
			if cell.gimmick_durability <= 0:
				cell.clear_gimmick()
				cell.color = -1
				destroyed_positions.append(Vector2i(cell.x, cell.y))
				destroyed_count += 1
		else:
			# 연쇄(CHAIN_MULT=8): 2배 카운트
			var mult = 1
			if cell.gimmick_type == 8:
				mult = 2
				cell.clear_gimmick()
			destroyed_count += mult
			cell.color = -1
			cell.clear_gimmick()
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
	return "선택한 색상 블록 %d개를 즉시 제거합니다." % N
