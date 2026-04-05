class_name ColorQueue
extends RefCounted

## stride scheduling + random offset 방식 색상 큐.
## 큐 크기: 항상 4개 유지 (1 active + 3 next).

var stride_length: int = 3
var offset_range: int = 1
var num_colors: int = 5

var _queue: Array[int] = []
var _base_index: int = 0

func _init() -> void:
	pass

func initialize() -> void:
	_queue.clear()
	_base_index = 0
	_fill_queue()

func _fill_queue() -> void:
	while _queue.size() < 4:
		_queue.append(_generate_next())

func _generate_next() -> int:
	var base_color = _base_index % num_colors
	var offset = randi_range(-offset_range, offset_range)
	var color = (base_color + offset) % num_colors
	if color < 0:
		color += num_colors
	_base_index += 1

	# 연속 3회 동일 색 방지
	if _queue.size() >= 2 and _queue[-1] == color and _queue[-2] == color:
		color = (color + 1) % num_colors

	return color

func get_active_color() -> int:
	return _queue[0]

func get_next_colors() -> Array[int]:
	return _queue.slice(1, 4)

func advance() -> void:
	_queue.pop_front()
	_fill_queue()

func peek_all() -> Array[int]:
	return _queue.duplicate()
