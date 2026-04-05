class_name StageSelectScreen
extends Control

const ResultPopupScene = preload("res://scenes/ui/result_popup.tscn")
const ChapterUnlockScript = preload("res://scripts/data/chapter_unlock.gd")
const InfinityPopupScene = "res://scenes/ui/infinity_confirm_popup.tscn"
const OptionsPopupScene = "res://scenes/ui/options_popup.tscn"

# ── 상단 바 ──
@onready var _player_icon: Panel = $MarginContainer/VBox/TopBar/PlayerIcon
@onready var _nickname_label: Label = $MarginContainer/VBox/TopBar/NicknameLabel
@onready var _currency_label: Label = $MarginContainer/VBox/TopBar/CurrencyLabel
@onready var _settings_btn: Button = $MarginContainer/VBox/TopBar/SettingsButton

# ── 챕터 바 ──
@onready var _chapter_prev_btn: Button = $MarginContainer/VBox/ChapterBar/ChapterPrevButton
@onready var _chapter_next_btn: Button = $MarginContainer/VBox/ChapterBar/ChapterNextButton
@onready var _chapter_label: Label = $MarginContainer/VBox/ChapterBar/ChapterLabel

# ── 노드맵 ──
@onready var _node_map_scroll: ScrollContainer = $MarginContainer/VBox/NodeMapScroll
@onready var _node_map_container: Control = $MarginContainer/VBox/NodeMapScroll/NodeMapContainer

# ── 해금 ──
@onready var _unlock_info_label: Label = $MarginContainer/VBox/UnlockInfoLabel
@onready var _unlock_btn: Button = $MarginContainer/VBox/UnlockButton

# ── 하단 네비 ──
@onready var _infinity_btn: Button = $MarginContainer/VBox/BottomNav/InfinityButton
@onready var _collection_btn: Button = $MarginContainer/VBox/BottomNav/CollectionButton
@onready var _shop_btn: Button = $MarginContainer/VBox/BottomNav/ShopButton
@onready var _achievements_btn: Button = $MarginContainer/VBox/BottomNav/AchievementsButton

var _stage_confirm_popup = null
var _infinity_confirm_popup = null
var _options_popup = null

var current_chapter: int = 1
var _result_chapter: int = 1
var _result_stage: int = 1

# 노드맵 설정
const NODE_RADIUS: float = 20.0
const NODE_GAP_Y: float = 80.0
const MAP_TOP_MARGIN: float = 50.0
const LINE_COLOR: Color = Color(0.3, 0.3, 0.5, 0.6)
const LINE_WIDTH: float = 2.0

const NODE_COLORS = {
	"locked": Color(0.25, 0.25, 0.3),
	"available": Color(0.3, 0.55, 0.9),
	"cleared_1": Color(0.6, 0.5, 0.2),
	"cleared_2": Color(0.75, 0.65, 0.15),
	"cleared_3": Color(0.95, 0.85, 0.1),
}

# 캐릭터 마커
var _character_marker: Panel = null
var _node_positions: Array[Vector2] = []  # positions[i] = 화면상 위치 (i=0 → 최상단 노드=10스테이지)
var _stage_count: int = 0

# 드래그 스크롤
var _dragging: bool = false
var _drag_start_y: float = 0.0
var _scroll_start: int = 0

func _ready() -> void:
	# 상단
	_settings_btn.pressed.connect(_on_settings)
	# 챕터
	_chapter_prev_btn.pressed.connect(_on_chapter_prev)
	_chapter_next_btn.pressed.connect(_on_chapter_next)
	_unlock_btn.pressed.connect(_on_unlock_button_pressed)
	# 하단 네비
	_infinity_btn.pressed.connect(_on_infinity)
	_collection_btn.pressed.connect(_on_collection)
	_shop_btn.pressed.connect(_on_shop)
	_achievements_btn.pressed.connect(_on_achievements)
	# 플레이어 정보
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	_update_player_info()
	_update_currency_display()
	_update_achievement_badge()

	var params = SceneManager.get_params()
	var ch = params.get("chapter", 1)
	_load_chapter(ch)

	if params.get("show_result", false):
		_result_chapter = ch
		_result_stage = params.get("stage", 1)
		call_deferred("_show_result_popup", params.get("result", {}))

# ─────────────────────────────────────────
# 플레이어 정보 (기존 메인 메뉴 기능)
# ─────────────────────────────────────────

