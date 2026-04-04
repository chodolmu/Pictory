class_name GimmickStar
extends GimmickBase

## S1 별 칸: 파괴 시 +1 보너스 턴. 스토리 모드 전용.

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
		"effects": [{"type": "bonus_turn", "value": 1}]
	}

func on_gravity(cell, grid) -> bool:
	return true

func get_visual_config(cell) -> Dictionary:
	return {"type": "star", "color": Color(1.0, 0.85, 0.0, 0.95)}
