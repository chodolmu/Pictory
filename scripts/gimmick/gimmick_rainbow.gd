class_name GimmickRainbow
extends GimmickBase

## M4 무지개 칸: BFS 와일드카드. 리컬러 시 기믹 소멸하여 일반 셀로 전환.

const RAINBOW_COLOR: int = -2

func can_recolor(cell, new_color: int) -> bool:
	return true

func on_recolor(cell, old_color: int, new_color: int) -> void:
	cell.color = new_color
	cell.clear_gimmick()  # 무지개 소멸 → 일반 셀

func can_bfs_traverse(cell, from_cell) -> bool:
	return true

func is_bfs_wildcard(cell) -> bool:
	return true  # 모든 색과 매칭

func can_destroy(cell) -> bool:
	return true

func on_destroy(cell) -> Dictionary:
	cell.clear_gimmick()
	return {"destroyed": true, "rewards": {}, "effects": []}

func on_gravity(cell, grid) -> bool:
	return true

func get_visual_config(cell) -> Dictionary:
	return {"type": "rainbow"}
