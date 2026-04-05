class_name GridView
extends Control

## Grid 데이터를 화면에 렌더링하는 Control 노드.
## AI-only 원칙: ColorRect만 사용, 외부 에셋 없음.

signal cell_touched(x: int, y: int)

# ─────────────────────────────────────────
# 설정 파라미터
# ─────────────────────────────────────────

@export var cell_size: int = 48
@export var cell_gap: int = 2
@export var buffer_gap: int = 8
@export var buffer_alpha: float = 0.45

const COLOR_PALETTE: Array[Color] = [
	Color(0.91, 0.30, 0.24),   # 빨강
	Color(0.20, 0.60, 0.86),   # 파랑
	Color(0.18, 0.80, 0.44),   # 초록
	Color(0.95, 0.77, 0.06),   # 노랑
	Color(0.56, 0.27, 0.68),   # 보라
	Color(1.00, 0.60, 0.20),   # 주황 (확장용)
	Color(0.20, 0.80, 0.80),   # 청록 (확장용)
]
const COLOR_EMPTY: Color = Color(0.15, 0.15, 0.15)

# ─────────────────────────────────────────
# 내부 상태
# ─────────────────────────────────────────

const GimmickRegistryScript = preload("res://scripts/gimmick/gimmick_registry.gd")
const GimmickVisualRendererScript = preload("res://scripts/gimmick/gimmick_visual_renderer.gd")

var _grid: Grid = null
var _cell_rects: Dictionary = {}   # Vector2i(x,y) -> ColorRect (배경)
var _gimmick_rects: Dictionary = {} # Vector2i(x,y) -> Control (기믹 오버레이)
var _input_locked: bool = false

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func setup(grid: Grid) -> void:
	_grid = grid
	_clear_rects()
	_build_rects()
	_center_on_viewport()

func refresh() -> void:
	if not _grid:
		return
	var gs = _grid.grid_size
	for y in range(gs):
		for x in range(gs):
			_refresh_cell_rect(x, y)

func refresh_cell(x: int, y: int) -> void:
	var rect = _cell_rects.get(Vector2i(x, y))
	if not rect:
		return
	var cell = _grid.get_cell(x, y)
	if cell:
		rect.color = _cell_color(cell)

func lock_input() -> void:
	_input_locked = true

func unlock_input() -> void:
	_input_locked = false

## 파괴 애니메이션: 지정 셀들을 흰색으로 번쩍인 뒤 축소+페이드아웃 (약 0.3s).
## 완료까지 await한다.
func animate_destroy(cells: Array) -> void:
	if cells.is_empty():
		return

	var tween = create_tween()
	tween.set_parallel(true)

	for cell in cells:
		var key = Vector2i(cell.x, cell.y)
		var rect: ColorRect = _cell_rects.get(key)
		if rect == null:
			continue
		var overlay = _gimmick_rects.get(key)

		# 흰색 번쩍
		var orig_color = rect.color
		rect.color = Color.WHITE
		tween.tween_property(rect, "color", orig_color, 0.05)

		# 축소 + 페이드 아웃 (pivot 중앙)
		rect.pivot_offset = rect.size / 2.0
		tween.tween_property(rect, "scale", Vector2.ZERO, 0.25).set_delay(0.05)
		tween.tween_property(rect, "modulate:a", 0.0, 0.25).set_delay(0.05)

		if overlay:
			overlay.pivot_offset = overlay.size / 2.0
			tween.tween_property(overlay, "scale", Vector2.ZERO, 0.25).set_delay(0.05)
			tween.tween_property(overlay, "modulate:a", 0.0, 0.25).set_delay(0.05)

	await tween.finished

	# 애니메이션 완료 후 rect 상태 리셋 (refresh()가 새 색으로 덮어쓸 것)
	for cell in cells:
		var key = Vector2i(cell.x, cell.y)
		var rect: ColorRect = _cell_rects.get(key)
		if rect:
			rect.scale = Vector2.ONE
			rect.modulate.a = 1.0
		var overlay = _gimmick_rects.get(key)
		if overlay:
			overlay.scale = Vector2.ONE
			overlay.modulate.a = 1.0

