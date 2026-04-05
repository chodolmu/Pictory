extends CanvasLayer
## SceneManager — Autoload 싱글턴.
## 페이드 아웃 → 씬 교체 → 페이드 인 트랜지션 + 파라미터 전달.

signal scene_changed(scene_path: String)

@export var fade_duration: float = 0.3
@export var fade_color: Color = Color.BLACK

var _transition_params: Dictionary = {}
var _color_rect: ColorRect
var _is_transitioning: bool = false

func _ready() -> void:
	layer = 100
	_setup_fade_overlay()

func _setup_fade_overlay() -> void:
	_color_rect = ColorRect.new()
	_color_rect.color = fade_color
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.modulate.a = 0.0
	add_child(_color_rect)
	_color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func change_scene(scene_path: String, params: Dictionary = {}) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_transition_params = params
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(_color_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished
	_do_change_scene(scene_path)

func _do_change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
	scene_changed.emit(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tween = create_tween()
	tween.tween_property(_color_rect, "modulate:a", 0.0, fade_duration)
	await tween.finished
	_on_transition_complete()

func _on_transition_complete() -> void:
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false

func get_params() -> Dictionary:
	return _transition_params

func get_param(key: String, default = null):
	return _transition_params.get(key, default)
