class_name GimmickIce
extends GimmickBase

## M3 얼음 칸: 셀 위의 보호막. 라인 파괴 2회에 완전 파괴.
## durability=2: 정상, durability=1: crack 상태

func can_recolor(cell, new_color: int) -> bool:
	return true  # 얼음 아래 색 변경 가능

func can_bfs_traverse(cell, from_cell) -> bool:
	return true

func is_bfs_wildcard(cell) -> bool:
	return false

func can_destroy(cell) -> bool:
	return true

func on_destroy(cell) -> Dictionary:
	cell.gimmick_durability -= 1
	if cell.gimmick_durability <= 0:
		cell.clear_gimmick()
		return {"destroyed": true, "rewards": {}, "effects": [{"type": "ice_break"}]}
	else:
		cell.gimmick_state = 1  # crack 상태
		return {"destroyed": false, "rewards": {}, "effects": [{"type": "ice_crack"}]}

func on_gravity(cell, grid) -> bool:
	return true  # 얼음 상태 유지한 채 낙하

func get_visual_config(cell) -> Dictionary:
	if cell.gimmick_state == 1:  # crack
		return {"type": "overlay_crack", "color": Color(0.53, 0.80, 1.0, 0.5)}
	return {"type": "overlay_rect", "color": Color(0.53, 0.80, 1.0, 0.35)}
