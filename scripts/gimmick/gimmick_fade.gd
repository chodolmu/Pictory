class_name GimmickFade
extends GimmickBase

## S3 퇴색 칸: 리컬러 후 2턴 뒤 원래 색으로 복귀.
## 스토리 모드 전용.

func can_recolor(cell, new_color: int) -> bool:
	return true

func on_recolor(cell, old_color: int, new_color: int, source: String = "bfs") -> void:
	var original = cell.gimmick_data.get("original_color", -1)
	if new_color != original:
		# 원래 색과 다르면 카운터 시작/리셋
		cell.gimmick_data["turn_counter"] = cell.gimmick_data.get("revert_turns", 2)
	else:
		# 원래 색으로 돌아오면 카운터 비활성
		cell.gimmick_data["turn_counter"] = -1

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

func on_turn(cell, turn_number: int) -> void:
	var counter = cell.gimmick_data.get("turn_counter", -1)
	if counter <= 0:
		return

	counter -= 1
	cell.gimmick_data["turn_counter"] = counter

	if counter == 0:
		# 원래 색으로 복귀
		var original = cell.gimmick_data.get("original_color", -1)
		if original >= 0:
			cell.color = original
		cell.gimmick_data["turn_counter"] = -1

func get_visual_config(cell) -> Dictionary:
	var counter = cell.gimmick_data.get("turn_counter", -1)
	var original = cell.gimmick_data.get("original_color", -1)
	return {
		"type": "fade",
		"turn_counter": counter,
		"original_color": original,
		"color": Color(0.8, 0.8, 0.8, 0.4)
	}
