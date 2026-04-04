extends Node

## 스토리 모드 플로우 컨트롤러 (Autoload).
## CHAPTER_TITLE → PRE_DIALOGUE → GAME → POST_DIALOGUE → RESULT 상태 머신.

enum FlowState {
	IDLE,
	CHAPTER_TITLE,
	PRE_DIALOGUE,
	GAME,
	POST_DIALOGUE,
	RESULT
}

var current_state: FlowState = FlowState.IDLE
var chapter: int = 1
var stage: int = 1
var is_first_visit: bool = false

var _last_game_result: Dictionary = {}

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func start_stage(p_chapter: int, p_stage: int) -> void:
	chapter = p_chapter
	stage = p_stage
	is_first_visit = _check_first_visit()

	if is_first_visit and stage == 1:
		_show_chapter_title()
	else:
		_show_pre_dialogue()

func on_chapter_title_finished() -> void:
	_show_pre_dialogue()

func on_pre_dialogue_finished() -> void:
	_start_game()

func on_game_finished(result: Dictionary) -> void:
	_last_game_result = result
	if result.get("is_clear", false):
		_show_post_dialogue()
	else:
		_show_result(result)

func on_post_dialogue_finished() -> void:
	_show_result(_last_game_result)

# ─────────────────────────────────────────
# 상태 전환
# ─────────────────────────────────────────

func _show_chapter_title() -> void:
	current_state = FlowState.CHAPTER_TITLE
	SceneManager.change_scene("res://scenes/story/chapter_title_screen.tscn", {
		"chapter": chapter,
		"stage": stage
	})

func _show_pre_dialogue() -> void:
	current_state = FlowState.PRE_DIALOGUE
	# 챕터 첫 스테이지에서만 pre 대화 트리거
	if stage != 1:
		_start_game()
		return
	var story_path = "res://resources/story/chapter_%02d/chapter_%02d_pre.json" % [chapter, chapter]
	if not FileAccess.file_exists(story_path):
		_start_game()
		return
	SceneManager.change_scene("res://scenes/story/story_screen.tscn", {
		"chapter": chapter,
		"stage": stage,
		"type": "pre",
		"next_scene": "res://scenes/game/game.tscn",
		"next_params": {
			"mode": "story",
			"stage_id": "ch%02d_s%02d" % [chapter, stage],
			"flow_controlled": true
		}
	})

func _start_game() -> void:
	current_state = FlowState.GAME
	SceneManager.change_scene("res://scenes/game/game.tscn", {
		"mode": "story",
		"stage_id": "ch%02d_s%02d" % [chapter, stage],
		"flow_controlled": true
	})

func _show_post_dialogue() -> void:
	current_state = FlowState.POST_DIALOGUE
	# 챕터 마지막 스테이지(10)에서만 post 대화 트리거
	if stage != 10:
		_show_result(_last_game_result)
		return
	var story_path = "res://resources/story/chapter_%02d/chapter_%02d_post.json" % [chapter, chapter]
	if not FileAccess.file_exists(story_path):
		_show_result(_last_game_result)
		return
	SceneManager.change_scene("res://scenes/story/story_screen.tscn", {
		"chapter": chapter,
		"stage": stage,
		"type": "post",
		"flow_controlled": true
	})

func _show_result(result: Dictionary) -> void:
	current_state = FlowState.RESULT
	# 결과를 stage_select로 전달하며, 결과 팝업은 stage_select에서 처리
	SceneManager.change_scene("res://scenes/main/stage_select.tscn", {
		"show_result": true,
		"result": result,
		"chapter": chapter,
		"stage": stage
	})

# ─────────────────────────────────────────
# 내부 유틸
# ─────────────────────────────────────────

func _check_first_visit() -> bool:
	## 챕터의 어떤 스테이지도 클리어된 적 없으면 첫 방문
	var stage_id = "ch%02d_s%02d" % [chapter, 1]
	return not SaveManager.is_stage_cleared(stage_id)

func _build_result_params() -> Dictionary:
	var r = _last_game_result.duplicate()
	r["chapter"] = chapter
	r["stage"] = stage
	return r
