extends SkillBase
## K7: 미래의눈 — 현재 보드에서 최적의 1턴 수를 힌트로 표시.

func _init() -> void:
	skill_id = "K7"
	skill_name = "미래의눈"

func execute(context: Dictionary, _target) -> Dictionary:
	var grid: Grid = context.get("grid")
	var color_queue = context.get("color_queue")
	if grid == null or color_queue == null:
		return { "success": false, "actions": [] }

	var active_color: int = color_queue.get_active_color()
	var best_pos = _find_best_move(grid, active_color)

	return {
		"success": true,
		"actions": [{
			"type": "hint",
			"position": best_pos,
			"color": active_color
		}]
	}

func _find_best_move(grid: Grid, active_color: int) -> Vector2i:
	var best_pos = Vector2i(-1, -1)
	var best_destroyed: int = -1
	var best_chains: int = -1

	for y in range(grid.grid_size):
		for x in range(grid.grid_size):
			var cell = grid.get_cell(x, y)
			if cell == null or cell.color < 0:
				continue
			if cell.color == active_color:
				continue  # 같은 색 터치는 무효
			if cell.gimmick_type == 1 or cell.gimmick_type == 2:  # LOCKED, STONE
				continue

			# 복사 그리드에서 시뮬레이션
			var sim_result = _simulate(grid, x, y, active_color)
			var destroyed = sim_result[0]
			var chains = sim_result[1]

			if destroyed > best_destroyed or (destroyed == best_destroyed and chains > best_chains):
				best_destroyed = destroyed
				best_chains = chains
				best_pos = Vector2i(x, y)

	return best_pos

func _simulate(grid: Grid, x: int, y: int, color: int) -> Array:
	# 간단 시뮬레이션: 클론 없이 group 크기로 추정
	# 실제 구현은 그리드 클론 후 ChainCombo 실행이 이상적이나
	# 성능을 위해 BFS 그룹 크기만 추정
	var group = FloodFill.flood_fill(grid, x, y)
	return [group.size(), 1]

func get_description() -> String:
	return "최적의 1수를 힌트로 표시합니다."
