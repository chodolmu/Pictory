class_name CurrencyConverter
extends RefCounted
## 점수/클리어 결과 → 재화 변환 유틸리티 (static 함수만).

# balance.json 상수 (하드코딩으로 관리, 추후 외부화 가능)
const STORY_CLEAR_BASE := 50
const STORY_STAR_BONUS := [0, 25, 50]  # 인덱스 = 별 수 - 1 (1성=0, 2성=25, 3성=50)
const STORY_REPLAY_BASE := 25
const INFINITY_SCORE_RATIO := 0.1
const INFINITY_MIN_REWARD := 10
const INFINITY_MAX_REWARD := 1000
const INFINITY_HIGHSCORE_BONUS := 100

static func calculate_story_reward(stars: int, is_first_clear: bool) -> int:
	var base = STORY_CLEAR_BASE if is_first_clear else STORY_REPLAY_BASE
	var star_bonus = STORY_STAR_BONUS[clampi(stars - 1, 0, 2)] if stars > 0 else 0
	return base + star_bonus

static func calculate_infinity_reward(score: int, is_new_highscore: bool) -> int:
	var reward = maxi(int(score * INFINITY_SCORE_RATIO), INFINITY_MIN_REWARD)
	if is_new_highscore:
		reward += INFINITY_HIGHSCORE_BONUS
	return mini(reward, INFINITY_MAX_REWARD)
