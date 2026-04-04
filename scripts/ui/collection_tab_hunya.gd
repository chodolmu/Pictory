extends Control
## CollectionTabHunya — 후냐 커스터마이징 탭.

@onready var _preview: Control = $HSplit/PreviewPanel/Preview
@onready var _cat_costume_btn: Button = $HSplit/Right/VBox/CategoryBar/CostumeButton
@onready var _cat_acc_btn: Button = $HSplit/Right/VBox/CategoryBar/AccessoryButton
@onready var _grid: GridContainer = $HSplit/Right/VBox/Scroll/Grid
@onready var _item_name_label: Label = $HSplit/Right/VBox/InfoBar/ItemNameLabel
@onready var _equip_btn: Button = $HSplit/Right/VBox/InfoBar/EquipButton

var _current_category: String = "costume"
var _selected_item_id: String = ""

func _ready() -> void:
	_cat_costume_btn.pressed.connect(_on_category.bind("costume"))
	_cat_acc_btn.pressed.connect(_on_category.bind("accessory"))
	_equip_btn.pressed.connect(_on_equip)
	_equip_btn.disabled = true
	_cat_costume_btn.button_pressed = true
	_refresh_grid()
	_refresh_preview()

func _on_category(category: String) -> void:
	_current_category = category
	_cat_costume_btn.button_pressed = (category == "costume")
	_cat_acc_btn.button_pressed = (category == "accessory")
	_selected_item_id = ""
	_item_name_label.text = ""
	_equip_btn.disabled = true
	_equip_btn.text = "장착"
	_refresh_grid()

func _refresh_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var all_items = CollectionManager.get_all_hunya_items(_current_category)
	for item in all_items:
		var btn = _make_item_button(item)
		_grid.add_child(btn)

func _make_item_button(item: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(90, 90)
	btn.toggle_mode = true
	var item_id = item.get("id", "")
	var is_unlocked = CollectionManager.is_hunya_item_unlocked(item_id)
	var color = Color(item.get("color", "#FFFFFF"))
	var equipped = CollectionManager.get_equipped_hunya()
	var category = item.get("type", "costume")
	var is_equipped = (equipped.get(category, "") == item_id)
	if is_unlocked:
		btn.modulate = Color.WHITE
		btn.text = item.get("name", "")
		if is_equipped:
			btn.text += "\n[장착중]"
	else:
		btn.modulate = Color(0.2, 0.2, 0.2, 0.5)
		btn.text = "?"
	btn.pressed.connect(_on_item_selected.bind(item_id, item.get("name", ""), is_unlocked))
	return btn

func _on_item_selected(item_id: String, item_name: String, is_unlocked: bool) -> void:
	if not is_unlocked:
		_item_name_label.text = "미해금"
		_equip_btn.disabled = true
		return
	_selected_item_id = item_id
	_item_name_label.text = item_name
	var equipped = CollectionManager.get_equipped_hunya()
	var cat = _current_category
	var is_equipped = (equipped.get(cat, "") == item_id)
	if is_equipped:
		_equip_btn.text = "장착 중"
		_equip_btn.disabled = true
	else:
		_equip_btn.text = "장착"
		_equip_btn.disabled = false
	_refresh_preview_with(item_id)

func _on_equip() -> void:
	if _selected_item_id == "":
		return
	CollectionManager.equip_hunya_item(_selected_item_id)
	_equip_btn.text = "장착 중"
	_equip_btn.disabled = true
	_refresh_grid()
	_refresh_preview()

func _refresh_preview() -> void:
	var equipped = CollectionManager.get_equipped_hunya()
	var costume_id = equipped.get("costume", "costume_default")
	_refresh_preview_with(costume_id)

func _refresh_preview_with(item_id: String) -> void:
	_preview.queue_redraw()
	_preview.set_meta("preview_item_id", item_id)
