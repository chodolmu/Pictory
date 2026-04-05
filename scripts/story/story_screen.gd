class_name StoryScreen
extends Control

## 스토리 연출 화면.
## story_params를 받아 JSON 로드 → DialogueUI 진행 → next_scene 전환.

@onready var _dialogue_ui: DialogueUI = $DialogueUI
@onready var _flash_rect: ColorRect = $FlashRect

# SceneManager가 전달한 파라미터
# {
#   "chapter": int,
#   "stage": int,
#   "type": "pre" | "post",
#   "next_scene": String,
#   "next_params": Dictionary
# }
var _params: Dictionary = {}

# ─────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────

func _ready() -> void:
	_flash_rect.color = Color.WHITE
	_flash_rect.modulate.a = 0.0
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_params = SceneManager.get_params()

	var chapter: int = _params.get("chapter", 1)
	var stage: int = _params.get("stage", 1)
	var dtype: String = _params.get("type", "pre")

	var story_path = "res://resources/story/chapter_%02d/stage_%02d_%s.json" % [chapter, stage, dtype]
	var lines = _load_story(story_path)
	# stage-level 파일이 없으면 chapter-level fallback
	if lines.is_empty():
		var chapter_path = "res://resources/story/chapter_%02d/chapter_%02d_%s.json" % [chapter, chapter, dtype]
		lines = _load_story(chapter_path)

	_dialogue_ui.get_manager().event_triggered.connect(_on_event_triggered)
	_dialogue_ui.skip_requested.connect(_on_dialogue_done)
	_dialogue_ui.exit_requested.connect(_on_exit_requested)

	if lines.is_empty():
		# 다이얼로그 없으면 즉시 다음 씬으로
		_go_next()
	else:
		_dialogue_ui.start_dialogue(lines)

# ─────────────────────────────────────────
# JSON 로드
# ─────────────────────────────────────────

func _load_story(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var text = file.get_as_text()
	file.close()
	var json = JSON.parse_string(text)
	if json == null or not json is Dictionary:
		push_error("StoryScreen: JSON 파싱 실패: " + path)
		return []
	return json.get("lines", [])

# ─────────────────────────────────────────
# 이벤트 처리
# ─────────────────────────────────────────

func _on_event_triggered(event_name: String, event_args: Dictionary) -> void:
	match event_name:
		"screen_shake":
			_do_screen_shake(event_args)
		"flash_white":
			_do_flash(Color.WHITE, event_args.get("duration", 0.5))
		"flash_black":
			_do_flash(Color.BLACK, event_args.get("duration", 0.5))
		"wait":
			_do_wait(event_args.get("seconds", 1.0))
		"bgm_change":
			pass  # S14에서 구현
		"imagen_join":
			await _do_imagen_join(event_args.get("imagen_id", ""))
		"chapter_clear":
			pass  # 챕터 클리어 연출은 후속 스프린트

func _do_screen_shake(args: Dictionary) -> void:
	var intensity: float = args.get("intensity", 5.0)
	var duration: float = args.get("duration", 0.5)
	var tween = create_tween()
	var steps = int(duration / 0.05)
	for i in range(steps):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(self, "position", offset, 0.05)
	tween.tween_property(self, "position", Vector2.ZERO, 0.05)

func _do_flash(color: Color, duration: float) -> void:
	_flash_rect.color = color
	var tween = create_tween()
	tween.tween_property(_flash_rect, "modulate:a", 1.0, duration * 0.3)
	tween.tween_property(_flash_rect, "modulate:a", 0.0, duration * 0.7)

func _do_imagen_join(imagen_id: String) -> void:
	if imagen_id.is_empty():
		return
	# 중복 해금 방지
	if ImagenDatabase.is_unlocked(imagen_id):
		return
	ImagenDatabase.unlock(imagen_id)
	var data = ImagenDatabase.get_imagen(imagen_id)
	if data == null:
		return
	# 다이얼로그 일시 정지
	_dialogue_ui.get_manager().set_process_mode(Node.PROCESS_MODE_DISABLED)
	var cutscene_scene = preload("res://scenes/story/imagen_join_cutscene.tscn")
	var cutscene = cutscene_scene.instantiate()
	add_child(cutscene)
	cutscene.setup(data)
	cutscene.show_cutscene()
	await cutscene.finished
	cutscene.queue_free()
	_dialogue_ui.get_manager().set_process_mode(Node.PROCESS_MODE_INHERIT)

func _do_wait(seconds: float) -> void:
	# DialogueManager 입력을 잠깐 블록. 간단히 타이머로 처리.
	_dialogue_ui.get_manager().set_process_mode(Node.PROCESS_MODE_DISABLED)
	var timer = get_tree().create_timer(seconds)
	timer.timeout.connect(func():
		_dialogue_ui.get_manager().set_process_mode(Node.PROCESS_MODE_INHERIT)
	)

# ─────────────────────────────────────────
# 씬 전환
# ─────────────────────────────────────────

func _on_dialogue_done() -> void:
	_go_next()

func _on_exit_requested() -> void:
	SceneManager.change_scene("res://scenes/main/stage_select.tscn")

func _go_next() -> void:
	var dtype: String = _params.get("type", "pre")
	if dtype == "pre":
		StoryFlowController.on_pre_dialogue_finished()
	elif dtype == "post":
		StoryFlowController.on_post_dialogue_finished()
	else:
		# fallback: next_scene 직접 이동
		var next_scene: String = _params.get("next_scene", "res://scenes/game/game.tscn")
		var next_params: Dictionary = _params.get("next_params", {})
		SceneManager.change_scene(next_scene, next_params)
