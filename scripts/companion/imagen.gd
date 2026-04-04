class_name ImagenData
extends Resource

## 이마젠 데이터 구조 (Resource).
## 이름, 속성, 스킬 ID, 쿨타임, 해금 조건을 포함.

@export var id: String = ""
@export var display_name: String = ""
@export var attribute: String = "fire"  # fire | water | grass | light | dark
@export var description: String = ""
@export var skill_id: String = "K1"     # K1~K11
@export var cooldown: int = 4           # 스킬 쿨타임 (턴 수)
@export var unlock_condition: Dictionary = {}
# 예: { "type": "story_clear", "chapter": 1, "stage": 3 }

func get_color() -> Color:
	match attribute:
		"fire":  return Color(1.0, 0.3, 0.2)
		"water": return Color(0.2, 0.5, 1.0)
		"grass": return Color(0.3, 0.8, 0.3)
		"light": return Color(1.0, 0.95, 0.6)
		"dark":  return Color(0.4, 0.2, 0.6)
		_:       return Color.WHITE

func get_skill_name() -> String:
	match skill_id:
		"K1":  return "단색폭풍"
		"K2":  return "무지개파동"
		"K3":  return "컬러스왑"
		"K4":  return "컬러봄"
		"K5":  return "행청소"
		"K6":  return "되감기"
		"K7":  return "미래의눈"
		"K8":  return "셔플"
		"K9":  return "큐뒤집기"
		"K10": return "시간의숨결"
		"K11": return "시간정지"
		_:     return skill_id
