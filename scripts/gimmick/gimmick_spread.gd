class_name GimmickSpread
extends GimmickBase

## S2 번짐 칸: 매 턴 종료 시 인접 1칸을 자기 색으로 감염.
## 스토리 모드 전용.

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

func on_turn(cell, turn_number: int) -> void:
	var grid = cell.gimmick_data.get("_grid_ref", null)
	if grid == null:
		return

	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	var valid_targets: Array = []

	for dir in directions:
		var nx = cell.x + dir.x
		var ny = cell.y + dir.y
		if not grid.is_valid_coord(nx, ny):
			continue
		var neighbor = grid.get_cell(nx, ny)
		if neighbor == null or not neighbor.active:
			continue
		# 감염 불가 대상 필터링
		if neighbor.gimmick_type == GimmickBase.GimmickType.STONE:
			continue
		if neighbor.gimmick_type == GimmickBase.GimmickType.LOCKED:
			continue
		var n_handler = GimmickRegistry.get_handler(neighbor.gimmick_type)
		if not n_handler.can_recolor(neighbor, cell.color):
			continue
		if neighbor.color == cell.color:
			continue
		valid_targets.append(neighbor)

	if valid_targets.is_empty():
		return

	var target = valid_targets[randi() % valid_targets.size()]
	var old_color = target.color
	target.color = cell.color
	# on_recolor 훅 호출 (퇴색 카운터, 무지개 소모 등)
	var t_handler = GimmickRegistry.get_handler(target.gimmick_type)
	t_handler.on_recolor(target, old_color, cell.color, "spread")

func get_visual_config(cell) -> Dictionary:
	return {"type": "spread", "color": Color(0.3, 0.7, 0.3, 0.7)}
