class_name OptionsPopup
extends CanvasLayer

const BGM_BUS := "BGM"
const SE_BUS := "SE"

@onready var _dim_overlay: ColorRect = $DimOverlay
@onready var _panel: PanelContainer = $PanelContainer
@onready var _bgm_slider: HSlider = $PanelContainer/VBox/BGMContainer/BGMSlider
@onready var _se_slider: HSlider = $PanelContainer/VBox/SEContainer/SESlider
@onready var _nickname_edit: LineEdit = $PanelContainer/VBox/NicknameContainer/NicknameLineEdit
@onready var _apply_btn: Button = $PanelContainer/VBox/ButtonContainer/ApplyButton
@onready var _back_btn: Button = $PanelContainer/VBox/ButtonContainer/BackButton
@onready var _nickname_apply_btn: Button = $PanelContainer/VBox/NicknameContainer/NicknameApplyButton
@onready var _quit_btn: Button = $PanelContainer/VBox/QuitGameButton

var _pending_bgm_vol: float = 80.0
var _pending_se_vol: float = 80.0

func _ready() -> void:
	_bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	_se_slider.value_changed.connect(_on_se_slider_changed)
	_apply_btn.pressed.connect(_on_apply_pressed)
	_back_btn.pressed.connect(_on_back_pressed)
	_nickname_apply_btn.pressed.connect(_on_nickname_apply_pressed)
	_quit_btn.pressed.connect(_on_quit_game_pressed)
	visible = false

func show_popup() -> void:
	var settings = SaveManager.get_settings()
	_bgm_slider.value = settings.get("bgm_volume", 80)
	_se_slider.value = settings.get("se_volume", 80)
	_pending_bgm_vol = _bgm_slider.value
	_pending_se_vol = _se_slider.value
	_nickname_edit.text = PlayerProfile.get_nickname()
	visible = true
	_animate_show()

func hide_popup() -> void:
	var tween = create_tween()
	tween.tween_property(_dim_overlay, "modulate:a", 0.0, 0.15)
	tween.parallel().tween_property(_panel, "scale", Vector2(0.8, 0.8), 0.15)
	tween.tween_callback(func(): visible = false)

func _animate_show() -> void:
	_dim_overlay.modulate.a = 0.0
	_panel.scale = Vector2(0.8, 0.8)
	var tween = create_tween()
	tween.tween_property(_dim_overlay, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_bgm_slider_changed(value: float) -> void:
	_pending_bgm_vol = value
	_apply_volume_preview(BGM_BUS, value)

func _on_se_slider_changed(value: float) -> void:
	_pending_se_vol = value
	_apply_volume_preview(SE_BUS, value)

func _apply_volume_preview(bus_name: String, value: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))

func _on_apply_pressed() -> void:
	SaveManager.save_settings({
		"bgm_volume": _pending_bgm_vol,
		"se_volume": _pending_se_vol
	})
	hide_popup()

func _on_back_pressed() -> void:
	var settings = SaveManager.get_settings()
	_apply_volume_preview(BGM_BUS, settings.get("bgm_volume", 80))
	_apply_volume_preview(SE_BUS, settings.get("se_volume", 80))
	hide_popup()

func _on_nickname_apply_pressed() -> void:
	var new_name = _nickname_edit.text.strip_edges()
	if new_name.length() > 0:
		PlayerProfile.set_nickname(new_name)

func _on_quit_game_pressed() -> void:
	hide_popup()
	var quit_popup = get_parent().get_node_or_null("ConfirmQuitPopup")
	if quit_popup:
		quit_popup.show_popup()
