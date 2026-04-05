class_name MainMenu
extends Control

## 메인 화면 — 스티커북 배경, 챕터 네비게이션, 시작, 색칠, 업적/동료/패션/상점.

const StagePreviewPopupScene = "res://scenes/ui/stage_preview_popup.tscn"
const ProfilePopupScene = "res://scenes/ui/profile_popup.tscn"
const GemShopScene = "res://scenes/ui/gem_shop.tscn"
const _OPTIONS_POPUP_SCENE = "res://scenes/ui/options_popup.tscn"
const _CONFIRM_QUIT_POPUP_SCENE = "res://scenes/ui/confirm_quit_popup.tscn"

# ── 탑바 ──
@onready var _player_icon: Panel = $MarginContainer/VBox/TopBar/PlayerInfoContainer/PlayerIcon
@onready var _nickname_label: Label = $MarginContainer/VBox/TopBar/PlayerInfoContainer/NicknameLabel
@onready var _chapter_label: Label = $MarginContainer/VBox/TopBar/ChapterLabel
@onready var _gem_label: Label = $MarginContainer/VBox/TopBar/GemLabel
@onready var _star_label: Label = $MarginContainer/VBox/TopBar/StarLabel
@onready var _settings_btn: Button = $MarginContainer/VBox/TopBar/SettingsButton

# ── 하트 ──
@onready var _heart_label: Label = $MarginContainer/VBox/HeartContainer/HeartLabel
@onready var _recovery_label: Label = $MarginContainer/VBox/HeartContainer/RecoveryLabel

# ── 스티커 영역 ──
@onready var _stage_progress_label: Label = $MarginContainer/VBox/StageProgressLabel
@onready var _sticker_book = $MarginContainer/VBox/StickerArea/StickerBook
@onready var _chapter_prev_btn: Button = $MarginContainer/VBox/StickerArea/ChapterPrevButton
@onready var _chapter_next_btn: Button = $MarginContainer/VBox/StickerArea/ChapterNextButton

# ── 버튼 ──
@onready var _start_btn: Button = $MarginContainer/VBox/ButtonRow/StartButton
@onready var _color_btn: Button = $MarginContainer/VBox/ButtonRow/ColorButton

# ── 하단 ──
@onready var _achievements_btn: Button = $MarginContainer/VBox/BottomButtons/AchievementsButton
@onready var _companion_btn: Button = $MarginContainer/VBox/BottomButtons/CompanionButton
@onready var _fashion_btn: Button = $MarginContainer/VBox/BottomButtons/FashionButton
@onready var _shop_btn: Button = $MarginContainer/VBox/BottomButtons/ShopButton

var _options_popup = null
var _confirm_quit_popup = null
var _stage_preview_popup = null

var current_chapter: int = 1

func _ready() -> void:
	_player_icon.gui_input.connect(_on_player_icon_input)
	_settings_btn.pressed.connect(_on_settings)
	_chapter_prev_btn.pressed.connect(_on_chapter_prev)
	_chapter_next_btn.pressed.connect(_on_chapter_next)
	_start_btn.pressed.connect(_on_start)
	_color_btn.pressed.connect(_on_color_sticker)
	_achievements_btn.pressed.connect(_on_achievements)
	_companion_btn.pressed.connect(_on_companion)
	_fashion_btn.pressed.connect(_on_fashion)
	_shop_btn.pressed.connect(_on_shop)

	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	PlayerProfile.nickname_changed.connect(_update_player_info)
	GemManager.gems_changed.connect(_on_gems_changed)
	HeartManager.hearts_changed.connect(_on_hearts_changed)
	StarManager.stars_changed.connect(_on_stars_changed)

	_update_player_info()
	_update_gem_display()
	_update_star_display()
	_update_heart_display()
	_update_achievement_badge()
	_load_chapter(_determine_current_chapter())

func _process(_delta: float) -> void:
	if not HeartManager.is_full():
		var secs = HeartManager.get_recovery_time_remaining()
		var m = int(secs) / 60
		var s = int(secs) % 60
		_recovery_label.text = "(%02d:%02d)" % [m, s]
	else:
		_recovery_label.text = ""

