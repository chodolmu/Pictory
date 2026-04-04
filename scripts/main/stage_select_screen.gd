class_name StageSelectScreen
extends Control

const StageButtonScene = preload("res://scenes/ui/stage_button.tscn")
const ChapterUnlockScript = preload("res://scripts/data/chapter_unlock.gd")

@onready var _back_btn: Button = $VBox/Header/BackButton
@onready var _chapter_tabs: HBoxContainer = $VBox/ChapterTabContainer
@onready var _stage_grid: GridContainer = $VBox/ScrollContainer/StageGrid
@onready var _unlock_info_label: Label = $VBox/UnlockInfoLabel
@onready var _unlock_btn: Button = $VBox/UnlockButton
@onready var _stage_confirm_popup = $StageConfirmPopup

var current_chapter: int = 1

func _ready() -> void:
	_back_btn.pressed.connect(_on_back)
	_unlock_btn.pressed.connect(_on_unlock_button_pressed)
	_stage_confirm_popup.start_requested.connect(_on_start_stage)
	_setup_chapter_tabs()
	_load_chapter(current_chapter)

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
	SceneManager.change_scene("res://scenes/game/game.tscn", {
		"mode": "story",
		"stage_id": config.stage_id
	})

func _on_back() -> void:
	SceneManager.change_scene("res://scenes/main/main_menu.tscn")

func _on_unlock_button_pressed() -> void:
	var next_chapter = current_chapter + 1
	if ChapterUnlockScript.try_unlock(next_chapter):
		_load_chapter(next_chapter)
