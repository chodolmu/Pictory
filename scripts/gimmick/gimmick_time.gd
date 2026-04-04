class_name GimmickTime
extends GimmickBase

## S4 시간 칸: 파괴 시 +N초. 무한 모드 전용.

func can_recolor(cell, new_color: int) -> bool:
	return true

func can_bfs_traverse(cell, from_cell) -> bool:
	return true

func is_bfs_wildcard(cell) -> bool:
	return false

func can_destroy(cell) -> bool:
	return true

func on_destroy(cell) -> Dictionary:
	var bonus = cell.gimmick_data.get("bonus_seconds", 5.0)
	cell.clear_gimmick()
	return {
		"destroyed": true,
		"rewards": {},
		"effects": [{"type": "bonus_time", "value": bonus}]
	}

func on_gravity(cell, grid) -> bool:
	return true

func get_visual_config(cell) -> Dictionary:
	return {"type": "time_icon", "color": Color(1.0, 1.0, 1.0, 0.9)}