# ─────────────────────────────────────────
# 플레이어 정보
# ─────────────────────────────────────────

func _update_player_info(_name: String = "") -> void:
	_nickname_label.text = PlayerProfile.get_nickname()
	_update_player_icon()

func _update_player_icon() -> void:
	var icon_id = CollectionManager.get_selected_icon()
	var icon_data = CollectionManager.get_icon_data(icon_id)
	var icon_color = Color("#E8A87C")
	if not icon_data.is_empty():
		icon_color = Color(icon_data.get("color", "#E8A87C"))
	var style = StyleBoxFlat.new()
	style.bg_color = icon_color
	style.corner_radius_top_left = 27
	style.corner_radius_top_right = 27
	style.corner_radius_bottom_left = 27
	style.corner_radius_bottom_right = 27
	_player_icon.add_theme_stylebox_override("panel", style)

func _update_gem_display() -> void:
	_gem_label.text = "💎 %d" % GemManager.get_balance()

func _update_star_display() -> void:
	_star_label.text = "⭐ %d" % StarManager.get_balance()
	_update_color_button()

func _update_heart_display() -> void:
	var cur = HeartManager.current_hearts
	var max_h = HeartManager.MAX_HEARTS
	_heart_label.text = "♥".repeat(cur) + "♡".repeat(max_h - cur)

func _update_color_button() -> void:
	var has_stars = StarManager.get_balance() > 0
	var has_remaining = _sticker_book and _sticker_book.get_remaining_count() > 0
	_color_btn.disabled = not (has_stars and has_remaining)
	_color_btn.text = "⭐ 색칠하기"

func _on_gems_changed(_current: int) -> void:
	_update_gem_display()

func _on_hearts_changed(_current: int, _max: int) -> void:
	_update_heart_display()

func _on_stars_changed(_current: int) -> void:
	_update_star_display()

# ─────────────────────────────────────────
# 챕터 네비게이션
# ─────────────────────────────────────────

func _determine_current_chapter() -> int:
	for ch in range(1, 11):
		for s in range(1, 11):
			var stage_id = "ch%02d_s%02d" % [ch, s]
			if not SaveManager.is_stage_cleared(stage_id):
				return ch
	return 10

func _load_chapter(chapter: int) -> void:
	current_chapter = chapter
	_chapter_label.text = "Chapter %d" % chapter
	_update_chapter_buttons()
	_update_stage_progress()
	# 스티커북 갱신 (await 포함 — 스티커 생성 후 버튼 갱신)
	if _sticker_book:
		await _sticker_book.setup_chapter(current_chapter)
	_update_color_button()

func _update_chapter_buttons() -> void:
	_chapter_prev_btn.disabled = (current_chapter <= 1)
	var next_unlocked = SaveManager.is_chapter_unlocked(current_chapter + 1)
	_chapter_next_btn.disabled = (current_chapter >= 10 or not next_unlocked)

func _update_stage_progress() -> void:
	var cleared = 0
	for s in range(1, 11):
		var stage_id = "ch%02d_s%02d" % [current_chapter, s]
		if SaveManager.is_stage_cleared(stage_id):
			cleared += 1
	_stage_progress_label.text = "%d / 10 클리어" % cleared

func _on_chapter_prev() -> void:
	if current_chapter > 1:
		_load_chapter(current_chapter - 1)

func _on_chapter_next() -> void:
	if current_chapter < 10 and SaveManager.is_chapter_unlocked(current_chapter + 1):
		_load_chapter(current_chapter + 1)

# ─────────────────────────────────────────
# 색칠하기 (별 소모)
# ─────────────────────────────────────────

func _on_color_sticker() -> void:
	if StarManager.get_balance() <= 0:
		return
	if _sticker_book and _sticker_book.get_remaining_count() > 0:
		if StarManager.spend(1):
			_sticker_book.color_next_sticker()
			_update_color_button()

# ─────────────────────────────────────────
# 시작
# ─────────────────────────────────────────

