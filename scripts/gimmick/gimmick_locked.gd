class_name GimmickLocked
extends GimmickBase

## M1 잠긴 칸: BFS 그룹에 포함되지만 리컬러 불가. 라인 완성 시 파괴.

func can_recolor(cell, new_color: int) -> bool:
	return false

func can_bfs_traverse(cell, from_cell) -> bool:
	return true

func is_bfs_wildcard(cell) -> bool:
	return false

func can_destroy(cell) -> bool:
	return true

func on_destroy(cell) -> Dictionary:
	cell.clear_gimmick()
	return {"destroyed": true, "rewards": {}, "effects": []}

func on_gravity(cell, grid) -> bool:
	return true

func get_visual_config(cell) -> Dictionary:
	return {"type": "icon", "icon": "lock", "color": Color(0.5, 0.5, 0.5, 0.7)}
