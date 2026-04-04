class_name GimmickChain
extends GimmickBase

## M8 연쇄 칸(Chain Multiplier): 포함된 파괴에서 파괴 수 2배 카운트.
## 여러 개 있어도 2배 (중첩 불가).

func can_recolor(cell, new_color: int) -> bool:
	return true

func can_bfs_traverse(cell, from_cell) -> bool:
	return true

func is_bfs_wildcard(cell) -> bool:
	return false

func can_destroy(cell) -> bool:
	return true

func on_destroy(cell) -> Dictionary:
	cell.clear_gimmick()
	return {
		"destroyed": true,
		"rewards": {},
		"effects": [{"type": "multiply_count", "value": 2}]
	}

func on_gravity(cell, grid) -> bool:
	return true

func get_visual_config(cell) -> Dictionary:
	return {"type": "chain_mult", "color": Color(1.0, 1.0, 1.0, 0.9)}
