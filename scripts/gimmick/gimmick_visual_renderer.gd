class_name GimmickVisualRenderer
extends RefCounted

## 기믹 오버레이를 CanvasItem 위에 그리는 유틸리티.
## GridView._draw() 내에서 호출한다.

const RAINBOW_COLORS: Array = [
	Color(1.0, 0.2, 0.2, 1.0),  # 빨강
	Color(1.0, 0.6, 0.1, 1.0),  # 주황
	Color(1.0, 1.0, 0.1, 1.0),  # 노랑
	Color(0.2, 0.9, 0.2, 1.0),  # 초록
	Color(0.2, 0.5, 1.0, 1.0),  # 파랑
	Color(0.7, 0.2, 1.0, 1.0),  # 보라
]

static func draw_gimmick_overlay(canvas: CanvasItem, cell, rect: Rect2) -> void:
	var config = GimmickRegistry.get_handler(cell.gimmick_type).get_visual_config(cell)
	match config.get("type", "none"):
		"none":
			pass
		"replace":
			# 셀 전체를 교체 (돌 칸)
			canvas.draw_rect(rect, config["color"])
			# 약간 어두운 테두리
			var border_color = config.get("border_color", Color(0.3, 0.3, 0.3, 1.0))
			canvas.draw_rect(rect, border_color, false, 2.0)
		"overlay_rect":
			# 반투명 오버레이 (얼음 정상)
			canvas.draw_rect(rect, config["color"])
		"overlay_crack":
			# 반투명 오버레이 + 금 (얼음 crack)
			canvas.draw_rect(rect, config["color"])
			var crack_color = Color(1.0, 1.0, 1.0, 0.8)
			var cx = rect.position.x + rect.size.x * 0.5
			var cy = rect.position.y + rect.size.y * 0.5
			canvas.draw_line(Vector2(rect.position.x + 4, rect.position.y + 4),
				Vector2(cx, cy), crack_color, 1.5)
			canvas.draw_line(Vector2(cx, cy),
				Vector2(rect.end.x - 6, rect.end.y - 4), crack_color, 1.5)
			canvas.draw_line(Vector2(rect.position.x + 8, rect.end.y - 6),
				Vector2(cx - 2, cy + 4), crack_color, 1.0)
		"icon":
			# 아이콘 오버레이 (잠긴 칸 자물쇠)
			if config.get("icon") == "lock":
				_draw_lock_icon(canvas, rect, config.get("color", Color(0.5, 0.5, 0.5, 0.8)))
		"rainbow":
			# 무지개 6색 밴드
			var band_h = rect.size.y / float(RAINBOW_COLORS.size())
			for i in range(RAINBOW_COLORS.size()):
				var band_rect = Rect2(rect.position.x, rect.position.y + i * band_h,
					rect.size.x, band_h + 1.0)
				canvas.draw_rect(band_rect, RAINBOW_COLORS[i])
		"icon" when config.get("icon") == "anchor":
			_draw_anchor_icon(canvas, rect, config.get("color", Color(0.2, 0.2, 0.2, 0.7)))
		"paint_bucket":
			_draw_paint_bucket_icon(canvas, rect, config.get("direction", "row"),
				config.get("color", Color(0.9, 0.5, 0.1, 0.85)))
		"coin":
			_draw_coin_icon(canvas, rect, config.get("color", Color(1.0, 0.85, 0.0, 0.9)))
		"chain_mult":
			_draw_chain_mult(canvas, rect, config.get("color", Color(1.0, 1.0, 1.0, 0.9)))
		"star":
			_draw_star_icon(canvas, rect, config.get("color", Color(1.0, 0.85, 0.0, 0.95)))
		"spread":
			_draw_spread_overlay(canvas, rect, config.get("color", Color(0.3, 0.7, 0.3, 0.7)))
		"fade":
			_draw_fade_overlay(canvas, rect, config)
		"time_icon":
			_draw_time_icon(canvas, rect, config.get("color", Color(1.0, 1.0, 1.0, 0.9)))
		"poison":
			_draw_poison_overlay(canvas, rect, config.get("color", Color(0.6, 0.2, 0.8, 0.5)))

