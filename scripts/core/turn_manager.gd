class_name TurnManager
extends RefCounted

## 턴 관리 시스템.

signal turn_changed(turns_used: int, turns_remaining: int)

var max_turns: int = 30
var turns_used: int = 0

var turns_remaining: int:
	get:
		return max_turns - turns_used

func use_turn() -> void:
	turns_used += 1
	turn_changed.emit(turns_used, turns_remaining)

func is_game_over() -> bool:
	return turns_remaining <= 0

func add_turns(amount: int) -> void:
	## 보너스 턴 추가.
	turns_used = max(0, turns_used - amount)
	turn_changed.emit(turns_used, turns_remaining)

func reset() -> void:
	turns_used = 0
	turn_changed.emit(turns_used, turns_remaining)
