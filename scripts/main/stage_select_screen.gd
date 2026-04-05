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
const NODE_RADIUS: float = 28.0
const NODE_GAP_Y: float = 90.0
const MAP_TOP_MARGIN: float = 60.0
const LINE_COLOR: Color = Color(0.3, 0.3, 0.5, 0.6)
const LINE_WIDTH: float = 3.0

const NODE_COLORS = {
	"locked": Color(0.25, 0.25, 0.3),
	"available": Color(0.3, 0.55, 0.9),
	"cleared_1": Color(0.6, 0.5, 0.2),
	"cleared_2": Color(0.75, 0.65, 0.15),
	"cleared_3": Color(0.95, 0.85, 0.1),
}

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
	# 기존 노드 제거
	for child in _node_map_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	var stages = LevelLoader.load_chapter_stages(chapter)
	var count = stages.size()
	var map_height = MAP_TOP_MARGIN + count * NODE_GAP_Y + 40.0
	_node_map_container.custom_minimum_size = Vector2(390, maxf(map_height, 900))

	# 뷰포트 너비
	var vp_width = get_viewport_rect().size.x
	if vp_width <= 0:
		vp_width = 390.0

	# 노드 위치 계산 (아래→위, 세로 배치, 약간 좌우 지그재그)
	var positions: Array[Vector2] = []
	for i in range(count):
		var stage_idx = count - 1 - i  # 1스테이지가 맨 아래
		var x_offset = 30.0 if (stage_idx % 2 == 0) else -30.0
		var px = vp_width / 2.0 + x_offset
		var py = MAP_TOP_MARGIN + i * NODE_GAP_Y
		positions.append(Vector2(px, py))

	# 연결선 그리기 (커스텀 드로잉)
	var line_drawer = Control.new()
	line_drawer.name = "LineDrawer"
	line_drawer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line_drawer.custom_minimum_size = _node_map_container.custom_minimum_size
	_node_map_container.add_child(line_drawer)

	# 연결선은 _draw에서 그림
	var line_positions = positions.duplicate()
	line_drawer.draw.connect(func():
		for i in range(line_positions.size() - 1):
			line_drawer.draw_line(line_positions[i], line_positions[i + 1], LINE_COLOR, LINE_WIDTH, true)
	)

	# 노드 버튼 생성 (위→아래 순서로 추가, 10→1)
	for i in range(count):
		var stage_idx = count - 1 - i  # positions[0] = stage 10, positions[count-1] = stage 1
		var config = stages[stage_idx]
		var save = SaveManager.get_stage_data(config.stage_id)
		var stars = save.get("stars", 0) if not save.is_empty() else 0
		var locked = _is_stage_locked(config)
		var pos = positions[i]

		var node_btn = _create_node_button(config, stars, locked, pos)
		_node_map_container.add_child(node_btn)

	# 스크롤을 맨 아래로 (1스테이지가 보이도록)
	await get_tree().process_frame
	_node_map_scroll.scroll_vertical = int(_node_map_container.custom_minimum_size.y)

	line_drawer.queue_redraw()

func _create_node_button(config, stars: int, locked: bool, pos: Vector2) -> Control:
	var container = Control.new()
	container.position = Vector2(pos.x - NODE_RADIUS - 10, pos.y - NODE_RADIUS - 10)
	container.size = Vector2((NODE_RADIUS + 10) * 2, (NODE_RADIUS + 10) * 2)

	# 원형 노드 (Panel + StyleBoxFlat)
	var panel = Panel.new()
	panel.position = Vector2(10, 10)
	panel.size = Vector2(NODE_RADIUS * 2, NODE_RADIUS * 2)
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = int(NODE_RADIUS)
	style.corner_radius_top_right = int(NODE_RADIUS)
	style.corner_radius_bottom_left = int(NODE_RADIUS)
	style.corner_radius_bottom_right = int(NODE_RADIUS)

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

	panel.add_theme_stylebox_override("panel", style)
	container.add_child(panel)

	# 스테이지 번호 라벨
	var lbl = Label.new()
	lbl.text = str(config.stage_number)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(10, 10)
	lbl.size = Vector2(NODE_RADIUS * 2, NODE_RADIUS * 2)
	lbl.add_theme_font_size_override("font_size", 16)
	if locked:
		lbl.modulate = Color(0.5, 0.5, 0.5)
	container.add_child(lbl)

	# 별 표시 (클리어된 경우)
	if stars > 0:
		var star_lbl = Label.new()
		star_lbl.text = "★".repeat(stars)
		star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_lbl.position = Vector2(10 - 8, 10 + NODE_RADIUS * 2 + 2)
		star_lbl.size = Vector2(NODE_RADIUS * 2 + 16, 20)
		star_lbl.add_theme_font_size_override("font_size", 10)
		star_lbl.modulate = Color(1.0, 0.85, 0.0)
		container.add_child(star_lbl)

	# 터치 영역 (투명 버튼)
	var btn = Button.new()
	btn.position = Vector2(0, 0)
	btn.size = container.size
	btn.flat = true
	btn.modulate = Color(1, 1, 1, 0)  # 완전 투명
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
