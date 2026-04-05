extends Node
## StarManager — Autoload 싱글턴.
## 별(스티커북 컬러 복구용 재화) 관리.

signal stars_changed(current: int)

var current_stars: int = 0

func _ready() -> void:
	current_stars = SaveManager.get_stars()

func add(amount: int = 1) -> void:
	current_stars += amount
	SaveManager.save_stars(current_stars)
	stars_changed.emit(current_stars)

func spend(amount: int = 1) -> bool:
	if current_stars < amount:
		return false
	current_stars -= amount
	SaveManager.save_stars(current_stars)
	stars_changed.emit(current_stars)
	return true

func get_balance() -> int:
	return current_stars
