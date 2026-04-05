class_name MainMenu
extends Control

@onready var _nickname_label: Label = $MarginContainer/VBox/Header/PlayerInfoContainer/NicknameLabel
@onready var _currency_label: Label = $MarginContainer/VBox/Header/CurrencyLabel
@onready var _stage_select_btn: Button = $MarginContainer/VBox/StageSelectButton
@onready var _infinity_btn: Button = $MarginContainer/VBox/InfinityModeButton
@onready var _settings_btn: Button = $MarginContainer/VBox/Header/SettingsButton
@onready var _achievements_btn: Button = $MarginContainer/VBox/BottomButtons/AchievementsButton
@onready var _collection_btn: Button = $MarginContainer/VBox/BottomButtons/CollectionButton
@onready var _shop_btn: Button = $MarginContainer/VBox/BottomButtons/ShopButton

# 팝업은 클릭 시 /root에 동적 생성 — CanvasLayer는 Control 자식으로 추가하면 잘림
const _INFINITY_POPUP_SCENE = "res://scenes/ui/infinity_confirm_popup.tscn"
const _OPTIONS_POPUP_SCENE = "res://scenes/ui/options_popup.tscn"
const _CONFIRM_QUIT_POPUP_SCENE = "res://scenes/ui/confirm_quit_popup.tscn"

var _infinity_confirm_popup = null
var _options_popup = null
var _confirm_quit_popup = null

func _ready() -> void:
	_stage_select_btn.pressed.connect(_on_stage_select)
	_infinity_btn.pressed.connect(_on_infinity)
	_settings_btn.pressed.connect(_on_settings)
	_achievements_btn.pressed.connect(_on_achievements)
	_collection_btn.pressed.connect(_on_collection)
	_shop_btn.pressed.connect(_on_shop)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	PlayerProfile.nickname_changed.connect(_update_player_info)
	_update_player_info()
	_update_currency_display()
	_update_achievement_badge()

func _update_player_info(_name: String = "") -> void:
	_nickname_label.text = PlayerProfile.get_nickname()

func _update_currency_display() -> void:
	_currency_label.text = "💰 %d" % SaveManager.get_currency()

func _get_or_create_popup(var_ref: String, scene_path: String) -> Node:
	# 팝업이 없거나 이미 해제됐으면 새로 만들어서 /root에 추가
	var popup = get(var_ref)
	if popup == null or not is_instance_valid(popup):
		popup = load(scene_path).instantiate()
		get_tree().root.add_child(popup)
		set(var_ref, popup)
	return popup

func _on_stage_select() -> void:
	_free_popups()
	SceneManager.change_scene("res://scenes/main/stage_select.tscn")

func _on_infinity() -> void:
	var popup = _get_or_create_popup("_infinity_confirm_popup", _INFINITY_POPUP_SCENE)
	popup.show_popup()

func _on_settings() -> void:
	var popup = _get_or_create_popup("_options_popup", _OPTIONS_POPUP_SCENE)
	popup.show_popup()

func _on_shop() -> void:
	_free_popups()
	SceneManager.change_scene("res://scenes/ui/shop.tscn")

func _on_collection() -> void:
	_free_popups()
	SceneManager.change_scene("res://scenes/ui/collection.tscn")

func _on_achievements() -> void:
	var popup = load("res://scenes/ui/achievement_popup.tscn").instantiate()
	get_tree().root.add_child(popup)
	while AchievementManager.has_pending_popups():
		popup.show_achievement(AchievementManager.pop_pending_popup())

func _on_achievement_unlocked(_id: String) -> void:
	_update_achievement_badge()

func _update_achievement_badge() -> void:
	var unclaimed = AchievementManager.get_unclaimed_count()
	if _achievements_btn:
		_achievements_btn.text = "업적" if unclaimed == 0 else "업적 (%d)" % unclaimed

func _free_popups() -> void:
	if _infinity_confirm_popup and is_instance_valid(_infinity_confirm_popup):
		_infinity_confirm_popup.queue_free()
		_infinity_confirm_popup = null
	if _options_popup and is_instance_valid(_options_popup):
		_options_popup.queue_free()
		_options_popup = null
	if _confirm_quit_popup and is_instance_valid(_confirm_quit_popup):
		_confirm_quit_popup.queue_free()
		_confirm_quit_popup = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		var popup = _get_or_create_popup("_confirm_quit_popup", _CONFIRM_QUIT_POPUP_SCENE)
		popup.show_popup()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var popup = _get_or_create_popup("_confirm_quit_popup", _CONFIRM_QUIT_POPUP_SCENE)
		popup.show_popup()