static func _draw_lock_icon(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	var cx = rect.position.x + rect.size.x * 0.5
	var cy = rect.position.y + rect.size.y * 0.5
	var body_w = rect.size.x * 0.45
	var body_h = rect.size.y * 0.35
	var body_x = cx - body_w * 0.5
	var body_y = cy - body_h * 0.1
	# 자물쇠 몸체
	canvas.draw_rect(Rect2(body_x, body_y, body_w, body_h), color)
	# 자물쇠 고리 (호)
	var arc_radius = body_w * 0.35
	canvas.draw_arc(Vector2(cx, body_y), arc_radius, PI, 0.0, 12, color, 2.0)

static func _draw_anchor_icon(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	var cx = rect.position.x + rect.size.x * 0.5
	var cy = rect.position.y + rect.size.y * 0.5
	var r = rect.size.x * 0.18
	# 원 (앵커 위)
	canvas.draw_arc(Vector2(cx, cy - r * 1.5), r, 0, TAU, 12, color, 2.0)
	# 세로 막대
	canvas.draw_line(Vector2(cx, cy - r * 0.5), Vector2(cx, cy + r * 1.5), color, 2.0)
	# 가로 가지
	canvas.draw_line(Vector2(cx - r * 1.2, cy), Vector2(cx + r * 1.2, cy), color, 2.0)
	# 아래 갈고리
	canvas.draw_line(Vector2(cx - r * 1.2, cy), Vector2(cx - r * 1.2, cy + r), color, 2.0)
	canvas.draw_line(Vector2(cx + r * 1.2, cy), Vector2(cx + r * 1.2, cy + r), color, 2.0)

static func _draw_paint_bucket_icon(canvas: CanvasItem, rect: Rect2,
		direction: String, color: Color) -> void:
	var cx = rect.position.x + rect.size.x * 0.5
	var cy = rect.position.y + rect.size.y * 0.5
	var w = rect.size.x * 0.28
	var h = rect.size.y * 0.3
	# 페인트통 몸체
	canvas.draw_rect(Rect2(cx - w * 0.5, cy - h * 0.5, w, h), color)
	# 방향 화살표
	var arrow_color = Color(1.0, 1.0, 1.0, 0.9)
	if direction == "row":
		canvas.draw_line(Vector2(cx - w, cy + h), Vector2(cx + w, cy + h), arrow_color, 2.0)
		canvas.draw_line(Vector2(cx + w * 0.6, cy + h - 4), Vector2(cx + w, cy + h), arrow_color, 2.0)
		canvas.draw_line(Vector2(cx + w * 0.6, cy + h + 4), Vector2(cx + w, cy + h), arrow_color, 2.0)
	else:
		canvas.draw_line(Vector2(cx + w, cy - h * 0.5), Vector2(cx + w, cy + h), arrow_color, 2.0)
		canvas.draw_line(Vector2(cx + w - 4, cy + h * 0.6), Vector2(cx + w, cy + h), arrow_color, 2.0)
		canvas.draw_line(Vector2(cx + w + 4, cy + h * 0.6), Vector2(cx + w, cy + h), arrow_color, 2.0)

static func _draw_coin_icon(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	var cx = rect.position.x + rect.size.x * 0.5
	var cy = rect.position.y + rect.size.y * 0.5
	var r = rect.size.x * 0.22
	canvas.draw_arc(Vector2(cx, cy), r, 0, TAU, 16, color, 3.0)

static func _draw_chain_mult(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	# "×2" 텍스트 위치 (우하단)
	var font_color = Color(1.0, 1.0, 0.2, 0.95)
	var pos = Vector2(rect.position.x + rect.size.x * 0.45, rect.end.y - 4)
	canvas.draw_string(ThemeDB.fallback_font, pos, "x2", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, font_color)

static func _draw_star_icon(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	var cx = rect.position.x + rect.size.x * 0.5
	var cy = rect.position.y + rect.size.y * 0.5
	var outer_r = rect.size.x * 0.28
	var inner_r = outer_r * 0.4
	var points: PackedVector2Array = []
	for i in range(10):
		var angle = i * TAU / 10.0 - TAU / 4.0
		var r = outer_r if i % 2 == 0 else inner_r
		points.append(Vector2(cx + r * cos(angle), cy + r * sin(angle)))
	canvas.draw_polygon(points, PackedColorArray([color]))

static func _draw_spread_overlay(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	# 셀 하단에 물방울 삼각형 3개
	var bx = rect.position.x
	var by = rect.end.y - 8
	var drop_w = rect.size.x / 5.0
	for i in range(3):
		var dx = bx + rect.size.x * 0.2 + i * drop_w * 1.2
		var pts = PackedVector2Array([
			Vector2(dx, by),
			Vector2(dx - drop_w * 0.4, by + 7),
			Vector2(dx + drop_w * 0.4, by + 7)
		])
		canvas.draw_polygon(pts, PackedColorArray([color]))

static func _draw_fade_overlay(canvas: CanvasItem, rect: Rect2, config: Dictionary) -> void:
	var counter = config.get("turn_counter", -1)
	var alpha = 0.25 if counter <= 0 else 0.45
	canvas.draw_rect(rect, Color(0.9, 0.9, 0.9, alpha))

static func _draw_time_icon(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	var cx = rect.position.x + rect.size.x * 0.5
	var cy = rect.position.y + rect.size.y * 0.5
	var r = rect.size.x * 0.22
	canvas.draw_arc(Vector2(cx, cy), r, 0, TAU, 16, color, 2.0)
	canvas.draw_line(Vector2(cx, cy), Vector2(cx, cy - r * 0.7), color, 1.5)
	canvas.draw_line(Vector2(cx, cy), Vector2(cx + r * 0.5, cy), color, 1.5)

static func _draw_poison_overlay(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	canvas.draw_rect(rect, color)
	# 모서리 독 방울
	var drops = [
		Vector2(rect.position.x + 6, rect.position.y + 6),
		Vector2(rect.end.x - 6, rect.position.y + 6),
		Vector2(rect.position.x + 6, rect.end.y - 6),
	]
	for d in drops:
		canvas.draw_circle(d, 3.0, Color(0.8, 0.3, 1.0, 0.9))
