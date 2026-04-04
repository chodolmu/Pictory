extends Node
## AdManager — Autoload 싱글턴.
## 광고 SDK 인터페이스. 현재는 DevAdProvider 스텁으로 동작.

const DevAdProviderScript = preload("res://scripts/data/dev_ad_provider.gd")

@export var daily_ad_limit: int = 10

signal ad_reward_granted(reward_type: String)
signal ad_failed(reason: String)
signal ad_closed()

var _provider: RefCounted = null
var _daily_ad_count: int = 0
var _last_ad_date: String = ""

func _ready() -> void:
	_provider = DevAdProviderScript.new()
	_provider.ad_reward_granted.connect(_on_reward_granted)
	_provider.ad_failed.connect(_on_ad_failed)
	_provider.ad_closed.connect(_on_ad_closed)
	_load_ad_data()
	_check_daily_reset()

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func is_rewarded_ad_ready() -> bool:
	return _provider.is_ready()

func show_rewarded_ad() -> void:
	_check_daily_reset()
	if not can_show_ad():
		ad_failed.emit("일일 광고 제한 초과")
		return
	_provider.show_rewarded_ad()

func get_daily_ad_count() -> int:
	_check_daily_reset()
	return _daily_ad_count

func get_daily_ad_limit() -> int:
	return daily_ad_limit

func can_show_ad() -> bool:
	_check_daily_reset()
	return _daily_ad_count < daily_ad_limit and is_rewarded_ad_ready()

# ─────────────────────────────────────────
# 내부
# ─────────────────────────────────────────

func _check_daily_reset() -> void:
	var today = Time.get_date_string_from_system()
	if _last_ad_date != today:
		_daily_ad_count = 0
		_last_ad_date = today
		_save_ad_data()

func _on_reward_granted(reward_type: String) -> void:
	_daily_ad_count += 1
	_save_ad_data()
	ad_reward_granted.emit(reward_type)

func _on_ad_failed(reason: String) -> void:
	ad_failed.emit(reason)

func _on_ad_closed() -> void:
	ad_closed.emit()

func _save_ad_data() -> void:
	SaveManager.save_ad_data({
		"daily_ad_count": _daily_ad_count,
		"last_ad_date": _last_ad_date
	})

func _load_ad_data() -> void:
	var data = SaveManager.get_ad_data()
	_daily_ad_count = data.get("daily_ad_count", 0)
	_last_ad_date = data.get("last_ad_date", "")
