extends Control
## CollectionTabImagen — 이마젠 동료 편성 탭.

@onready var _back_btn: Button = $MarginContainer/VBox/TopBar/BackButton
@onready var _count_label: Label = $MarginContainer/VBox/CountLabel
@onready var _party_slot_0: Control = $MarginContainer/VBox/PartySlots/Slot0
@onready var _party_slot_1: Control = $MarginContainer/VBox/PartySlots/Slot1
@onready var _grid: GridContainer = $MarginContainer/VBox/Scroll/Grid
@onready var _detail_panel: Control = $MarginContainer/VBox/DetailPanel
@onready var _detail_name: Label = $MarginContainer/VBox/DetailPanel/VBox/NameLabel
@onready var _detail_attr: Label = $MarginContainer/VBox/DetailPanel/VBox/AttrLabel
@onready var _detail_skill: Label = $MarginContainer/VBox/DetailPanel/VBox/SkillLabel
@onready var _detail_desc: Label = $MarginContainer/VBox/DetailPanel/VBox/DescLabel
@onready var _assign_btn: Button = $MarginContainer/VBox/DetailPanel/VBox/Buttons/AssignButton
@onready var _unassign_btn: Button = $MarginContainer/VBox/DetailPanel/VBox/Buttons/UnassignButton

var _selected_imagen_id: String = ""

func _ready() -> void:
	_back_btn.pressed.connect(_on_back)
	_assign_btn.pressed.connect(_on_assign)
	_unassign_btn.pressed.connect(_on_unassign)
	_detail_panel.visible = false
	_refresh()

func _on_back() -> void:
	SceneManager.change_scene("res://scenes/main/main_menu.tscn")

func _refresh() -> void:
	_refresh_count()
	_refresh_party_slots()
	_refresh_grid()

func _refresh_count() -> void:
	var total = ImagenDatabase.get_all_list().size()
	var unlocked = ImagenDatabase.get_unlocked_list().size()
	_count_label.text = "수집: %d / %d 마리" % [unlocked, total]

func _refresh_party_slots() -> void:
	var party = PartyManager.selected_party
	_update_slot(_party_slot_0, party[0] if party.size() > 0 else "")
	_update_slot(_party_slot_1, party[1] if party.size() > 1 else "")

func _update_slot(slot: Control, imagen_id: String) -> void:
	var label = slot.get_node_or_null("Label")
	var preview = slot.get_node_or_null("Preview")
	if imagen_id == "":
		if label:
			label.text = "비어 있음"
		if preview:
			preview.modulate = Color(0.5, 0.5, 0.5, 0.5)
			preview.queue_redraw()
	else:
		var data = ImagenDatabase.get_imagen(imagen_id)
		if data and label:
			label.text = data.display_name
		if preview:
			preview.modulate = Color.WHITE
			preview.set_meta("imagen_id", imagen_id)
			preview.queue_redraw()

func _refresh_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var all_imagenes = ImagenDatabase.get_all_list()
	for data in all_imagenes:
		var btn = _make_imagen_button(data)
		_grid.add_child(btn)

func _make_imagen_button(data: ImagenData) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(90, 90)
	btn.toggle_mode = true
	var is_unlocked = ImagenDatabase.is_unlocked(data.id)
	if is_unlocked:
		btn.modulate = Color.WHITE
		btn.text = data.display_name
	else:
		btn.modulate = Color(0.1, 0.1, 0.1, 1.0)
		btn.text = "???"
	btn.pressed.connect(_on_imagen_selected.bind(data.id, is_unlocked))
	return btn

func _on_imagen_selected(imagen_id: String, is_unlocked: bool) -> void:
	if not is_unlocked:
		_detail_panel.visible = false
		return
	_selected_imagen_id = imagen_id
	var data = ImagenDatabase.get_imagen(imagen_id)
	if data == null:
		return
	_detail_name.text = data.display_name
	_detail_attr.text = "속성: " + data.attribute
	_detail_skill.text = "스킬: %s (쿨타임: %d턴)" % [data.get_skill_name(), data.cooldown]
	_detail_desc.text = data.description
	var party = PartyManager.selected_party
	var in_party = imagen_id in party
	_assign_btn.visible = not in_party
	_unassign_btn.visible = in_party
	_assign_btn.disabled = (party.size() >= PartyManager.MAX_PARTY_SIZE and not in_party)
	_detail_panel.visible = true

func _on_assign() -> void:
	if _selected_imagen_id == "":
		return
	var party = PartyManager.selected_party.duplicate()
	if _selected_imagen_id not in party and party.size() < PartyManager.MAX_PARTY_SIZE:
		party.append(_selected_imagen_id)
		PartyManager.set_party(party)
	_refresh()
	_on_imagen_selected(_selected_imagen_id, true)

func _on_unassign() -> void:
	if _selected_imagen_id == "":
		return
	var party = PartyManager.selected_party.duplicate()
	party.erase(_selected_imagen_id)
	PartyManager.set_party(party)
	_refresh()
	_on_imagen_selected(_selected_imagen_id, true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		SceneManager.change_scene("res://scenes/main/main_menu.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		SceneManager.change_scene("res://scenes/main/main_menu.tscn")
