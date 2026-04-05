class_name DialogueUI
extends CanvasLayer

## 다이얼로그 UI 씬 컨트롤러.
## DialogueManager를 소유하고 입력 이벤트를 전달.

signal skip_requested       # 스토리 전체 스킵
signal exit_requested       # 스테이지 선택으로 나가기

const DialogueManagerScript = preload("res://scripts/story/dialogue_manager.gd")

@onready var _background: ColorRect = $Background
@onready var _char_left: Control = $CharacterLeft
@onready var _char_right: Control = $CharacterRight
@onready var _text_box: PanelContainer = $TextBox
@onready var _name_label: Label = $TextBox/VBox/NameLabel
@onready var _dialogue_text: RichTextLabel = $TextBox/VBox/DialogueText
@onready var _next_indicator: Label = $TextBox/NextIndicator
@onready var _skip_button: Button = $SkipButton
@onready var _exit_button: Button = $ExitButton
@onready var _skip_confirm: PanelContainer = $SkipConfirmPanel
@onready var _skip_confirm_ok: Button = $SkipConfirmPanel/VBox/ButtonRow/ConfirmOKButton
@onready var _skip_confirm_cancel: Button = $SkipConfirmPanel/VBox/ButtonRow/ConfirmCancelButton
@onready var _exit_confirm: PanelContainer = $ExitConfirmPanel
@onready var _exit_confirm_ok: Button = $ExitConfirmPanel/VBox/ButtonRow/ConfirmOKButton
@onready var _exit_confirm_cancel: Button = $ExitConfirmPanel/VBox/ButtonRow/ConfirmCancelButton

var _manager: DialogueManager = null
var _confirm_open: bool = false

# ─────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────

func _ready() -> void:
	_manager = DialogueManagerScript.new()
	_manager.name = "DialogueManager"
	add_child(_manager)
	_manager.setup(_dialogue_text, _name_label, _next_indicator, _char_left, _char_right)
	_manager.dialogue_finished.connect(_on_dialogue_finished)

	_skip_button.pressed.connect(_on_skip_button_pressed)
	_exit_button.pressed.connect(_on_exit_button_pressed)
	_skip_confirm_ok.pressed.connect(_on_skip_confirmed)
	_skip_confirm_cancel.pressed.connect(_close_confirms)
	_exit_confirm_ok.pressed.connect(_on_exit_confirmed)
	_exit_confirm_cancel.pressed.connect(_close_confirms)

	_skip_confirm.visible = false
	_exit_confirm.visible = false
	visible = false

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func start_dialogue(story_data: Array) -> void:
	visible = true
	_manager.start_dialogue(story_data)

func get_manager() -> DialogueManager:
	return _manager

# ─────────────────────────────────────────
# 입력 처리
# ─────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not visible or _confirm_open:
		return
	if event is InputEventScreenTouch and event.pressed:
		_manager.advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_manager.advance()
		get_viewport().set_input_as_handled()

# ─────────────────────────────────────────
# 버튼 핸들러
# ─────────────────────────────────────────

func _on_skip_button_pressed() -> void:
	_confirm_open = true
	_skip_confirm.visible = true

func _on_exit_button_pressed() -> void:
	_confirm_open = true
	_exit_confirm.visible = true

func _on_skip_confirmed() -> void:
	_confirm_open = false
	_skip_confirm.visible = false
	_manager.skip_all()

func _on_exit_confirmed() -> void:
	_confirm_open = false
	_exit_confirm.visible = false
	exit_requested.emit()

func _close_confirms() -> void:
	_confirm_open = false
	_skip_confirm.visible = false
	_exit_confirm.visible = false

# ─────────────────────────────────────────
# DialogueManager 시그널
# ─────────────────────────────────────────

func _on_dialogue_finished() -> void:
	skip_requested.emit()
