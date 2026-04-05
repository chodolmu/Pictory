class_name StageSelectScreen
extends Control

const ResultPopupScene = preload("res://scenes/ui/result_popup.tscn")
const ChapterUnlockScript = preload("res://scripts/data/chapter_unlock.gd")

@onready var _back_btn: Button = $MarginContainer/VBox/Header/BackButton
@onready var _chapter_prev_btn: Button = $MarginContainer/VBox/Header/ChapterPrevButton
@onready var _chapter_next_btn: Button = $MarginContainer/VBox/Header/ChapterNextButton
@onready var _chapter_label: Label = $MarginContainer/VBox/Header/ChapterLabel
@onready var _node_map_scroll: ScrollContainer = $MarginContainer/VBox/NodeMapScroll
@onready var _node_map_container: Control = $MarginContainer/VBox/NodeMapScroll/NodeMapContainer
@onready var _unlock_info_label: Label = $MarginContainer/VBox/UnlockInfoLabel
@onready var _unlock_btn: Button = $MarginContainer/VBox/UnlockButton

var _stage_confirm_popup = null

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
var _current_stage_pos: Vector2 = Vector2.ZERO

# 드래그 스크롤
var _dragging: bool = false
var _drag_start_y: float = 0.0
var _scroll_start: int = 0

func _ready() -> void:
	_back_btn.pressed.connect(_on_back)
	_chapter_prev_btn.pressed.connect(_on_chapter_prev)
	_chapter_next_btn.pressed.connect(_on_chapter_next)
	_unlock_btn.pressed.connect(_on_unlock_button_pressed)

	var params = SceneManager.get_params()
	var ch = params.get("chapter", 1)
	_load_chapter(ch)

	if params.get("show_result", false):
		_result_chapter = ch
		_result_stage = params.get("stage", 1)
		call_deferred("_show_result_popup", params.get("result", {}))

func _load_chapter(chapter: int) -> void:
	current_chapter = chapter
	_chapter_label.text = "챕터 %d" % chapter
	_update_chapter_buttons()
	_build_node_map(chapter)
	_update_unlock_info()

func _build_node_map(chapter: int) -> void:
	for child in _node_map_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	var stages = LevelLoader.load_chapter_stages(chapter)
	var count = stages.size()
	var map_height = MAP_TOP_MARGIN + count * NODE_GAP_Y + 60.0
	_node_map_container.custom_minimum_size = Vector2(390, maxf(map_height, 900))

	var vp_width = get_viewport_rect().size.x
	if vp_width <= 0:
		vp_width = 390.0

	# 현재 스테이지 찾기 (플레이어 위치)
	var current_stage_idx = _find_current_stage(stages)

	# 노드 위치 계산 (아래→위, 지그재그)
	var positions: Array[Vector2] = []
	for i in range(count):
		var stage_idx = count - 1 - i
		var x_offset = 25.0 if (stage_idx % 2 == 0) else -25.0
		var px = vp_width / 2.0 + x_offset
		var py = MAP_TOP_MARGIN + i * NODE_GAP_Y
		positions.append(Vector2(px, py))

	# 연결선
	var line_drawer = Control.new()
	line_drawer.name = "LineDrawer"
	line_drawer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line_drawer.custom_minimum_size = _node_map_container.custom_minimum_size
	_node_map_container.add_child(line_drawer)

	var line_positions = positions.duplicate()
	line_drawer.draw.connect(func():
		for i in range(line_positions.size() - 1):
			line_drawer.draw_line(line_positions[i], line_positions[i + 1], LINE_COLOR, LINE_WIDTH, true)
	)

	# 캐릭터 위치 저장
	var char_position_idx = count - 1 - current_stage_idx  # positions 인덱스
	if char_position_idx >= 0 and char_position_idx < positions.size():
		_current_stage_pos = positions[char_position_idx]

	# 노드 버튼 생성
	for i in range(count):
		var stage_idx = count - 1 - i
		var config = stages[stage_idx]
		var save = SaveManager.get_stage_data(config.stage_id)
		var stars = save.get("stars", 0) if not save.is_empty() else 0
		var locked = _is_stage_locked(config)
		var pos = positions[i]
		var is_current = (stage_idx == current_stage_idx)

		var node_btn = _create_node_button(config, stars, locked, pos, is_current)
		_node_map_container.add_child(node_btn)

	# 캐릭터 마커 생성
	_create_character_marker()

	# 스크롤 위치: 캐릭터가 보이도록
	await get_tree().process_frame
	var scroll_target = int(_current_stage_pos.y - _node_map_scroll.size.y / 2.0)
	_node_map_scroll.scroll_vertical = clampi(scroll_target, 0, int(_node_map_container.custom_minimum_size.y))

	line_drawer.queue_redraw()