func _get_next_stage() -> String:
	for s in range(1, 11):
		var stage_id = "ch%02d_s%02d" % [current_chapter, s]
		if not SaveManager.is_stage_cleared(stage_id):
			return stage_id
	return ""

func _on_start() -> void:
	var stage_id = _get_next_stage()
	if stage_id == "":
		return
	if HeartManager.current_hearts <= 0:
		return
	_show_stage_preview(stage_id)

func _show_stage_preview(stage_id: String) -> void:
	if _stage_preview_popup and is_instance_valid(_stage_preview_popup):
		_stage_preview_popup.queue_free()
	_stage_preview_popup = load(StagePreviewPopupScene).instantiate()
	get_tree().root.add_child(_stage_preview_popup)
	_stage_preview_popup.show_preview(stage_id)
	_stage_preview_popup.start_requested.connect(_on_preview_start)
	_stage_preview_popup.cancelled.connect(func():
		if _stage_preview_popup:
			_stage_preview_popup.queue_free()
			_stage_preview_popup = null
	)

func _on_preview_start(stage_id: String) -> void:
	if _stage_preview_popup:
		_stage_preview_popup.queue_free()
		_stage_preview_popup = null
	StoryFlowController.start_stage(current_chapter, _get_stage_number(stage_id))

func _get_stage_number(stage_id: String) -> int:
	var parts = stage_id.split("_")
	if parts.size() >= 2:
		return parts[1].substr(1).to_int()
	return 1

# ─────────────────────────────────────────
# 프로필 팝업
# ─────────────────────────────────────────

func _on_player_icon_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_profile_popup()
	elif event is InputEventScreenTouch and event.pressed:
		_show_profile_popup()

func _show_profile_popup() -> void:
	var popup = load(ProfilePopupScene).instantiate()
	get_tree().root.add_child(popup)

# ─────────────────────────────────────────
# 하단 버튼
# ─────────────────────────────────────────

func _on_achievements() -> void:
	var popup = load("res://scenes/ui/achievement_popup.tscn").instantiate()
	get_tree().root.add_child(popup)
	while AchievementManager.has_pending_popups():
		popup.show_achievement(AchievementManager.pop_pending_popup())

func _on_companion() -> void:
	_free_popups()
	SceneManager.change_scene("res://scenes/ui/collection_tab_imagen.tscn")

func _on_fashion() -> void:
	_free_popups()
	SceneManager.change_scene("res://scenes/ui/collection_tab_icon.tscn")

func _on_shop() -> void:
	_free_popups()
	SceneManager.change_scene(GemShopScene)

func _on_settings() -> void:
	var popup = _get_or_create_popup("_options_popup", _OPTIONS_POPUP_SCENE)
	popup.show_popup()

func _on_achievement_unlocked(_id: String) -> void:
	_update_achievement_badge()

func _update_achievement_badge() -> void:
	var unclaimed = AchievementManager.get_unclaimed_count()
	if _achievements_btn:
		_achievements_btn.text = "업적" if unclaimed == 0 else "업적 (%d)" % unclaimed

# ─────────────────────────────────────────
# 유틸
# ─────────────────────────────────────────

func _get_or_create_popup(var_ref: String, scene_path: String) -> Node:
	var popup = get(var_ref)
	if popup == null or not is_instance_valid(popup):
		popup = load(scene_path).instantiate()
		get_tree().root.add_child(popup)
		set(var_ref, popup)
	return popup

func _free_popups() -> void:
	if _options_popup and is_instance_valid(_options_popup):
		_options_popup.queue_free()
		_options_popup = null
	if _confirm_quit_popup and is_instance_valid(_confirm_quit_popup):
		_confirm_quit_popup.queue_free()
		_confirm_quit_popup = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		var popup = _get_or_create_popup("_confirm_quit_popup", _CONFIRM_QUIT_POPUP_SCENE)
		popup.show_popup()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var popup = _get_or_create_popup("_confirm_quit_popup", _CONFIRM_QUIT_POPUP_SCENE)
		popup.show_popup()
