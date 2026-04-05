extends Control
## Collection — 컬렉션 메인 화면. 3탭 전환.

@onready var _tab_hunya_btn: Button = $VBox/TabBar/HunyaTabButton
@onready var _tab_imagen_btn: Button = $VBox/TabBar/ImagenTabButton
@onready var _tab_icon_btn: Button = $VBox/TabBar/IconTabButton
@onready var _back_btn: Button = $VBox/Header/BackButton
@onready var _content_container: Control = $VBox/ContentContainer

const HUNYA_TAB = preload("res://scenes/ui/collection_tab_hunya.tscn")
const IMAGEN_TAB = preload("res://scenes/ui/collection_tab_imagen.tscn")
const ICON_TAB = preload("res://scenes/ui/collection_tab_icon.tscn")

var _current_tab: int = -1

func _ready() -> void:
	_back_btn.pressed.connect(_on_back)
	_tab_hunya_btn.pressed.connect(_on_tab.bind(0))
	_tab_imagen_btn.pressed.connect(_on_tab.bind(1))
	_tab_icon_btn.pressed.connect(_on_tab.bind(2))
	_on_tab(0)

func _on_tab(index: int) -> void:
	if _current_tab == index:
		return
	_current_tab = index
	_update_tab_buttons()
	_show_tab_content(index)

func _update_tab_buttons() -> void:
	_tab_hunya_btn.button_pressed = (_current_tab == 0)
	_tab_imagen_btn.button_pressed = (_current_tab == 1)
	_tab_icon_btn.button_pressed = (_current_tab == 2)

func _show_tab_content(index: int) -> void:
	for child in _content_container.get_children():
		child.queue_free()
	var tab
	match index:
		0: tab = HUNYA_TAB.instantiate()
		1: tab = IMAGEN_TAB.instantiate()
		2: tab = ICON_TAB.instantiate()
	_content_container.add_child(tab)

func _on_back() -> void:
	SceneManager.change_scene("res://scenes/main/stage_select.tscn")
