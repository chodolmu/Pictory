class_name PartySelect
extends VBoxContainer

## 편성 UI 컴포넌트.
## stage_confirm_popup 또는 stage_preview_popup에 포함.

signal party_updated(party_ids: Array[String])

@onready var _slot_container: HBoxContainer = $SlotContainer
@onready var _imagen_list: GridContainer = $ListScroll/ImagenList
@onready var _info_panel: PanelContainer = $InfoPanel
@onready var _info_name: Label = $InfoPanel/VBox/SkillName
@onready var _info_desc: RichTextLabel = $InfoPanel/VBox/SkillDescription
@onready var _info_cd: Label = $InfoPanel/VBox/CooldownInfo

var _mode: String = "story"
var _slots: Array[String] = ["", "", ""]  # 최대 3슬롯

# ─────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────

func setup(mode: String) -> void:
	_mode = mode
	_slots = ["", "", ""]

	# 저장된 파티 복원
	var saved = PartyManager.selected_party
	for i in range(mini(saved.size(), 3)):
		_slots[i] = saved[i]

	_refresh_slots()
	_refresh_list()
	_info_panel.visible = false

# ─────────────────────────────────────────
# 슬롯 UI
# ─────────────────────────────────────────

func _refresh_slots() -> void:
	for i in range(3):
		var slot_panel = _slot_container.get_child(i) if i < _slot_container.get_child_count() else null
		if slot_panel == null:
			continue
		var id = _slots[i]
		var name_label = slot_panel.get_node_or_null("VBox/NameLabel")
		var icon = slot_panel.get_node_or_null("VBox/ImagenIcon")
		var remove_btn = slot_panel.get_node_or_null("VBox/RemoveButton")
		var skill_label = slot_panel.get_node_or_null("VBox/SkillLabel")

		if id.is_empty():
			if name_label: name_label.text = "비어있음"
			if icon: icon.modulate = Color(0.5, 0.5, 0.5)
			if skill_label: skill_label.text = ""
			if remove_btn: remove_btn.visible = false
		else:
			var data = ImagenDatabase.get_imagen(id)
			if data == null:
				_slots[i] = ""
				continue
			if name_label: name_label.text = data.display_name
			if icon:
				icon.modulate = Color.WHITE
				_paint_icon(icon, data)
			if skill_label: skill_label.text = data.get_skill_name()
			if remove_btn:
				remove_btn.visible = true
				# 버튼 시그널 연결 (중복 방지)
				if not remove_btn.pressed.is_connected(_on_remove.bind(i)):
					remove_btn.pressed.connect(_on_remove.bind(i))

func _paint_icon(icon: Control, data: ImagenData) -> void:
	var bg = icon.get_node_or_null("BG")
	if bg is ColorRect:
		bg.color = data.get_color()

# ─────────────────────────────────────────
# 이마젠 목록
# ─────────────────────────────────────────

func _refresh_list() -> void:
	for child in _imagen_list.get_children():
		child.queue_free()
	await get_tree().process_frame

	for data in ImagenDatabase.get_all_list():
		var card = _create_card(data)
		_imagen_list.add_child(card)

func _create_card(data: ImagenData) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(80, 90)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# 아이콘 (속성 색상 사각형)
	var icon_rect = ColorRect.new()
	icon_rect.custom_minimum_size = Vector2(50, 50)
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon_rect)

	var name_lbl = Label.new()
	name_lbl.text = data.display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(name_lbl)

	var skill_lbl = Label.new()
	skill_lbl.text = data.get_skill_name()
	skill_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(skill_lbl)

	var unlocked = ImagenDatabase.is_unlocked(data.id)

	if not unlocked:
		# 미해금: 어둡게
		icon_rect.color = Color(0.15, 0.15, 0.15)
		panel.modulate = Color(0.5, 0.5, 0.5)
	else:
		icon_rect.color = data.get_color()

		var btn = Button.new()
		btn.text = ""
		btn.flat = true
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.add_child(btn)
		btn.pressed.connect(_on_card_pressed.bind(data))
		btn.mouse_entered.connect(_on_card_hovered.bind(data))

	return panel


# ─────────────────────────────────────────
# 이벤트
# ─────────────────────────────────────────

func _on_card_pressed(data: ImagenData) -> void:
	if data.id in _slots:
		return  # 중복 방지
	for i in range(3):
		if _slots[i].is_empty():
			_slots[i] = data.id
			_refresh_slots()
			_emit_party()
			return

func _on_card_hovered(data: ImagenData) -> void:
	_info_panel.visible = true
	_info_name.text = "%s — %s" % [data.display_name, data.get_skill_name()]
	_info_desc.text = data.description
	_info_cd.text = "쿨타임: %d턴" % data.cooldown

func _on_remove(slot: int) -> void:
	_slots[slot] = ""
	_refresh_slots()
	_emit_party()

func _emit_party() -> void:
	var ids: Array[String] = []
	for id in _slots:
		if not id.is_empty():
			ids.append(id)
	PartyManager.set_party(ids)
	party_updated.emit(ids)

func get_party() -> Array[String]:
	var ids: Array[String] = []
	for id in _slots:
		if not id.is_empty():
			ids.append(id)
	return ids
