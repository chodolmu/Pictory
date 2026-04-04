class_name GimmickAnchor
extends GimmickBase

## M5 앵커 칸: 중력 무시(고정). 리컬러/BFS/파괴 모두 정상.

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
	return {"destroyed": true, "rewards": {}, "effects": []}

func on_gravity(cell, grid) -> bool:
	return false  # 고정 — 세그먼트 분할 경계

func get_visual_config(cell) -> Dictionary:
	return {"type": "icon", "icon": "anchor", "color": Color(0.2, 0.2, 0.2, 0.7)}
