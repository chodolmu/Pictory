class_name ResultPopup
extends CanvasLayer

## 스테이지 클리어 / 게임오버 결과 팝업.

signal next_stage_requested()
signal retry_requested()
signal main_menu_requested()

@onready var _title_label: Label = $PanelContainer/VBox/TitleLabel
@onready var _stars_container = $PanelContainer/VBox/StarsContainer
@onready var _score_label: Label = $PanelContainer/VBox/ScoreLabel
@onready var _currency_label: Label = $PanelContainer/VBox/CurrencyLabel
@onready var _destroyed_label: Label = $PanelContainer/VBox/DestroyedLabel
@onready var _high_score_label: Label = $PanelContainer/VBox/HighScoreLabel
@onready var _next_stage_button: Button = $PanelContainer/VBox/ButtonContainer/NextStageButton
@onready var _retry_button: Button = $PanelContainer/VBox/ButtonContainer/RetryButton
@onready var _main_menu_button: Button = $PanelContainer/VBox/ButtonContainer/MainMenuButton

var _star_nodes: Array = []

func _ready() -> void:
	_star_nodes = [
		$PanelContainer/VBox/StarsContainer/Star1,
		$PanelContainer/VBox/StarsContainer/Star2,
		$PanelContainer/VBox/StarsContainer/Star3,
	]
	visible = false
	_next_stage_button.pressed.connect(_on_next_stage_pressed)
	_retry_button.pressed.connect(_on_retry_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func show_clear(stars: int, score: int, currency: int, has_next_stage: bool) -> void:
	_title_label.text = "스테이지 클리어!"
	_stars_container.visible = true
	_score_label.text = "점수: %s" % _format_number(score)
	_currency_label.text = "획득 재화: +%d" % currency
	_currency_label.visible = true
	_destroyed_label.visible = false
	_high_score_label.visible = false
	_next_stage_button.visible = true
	_next_stage_button.disabled = not has_next_stage

	_reset_stars()
	visible = true
	_animate_popup()
	_animate_stars(stars)

func show_game_over(score: int, extra_data: Dictionary = {}) -> void:
	_title_label.text = "게임 오버"
	_stars_container.visible = false
	_score_label.text = "점수: %s" % _format_number(score)
	_next_stage_button.visible = false

	if extra_data.has("currency") and extra_data["currency"] > 0:
		_currency_label.text = "획득 재화: +%d" % extra_data["currency"]
		_currency_label.visible = true
	else:
		_currency_label.visible = false

	if extra_data.has("total_destroyed"):
		_destroyed_label.visible = true
		_destroyed_label.text = "파괴 블록: %d개" % extra_data["total_destroyed"]
	else:
		_destroyed_label.visible = false

	if extra_data.has("is_new_record") and extra_data["is_new_record"]:
		_high_score_label.visible = true
		_high_score_label.modulate = Color.GOLD
		_high_score_label.text = "NEW! 최고 기록: %s" % _format_number(score)
	elif extra_data.has("high_score"):
		_high_score_label.visible = true
		_high_score_label.modulate = Color.WHITE
		_high_score_label.text = "최고 기록: %s" % _format_number(extra_data["high_score"])
	else:
		_high_score_label.visible = false

	visible = true
	_animate_popup()

# ─────────────────────────────────────────
# 내부 연출
# ─────────────────────────────────────────

func _animate_popup() -> void:
	var panel = $PanelContainer
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.3)

func _reset_stars() -> void:
	for star in _star_nodes:
		star.modulate = Color(0.4, 0.4, 0.4)
		star.scale = Vector2.ZERO

func _animate_stars(count: int) -> void:
	var tween = create_tween()
	for i in range(mini(count, _star_nodes.size())):
		var star = _star_nodes[i]
		tween.tween_property(star, "scale", Vector2.ONE, 0.3).from(Vector2.ZERO).set_trans(Tween.TRANS_BACK)
		tween.parallel().tween_property(star, "modulate", Color.YELLOW, 0.2)
		tween.tween_interval(0.1)

# ─────────────────────────────────────────
# 버튼 핸들러
# ─────────────────────────────────────────

func _on_next_stage_pressed() -> void:
	next_stage_requested.emit()

func _on_retry_pressed() -> void:
	retry_requested.emit()

func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()

# ─────────────────────────────────────────
# 유틸
# ─────────────────────────────────────────

func _format_number(n: int) -> String:
	var s = str(n)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