func _update_player_info() -> void:
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
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	_player_icon.add_theme_stylebox_override("panel", style)

func _update_currency_display() -> void:
	_currency_label.text = "💰 %d" % SaveManager.get_currency()

func _on_achievement_unlocked(_id: String) -> void:
	_update_achievement_badge()

func _update_achievement_badge() -> void:
	var unclaimed = AchievementManager.get_unclaimed_count()
	if _achievements_btn:
		_achievements_btn.text = "업적" if unclaimed == 0 else "업적(%d)" % unclaimed

# ─────────────────────────────────────────
# 하단 네비 (기존 메인 메뉴 기능)
# ─────────────────────────────────────────

func _on_infinity() -> void:
	var popup = _get_or_create_popup("_infinity_confirm_popup", InfinityPopupScene)
	popup.show_popup()

func _on_settings() -> void:
	var popup = _get_or_create_popup("_options_popup", OptionsPopupScene)
	popup.show_popup()

func _on_shop() -> void:
	_free_popups()
	SceneManager.change_scene("res://scenes/ui/shop.tscn")

func _on_collection() -> void:
	_free_popups()
	SceneManager.change_scene("res://scenes/ui/collection.tscn")

func _on_achievements() -> void:
	var popup = load("res://scenes/ui/achievement_popup.tscn").instantiate()
	get_tree().root.add_child(popup)
	while AchievementManager.has_pending_popups():
		popup.show_achievement(AchievementManager.pop_pending_popup())

func _get_or_create_popup(var_ref: String, scene_path: String) -> Node:
	var popup = get(var_ref)
	if popup == null or not is_instance_valid(popup):
		popup = load(scene_path).instantiate()
		get_tree().root.add_child(popup)
		set(var_ref, popup)
	return popup

func _free_popups() -> void:
	for ref in ["_infinity_confirm_popup", "_options_popup", "_stage_confirm_popup"]:
		var popup = get(ref)
		if popup != null and is_instance_valid(popup):
			popup.queue_free()
			set(ref, null)

# ─────────────────────────────────────────
# 노드맵
# ─────────────────────────────────────────

func _load_chapter(chapter: int) -> void:
	current_chapter = chapter
	_chapter_label.text = "챕터 %d" % chapter
	_update_chapter_buttons()
	_build_node_map(chapter)
	_update_unlock_info()
	_update_currency_display()

func _build_node_map(chapter: int) -> void:
	for child in _node_map_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	var stages = LevelLoader.load_chapter_stages(chapter)
	_stage_count = stages.size()
	var map_height = MAP_TOP_MARGIN + _stage_count * NODE_GAP_Y + 60.0
	_node_map_container.custom_minimum_size = Vector2(390, maxf(map_height, 900))

	var vp_width = get_viewport_rect().size.x
	if vp_width <= 0:
		vp_width = 390.0

	# 캐릭터 위치: 마지막으로 클리어한 스테이지
	var last_cleared_idx = _find_last_cleared_stage(stages)

	# 노드 위치 계산
	_node_positions.clear()
	for i in range(_stage_count):
		var stage_idx = _stage_count - 1 - i
		var x_offset = 25.0 if (stage_idx % 2 == 0) else -25.0
		var px = vp_width / 2.0 + x_offset
		var py = MAP_TOP_MARGIN + i * NODE_GAP_Y
		_node_positions.append(Vector2(px, py))

	# 연결선
	var line_drawer = Control.new()
	line_drawer.name = "LineDrawer"
	line_drawer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line_drawer.custom_minimum_size = _node_map_container.custom_minimum_size
	_node_map_container.add_child(line_drawer)
	var lp = _node_positions.duplicate()
	line_drawer.draw.connect(func():
		for i in range(lp.size() - 1):
			line_drawer.draw_line(lp[i], lp[i + 1], LINE_COLOR, LINE_WIDTH, true)
	)

	# 노드 버튼 생성
	for i in range(_stage_count):
		var stage_idx = _stage_count - 1 - i
		var config = stages[stage_idx]
		var save = SaveManager.get_stage_data(config.stage_id)
		var stars = save.get("stars", 0) if not save.is_empty() else 0
		var locked = _is_stage_locked(config)
		var pos = _node_positions[i]
		var is_current_target = (stage_idx == last_cleared_idx + 1) if last_cleared_idx < _stage_count - 1 else false

		var node_btn = _create_node_button(config, stars, locked, pos, is_current_target)
		_node_map_container.add_child(node_btn)

	# 캐릭터 마커: 마지막 클리어 노드에 배치
	var char_pos_idx = _stage_count - 1 - maxi(last_cleared_idx, 0)
	_create_character_marker(_node_positions[char_pos_idx])

	# 스크롤: 캐릭터가 보이도록
	await get_tree().process_frame
	var scroll_target = int(_node_positions[char_pos_idx].y - _node_map_scroll.size.y / 2.0)
	_node_map_scroll.scroll_vertical = clampi(scroll_target, 0, int(_node_map_container.custom_minimum_size.y))

	line_drawer.queue_redraw()

