extends SkillBase
## K10: 시간의숨결 — 보너스 턴 +N (스토리 전용).

const N := 3

func _init() -> void:
	skill_id = "K10"
	skill_name = "시간의숨결"

func execute(context: Dictionary, _target) -> Dictionary:
	var tm = context.get("turn_manager")
	if tm == null:
		return { "success": false, "actions": [] }
	# TurnManager 또는 StoryMode에 직접 turns 추가
	var gm = context.get("game_manager")
	if gm and gm._current_mode:
		gm._current_mode.remaining_turns += N
		gm._hud.update_turns(0, gm._current_mode.remaining_turns)

	return {
		"success": true,
		"actions": [{ "type": "bonus_turns", "value": N }]
	}

func can_use(context: Dictionary) -> bool:
	return context.get("mode", "") == "story"

func get_description() -> String:
	return "턴을 %d회 추가합니다. (스토리 전용)" % N
