extends SkillBase
## K9: 큐뒤집기 — 버퍼 큐의 색상 순서를 역순으로 뒤집기.

func _init() -> void:
	skill_id = "K9"
	skill_name = "큐뒤집기"

func execute(context: Dictionary, _target) -> Dictionary:
	var cq = context.get("color_queue")
	if cq == null:
		return { "success": false, "actions": [] }

	# 현재 색 이후 큐를 역순으로
	# ColorQueue._queue: [active, next1, next2, next3]
	# active는 그대로, next들만 뒤집기
	if cq._queue.size() <= 1:
		return { "success": true, "actions": [{ "type": "queue_flip_done" }] }

	var active = cq._queue[0]
	var rest: Array[int] = []
	for i in range(1, cq._queue.size()):
		rest.append(cq._queue[i])
	rest.reverse()
	cq._queue = [active] + rest

	return {
		"success": true,
		"actions": [{ "type": "queue_flip_done" }]
	}

func get_description() -> String:
	return "다음 색상 큐 순서를 역순으로 뒤집습니다."