func _find_current_stage(stages: Array) -> int:
	# 가장 높은 클리어된 스테이지의 다음, 또는 첫 번째 미클리어 스테이지
	var highest_cleared = -1
	for i in range(stages.size()):
		var save = SaveManager.get_stage_data(stages[i].stage_id)
		if not save.is_empty() and save.get("stars", 0) > 0:
			highest_cleared = i
	if highest_cleared < 0:
		return 0  # 아무것도 안 깸 → 1스테이지
	if highest_cleared >= stages.size() - 1:
		return stages.size() - 1  # 다 깸 → 마지막 스테이지
	return highest_cleared + 1  # 다음 스테이지

func _create_character_marker() -> void:
	_character_marker = Panel.new()
	_character_marker.name = "CharacterMarker"
	var marker_size = NODE_RADIUS * 1.6
	_character_marker.size = Vector2(marker_size, marker_size)
	_character_marker.position = Vector2(
		_current_stage_pos.x - marker_size / 2.0,
		_current_stage_pos.y - NODE_RADIUS - marker_size - 4.0
	)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.90, 0.80)  # 후냐 크림색
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

	# 바운스 애니메이션
	_animate_character_bounce()

func _animate_character_bounce() -> void:
	if _character_marker == null or not is_instance_valid(_character_marker):
		return
	var base_y = _character_marker.position.y
	var tween = create_tween().set_loops()
	tween.tween_property(_character_marker, "position:y", base_y - 6.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_character_marker, "position:y", base_y, 0.5).set_trans(Tween.TRANS_SINE)

func _move_character_to_stage(target_pos: Vector2) -> void:
	if _character_marker == null or not is_instance_valid(_character_marker):
		return
	var marker_size = _character_marker.size.x
	var target = Vector2(
		target_pos.x - marker_size / 2.0,
		target_pos.y - NODE_RADIUS - marker_size - 4.0
	)
	var tween = create_tween()
	tween.tween_property(_character_marker, "position", target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _create_node_button(config, stars: int, locked: bool, pos: Vector2, is_current: bool) -> Control:
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

	# 현재 스테이지 강조 테두리
	if is_current and not locked:
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
		btn.pressed.connect(_on_stage_selected.bind(config.stage_id))
	container.add_child(btn)

	return container

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

func _on_stage_selected(s_id: String) -> void:
	var config = LevelLoader.load_stage(s_id)
	if config == null:
		return
	if _stage_confirm_popup == null or not is_instance_valid(_stage_confirm_popup):
		_stage_confirm_popup = load("res://scenes/ui/stage_confirm_popup.tscn").instantiate()
		get_tree().root.add_child(_stage_confirm_popup)
		_stage_confirm_popup.start_requested.connect(_on_start_stage)
	_stage_confirm_popup.show_popup(config)

func _on_start_stage(config) -> void:
	StoryFlowController.start_stage(config.chapter, config.stage_number)

func _show_result_popup(result: Dictionary) -> void:
	var popup = ResultPopupScene.instantiate()
	add_child(popup)
	var is_clear: bool = result.get("is_clear", false)
	var stars: int = result.get("stars", 0)
	var score: int = result.get("score", 0)

	if is_clear:
		var max_stages = 10
		var has_next = _result_stage < max_stages
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
	var next = _result_stage + 1
	if next > 10:
		pass
	else:
		StoryFlowController.start_stage(_result_chapter, next)

func _on_unlock_button_pressed() -> void:
	var next_chapter = current_chapter + 1
	if ChapterUnlockScript.try_unlock(next_chapter):
		_load_chapter(next_chapter)

func _on_back() -> void:
	if _stage_confirm_popup != null and is_instance_valid(_stage_confirm_popup):
		_stage_confirm_popup.queue_free()
		_stage_confirm_popup = null
	SceneManager.change_scene("res://scenes/main/main_menu.tscn")

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
