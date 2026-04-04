class_name ChainCombo
extends RefCounted

## destroy → gravity → recheck 반복 chain combo 시스템.

const MAX_CHAIN: int = 20

class ChainResult:
	var chain_count: int = 0
	var total_destroyed: int = 0
	var destroyed_per_chain: Array[int] = []

static func execute(grid: Grid) -> ChainResult:
	var result = ChainResult.new()

	for i in range(MAX_CHAIN):
		var destroy_set = RowDestroy.check_all(grid)

		if destroy_set.size() == 0:
			break

		# 파괴
		for cell in destroy_set:
			grid.set_cell_color(cell.x, cell.y, -1)

		# Gravity
		Gravity.apply(grid)

		result.chain_count += 1
		result.total_destroyed += destroy_set.size()
		result.destroyed_per_chain.append(destroy_set.size())

		print("Chain ", result.chain_count, ": destroyed ", destroy_set.size(), " cells")

	if result.chain_count >= MAX_CHAIN:
		push_warning("ChainCombo: MAX_CHAIN reached!")

	return result