## 중력 낙하 애니메이션: 각 셀을 from 위치에서 to 위치로 트윈 (약 0.2s).
## moves: Array of {from_x, from_y, to_x, to_y, color, ...}
## 완료까지 await한다.
func animate_gravity(moves: Array) -> void:
	if moves.is_empty():
		return

	var tween = create_tween()
	tween.set_parallel(true)

	for move in moves:
		var from_key = Vector2i(move["from_x"], move["from_y"])
		var to_key   = Vector2i(move["to_x"],   move["to_y"])

		var rect: ColorRect = _cell_rects.get(from_key)
		var overlay = _gimmick_rects.get(from_key)
		if rect == null:
			continue

		var to_pos = _cell_pixel_pos(move["to_x"], move["to_y"])
		tween.tween_property(rect, "position", to_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if overlay:
			tween.tween_property(overlay, "position", to_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await tween.finished

	# 위치 트윈 후 모든 rect를 그리드 데이터 기준으로 즉시 재배치
	# (refresh()가 색을 갱신하지만 position은 갱신 안 하므로 여기서 복원)
	if not _grid:
		return
	var gs = _grid.grid_size
	for y in range(gs):
		for x in range(gs):
			var key = Vector2i(x, y)
			var rect: ColorRect = _cell_rects.get(key)
			if rect:
				rect.position = _cell_pixel_pos(x, y)
			var overlay = _gimmick_rects.get(key)
			if overlay:
				overlay.position = _cell_pixel_pos(x, y)

# ─────────────────────────────────────────
# 내부 렌더링
# ─────────────────────────────────────────

func _clear_rects() -> void:
	for child in get_children():
		child.queue_free()
	_cell_rects.clear()
	_gimmick_rects.clear()

func _build_rects() -> void:
	if not _grid:
		return
	var gs = _grid.grid_size
	# main: y = 0 ~ gs-1 (buffer는 비표시)
	for y in range(gs):
		for x in range(gs):
			_create_cell_rect(x, y)

func _create_cell_rect(x: int, y: int) -> void:
	var cell = _grid.get_cell(x, y)
	if not cell:
		return
	var pos = _cell_pixel_pos(x, y)
	var sz = Vector2(cell_size, cell_size)

	# 배경 ColorRect
	var rect = ColorRect.new()
	rect.size = sz
	rect.position = pos
	rect.color = _cell_color(cell)
	add_child(rect)
	_cell_rects[Vector2i(x, y)] = rect

	# 기믹 오버레이 Control (_draw로 처리)
	var overlay = _GimmickOverlay.new()
	overlay.size = sz
	overlay.position = pos
	overlay.cell_ref = cell
	add_child(overlay)
	_gimmick_rects[Vector2i(x, y)] = overlay

func _create_separator() -> void:
	var gs = _grid.grid_size
	var sep = ColorRect.new()
	var total_width = gs * (cell_size + cell_gap) - cell_gap
	sep.size = Vector2(total_width, 2)
	# buffer와 main 사이 정중앙
	var buffer_bottom_y = gs * (cell_size + cell_gap)
	sep.position = Vector2(0, buffer_bottom_y + (buffer_gap - 2) / 2.0)
	sep.color = Color(1, 1, 1, 0.3)
	add_child(sep)

func _refresh_cell_rect(x: int, y: int) -> void:
	var key = Vector2i(x, y)
	var rect = _cell_rects.get(key)
	if not rect:
		return
	var cell = _grid.get_cell(x, y)
	if cell:
		rect.color = _cell_color(cell)
		# 기믹 오버레이 갱신
		var overlay = _gimmick_rects.get(key)
		if overlay:
			overlay.queue_redraw()

func _cell_pixel_pos(x: int, y: int) -> Vector2:
	var px = x * (cell_size + cell_gap)
	var py = y * (cell_size + cell_gap)
	return Vector2(px, py)

func _cell_color(cell: Cell) -> Color:
	var base: Color
	if cell.color < 0 or cell.color >= COLOR_PALETTE.size():
		base = Color.TRANSPARENT
	else:
		base = COLOR_PALETTE[cell.color]

	if cell.y < 0:  # buffer
		# fade-out: 위쪽일수록 더 투명
		var gs = _grid.grid_size
		var row_from_bottom = cell.y + gs  # 0 = 최상단 buffer, gs-1 = 최하단 buffer
		var alpha = buffer_alpha * (0.4 + 0.6 * float(row_from_bottom) / float(gs - 1))
		return Color(base.r, base.g, base.b, alpha)
	return base

func _center_on_viewport() -> void:
	if not _grid:
		return
	var gs = _grid.grid_size
	var total_width = gs * (cell_size + cell_gap) - cell_gap
	var total_height = gs * (cell_size + cell_gap) - cell_gap
	var vp_size = get_viewport_rect().size

	# HUD TopBar: 상단 60px, BottomBar: 하단 108px 확보
	const TOP_RESERVED: float = 60.0
	const BOTTOM_RESERVED: float = 108.0
	var usable_height = vp_size.y - TOP_RESERVED - BOTTOM_RESERVED
	var usable_top = TOP_RESERVED

	# 그리드�� usable 영역보다 크면 cell_size를 줄임
	if total_height > usable_height or total_width > vp_size.x - 24.0:
		var scale_h = usable_height / total_height
		var scale_w = (vp_size.x - 24.0) / total_width
		var scale = minf(scale_h, scale_w)
		cell_size = int(float(cell_size) * scale)
		cell_size = maxi(cell_size, 20)
		# 재계산
		total_width = gs * (cell_size + cell_gap) - cell_gap
		total_height = gs * (cell_size + cell_gap) - cell_gap
		# cell_rect 재빌드
		_clear_rects()
		_build_rects()

	var cx = (vp_size.x - total_width) / 2.0
	var cy = usable_top + (usable_height - total_height) / 2.0
	position = Vector2(cx, cy)

# ─────────────────────────────────────────
# 입력 처리
# ─────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if _input_locked or not _grid:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_touch(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch(event.position)

func _handle_touch(screen_pos: Vector2) -> void:
	var local_pos = screen_pos - global_position
	var gs = _grid.grid_size

	var gx = int(local_pos.x / (cell_size + cell_gap))
	var gy = int(local_pos.y / (cell_size + cell_gap))

	if gx < 0 or gx >= gs:
		return
	if gy < 0 or gy >= gs:
		return

	cell_touched.emit(gx, gy)

# ─────────────────────────────────────────
# 기믹 오버레이 내부 클래스
# ─────────────────────────────────────────

class _GimmickOverlay extends Control:
	var cell_ref = null

	func _draw() -> void:
		if cell_ref == null or not cell_ref.has_gimmick():
			return
		var rect = Rect2(Vector2.ZERO, size)
		GimmickVisualRenderer.draw_gimmick_overlay(self, cell_ref, rect)
