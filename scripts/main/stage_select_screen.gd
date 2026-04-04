class_name StageSelectScreen
extends Control

const StageButtonScene = preload("res://scenes/ui/stage_button.tscn")
const ChapterUnlockScript = preload("res://scripts/data/chapter_unlock.gd")
const ResultPopupScene = preload("res://scenes/ui/result_popup.tscn")

@onready var _back_btn: Button = $VBox/Header/BackButton
@onready var _chapter_tabs: HBoxContainer = $VBox/ChapterTabContainer
@onready var _stage_grid: GridContainer = $VBox/ScrollContainer/StageGrid
@onready var _unlock_info_label: Label = $VBox/UnlockInfoLabel
@onready var _unlock_btn: Button = $VBox/UnlockButton
@onready var _stage_confirm_popup = $StageConfirmPopup
@onready var _fill_rect: ColorRect = $FillRect

var current_chapter: int = 1
var _result_chapter: int = 1
var _result_stage: int = 1

func _ready() -> void:
	_back_btn.pressed.connect(_on_back)
	_unlock_btn.pressed.connect(_on_unlock_button_pressed)
	_stage_confirm_popup.start_requested.connect(_on_start_stage)

	var params = SceneManager.get_params()
	var ch = params.get("chapter", 1)
	var st = params.get("stage", 1)
	_setup_chapter_tabs()
	_load_chapter(ch)

	if params.get("show_result", false):
		_result_chapter = ch
		_result_stage = st
		# 한 프레임 뒤에 팝업 — 씬 로드 완료 후
		call_deferred("_show_result_popup", params.get("result", {}))

func _show_result_popup(result: Dictionary) -> void:
	var popup = ResultPopupScene.instantiate()
	add_child(popup)
	var is_clear: bool = result.get("is_clear", false)
	var stars: int = result.get("stars", 0)
	var score: int = result.get("score", 0)
	var stage_id: String = result.get("stage_id", "")

	if is_clear:
		var max_stages = 10
		var has_next = _result_stage < max_stages
		popup.show_clear(stars, score, 0, has_next)
		popup.next_stage_requested.connect(_on_result_next_stage)
	else:
		popup.show_game_over(score, {})
	popup.retry_requested.connect(func():
		popup.queue_free()
		StoryFlowController.start_stage(_result_chapter, _result_stage)
	)
	popup.main_menu_requested.connect(func():
		popup.queue_free()
	)

func _on_result_next_stage() -> void:
	var next = _result_stage + 1
	if next > 10:
		# 챕터 완료 처리
		pass
	else:
		StoryFlowController.start_stage(_result_chapter, next)

func _load_chapter(chapter: int) -> void:
	current_chapter = chapter
	# 스테이지 그리드 클리어
	for child in _stage_grid.get_children():
		child.queue_free()
	await get_tree().process_frame

	var stages = LevelLoader.load_chapter_stages(chapter)
	for config in stages:
		var btn = StageButtonScene.instantiate()
		var save = SaveManager.get_stage_data(config.stage_id)
		var s_stars = save.get("stars", 0) if not save.is_empty() else 0
		var locked = _is_stage_locked(config)
		btn.setup(config.stage_id, config.stage_number, s_stars, locked)
		btn.stage_selected.connect(_on_stage_selected)
		_stage_grid.add_child(btn)

	_update_chapter_tabs()
	_update_unlock_info()
	_update_fill_bg(chapter)

func _is_stage_locked(config) -> bool:
	if config.stage_number == 1:
		return false
	var prev_id = "ch%02d_s%02d" % [config.chapter, config.stage_number - 1]
	var prev_save = SaveManager.get_stage_data(prev_id)
	return prev_save.is_empty() or prev_save.get("stars", 0) == 0

func _setup_chapter_tabs() -> void:
	for child in _chapter_tabs.get_children():
		child.queue_free()
	for i in range(1, 11):
		var tab_btn = Button.new()
		tab_btn.text = "챕터 %d" % i
		var unlocked = SaveManager.is_chapter_unlocked(i)
		tab_btn.disabled = not unlocked
		var ch = i
		tab_btn.pressed.connect(func(): _load_chapter(ch))
		_chapter_tabs.add_child(tab_btn)

func _update_chapter_tabs() -> void:
	var tabs = _chapter_tabs.get_children()
	for i in range(tabs.size()):
		var tab = tabs[i]
		var ch = i + 1
		tab.disabled = not SaveManager.is_chapter_unlocked(ch)
		tab.flat = (ch != current_chapter)

func _update_unlock_info() -> void:
	var next_chapter = current_chapter + 1
	if next_chapter > 10 or SaveManager.is_chapter_unlocked(next_chapter):
		_unlock_info_label.visible = false
		_unlock_btn.visible = false
		return
	var check = ChapterUnlockScript.can_unlock(next_chapter)
	_unlock_info_label.visible = true
	if check["can_unlock"]:
		_unlock_info_label.text = "다음 챕터 해금 가능! (%d 코인)" % check["cost"]
		_unlock_btn.visible = true
	else:
		_unlock_info_label.text = check["reason"]
		_unlock_btn.visible = false

func _on_stage_selected(s_id: String) -> void:
	var config = LevelLoader.load_stage(s_id)
	if config:
		_stage_confirm_popup.show_popup(config)

func _on_start_stage(config) -> void:
	StoryFlowController.start_stage(config.chapter, config.stage_number)

func _update_fill_bg(chapter: int) -> void:
	# 클리어된 스테이지 수에 따라 아래에서 위로 배경 채움
	var total_stages := 10
	var cleared := 0
	for s in range(1, total_stages + 1):
		var sid = "ch%02d_s%02d" % [chapter, s]
		var save = SaveManager.get_stage_data(sid)
		if not save.is_empty() and save.get("stars", 0) > 0:
			cleared += 1

	var ratio := float(cleared) / float(total_stages)
	# anchor_top을 조절해서 아래에서 위로 채워지게
	_fill_rect.anchor_top = 1.0 - ratio
	_fill_rect.anchor_bottom = 1.0

func _on_back() -> void:
	SceneManager.change_scene("res://scenes/main/main_menu.tscn")

func _on_unlock_button_pressed() -> void:
	var next_chapter = current_chapter + 1
	if ChapterUnlockScript.try_unlock(next_chapter):
		_load_chapter(next_chapter)
