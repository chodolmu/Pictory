extends Node
## GemManager — Autoload 싱글턴.
## 젬(턴 구매용 재화) 관리.

signal gems_changed(current: int)

var current_gems: int = 0

func _ready() -> void:
	current_gems = SaveManager.get_gems()

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func add(amount: int) -> void:
	current_gems += amount
	SaveManager.save_gems(current_gems)
	gems_changed.emit(current_gems)

func spend(amount: int) -> bool:
	if current_gems < amount:
		return false
	current_gems -= amount
	SaveManager.save_gems(current_gems)
	gems_changed.emit(current_gems)
	return true

func get_balance() -> int:
	return current_gems