func _find_last_cleared_stage(stages: Array) -> int:
	var highest_cleared = -1
	for i in range(stages.size()):
		var save = SaveManager.get_stage_data(stages[i].stage_id)
		if not save.is_empty() and save.get("stars", 0) > 0:
			highest_cleared = i
	return highest_cleared

func _create_character_marker(pos: Vector2) -> void:
	_character_marker = Panel.new()
	_character_marker.name = "CharacterMarker"
	var marker_size = NODE_RADIUS * 1.6
	_character_marker.size = Vector2(marker_size, marker_size)
	_character_marker.position = Vector2(
		pos.x - marker_size / 2.0,
		pos.y - NODE_RADIUS - marker_size - 4.0
	)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.90, 0.80)
	var r = int(marker_size / 2.0)
	style.corner_radius_top_left = r
	style.corner_radius_top_right = r
	style.corner_radius_bottom_left = r
	style.corner_radius_bottom_right = r
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.8, 0.7, 0.5)
	_character_marker.add_theme_stylebox_override("panel", style)
	_node_map_container.add_child(_character_marker)
	_animate_character_bounce()

func _animate_character_bounce() -> void:
	if _character_marker == null or not is_instance_valid(_character_marker):
		return
	var base_y = _character_marker.position.y
	var tween = create_tween().set_loops()
	tween.tween_property(_character_marker, "position:y", base_y - 6.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_character_marker, "position:y", base_y, 0.5).set_trans(Tween.TRANS_SINE)

