class_name SkillHUD
extends HBoxContainer

## 인게임 스킬 버튼 HUD.
## SkillManager와 연동하여 쿨타임/상태를 시각화.

signal skill_button_pressed(slot: int)

var _skill_manager: SkillManager = null
var _buttons: Array[Control] = []

const BTN_SIZE = Vector2(60, 60)

# ─────────────────────────────────────────
# 초기화
# ─────────────────────────────────────────

func setup(skill_manager: SkillManager) -> void:
	_skill_manager = skill_manager
	_rebuild_buttons()

	skill_manager.skill_cooldown_updated.connect(_on_cooldown_updated)
	skill_manager.skill_ready.connect(_on_skill_ready)

func _rebuild_buttons() -> void:
	# 기존 버튼 제거
	for child in get_children():
		child.queue_free()
	_buttons.clear()
	await get_tree().process_frame

	var count = _skill_manager.get_slot_count()
	visible = count > 0

	for i in range(count):
		var info = _skill_manager.get_slot_info(i)
		var btn = _create_skill_button(i, info)
		add_child(btn)
		_buttons.append(btn)

func _create_skill_button(slot: int, info: Dictionary) -> Control:
	var container = Control.new()
	container.custom_minimum_size = BTN_SIZE

	# 배경
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var img_data = ImagenDatabase.get_imagen(info.get("imagen_id", ""))
	bg.color = img_data.get_color() if img_data else Color(0.4, 0.4, 0.4)
	container.add_child(bg)

	# 쿨타임 오버레이
	var overlay = ColorRect.new()
	overlay.name = "CooldownOverlay"
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchor(SIDE_LEFT, 0.0)
	overlay.set_anchor(SIDE_RIGHT, 1.0)
	overlay.set_anchor(SIDE_TOP, 0.0)
	overlay.set_anchor(SIDE_BOTTOM, 0.0)
	overlay.offset_bottom = 0.0
	overlay.visible = false
	container.add_child(overlay)

	# 쿨타임 숫자
	var cd_label = Label.new()
	cd_label.name = "CooldownLabel"
	cd_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_label.add_theme_font_size_override("font_size", 20)
	cd_label.visible = false
	container.add_child(cd_label)

	# 스킬 이름
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.text = info.get("display_name", "")
	container.add_child(name_label)

	# 탭 처리용 버튼
	var btn = Button.new()
	btn.name = "TouchArea"
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.pressed.connect(_on_button_pressed.bind(slot))
	container.add_child(btn)

	return container

# ─────────────────────────────────────────
# 상태 갱신
# ─────────────────────────────────────────

func _on_cooldown_updated(slot: int, remaining: int) -> void:
	if slot >= _buttons.size():
		return
	var btn_ctrl = _buttons[slot]
	var overlay = btn_ctrl.get_node_or_null("CooldownOverlay")
	var cd_label = btn_ctrl.get_node_or_null("CooldownLabel")

	if remaining > 0:
		var info = _skill_manager.get_slot_info(slot)
		var max_cd = info.get("cooldown_max", 1)
		var ratio = float(remaining) / float(max_cd)
		if overlay:
			overlay.visible = true
			overlay.offset_bottom = BTN_SIZE.y * ratio
		if cd_label:
			cd_label.visible = true
			cd_label.text = str(remaining)
	else:
		if overlay: overlay.visible = false
		if cd_label: cd_label.visible = false

func _on_skill_ready(slot: int) -> void:
	if slot >= _buttons.size():
		return
	_on_cooldown_updated(slot, 0)
	# "READY" 플래시 효과
	var btn_ctrl = _buttons[slot]
	var tween = create_tween()
	tween.tween_property(btn_ctrl, "modulate", Color(1.5, 1.5, 1.5), 0.15)
	tween.tween_property(btn_ctrl, "modulate", Color.WHITE, 0.15)

# ─────────────────────────────────────────
# 버튼 탭
# ─────────────────────────────────────────

func _on_button_pressed(slot: int) -> void:
	if not _skill_manager.is_skill_ready(slot):
		_shake_button(slot)
		return
	skill_button_pressed.emit(slot)

func _shake_button(slot: int) -> void:
	if slot >= _buttons.size():
		return
	var btn_ctrl = _buttons[slot]
	var original_pos = btn_ctrl.position
	var tween = create_tween()
	tween.tween_property(btn_ctrl, "position", original_pos + Vector2(4, 0), 0.05)
	tween.tween_property(btn_ctrl, "position", original_pos - Vector2(4, 0), 0.05)
	tween.tween_property(btn_ctrl, "position", original_pos, 0.05)
