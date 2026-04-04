extends Node
## Economy — Autoload 싱글턴.
## 블록 파괴 시 점수 계산 및 점수→재화 변환.

@export var base_point_per_block: int = 10
@export var combo_bonus_base: int = 50
@export var combo_bonus_multiplier: float = 1.5
@export var score_to_currency_ratio: float = 0.01

signal score_changed(new_score: int)
signal currency_earned(amount: int)

var current_score: int = 0
var _total_currency_earned: int = 0

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func reset() -> void:
	current_score = 0
	score_changed.emit(current_score)

func calculate_action_score(destroyed_blocks: int, combo_level: int) -> int:
	var base = destroyed_blocks * base_point_per_block
	var combo_bonus = 0
	if combo_level >= 1:
		combo_bonus = floori(combo_bonus_base * pow(combo_bonus_multiplier, combo_level))
	return base + combo_bonus

func add_score(destroyed_blocks: int, combo_level: int) -> int:
	var gained = calculate_action_score(destroyed_blocks, combo_level)
	current_score += gained
	score_changed.emit(current_score)
	return gained

func convert_score_to_currency(score: int) -> int:
	return floori(score * score_to_currency_ratio)

func get_total_currency_earned() -> int:
	return _total_currency_earned

func finalize_and_earn_currency() -> int:
	## 스테이지/게임 종료 시 현재 점수를 재화로 변환하여 누적.
	var earned = convert_score_to_currency(current_score)
	_total_currency_earned += earned
	currency_earned.emit(earned)
	return earned
