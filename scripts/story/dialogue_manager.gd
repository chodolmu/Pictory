class_name DialogueManager
extends Node

## 스토리 다이얼로그 핵심 매니저.
## Array[Dictionary] 형태의 스토리 데이터를 받아 한 줄씩 진행.
## 타이핑 애니메이션, 캐릭터 표시 제어, 이벤트 트리거를 담당.

signal dialogue_started
signal dialogue_line_shown(line_data: Dictionary)
signal dialogue_finished
signal event_triggered(event_name: String, event_args: Dictionary)

@export var typing_speed: float = 30.0  # 초당 글자 수

# ─────────────────────────────────────────
# 내부 상태
# ─────────────────────────────────────────

var _lines: Array = []
var _current_index: int = 0
var _is_active: bool = false
var _is_typing: bool = false

# UI 참조 (DialogueUI에서 주입)
var _rich_text: RichTextLabel = null
var _name_label: Label = null
var _next_indicator: Control = null
var _char_left: Control = null
var _char_right: Control = null

var _typing_tween: Tween = null

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func setup(rich_text: RichTextLabel, name_label: Label,
		next_indicator: Control,
		char_left: Control, char_right: Control) -> void:
	_rich_text = rich_text
	_name_label = name_label
	_next_indicator = next_indicator
	_char_left = char_left
	_char_right = char_right

func start_dialogue(story_data: Array) -> void:
	_lines = story_data
	_current_index = 0
	_is_active = true
	dialogue_started.emit()
	_show_line(_current_index)

func advance() -> void:
	if not _is_active:
		return
	if _is_typing:
		# 타이핑 중 → 즉시 전체 표시
		_skip_typing()
	else:
		# 타이핑 완료 → 다음 대사
		_next_line()

func skip_all() -> void:
	if not _is_active:
		return
	_is_active = false
	if _typing_tween:
		_typing_tween.kill()
	_is_typing = false
	dialogue_finished.emit()

func is_active() -> bool:
	return _is_active

# ─────────────────────────────────────────
# 내부 — 대사 진행
# ─────────────────────────────────────────

func _show_line(index: int) -> void:
	if index >= _lines.size():
		_finish()
		return

	var line: Dictionary = _lines[index]

	# 유효성 검증
	if not _validate_line(line):
		_next_line()
		return

	# 이름 표시
	var name_text: String = line.get("name_display", "")
	if _name_label:
		_name_label.text = name_text
		_name_label.visible = not name_text.is_empty()

	# 텍스트 설정
	var text: String = line.get("text", "")
	if _rich_text:
		_rich_text.text = text
		_rich_text.visible_characters = 0

	# 캐릭터 표시 업데이트
	var position: String = line.get("position", "left")
	var speaker: String = line.get("speaker", "")
	var expression = line.get("expression", null)
	_update_character_display(speaker, position, expression)

	# 이벤트 트리거 (대사 표시 전)
	var event = line.get("event", null)
	if event != null and event is Dictionary:
		var etype: String = event.get("type", "")
		var eargs: Dictionary = event.get("args", {})
		if not etype.is_empty():
			event_triggered.emit(etype, eargs)

	# 타이핑 애니메이션 시작
	_start_typing(text)

	dialogue_line_shown.emit(line)

func _start_typing(text: String) -> void:
	if _rich_text == null:
		return

	var total_chars = _rich_text.get_total_character_count()
	if total_chars <= 0:
		_on_typing_finished()
		return

	_is_typing = true
	if _next_indicator:
		_next_indicator.visible = false

	var duration = float(total_chars) / typing_speed
	if _typing_tween:
		_typing_tween.kill()
	_typing_tween = create_tween()
	_typing_tween.tween_property(_rich_text, "visible_characters", total_chars, duration).from(0)
	_typing_tween.tween_callback(_on_typing_finished)

func _skip_typing() -> void:
	if _typing_tween:
		_typing_tween.kill()
		_typing_tween = null
	if _rich_text:
		_rich_text.visible_characters = -1  # 전체 표시
	_on_typing_finished()

func _on_typing_finished() -> void:
	_is_typing = false
	if _next_indicator:
		_next_indicator.visible = true
		_animate_next_indicator()

func _next_line() -> void:
	_current_index += 1
	if _next_indicator:
		_next_indicator.visible = false
	_show_line(_current_index)

