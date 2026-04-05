class_name GimmickPaintBucket
extends GimmickBase

## M6 페인트통: 리컬러 시 행(row) 또는 열(col) 전체를 같은 색으로 변환.
## 1회 사용 후 소모.

var _is_propagating: bool = false

func can_recolor(cell, new_color: int) -> bool:
	return true

func on_recolor(cell, old_color: int, new_color: int, source: String = "bfs") -> void:
	# source="paint"이면 다른 페인트통에 의한 전파 → 연쇄 차단
	if source == "paint":
		return
	# 이미 전파 중이면 무한 루프 방지
	if _is_propagating:
		return

	_is_propagating = true

	var direction = cell.gimmick_data.get("direction", "row")
	# grid 참조는 cell에서 직접 얻을 수 없으므로 gimmick_data에 저장된 grid 참조 사용
	var grid = cell.gimmick_data.get("_grid_ref", null)
	if grid == null:
		_is_propagating = false
		cell.clear_gimmick()
		return

	var target_cells: Array
	if direction == "row":
		target_cells = grid.get_row(cell.y)
	else:
		target_cells = grid.get_column(cell.x)

	for target in target_cells:
		if target == cell:
			continue
		var t_handler = GimmickRegistry.get_handler(target.gimmick_type)
		if t_handler.can_recolor(target, new_color):
			var t_old = target.color
			target.color = new_color
			t_handler.on_recolor(target, t_old, new_color, "paint")

	# 항상 리셋 (에러 발생 시에도 영구 잠김 방지)
	_is_propagating = false
	if cell.has_gimmick():
		cell.clear_gimmick()

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
	var dir = cell.gimmick_data.get("direction", "row")
	return {"type": "paint_bucket", "direction": dir, "color": Color(0.9, 0.5, 0.1, 0.85)}
