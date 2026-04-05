class_name ResultPopup
extends CanvasLayer

## 스테이지 결과 팝업 — 성공/실패 + 턴 추가 구매 흐름.

signal continue_requested()  # 턴 추가 후 게임 계속
signal retry_requested()     # 하트 소모 + 재도전
signal main_menu_requested() # 하트 소모 + 로비 복귀

@onready var _title_label: Label = $PanelContainer/VBox/TitleLabel
@onready var _message_label: Label = $PanelContainer/VBox/MessageLabel
@onready var _continue_button: Button = $PanelContainer/VBox/ButtonContainer/ContinueButton
@onready var _retry_button: Button = $PanelContainer/VBox/ButtonContainer/RetryButton
@onready var _main_menu_button: Button = $PanelContainer/VBox/ButtonContainer/MainMenuButton

func _ready() -> void:
	visible = false
	_continue_button.pressed.connect(_on_continue_pressed)
	_retry_button.pressed.connect(_on_retry_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func show_success() -> void:
	_title_label.text = "스테이지 클리어!"
	_message_label.visible = false
	_continue_button.visible = false
	_retry_button.visible = false
	_main_menu_button.text = "로비로 돌아가기"
	visible = true
	_animate_popup()

func show_fail() -> void:
	## 최종 실패 — 턴 추가 불가, 하트 소모.
	_title_label.text = "스테이지 실패"
	_message_label.visible = false
	_continue_button.visible = false
	_retry_button.visible = true
	_retry_button.text = "재도전"
	_main_menu_button.text = "로비로 돌아가기"
	visible = true
	_animate_popup()

func show_fail_with_continue(gem_cost: int) -> void:
	## 턴 추가 가능한 실패 — 젬으로 5턴 구매 제안.
	_title_label.text = "턴이 부족합니다!"
	_message_label.text = "💎 %d으로 5턴을 추가할 수 있습니다" % gem_cost
	_message_label.visible = true
	_continue_button.visible = true
	_continue_button.text = "💎 %d → 5턴 추가" % gem_cost
	_continue_button.disabled = GemManager.get_balance() < gem_cost
	_retry_button.visible = false
	_main_menu_button.text = "포기하기"
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

# ─────────────────────────────────────────
# 버튼 핸들러
# ─────────────────────────────────────────

func _on_continue_pressed() -> void:
	continue_requested.emit()

func _on_retry_pressed() -> void:
	retry_requested.emit()

func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()
