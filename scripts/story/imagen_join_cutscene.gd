class_name ImagenJoinCutscene
extends CanvasLayer

## 이마젠 합류 연출 씬.
## setup(data) 후 show() 호출 → 4초 애니메이션 → finished 시그널.

signal finished

@onready var _background: ColorRect = $Background
@onready var _particle_center: Control = $ParticleCenter
@onready var _imagen_body: ColorRect = $ImagenDisplay/Body
@onready var _imagen_name: Label = $TextArea/ImagenName
@onready var _join_text: Label = $TextArea/JoinText
@onready var _skill_name: Label = $TextArea/SkillName
@onready var _skill_desc: Label = $TextArea/SkillDesc

var _data: ImagenData = null
var _anim_tween: Tween = null
var _skipped: bool = false

func _ready() -> void:
	visible = false

func setup(imagen_data: ImagenData) -> void:
	_data = imagen_data

func show_cutscene() -> void:
	if _data == null:
		finished.emit()
		return
	visible = true
	_skipped = false
	_fill_data()
	_run_animation()

func _fill_data() -> void:
	_imagen_body.color = _data.get_color()
	_imagen_name.text = _data.display_name
	_join_text.text = "동료가 되었다!"
	_skill_name.text = "스킬: " + _data.get_skill_name()
	_skill_desc.text = _data.description

	# 초기 상태: 투명
	_imagen_body.modulate.a = 0.0
	_imagen_body.scale = Vector2.ZERO
	_imagen_name.modulate.a = 0.0
	_join_text.modulate.a = 0.0
	_skill_name.modulate.a = 0.0
	_skill_desc.modulate.a = 0.0

func _run_animation() -> void:
	_anim_tween = create_tween()

	# 0.0~0.5s: 배경 등장
	_background.modulate.a = 0.0
	_anim_tween.tween_property(_background, "modulate:a", 0.85, 0.5)

	# 0.5~1.5s: 이마젠 도형 등장 (scale 0→1, alpha 0→1)
	_anim_tween.tween_property(_imagen_body, "modulate:a", 1.0, 0.5)
	_anim_tween.parallel().tween_property(_imagen_body, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 1.5~2.5s: 이름 + "동료가 되었다!" 표시
	_anim_tween.tween_property(_imagen_name, "modulate:a", 1.0, 0.3)
	_anim_tween.tween_property(_join_text, "modulate:a", 1.0, 0.3)

	# 2.5~3.5s: 스킬 정보 표시
	_anim_tween.tween_interval(0.5)
	_anim_tween.tween_property(_skill_name, "modulate:a", 1.0, 0.3)
	_anim_tween.tween_property(_skill_desc, "modulate:a", 1.0, 0.3)

	# 3.5~4.0s: 정지 후 페이드아웃
	_anim_tween.tween_interval(1.0)
	_anim_tween.tween_property(_background, "modulate:a", 0.0, 0.5)
	_anim_tween.parallel().tween_property(_imagen_body, "modulate:a", 0.0, 0.5)
	_anim_tween.parallel().tween_property(_imagen_name, "modulate:a", 0.0, 0.5)
	_anim_tween.parallel().tween_property(_join_text, "modulate:a", 0.0, 0.5)
	_anim_tween.parallel().tween_property(_skill_name, "modulate:a", 0.0, 0.5)
	_anim_tween.parallel().tween_property(_skill_desc, "modulate:a", 0.0, 0.5)
	_anim_tween.tween_callback(_on_finished)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _skipped:
		return
	var tapped = (event is InputEventScreenTouch and event.pressed) or \
				 (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not tapped:
		return
	_skip()
	get_viewport().set_input_as_handled()

func _skip() -> void:
	_skipped = true
	if _anim_tween:
		_anim_tween.kill()
	_on_finished()

func _on_finished() -> void:
	visible = false
	finished.emit()
