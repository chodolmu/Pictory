class_name GimmickCoin
extends GimmickBase

## M7 코인 칸: 파괴 시 추가 재화 지급. BFS/리컬러/중력은 일반 셀과 동일.

func can_recolor(cell, new_color: int) -> bool:
	return true

func can_bfs_traverse(cell, from_cell) -> bool:
	return true

func is_bfs_wildcard(cell) -> bool:
	return false

func can_destroy(cell) -> bool:
	return true

func on_destroy(cell) -> Dictionary:
	var coin_value = cell.gimmick_data.get("coin_value", 10)
	cell.clear_gimmick()
	return {"destroyed": true, "rewards": {"coins": coin_value}, "effects": []}

func on_gravity(cell, grid) -> bool:
	return true

func get_visual_config(cell) -> Dictionary:
	var coin_value = cell.gimmick_data.get("coin_value", 10)
	return {"type": "coin", "value": coin_value, "color": Color(1.0, 0.85, 0.0, 0.9)}