func _move_character_to_node(target_pos: Vector2, callback: Callable = Callable()) -> void:
	if _character_marker == null or not is_instance_valid(_character_marker):
		return
	var marker_size = _character_marker.size.x
	var target = Vector2(
		target_pos.x - marker_size / 2.0,
		target_pos.y - NODE_RADIUS - marker_size - 4.0
	)
	var tween = create_tween()
	tween.tween_property(_character_marker, "position", target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if callback.is_valid():
		tween.tween_callback(callback)

func _create_node_button(config, stars: int, locked: bool, pos: Vector2, is_current_target: bool) -> Control:
	var container = Control.new()
	container.position = Vector2(pos.x - NODE_RADIUS - 8, pos.y - NODE_RADIUS - 8)
	container.size = Vector2((NODE_RADIUS + 8) * 2, (NODE_RADIUS + 8) * 2)

	var panel = Panel.new()
	panel.position = Vector2(8, 8)
	panel.size = Vector2(NODE_RADIUS * 2, NODE_RADIUS * 2)
	var style = StyleBoxFlat.new()
	var r = int(NODE_RADIUS)
	style.corner_radius_top_left = r
	style.corner_radius_top_right = r
	style.corner_radius_bottom_left = r
	style.corner_radius_bottom_right = r

	if locked:
		style.bg_color = NODE_COLORS["locked"]
	elif stars == 0:
		style.bg_color = NODE_COLORS["available"]
	elif stars == 1:
		style.bg_color = NODE_COLORS["cleared_1"]
	elif stars == 2:
		style.bg_color = NODE_COLORS["cleared_2"]
	else:
		style.bg_color = NODE_COLORS["cleared_3"]

	if is_current_target and not locked:
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = Color(1.0, 1.0, 1.0, 0.8)

	panel.add_theme_stylebox_override("panel", style)
	container.add_child(panel)

	var lbl = Label.new()
	lbl.text = str(config.stage_number)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(8, 8)
	lbl.size = Vector2(NODE_RADIUS * 2, NODE_RADIUS * 2)
	lbl.add_theme_font_size_override("font_size", 13)
	if locked:
		lbl.modulate = Color(0.5, 0.5, 0.5)
	container.add_child(lbl)

	if stars > 0:
		var star_lbl = Label.new()
		star_lbl.text = "★".repeat(stars)
		star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_lbl.position = Vector2(8 - 6, 8 + NODE_RADIUS * 2 + 1)
		star_lbl.size = Vector2(NODE_RADIUS * 2 + 12, 16)
		star_lbl.add_theme_font_size_override("font_size", 9)
		star_lbl.modulate = Color(1.0, 0.85, 0.0)
		container.add_child(star_lbl)

	var btn = Button.new()
	btn.position = Vector2.ZERO
	btn.size = container.size
	btn.flat = true
	btn.modulate = Color(1, 1, 1, 0)
	if not locked:
		# 클릭 시: 캐릭터 이동 → 스테이지 진입
		var stage_id = config.stage_id
		var stage_num = config.stage_number
		var node_pos = pos
		btn.pressed.connect(_on_node_clicked.bind(stage_id, stage_num, node_pos))
	container.add_child(btn)

	return container

func _on_node_clicked(stage_id: String, stage_num: int, node_pos: Vector2) -> void:
	# 캐릭터를 해당 노드로 이동시킨 후 스테이지 진입
	_move_character_to_node(node_pos, func():
		_open_stage_confirm(stage_id)
	)

func _open_stage_confirm(stage_id: String) -> void:
	var config = LevelLoader.load_stage(stage_id)
	if config == null:
		return
	if _stage_confirm_popup == null or not is_instance_valid(_stage_confirm_popup):
		_stage_confirm_popup = load("res://scenes/ui/stage_confirm_popup.tscn").instantiate()
		get_tree().root.add_child(_stage_confirm_popup)
		_stage_confirm_popup.start_requested.connect(_on_start_stage)
	_stage_confirm_popup.show_popup(config)

func _on_start_stage(config) -> void:
	StoryFlowController.start_stage(config.chapter, config.stage_number)

func _is_stage_locked(config) -> bool:
	if config.stage_number == 1:
		return false
	var prev_id = "ch%02d_s%02d" % [config.chapter, config.stage_number - 1]
	var prev_save = SaveManager.get_stage_data(prev_id)
	return prev_save.is_empty() or prev_save.get("stars", 0) == 0

func _update_chapter_buttons() -> void:
	_chapter_prev_btn.disabled = (current_chapter <= 1)
	var next_unlocked = SaveManager.is_chapter_unlocked(current_chapter + 1)
	_chapter_next_btn.disabled = (current_chapter >= 10 or not next_unlocked)

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

func _on_chapter_prev() -> void:
	if current_chapter > 1:
		_load_chapter(current_chapter - 1)

func _on_chapter_next() -> void:
	if current_chapter < 10 and SaveManager.is_chapter_unlocked(current_chapter + 1):
		_load_chapter(current_chapter + 1)

# ─────────────────────────────────────────
# 결과 팝업
# ─────────────────────────────────────────

func _show_result_popup(result: Dictionary) -> void:
	var popup = ResultPopupScene.instantiate()
	add_child(popup)
	var is_clear: bool = result.get("is_clear", false)
	var stars: int = result.get("stars", 0)
	var score: int = result.get("score", 0)

	if is_clear:
		var has_next = _result_stage < 10
		var currency: int = result.get("currency", 0)
		popup.show_clear(stars, score, currency, has_next)
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
	if _result_stage + 1 <= 10:
		StoryFlowController.start_stage(_result_chapter, _result_stage + 1)

func _on_unlock_button_pressed() -> void:
	var next_chapter = current_chapter + 1
	if ChapterUnlockScript.try_unlock(next_chapter):
		_load_chapter(next_chapter)

# ─────────────────────────────────────────
# 드래그 스크롤
# ─────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_dragging = true
			_drag_start_y = event.position.y
			_scroll_start = _node_map_scroll.scroll_vertical
		else:
			_dragging = false
	elif event is InputEventScreenDrag and _dragging:
		var delta = _drag_start_y - event.position.y
		_node_map_scroll.scroll_vertical = _scroll_start + int(delta)
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = true
			_drag_start_y = event.position.y
			_scroll_start = _node_map_scroll.scroll_vertical
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var delta = _drag_start_y - event.position.y
		_node_map_scroll.scroll_vertical = _scroll_start + int(delta)
