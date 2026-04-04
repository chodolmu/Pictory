class_name MainMenu
extends Control

@onready var _nickname_label: Label = $VBox/Header/PlayerInfoContainer/NicknameLabel
@onready var _currency_label: Label = $VBox/Header/CurrencyLabel
@onready var _stage_select_btn: Button = $VBox/StageSelectButton
@onready var _infinity_btn: Button = $VBox/InfinityModeButton
@onready var _settings_btn: Button = $VBox/Header/SettingsButton
@onready var _achievements_btn: Button = $VBox/BottomButtons/AchievementsButton
@onready var _collection_btn: Button = $VBox/BottomButtons/CollectionButton
@onready var _shop_btn: Button = $VBox/BottomButtons/ShopButton
@onready var _infinity_confirm_popup = $InfinityConfirmPopup
@onready var _options_popup = $OptionsPopup
@onready var _confirm_quit_popup = $ConfirmQuitPopup

func _ready() -> void:
	_stage_select_btn.pressed.connect(_on_stage_select)
	_infinity_btn.pressed.connect(_on_infinity)
	_settings_btn.pressed.connect(_on_settings)
	_achievements_btn.pressed.connect(_on_placeholder.bind("업적"))
	_collection_btn.pressed.connect(_on_placeholder.bind("컬렉션"))
	_shop_btn.pressed.connect(_on_placeholder.bind("상점"))
	PlayerProfile.nickname_changed.connect(_update_player_info)
	_update_player_info()
	_update_currency_display()

func _update_player_info(_name: String = "") -> void:
	_nickname_label.text = PlayerProfile.get_nickname()

func _update_currency_display() -> void:
	_currency_label.text = "코인: %d" % SaveManager.get_currency()

func _on_stage_select() -> void:
	SceneManager.change_scene("res://scenes/main/stage_select.tscn")

func _on_infinity() -> void:
	_infinity_confirm_popup.show_popup()

func _on_settings() -> void:
	_options_popup.show_popup()

func _on_placeholder(feature_name: String) -> void:
	print("[placeholder] %s — S10/S11에서 구현 예정" % feature_name)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_confirm_quit_popup.show_popup()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_confirm_quit_popup.show_popup()
