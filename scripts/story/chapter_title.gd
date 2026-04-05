class_name ChapterTitle
extends CanvasLayer

## 챕터 타이틀 카드 연출.
## show_title() 호출 → 3초 애니메이션 → title_finished 시그널.

signal title_finished

const CHAPTER_TITLES := {
	1: "퍼즐 세계에 오신 것을 환영합니다",
	2: "어둠의 숲",
	3: "얼어붙은 강",
	4: "불꽃의 산",
	5: "바람의 고원",
}

@onready var _background: ColorRect = $Background
@onready var _chapter_number: Label = $ChapterNumber
@onready var _chapter_name: Label = $ChapterName
@onready var _deco_left: ColorRect = $Decoration/DecoLeft
@onready var _deco_right: ColorRect = $Decoration/DecoRight

var _phase: int = 0  # 0=진행중 1=정지 2=완료
var _anim_tween: Tween = null

func _ready() -> void:
	_background.color = Color.BLACK
	_chapter_number.modulate.a = 0.0
	_chapter_name.modulate.a = 0.0
	_deco_left.modulate.a = 0.0
	_deco_right.modulate.a = 0.0
	visible = false

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func show_title(chapter_number: int, chapter_name: String = "") -> void:
	if chapter_name.is_empty():
		chapter_name = CHAPTER_TITLES.get(chapter_number, "")

	_chapter_number.text = "Chapter %d" % chapter_number
	_chapter_name.text = chapter_name
	_phase = 0
	visible = true
	_run_animation()

# ─────────────────────────────────────────
# 입력 — 탭으로 스킵
# ─────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var tapped = (event is InputEventScreenTouch and event.pressed) or \
				 (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not tapped:
		return

	match _phase:
		0:
			# 진행 중 → 즉시 정지 단계로
			if _anim_tween:
				_anim_tween.kill()
			_skip_to_hold()
		1:
			# 정지 중 → 페이드아웃 시작
			_run_fadeout()
	get_viewport().set_input_as_handled()

# ─────────────────────────────────────────
# 애니메이션
# ─────────────────────────────────────────

func _run_animation() -> void:
	_anim_tween = create_tween()

	# 0.0~0.5s: 챕터 번호 페이드인
	_anim_tween.tween_property(_chapter_number, "modulate:a", 1.0, 0.5)

	# 0.5~1.0s: 챕터 이름 슬라이드업 + 페이드인
	var name_start_pos = _chapter_name.position + Vector2(0, 20)
	_chapter_name.position = name_start_pos
	_anim_tween.tween_property(_chapter_name, "modulate:a", 1.0, 0.5)
	_anim_tween.parallel().tween_property(_chapter_name, "position",
		_chapter_name.position - Vector2(0, 20), 0.5)

	# 1.0~1.5s: 장식 라인 펼쳐짐
	_deco_left.size.x = 0.0
	_deco_right.size.x = 0.0
	_anim_tween.tween_property(_deco_left, "modulate:a", 1.0, 0.1)
	_anim_tween.parallel().tween_property(_deco_right, "modulate:a", 1.0, 0.1)
	_anim_tween.tween_property(_deco_left, "size:x", 200.0, 0.4)
	_anim_tween.parallel().tween_property(_deco_right, "size:x", 200.0, 0.4)

	# 1.5~2.5s: 정지
	_anim_tween.tween_callback(func(): _phase = 1)
	_anim_tween.tween_interval(1.0)

	# 2.5~3.0s: 페이드아웃
	_anim_tween.tween_callback(_run_fadeout)

func _skip_to_hold() -> void:
	_chapter_number.modulate.a = 1.0
	_chapter_name.modulate.a = 1.0
	_chapter_name.position.y -= 20  # 슬라이드 완료 위치로
	_deco_left.modulate.a = 1.0
	_deco_right.modulate.a = 1.0
	_deco_left.size.x = 200.0
	_deco_right.size.x = 200.0
	_phase = 1

func _run_fadeout() -> void:
	_phase = 2
	if _anim_tween:
		_anim_tween.kill()
	_anim_tween = create_tween()
	_anim_tween.tween_property(_background, "modulate:a", 0.0, 0.5)
	_anim_tween.parallel().tween_property(_chapter_number, "modulate:a", 0.0, 0.5)
	_anim_tween.parallel().tween_property(_chapter_name, "modulate:a", 0.0, 0.5)
	_anim_tween.parallel().tween_property(_deco_left, "modulate:a", 0.0, 0.5)
	_anim_tween.parallel().tween_property(_deco_right, "modulate:a", 0.0, 0.5)
	_anim_tween.tween_callback(_on_finished)

func _on_finished() -> void:
	visible = false
	_background.modulate.a = 1.0
	_chapter_number.modulate.a = 1.0
	_chapter_name.modulate.a = 1.0
	_deco_left.modulate.a = 1.0
	_deco_right.modulate.a = 1.0
	title_finished.emit()
