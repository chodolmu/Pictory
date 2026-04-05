class_name CurrencyConverter
extends RefCounted
## 점수/클리어 결과 → 재화 변환 유틸리티 (static 함수만).

# balance.json 상수 (하드코딩으로 관리, 추후 외부화 가능)
const STORY_CLEAR_BASE := 50
const STORY_STAR_BONUS := [0, 25, 50]  # 인덱스 = 별 수 - 1 (1성=0, 2성=25, 3성=50)
const STORY_REPLAY_BASE := 25
const INFINITY_SCORE_RATIO := 0.5
const INFINITY_MIN_REWARD := 50
const INFINITY_MAX_REWARD := 5000
const INFINITY_HIGHSCORE_BONUS := 500

static func calculate_story_reward(_stars: int, _is_first_clear: bool) -> int:
	# 스토리 모드에서는 코인 보상 없음 — 코인은 인피니티 모드에서만 획득
	return 0

static func calculate_infinity_reward(score: int, is_new_highscore: bool) -> int:
	var reward = maxi(int(score * INFINITY_SCORE_RATIO), INFINITY_MIN_REWARD)
	if is_new_highscore:
		reward += INFINITY_HIGHSCORE_BONUS
	return mini(reward, INFINITY_MAX_REWARD)
