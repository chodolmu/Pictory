class_name ChapterUnlock
extends RefCounted
## 챕터 해금 조건 유틸리티 (static 함수).
## 이전 챕터 전 스테이지 클리어 시 자동 해금.

static func can_unlock(chapter: int) -> Dictionary:
	var prev_chapter = chapter - 1

	if not _is_chapter_all_cleared(prev_chapter):
		return {
			"can_unlock": false,
			"reason": "챕터 %d을 모두 클리어해야 합니다" % prev_chapter,
		}

	return {"can_unlock": true, "reason": ""}

static func try_unlock(chapter: int) -> bool:
	var check = can_unlock(chapter)
	if not check["can_unlock"]:
		return false
	SaveManager.unlock_chapter(chapter)
	return true

static func _is_chapter_all_cleared(chapter: int) -> bool:
	for i in range(1, 11):
		var stage_id = "ch%02d_s%02d" % [chapter, i]
		if not SaveManager.is_stage_cleared(stage_id):
			return false
	return true
