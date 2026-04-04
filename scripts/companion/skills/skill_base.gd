class_name SkillBase
extends RefCounted

## 스킬 베이스 클래스. 모든 스킬은 이를 상속.

var skill_id: String = ""
var skill_name: String = ""
var target_type: int = 0  # SkillManager.TargetType

# 스킬 실행.
# context: { grid, color_queue, turn_manager, mode, game_manager }
# target: 타겟 선택 결과 (없으면 null)
# return: { success: bool, actions: Array }
func execute(context: Dictionary, target) -> Dictionary:
	return { "success": false, "actions": [] }

# 사용 가능 여부 (보드 상태에 따라)
func can_use(context: Dictionary) -> bool:
	return true

# 스킬 설명 텍스트
func get_description() -> String:
	return ""
