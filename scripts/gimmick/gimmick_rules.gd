class_name GimmickRules
extends RefCounted

## 기믹 상호작용 규칙 유틸리티.
## 페인트통 전파, 번짐 감염, 라인 색 기여 등 조합 판단을 통합 제공.

## 페인트통 전파 시 대상 셀 리컬러 가능 여부
static func can_paint_propagate_to(cell) -> bool:
	var handler = GimmickRegistry.get_handler(cell.gimmick_type)
	return handler.can_recolor(cell, -1)

## 번짐 감염 시 대상 셀 감염 가능 여부
static func can_spread_infect(cell, spread_color: int) -> bool:
	if cell.color == spread_color:
		return false
	if cell.gimmick_type == GimmickBase.GimmickType.STONE:
		return false
	if cell.gimmick_type == GimmickBase.GimmickType.LOCKED:
		return false
	var handler = GimmickRegistry.get_handler(cell.gimmick_type)
	return handler.can_recolor(cell, spread_color)

## 라인 완성 판정에서 셀의 색 기여값
## -99 = 라인 불완성 강제 (돌 칸)
## -2  = 와일드카드 (무지개)
## >=0 = 실제 색
static func get_line_color(cell) -> int:
	if cell.gimmick_type == GimmickBase.GimmickType.STONE:
		return -99
	var handler = GimmickRegistry.get_handler(cell.gimmick_type)
	if handler.is_bfs_wildcard(cell):
		return -2
	return cell.color
