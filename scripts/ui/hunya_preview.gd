extends Control
## HunyaPreview — 후냐 캐릭터 프리뷰 (AI-only 도형 기반).

func _draw() -> void:
	var equipped = CollectionManager.get_equipped_hunya()
	var costume_id = equipped.get("costume", "costume_default")
	var acc_id = equipped.get("accessory", "acc_none")

	# preview_item_id 오버라이드
	if has_meta("preview_item_id"):
		costume_id = get_meta("preview_item_id")

	var costume_color = _get_item_color(costume_id, "costume", Color(0.91, 0.66, 0.49))
	var acc_color = _get_item_color(acc_id, "accessory", Color(1, 0, 0.6))

	var cx = size.x * 0.5
	var cy = size.y * 0.5

	# 몸통
	draw_circle(Vector2(cx, cy + 20), 40, costume_color)
	# 머리
	draw_circle(Vector2(cx, cy - 28), 28, costume_color.lightened(0.1))
	# 눈
	draw_circle(Vector2(cx - 8, cy - 30), 5, Color.BLACK)
	draw_circle(Vector2(cx + 8, cy - 30), 5, Color.BLACK)
	draw_circle(Vector2(cx - 7, cy - 31), 2, Color.WHITE)
	draw_circle(Vector2(cx + 9, cy - 31), 2, Color.WHITE)
	# 볼
	draw_circle(Vector2(cx - 16, cy - 20), 6, Color(1, 0.6, 0.6, 0.5))
	draw_circle(Vector2(cx + 16, cy - 20), 6, Color(1, 0.6, 0.6, 0.5))
	# 입
	draw_arc(Vector2(cx, cy - 16), 8, 0.2, PI - 0.2, 12, Color(0.5, 0.2, 0.2), 2.0)
	# 귀
	draw_circle(Vector2(cx - 26, cy - 40), 10, costume_color)
	draw_circle(Vector2(cx + 26, cy - 40), 10, costume_color)
	draw_circle(Vector2(cx - 26, cy - 40), 5, Color(1, 0.7, 0.7))
	draw_circle(Vector2(cx + 26, cy - 40), 5, Color(1, 0.7, 0.7))
	# 꼬리
	var tail_pts = PackedVector2Array([
		Vector2(cx + 38, cy + 40),
		Vector2(cx + 55, cy + 20),
		Vector2(cx + 60, cy + 50),
		Vector2(cx + 40, cy + 55)
	])
	draw_colored_polygon(tail_pts, costume_color)

	# 악세서리
	_draw_accessory(acc_id, acc_color, cx, cy)

func _draw_accessory(acc_id: String, color: Color, cx: float, cy: float) -> void:
	match acc_id:
		"acc_bow":
			# 리본 (두 원 + 중심)
			draw_circle(Vector2(cx - 16, cy - 58), 10, color)
			draw_circle(Vector2(cx + 16, cy - 58), 10, color)
			draw_circle(Vector2(cx, cy - 58), 6, color.darkened(0.2))
		"acc_hat":
			# 모자 (사각형)
			draw_rect(Rect2(cx - 24, cy - 72, 48, 24), color)
			draw_rect(Rect2(cx - 30, cy - 50, 60, 8), color.lightened(0.1))
		"acc_crown":
			# 왕관 (삼각형들)
			var crown_pts = PackedVector2Array([
				Vector2(cx - 20, cy - 50),
				Vector2(cx - 20, cy - 70),
				Vector2(cx - 10, cy - 60),
				Vector2(cx, cy - 74),
				Vector2(cx + 10, cy - 60),
				Vector2(cx + 20, cy - 70),
				Vector2(cx + 20, cy - 50)
			])
			draw_colored_polygon(crown_pts, color)
		"acc_glasses":
			# 안경 (두 원 테두리)
			draw_arc(Vector2(cx - 10, cy - 30), 8, 0, TAU, 16, color, 3.0)
			draw_arc(Vector2(cx + 10, cy - 30), 8, 0, TAU, 16, color, 3.0)
			draw_line(Vector2(cx - 2, cy - 30), Vector2(cx + 2, cy - 30), color, 2.0)
		"acc_flower":
			# 꽃 (원들)
			for i in range(5):
				var angle = (TAU / 5.0) * i - PI * 0.5
				var fx = cx + cos(angle) * 14
				var fy = cy - 58 + sin(angle) * 14
				draw_circle(Vector2(fx, fy), 7, color)
			draw_circle(Vector2(cx, cy - 58), 7, Color.YELLOW)

func _get_item_color(item_id: String, category: String, fallback: Color) -> Color:
	var all = CollectionManager.get_all_hunya_items(category)
	for item in all:
		if item.get("id", "") == item_id:
			return Color(item.get("color", "#FFFFFF"))
	return fallback
