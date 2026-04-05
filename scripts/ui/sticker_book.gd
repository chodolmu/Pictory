class_name StickerBook
extends Control

## 스티커북 — 챕터별 배경 위에 오브젝트를 배치하고
## 별 소모 시 순서대로 컬러 복구 연출을 재생.

signal sticker_colored(chapter: int, index: int)

const STICKER_SCRIPT = preload("res://scripts/ui/sticker_object.gd")

# 챕터별 기본 색상 (배경용)
const CHAPTER_BG_COLORS: Array[Color] = [
	Color(0.12, 0.14, 0.10),  # Ch1: 어두운 숲
	Color(0.10, 0.12, 0.18),  # Ch2: 어두운 바다
	Color(0.16, 0.14, 0.10),  # Ch3: 어두운 사막
	Color(0.12, 0.10, 0.16),  # Ch4: 어두운 마법
	Color(0.16, 0.10, 0.10),  # Ch5: 어두운 화산
	Color(0.10, 0.14, 0.14),  # Ch6: 어두운 얼음
	Color(0.14, 0.12, 0.10),  # Ch7: 어두운 고대
	Color(0.12, 0.12, 0.14),  # Ch8: 어두운 기계
	Color(0.14, 0.10, 0.12),  # Ch9: 어두운 심연
	Color(0.18, 0.16, 0.10),  # Ch10: 어두운 황금
]

# 챕터별 오브젝트 컬러 (스티커 색상)
const STICKER_PALETTES: Array[Array] = [
	[Color(0.3, 0.7, 0.3), Color(0.8, 0.5, 0.3), Color(0.4, 0.8, 0.5),
	 Color(0.6, 0.4, 0.2), Color(0.2, 0.6, 0.4), Color(0.9, 0.8, 0.2),
	 Color(0.5, 0.7, 0.2), Color(0.7, 0.3, 0.3), Color(0.3, 0.5, 0.7), Color(0.8, 0.6, 0.8)],
	[Color(0.2, 0.5, 0.9), Color(0.3, 0.7, 0.8), Color(0.1, 0.4, 0.7),
	 Color(0.5, 0.8, 0.9), Color(0.2, 0.3, 0.6), Color(0.6, 0.9, 1.0),
	 Color(0.4, 0.6, 0.8), Color(0.1, 0.6, 0.5), Color(0.3, 0.4, 0.9), Color(0.7, 0.8, 1.0)],
	[Color(0.9, 0.7, 0.3), Color(0.8, 0.6, 0.2), Color(0.7, 0.5, 0.2),
	 Color(1.0, 0.8, 0.4), Color(0.6, 0.4, 0.1), Color(0.9, 0.9, 0.5),
	 Color(0.8, 0.7, 0.5), Color(0.7, 0.6, 0.3), Color(0.5, 0.4, 0.2), Color(1.0, 0.9, 0.6)],
]

const OBJECTS_PER_CHAPTER: int = 10

# 오브젝트 형태 (프로시저럴)
enum Shape { CIRCLE, RECT, DIAMOND, TRIANGLE, STAR_SHAPE }

var _current_chapter: int = 1
var _stickers: Array = []  # StickerObject 배열
var _bg_rect: ColorRect = null
var _restored_indices: Array = []

func _ready() -> void:
	_bg_rect = ColorRect.new()
	_bg_rect.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_bg_rect.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_bg_rect)
	move_child(_bg_rect, 0)

func setup_chapter(chapter: int) -> void:
	_current_chapter = clampi(chapter, 1, 10)
	_clear_stickers()
	_apply_bg_color()
	# 레이아웃 완료 후 스티커 생성 (size가 0일 수 있으므로)
	await get_tree().process_frame
	_generate_stickers()
	_restore_saved_progress()

func color_next_sticker() -> bool:
	## 다음 미복구 스티커를 컬러로 전환. 성공 시 true.
	for sticker in _stickers:
		if not sticker.is_colored():
			sticker.set_colored(false)  # 애니메이션 재생
			_restored_indices.append(sticker.sticker_index)
			SaveManager.save_sticker_progress(_current_chapter, _restored_indices)
			sticker_colored.emit(_current_chapter, sticker.sticker_index)
			return true
	return false  # 전부 복구됨

func get_remaining_count() -> int:
	var count = 0
	for sticker in _stickers:
		if not sticker.is_colored():
			count += 1
	return count

func is_chapter_complete() -> bool:
	return get_remaining_count() == 0

# ─────────────────────────────────────────
# 내부
# ─────────────────────────────────────────

func _clear_stickers() -> void:
	for s in _stickers:
		if is_instance_valid(s):
			s.queue_free()
	_stickers.clear()
	_restored_indices.clear()

func _apply_bg_color() -> void:
	var idx = _current_chapter - 1
	if idx < CHAPTER_BG_COLORS.size():
		_bg_rect.color = CHAPTER_BG_COLORS[idx]
	else:
		_bg_rect.color = Color(0.1, 0.1, 0.1)

