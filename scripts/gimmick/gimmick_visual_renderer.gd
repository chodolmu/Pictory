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
