class_name ChapterUnlock
extends RefCounted
## 챕터 해금 조건/비용 유틸리티 (static 함수).

const CHAPTER_COSTS: Dictionary = {
	2: 500,
	3: 800,
	4: 1200,
	5: 1600,
	6: 2000,
	7: 2500,
	8: 3000,
	9: 3500,
	10: 4000
}

static func get_unlock_cost(chapter: int) -> int:
	return CHAPTER_COSTS.get(chapter, 0)

static func can_unlock(chapter: int) -> Dictionary:
	var cost = get_unlock_cost(chapter)
	var prev_chapter = chapter - 1

	if not _is_chapter_all_cleared(prev_chapter):
		return {
			"can_unlock": false,
			"reason": "챕터 %d을 모두 클리어해야 합니다" % prev_chapter,
			"cost": cost
		}

	if SaveManager.get_currency() < cost:
		return {
			"can_unlock": false,
			"reason": "코인이 부족합니다 (%d/%d)" % [SaveManager.get_currency(), cost],
			"cost": cost
		}

	return {"can_unlock": true, "reason": "", "cost": cost}

static func try_unlock(chapter: int) -> bool:
	var check = can_unlock(chapter)
	if not check["can_unlock"]:
		return false
	SaveManager.spend_currency(check["cost"])
	SaveManager.unlock_chapter(chapter)
	return true

static func _is_chapter_all_cleared(chapter: int) -> bool:
	for i in range(1, 11):
		var stage_id = "ch%02d_s%02d" % [chapter, i]
		if not SaveManager.is_stage_cleared(stage_id):
			return false
	return true