func _generate_stickers() -> void:
	## 프로시저럴 오브젝트 10개 생성 — 챕터별 시드로 배치 위치 결정.
	var rng = RandomNumberGenerator.new()
	rng.seed = _current_chapter * 12345

	var area_w = size.x if size.x > 10 else 390.0
	var area_h = size.y if size.y > 10 else 844.0
	var margin = 30.0

	var palette = _get_palette(_current_chapter)

	for i in range(OBJECTS_PER_CHAPTER):
		var sticker = _create_procedural_sticker(i, rng, palette, area_w, area_h, margin)
		add_child(sticker)
		_stickers.append(sticker)

func _get_palette(chapter: int) -> Array:
	var idx = (chapter - 1) % STICKER_PALETTES.size()
	return STICKER_PALETTES[idx]

func _create_procedural_sticker(index: int, rng: RandomNumberGenerator,
		palette: Array, area_w: float, area_h: float, margin: float) -> TextureRect:
	## 프로시저럴 도형 텍스처를 가진 StickerObject 생성.
	var sticker = TextureRect.new()
	sticker.set_script(STICKER_SCRIPT)
	sticker.sticker_index = index

	# 크기 (화면 비율 기반 스케일링)
	var scale_factor = area_w / 390.0
	var obj_size = rng.randf_range(40.0, 80.0) * scale_factor
	sticker.custom_minimum_size = Vector2(obj_size, obj_size)
	sticker.size = Vector2(obj_size, obj_size)

	# 위치 (겹침 최소화 — 그리드 기반 + 랜덤 오프셋)
	var cols = 3
	var rows = ceili(float(OBJECTS_PER_CHAPTER) / cols)
	var col = index % cols
	var row = index / cols
	var cell_w = (area_w - margin * 2) / cols
	var cell_h = (area_h - margin * 2) / rows
	var x = margin + col * cell_w + rng.randf_range(10.0, cell_w - obj_size - 10.0)
	var y = margin + row * cell_h + rng.randf_range(10.0, cell_h - obj_size - 10.0)
	sticker.position = Vector2(x, y)

	# 도형 텍스처 생성 (32px 고정으로 픽셀 루프 최소화, TextureRect가 스케일)
	var color = palette[index % palette.size()]
	var shape_type = index % 5
	var tex = _generate_shape_texture(32, color, shape_type)
	sticker.texture = tex
	sticker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sticker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	# 파티클 자식 추가
	_add_sparkle_particles(sticker, obj_size)

	# 초기 상태: 흑백
	sticker.set_grayscale()

	return sticker

func _generate_shape_texture(tex_size: int, color: Color, shape: int) -> ImageTexture:
	## 도형을 Image에 직접 그려서 텍스처 생성.
	var img = Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var center = Vector2(tex_size / 2.0, tex_size / 2.0)
	var radius = tex_size / 2.0 - 2.0

	match shape:
		0:  # 원
			for y in range(tex_size):
				for x in range(tex_size):
					var dist = Vector2(x, y).distance_to(center)
					if dist <= radius:
						img.set_pixel(x, y, color)
		1:  # 사각형 (둥근 모서리)
			var m = 4
			for y in range(m, tex_size - m):
				for x in range(m, tex_size - m):
					img.set_pixel(x, y, color)
		2:  # 다이아몬드
			for y in range(tex_size):
				for x in range(tex_size):
					var dx = absf(x - center.x)
					var dy = absf(y - center.y)
					if dx / radius + dy / radius <= 1.0:
						img.set_pixel(x, y, color)
		3:  # 삼각형
			for y in range(tex_size):
				var row_frac = float(y) / tex_size
				var half_w = row_frac * radius
				for x in range(tex_size):
					if absf(x - center.x) <= half_w and y >= 2:
						img.set_pixel(x, y, color)
		_:  # 별 (5꼭지)
			for y in range(tex_size):
				for x in range(tex_size):
					var angle = atan2(y - center.y, x - center.x)
					var dist = Vector2(x, y).distance_to(center)
					var r = radius * (0.5 + 0.5 * absf(cos(2.5 * angle)))
					if dist <= r:
						img.set_pixel(x, y, color)

	return ImageTexture.create_from_image(img)

func _add_sparkle_particles(parent: Node, obj_size: float) -> void:
	## 반짝이 파티클 — CPUParticles2D (모바일 호환).
	var particles = CPUParticles2D.new()
	particles.name = "Particles"
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.5
	particles.explosiveness = 0.9
	particles.position = Vector2(obj_size / 2.0, obj_size / 2.0)
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 80.0
	particles.gravity = Vector2(0, 60)
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.0
	particles.color = Color(1.0, 0.95, 0.6, 0.9)

	parent.add_child(particles)

func _restore_saved_progress() -> void:
	## 세이브에서 이미 복구된 스티커들을 즉시 컬러로.
	_restored_indices = SaveManager.get_sticker_progress(_current_chapter).duplicate()
	for sticker in _stickers:
		if sticker.sticker_index in _restored_indices:
			sticker.set_colored(true)  # 즉시 (애니메이션 없이)
