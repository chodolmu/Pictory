class_name ChapterBackground
extends TextureRect

## 챕터 배경 — 스테이지 클리어에 따라 점진적으로 색이 차오르는 연출.
## ShaderMaterial에 grayscale_wipe.gdshader 적용 필요.
##
## 사용법:
##   chapter_bg.set_chapter(chapter_num)
##   chapter_bg.animate_to_progress(cleared_count / 10.0)

# 챕터별 기본 색상 (배경 텍스처가 없을 때 ColorRect 대체용)
const CHAPTER_COLORS: Array[Color] = [
	Color(0.35, 0.65, 0.35),  # Ch1: 초록 (숲)
	Color(0.30, 0.50, 0.80),  # Ch2: 파랑 (바다)
	Color(0.80, 0.65, 0.30),  # Ch3: 금색 (사막)
	Color(0.55, 0.35, 0.70),  # Ch4: 보라 (마법)
	Color(0.80, 0.40, 0.35),  # Ch5: 빨강 (화산)
	Color(0.30, 0.70, 0.70),  # Ch6: 청록 (얼음)
	Color(0.70, 0.55, 0.40),  # Ch7: 갈색 (고대)
	Color(0.50, 0.50, 0.60),  # Ch8: 회색 (기계)
	Color(0.65, 0.30, 0.55),  # Ch9: 자주 (심연)
	Color(0.90, 0.80, 0.40),  # Ch10: 황금 (최종)
]

var _current_chapter: int = 1
var _shader_material: ShaderMaterial = null

func _ready() -> void:
	_setup_shader()

func _setup_shader() -> void:
	var shader = load("res://shaders/grayscale_wipe.gdshader")
	if shader == null:
		push_warning("ChapterBackground: 셰이더 로드 실패")
		return
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader
	_shader_material.set_shader_parameter("progress", 0.0)
	_shader_material.set_shader_parameter("edge_softness", 0.05)
	material = _shader_material

func set_chapter(chapter: int) -> void:
	_current_chapter = clampi(chapter, 1, 10)
	_apply_chapter_visual()

func _apply_chapter_visual() -> void:
	## 챕터별 배경 텍스처 로드 시도. 없으면 단색 그라데이션 생성.
	var tex_path = "res://resources/chapters/ch%02d_bg.png" % _current_chapter
	if ResourceLoader.exists(tex_path):
		texture = load(tex_path)
	else:
		# 텍스처 없음 — 프로시저럴 그라데이션 생성
		_generate_gradient_texture()

func _generate_gradient_texture() -> void:
	## 챕터 색상 기반 그라데이션 텍스처 생성.
	var color = CHAPTER_COLORS[_current_chapter - 1] if _current_chapter <= CHAPTER_COLORS.size() else Color.GRAY
	var grad = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.set_color(0, color.darkened(0.3))
	gradient.set_color(1, color.lightened(0.2))
	grad.gradient = gradient
	grad.fill_from = Vector2(0.5, 1.0)
	grad.fill_to = Vector2(0.5, 0.0)
	grad.width = 256
	grad.height = 512
	texture = grad

func set_progress(value: float) -> void:
	## 즉시 진행도 설정 (0.0 ~ 1.0).
	if _shader_material:
		_shader_material.set_shader_parameter("progress", clampf(value, 0.0, 1.0))

func animate_to_progress(target: float, duration: float = 0.8) -> void:
	## 현재 진행도에서 target까지 Tween 애니메이션.
	if _shader_material == null:
		return
	var current = _shader_material.get_shader_parameter("progress")
	if is_equal_approx(current, target):
		return
	var tween = create_tween()
	tween.tween_method(_set_progress_param, current, clampf(target, 0.0, 1.0), duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# 펀치 스케일 효과 (색이 차오를 때)
	if target > current:
		tween.parallel().tween_property(self, "scale", Vector2(1.02, 1.02), duration * 0.4)\
			.set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "scale", Vector2.ONE, duration * 0.3)

func _set_progress_param(value: float) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("progress", value)

func get_chapter_progress(chapter: int) -> float:
	## SaveManager에서 챕터 클리어 수를 읽어 0.0~1.0 반환.
	var cleared = 0
	for s in range(1, 11):
		var stage_id = "ch%02d_s%02d" % [chapter, s]
		if SaveManager.is_stage_cleared(stage_id):
			cleared += 1
	return float(cleared) / 10.0
