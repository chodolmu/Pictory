class_name TurnManager
extends RefCounted

## 게임 모드별 턴 관리 시스템.

signal turn_changed(turns_used: int, turns_remaining: int)

var mode: String = "story"
var max_turns: int = 30

var turns_used: int = 0

var turns_remaining: int:
	get:
		if mode == "story":
			return max_turns - turns_used
		return -1  # infinity mode에서는 의미 없음

func use_turn() -> void:
	turns_used += 1
	turn_changed.emit(turns_used, turns_remaining)

func is_game_over() -> bool:
	if mode == "story":
		return turns_remaining <= 0
	return false

func reset() -> void:
	turns_used = 0
	turn_changed.emit(turns_used, turns_remaining)
