class_name StickerObject
extends TextureRect

## 스티커북의 개별 오브젝트.
## 흑백 상태에서 별 소모 시 컬러로 전환되며 연출 재생.

signal color_restored(index: int)

@export var sticker_index: int = 0

var _is_colored: bool = false
var _shader_material: ShaderMaterial = null

func _ready() -> void:
	_setup_shader()
	# pivot은 레이아웃 완료 후 설정
	if size.length() > 0:
		pivot_offset = size / 2.0
	else:
		resized.connect(_update_pivot, CONNECT_ONE_SHOT)

func _update_pivot() -> void:
	pivot_offset = size / 2.0

func _setup_shader() -> void:
	var shader = load("res://shaders/grayscale_wipe.gdshader")
	if shader == null:
		return
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader
	_shader_material.set_shader_parameter("progress", 0.0)
	_shader_material.set_shader_parameter("edge_softness", 0.08)
	material = _shader_material

func set_colored(instant: bool = false) -> void:
	_is_colored = true
	if _shader_material:
		if instant:
			_shader_material.set_shader_parameter("progress", 1.0)
		else:
			_animate_color_restore()

func set_grayscale() -> void:
	_is_colored = false
	if _shader_material:
		_shader_material.set_shader_parameter("progress", 0.0)

func is_colored() -> bool:
	return _is_colored

func _animate_color_restore() -> void:
	## 색 복구 연출: wipe + bounce + 파티클.
	var tween = create_tween()

	# ① 색 채우기 (아래→위 wipe)
	tween.tween_method(_set_progress, 0.0, 1.0, 0.6)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# ② 바운스 스케일
	tween.parallel().tween_property(self, "scale", Vector2(1.15, 1.15), 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# ③ 파티클 (자식에 CPUParticles2D가 있으면 발사)
	var particles = get_node_or_null("Particles")
	if particles and particles is CPUParticles2D:
		tween.parallel().tween_callback(func():
			particles.restart()
			particles.emitting = true
		).set_delay(0.1)

	tween.tween_callback(func():
		color_restored.emit(sticker_index)
	)

func _set_progress(value: float) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("progress", value)
