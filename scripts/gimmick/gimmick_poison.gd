class_name GimmickPoison
extends GimmickBase

## S5 독 칸: 존재 동안 액션당 시간 감소 가속. 무한 모드 전용.

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
	return true

func get_visual_config(cell) -> Dictionary:
	return {"type": "poison", "color": Color(0.6, 0.2, 0.8, 0.5)}
