class_name DevAdProvider
extends RefCounted
## 개발용 광고 스텁. 즉시 보상 지급.

signal ad_reward_granted(reward_type: String)
signal ad_failed(reason: String)
signal ad_closed()

func is_ready() -> bool:
	return true

func show_rewarded_ad() -> void:
	print("[AdManager-DEV] 광고 스텁 실행됨")
	# 0.5초 후 보상 시그널 (실제 광고 시청 흉내)
	var timer = Timer.new()
	Engine.get_main_loop().root.add_child(timer)
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(func():
		timer.queue_free()
		ad_reward_granted.emit("rewarded")
	)
	timer.start()
