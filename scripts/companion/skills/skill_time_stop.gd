extends SkillBase
## K11: 시간정지 — N초간 타이머 일시 정지 (인피니티 전용).

const N := 10.0

func _init() -> void:
	skill_id = "K11"
	skill_name = "시간정지"

func execute(context: Dictionary, _target) -> Dictionary:
	var gm = context.get("game_manager")
	if gm == null:
		return { "success": false, "actions": [] }
	if gm._current_mode == null:
		return { "success": false, "actions": [] }
	gm._current_mode.pause_timer(N)
	return {
		"success": true,
		"actions": [{ "type": "time_stop", "duration": N }]
	}

func can_use(context: Dictionary) -> bool:
	return context.get("mode", "") == "infinity"

func get_description() -> String:
	return "타이머를 %d초간 정지합니다. (인피니티 전용)" % int(N)
