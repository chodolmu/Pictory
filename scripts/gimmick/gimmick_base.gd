class_name GimmickBase
extends RefCounted

## 모든 기믹 핸들러가 상속하는 베이스 클래스.
## 기본 구현은 "기믹 없음" 동작(통과/허용/아무것도 안 함).

enum GimmickType {
	NONE         = 0,
	# 공용 (M 시리즈)
	LOCKED       = 1,
	STONE        = 2,
	ICE          = 3,
	RAINBOW      = 4,
	ANCHOR       = 5,
	PAINT_BUCKET = 6,
	COIN         = 7,
	CHAIN_MULT   = 8,
	# 스토리 전용 (S 시리즈)
	STAR         = 10,
	SPREAD       = 11,
	FADE         = 12,
	# 무한 전용
	TIME         = 20,
	POISON       = 21,
}

# ─────────────────────────────────────────
# 라이프사이클 훅 (virtual methods)
# ─────────────────────────────────────────

## BFS 리컬러 허용 여부. false이면 셀 색상 유지.
func can_recolor(cell, new_color: int) -> bool:
	return true

## 리컬러 완료 직후 호출.
func on_recolor(cell, old_color: int, new_color: int) -> void:
	pass

## BFS 탐색 시 해당 셀로 진입 가능 여부.
func can_bfs_traverse(cell, from_cell) -> bool:
	return true

## BFS 색 비교 시 와일드카드(모든 색 매칭) 여부.
func is_bfs_wildcard(cell) -> bool:
	return false

## 라인 파괴 대상 판정.
func can_destroy(cell) -> bool:
	return true

## 파괴 처리. 반환: {destroyed: bool, rewards: Dictionary, effects: Array}
func on_destroy(cell) -> Dictionary:
	return {"destroyed": true, "rewards": {}, "effects": []}

## 중력 낙하 여부. false이면 고정.
func on_gravity(cell, grid) -> bool:
	return true

## 턴 종료 시 호출.
func on_turn(cell, turn_number: int) -> void:
	pass

## 렌더링 설정 반환.
func get_visual_config(cell) -> Dictionary:
	return {"type": "none"}
