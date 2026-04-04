class_name HUD
extends Control

## HUD: 스테이지/턴/파괴/목표 + progress bar + chain 표시.

@onready var stage_label: Label = $TopBar/StageLabel
@onready var turn_label: Label = $TopBar/TurnLabel
@onready var destroyed_label: Label = $BottomBar/DestroyedLabel
@onready var goal_label: Label = $BottomBar/GoalLabel
@onready var chain_label: Label = $ChainLabel
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var progress_label: Label = $ProgressBar/ProgressLabel

var _mode: String = "story"
var _total_destroyed: int = 0
var _goal: int = 100

# ─────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────

func setup(mode: String, stage: int = 1, goal: int = 100, max_turns: int = 30) -> void:
	_mode = mode
	_goal = goal
	_total_destroyed = 0

	if mode == "story":
		stage_label.text = "Stage %d" % stage
		goal_label.text = "Goal: %d" % goal
		turn_label.text = "Turns: %d" % max_turns
		progress_bar.max_value = goal
		progress_bar.value = 0
		progress_label.text = "0 / %d" % goal
	else:
		stage_label.text = "Infinity"
		goal_label.text = ""
		turn_label.text = "Turns: 0"
		progress_bar.max_value = 1.0
		progress_bar.value = 1.0
		progress_label.text = ""

	chain_label.visible = false

# ─────────────────────────────────────────
# 갱신
# ─────────────────────────────────────────

func update_turns(used: int, remaining: int) -> void:
	if _mode == "story":
		turn_label.text = "Turns: %d" % remaining
	else:
		turn_label.text = "Turns: %d" % used

func update_destroyed(count: int) -> void:
	_total_destroyed += count
	destroyed_label.text = "Destroyed: %d" % _total_destroyed

	if _mode == "story":
		var tween = create_tween()
		tween.tween_property(progress_bar, "value", float(_total_destroyed), 0.3)
		progress_label.text = "%d / %d" % [_total_destroyed, _goal]
		_update_bar_color()

func setup_infinity_timer(time_limit: float) -> void:
	progress_bar.max_value = time_limit
	progress_bar.value = time_limit
	progress_label.text = "%d s" % int(time_limit)

func update_timer(remaining: float) -> void:
	progress_bar.value = remaining
	progress_label.text = "%d s" % int(remaining)
	_update_bar_color()

func show_chain(chain_count: int) -> void:
	if chain_count > 1:
		chain_label.text = "Chain x%d!" % chain_count
		chain_label.modulate.a = 1.0
		chain_label.visible = true
		var tween = create_tween()
		tween.tween_property(chain_label, "modulate:a", 0.0, 0.8).set_delay(0.7)
		tween.tween_callback(func(): chain_label.visible = false; chain_label.modulate.a = 1.0)
	else:
		chain_label.visible = false

# ─────────────────────────────────────────
# Progress bar 색상 그라데이션
# ─────────────────────────────────────────

func _update_bar_color() -> void:
	var ratio: float
	if _mode == "story":
		ratio = float(_total_destroyed) / float(_goal) if _goal > 0 else 0.0
	else:
		ratio = progress_bar.value / progress_bar.max_value if progress_bar.max_value > 0 else 0.0

	var color: Color
	if ratio > 0.6:
		color = Color.GREEN.lerp(Color.YELLOW, (1.0 - ratio) / 0.4)
	elif ratio > 0.3:
		color = Color.YELLOW.lerp(Color.ORANGE, (0.6 - ratio) / 0.3)
	else:
		color = Color.ORANGE.lerp(Color.RED, (0.3 - ratio) / 0.3 if ratio > 0.0 else 1.0)

	var style = progress_bar.get_theme_stylebox("fill").duplicate()
	if style is StyleBoxFlat:
		style.bg_color = color
		progress_bar.add_theme_stylebox_override("fill", style)
