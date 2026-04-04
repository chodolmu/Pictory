class_name GimmickStone
extends GimmickBase

## M2 돌 칸: BFS 차단, 파괴 불가, 중력 무시(고정).

func can_recolor(cell, new_color: int) -> bool:
	return false

func can_bfs_traverse(cell, from_cell) -> bool:
	return false  # 돌 너머 BFS 차단

func is_bfs_wildcard(cell) -> bool:
	return false

func can_destroy(cell) -> bool:
	return false  # 절대 파괴 불가

func on_destroy(cell) -> Dictionary:
	return {"destroyed": false, "rewards": {}, "effects": []}

func on_gravity(cell, grid) -> bool:
	return false  # 고정

func get_visual_config(cell) -> Dictionary:
	return {"type": "replace", "color": Color(0.5, 0.5, 0.5, 1.0), "border_color": Color(0.3, 0.3, 0.3, 1.0)}
