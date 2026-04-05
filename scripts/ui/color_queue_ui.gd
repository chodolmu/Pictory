class_name ColorQueueUI
extends Control

## 활성 색상(큰 원) + 다음 3개(작은 원) 표시 UI.

const ACTIVE_RADIUS: float = 24.0
const NEXT_RADIUS: float = 14.0
const SPACING: float = 12.0

var _color_queue = null

func _ready() -> void:
	custom_minimum_size.x = 200.0

func setup(queue) -> void:
	_color_queue = queue
	queue_redraw()

func refresh() -> void:
	queue_redraw()

func _draw() -> void:
	if _color_queue == null:
		return

	var palette = GridView.COLOR_PALETTE

	# Active color (큰 원)
	var active_color = _color_queue.get_active_color()
	var active_pos = Vector2(ACTIVE_RADIUS + 8.0, ACTIVE_RADIUS + 8.0)
	draw_circle(active_pos, ACTIVE_RADIUS, palette[active_color])
	draw_arc(active_pos, ACTIVE_RADIUS, 0.0, TAU, 32, Color.WHITE, 2.0)

	# Next colors (작은 원들)
	var next_colors = _color_queue.get_next_colors()
	var next_x = active_pos.x + ACTIVE_RADIUS + SPACING + NEXT_RADIUS
	for i in range(next_colors.size()):
		var pos = Vector2(next_x, active_pos.y)
		draw_circle(pos, NEXT_RADIUS, palette[next_colors[i]])
		draw_arc(pos, NEXT_RADIUS, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.6), 1.5)
		next_x += NEXT_RADIUS * 2.0 + SPACING * 0.5
