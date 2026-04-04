extends SkillBase
## K6: 되감기 — 직전 보드 상태로 복구.

func _init() -> void:
	skill_id = "K6"
	skill_name = "되감기"

func execute(context: Dictionary, _target) -> Dictionary:
	var gm = context.get("game_manager")
	if gm == null:
		return { "success": false, "actions": [] }
	var restored = gm.restore_snapshot()
	if not restored:
		return { "success": false, "actions": [] }
	return {
		"success": true,
		"actions": [{ "type": "undo_done" }]
	}

func can_use(context: Dictionary) -> bool:
	var gm = context.get("game_manager")
	if gm == null:
		return false
	return gm.has_snapshot()

func get_description() -> String:
	return "직전 1회 액션을 되돌립니다."
