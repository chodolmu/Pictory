class_name ChainCombo
extends RefCounted

## destroy → gravity → recheck 반복 chain combo 시스템.
## S07: 기믹 on_destroy 효과(코인/별/시간/연쇄배율) 수집 추가.

const MAX_CHAIN: int = 20

class ChainResult:
	var chain_count: int = 0
	var total_destroyed: int = 0
	var effective_destroyed: int = 0   # 연쇄 칸 배율 반영
	var destroyed_per_chain: Array[int] = []
	var collected_effects: Array = []  # {type, value} 배열
	var collected_rewards: Dictionary = {}  # 누적 보상

## 애니메이션용: 각 체인 스텝의 파괴/이동 정보를 반환하なが 그리드를 실제로 변경한다.
## 반환: Array of {destroyed_cells: Array[Cell], gravity_moves: Array, chain_index: int}
## game_manager._execute_chain_with_animation()이 같은 로직을 인라인으로 구현하므로
## 이 함수는 외부 스크립트에서 사전 계획용으로 활용할 수 있다.
static func execute_steps(grid: Grid) -> Array:
	var steps: Array = []
	var sim_grid = grid  # grid를 직접 변경함

	for i in range(MAX_CHAIN):
		var destroy_set = RowDestroy.check_all(sim_grid)
		if destroy_set.size() == 0:
			break

		# 파괴 대상 셀 목록
		var destroyed_cells: Array = destroy_set.duplicate()

		# gravity 이동 계산 (파괴 적용 전 그리드 기준으로 계산하면 틀리므로,
		# 파괴 적용 후 임시 상태를 만들어서 계산)
		for cell in destroy_set:
			sim_grid.set_cell_color(cell.x, cell.y, -1)

		var gravity_moves = Gravity.calculate_moves(sim_grid)

		# gravity 실제 적용 (다음 반복을 위해)
		Gravity.apply(sim_grid)

		steps.append({
			"destroyed_cells": destroyed_cells,
			"gravity_moves": gravity_moves,
			"chain_index": i
		})

	return steps

static func execute(grid: Grid) -> ChainResult:
	var result = ChainResult.new()

	for i in range(MAX_CHAIN):
		var destroy_set = RowDestroy.check_all(grid)

		if destroy_set.size() == 0:
			break

		# 파괴 처리 + 기믹 효과 수집
		var has_chain_mult = false
		for cell in destroy_set:
			var handler = GimmickRegistry.get_handler(cell.gimmick_type)
			var d_result = handler.on_destroy(cell)
			if d_result.get("destroyed", true):
				grid.set_cell_color(cell.x, cell.y, -1)
				# 보상 수집
				var rewards = d_result.get("rewards", {})
				for k in rewards:
					result.collected_rewards[k] = result.collected_rewards.get(k, 0) + rewards[k]
				# 효과 수집
				for effect in d_result.get("effects", []):
					result.collected_effects.append(effect)
					if effect.get("type") == "multiply_count":
						has_chain_mult = true

		# Gravity
		Gravity.apply(grid)

		var effective = destroy_set.size() * 2 if has_chain_mult else destroy_set.size()
		result.chain_count += 1
		result.total_destroyed += destroy_set.size()
		result.effective_destroyed += effective
		result.destroyed_per_chain.append(destroy_set.size())

		print("Chain ", result.chain_count, ": destroyed ", destroy_set.size(),
			" (effective: ", effective, ")")

	if result.chain_count >= MAX_CHAIN:
		push_warning("ChainCombo: MAX_CHAIN reached!")

	return result