func _finish() -> void:
	_is_active = false
	dialogue_finished.emit()

# ─────────────────────────────────────────
# 캐릭터 표시
# ─────────────────────────────────────────

func _update_character_display(speaker: String, position: String, expression) -> void:
	if _char_left == null or _char_right == null:
		return

	match position:
		"left":
			_set_character_active(_char_left, speaker, expression)
			_set_character_dim(_char_right)
		"right":
			_set_character_dim(_char_left)
			_set_character_active(_char_right, speaker, expression)
		"center", _:
			# 내레이터 등 — 둘 다 약간 어둡게
			_set_character_dim(_char_left)
			_set_character_dim(_char_right)

func _set_character_active(char_node: Control, speaker: String, expression) -> void:
	char_node.visible = true
	var tween = create_tween()
	tween.tween_property(char_node, "modulate", Color.WHITE, 0.15)

	# expression 변경
	if expression != null and expression is String:
		_apply_expression(char_node, expression)

	# 화자 외형 적용
	_apply_speaker_appearance(char_node, speaker)

func _set_character_dim(char_node: Control) -> void:
	var tween = create_tween()
	tween.tween_property(char_node, "modulate", Color(0.5, 0.5, 0.5, 1.0), 0.15)

func _apply_expression(char_node: Control, expression: String) -> void:
	var face = char_node.get_node_or_null("Face")
	if face == null:
		return

	var eye_l = face.get_node_or_null("EyeLeft")
	var eye_r = face.get_node_or_null("EyeRight")
	var mouth = face.get_node_or_null("Mouth")

	if eye_l == null or eye_r == null or mouth == null:
		return

	match expression:
		"happy":
			eye_l.size = Vector2(8, 4)
			eye_r.size = Vector2(8, 4)
			mouth.size = Vector2(16, 6)
			mouth.color = Color(0.8, 0.2, 0.2)
		"sad":
			eye_l.size = Vector2(8, 4)
			eye_r.size = Vector2(8, 4)
			mouth.size = Vector2(12, 4)
			mouth.color = Color(0.5, 0.3, 0.3)
		"angry":
			eye_l.size = Vector2(10, 3)
			eye_r.size = Vector2(10, 3)
			mouth.size = Vector2(14, 3)
			mouth.color = Color(0.7, 0.1, 0.1)
		"surprised":
			eye_l.size = Vector2(10, 10)
			eye_r.size = Vector2(10, 10)
			mouth.size = Vector2(8, 8)
			mouth.color = Color(0.6, 0.3, 0.3)
		"normal", _:
			eye_l.size = Vector2(8, 6)
			eye_r.size = Vector2(8, 6)
			mouth.size = Vector2(14, 5)
			mouth.color = Color(0.6, 0.3, 0.3)

func _apply_speaker_appearance(char_node: Control, speaker: String) -> void:
	var body = char_node.get_node_or_null("Body")
	if body == null:
		return

	match speaker:
		"hunya":
			body.color = Color(0.95, 0.90, 0.80)  # 크림색
		"imagen_fire":
			body.color = Color(0.95, 0.30, 0.20)  # 빨강
		"imagen_water":
			body.color = Color(0.20, 0.50, 0.95)  # 파랑
		"imagen_grass":
			body.color = Color(0.20, 0.75, 0.30)  # 초록
		"unknown":
			body.color = Color(0.15, 0.15, 0.15)  # 거의 검정 (실루엣)
		_:
			body.color = Color(0.70, 0.70, 0.70)  # 회색 기본

# ─────────────────────────────────────────
# 다음 표시 깜빡임
# ─────────────────────────────────────────

func _animate_next_indicator() -> void:
	if _next_indicator == null:
		return
	var tween = create_tween().set_loops()
	tween.tween_property(_next_indicator, "modulate:a", 0.1, 0.5)
	tween.tween_property(_next_indicator, "modulate:a", 1.0, 0.5)

# ─────────────────────────────────────────
# 유효성 검증
# ─────────────────────────────────────────

func _validate_line(line: Dictionary) -> bool:
	var required = ["speaker", "name_display", "text", "position"]
	for field in required:
		if not line.has(field):
			push_error("DialogueManager: 대사 라인에 필수 필드 없음: " + field)
			return false
	return true
