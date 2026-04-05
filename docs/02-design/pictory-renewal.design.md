# Pictory Renewal Design Document

> **Summary**: 2026-04 회의 결과 기반 시스템 전면 개편 상세 설계
>
> **Project**: Pictory
> **Version**: 1.0.0
> **Date**: 2026-04-05
> **Status**: Draft
> **Planning Doc**: [PDCA_renewal_2026-04.md](../01-plan/PDCA_renewal_2026-04.md)

---

## 1. Overview

### 1.1 Design Goals

- 인피니티 모드/별 시스템/다중 재화를 제거하여 게임 루프를 단순화
- 하트 + 젬 2종 재화로 로얄매치 스타일 수익 모델 전환
- 동료 3명 편성으로 전략적 깊이 강화
- 메인화면 중심 UX로 화면 전환 최소화

### 1.2 Design Principles

- 기존 `pictory-core.design.md`의 원칙 유지 (데이터-로직-뷰 분리, Signal 기반, 파이프라인 구조)
- 삭제 우선: 사용하지 않는 코드를 남기지 않는다
- 단일 모드: StoryMode만 존재, 모드 분기 코드 제거

---

## 2. Architecture Changes

### 2.1 Autoload 변경

```
[현재]                          [변경 후]
SaveManager         ────────►  SaveManager (수정: 스키마 변경)
PlayerProfile       ────────►  PlayerProfile (수정: 가입일 추가)
LevelLoader         ────────►  LevelLoader (유지)
Economy             ────────►  (삭제)
SceneManager        ────────►  SceneManager (유지)
StoryFlowController ────────►  StoryFlowController (수정: 별 제거)
ImagenDatabase      ────────►  ImagenDatabase (유지)
PartyManager        ────────►  PartyManager (수정: 3슬롯)
CollectionManager   ────────►  CollectionManager (유지)
AchievementManager  ────────►  AchievementManager (유지)
StaminaManager      ────────►  HeartManager (리네이밍 + 리뉴얼)
AdManager           ────────►  (삭제)
(없음)              ────────►  GemManager (신규)
```

### 2.2 System Diagram (변경 후)

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────┐  │
│  │ GridView │ │   HUD    │ │ColorQueue│ │ ResultPopup   │  │
│  │          │ │(턴/목표) │ │  UI      │ │(성공/실패/    │  │
│  │          │ │          │ │          │ │ 턴추가구매)   │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └───────┬───────┘  │
│       │            │            │                │           │
├───────┼────────────┼────────────┼────────────────┼───────────┤
│       ▼            ▼            ▼                ▼           │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                  GameManager                         │    │
│  │  (스토리 모드 전용, 턴 진행, 클리어/게임오버 판정)      │    │
│  └────┬──────────┬──────────┬──────────┬───────────────┘    │
│       │          │          │          │                     │
│  ┌────▼───┐ ┌───▼────┐ ┌──▼───────┐ ┌▼──────────────┐     │
│  │  Grid  │ │Flood   │ │RowDestroy│ │ SkillManager  │     │
│  │ (Data) │ │Fill    │ │+ Gravity │ │ (3슬롯)       │     │
│  │ +Buffer│ │        │ │+ Chain   │ │               │     │
│  └────────┘ └────────┘ └──────────┘ └───────────────┘     │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                          Data Layer                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │  Level   │ │  Save    │ │  Heart   │ │    Gem       │  │
│  │  Loader  │ │ Manager  │ │ Manager  │ │  Manager     │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 Signal Flow (변경 후 게임 루프)

```
User Touch
    │
    ▼
GridView.cell_touched(x, y)
    │
    ▼
GameManager._on_cell_touched(x, y)
    ├── FloodFill.find_connected_group(grid, x, y)
    ├── Grid.apply_color(group, selected_color)
    ├── ColorQueue.advance()
    │
    ▼
ChainCombo.execute(grid)
    ├── RowDestroy.check_and_destroy(grid)
    ├── Gravity.apply(grid)
    └── 연쇄 반복
    │
    ▼
GameManager._finalize_action()
    ├── HUD 갱신
    ├── StoryMode.on_action_performed()
    │     ├── 목표 달성?  → stage_cleared()
    │     └── 턴 == 0?   → stage_failed()
    ├── SkillManager.on_turn_end()  (쿨타임 -1)
    └── save_snapshot()
    │
    ▼
[클리어 시]
    GameManager._on_stage_cleared()
    ├── SaveManager.save_stage_result(stage_id, cleared=true)
    ├── 챕터 마지막 스테이지? → GemManager.add(100)
    └── StoryFlowController → 로비 복귀 (+ ResultPopup "성공")

[실패 시]
    GameManager._on_stage_failed()
    └── ResultPopup 표시
          ├── [턴 추가 1차: 50젬] → GameManager.add_turns(5) → 게임 계속
          ├── [턴 추가 2차: 200젬] → GameManager.add_turns(5) → 게임 계속
          ├── [재도전] → HeartManager.consume(1) → 같은 스테이지 재시작
          └── [포기] → HeartManager.consume(1) → 로비 복귀
```

---

## 3. Detailed Design

### 3.1 HeartManager (기존 StaminaManager 대체)

**파일**: `scripts/data/heart_manager.gd`
**Autoload**: `HeartManager`

```
상수:
  MAX_HEARTS         = 5
  RECOVERY_SECONDS   = 1800    # 30분

상태:
  current_hearts: int          # 현재 하트 수 (0~5)
  last_recovery_time: int      # 마지막 회복 시각 (Unix timestamp)

시그널:
  hearts_changed(current: int, max: int)
  hearts_depleted()

API:
  consume(amount: int) -> bool
    현재 >= amount 이면 차감 후 true, 아니면 false + hearts_depleted 발생

  add(amount: int) -> void
    min(current + amount, MAX_HEARTS) 적용

  get_recovery_time_remaining() -> float
    다음 1개 회복까지 남은 초

  is_full() -> bool

내부:
  _process(delta):
    current < MAX 이면 accumulator 누적, 1800초마다 +1

  _apply_offline_recovery():
    앱 시작 시 (now - last_recovery_time) / 1800 만큼 회복

저장:
  SaveManager에 { hearts: int, last_recovery: int } 저장/로드
```

**소모 시점**: 스테이지 **실패 확정** 시에만 1개 소모 (시작 시 소모 아님).

실패 확정 = 턴 추가 구매 안 함 + 재도전 선택 or 포기 선택.

### 3.2 GemManager (신규)

**파일**: `scripts/data/gem_manager.gd`
**Autoload**: `GemManager`

```
상태:
  current_gems: int

시그널:
  gems_changed(current: int)

API:
  add(amount: int) -> void
    current_gems += amount, 저장

  spend(amount: int) -> bool
    current_gems >= amount 이면 차감 후 true, 아니면 false

  get_balance() -> int

저장:
  SaveManager에 { gems: int } 저장/로드
```

**획득 경로**:
1. 챕터 마지막 스테이지 (s10) 클리어 시 100젬
2. 젬 상점에서 실결제 구매

### 3.3 실패 시 턴 추가 흐름

**담당**: `ResultPopup` (수정)

```
상태 머신:
  FIRST_FAIL   → 턴 추가 1차 제안 (50젬)
  SECOND_FAIL  → 턴 추가 2차 제안 (200젬)
  FINAL_FAIL   → 하트 차감 + 재도전/포기만

흐름:
  _on_stage_failed() 호출 시:
    GameManager → ResultPopup.show_fail(fail_phase)

  fail_phase == FIRST_FAIL:
    ┌─────────────────────────────────┐
    │       턴이 부족합니다!           │
    │                                 │
    │   [💎50 → 5턴 추가]            │
    │   [포기하기]                     │
    └─────────────────────────────────┘
    "5턴 추가" 클릭:
      GemManager.spend(50) 성공 →
        ResultPopup 숨김
        GameManager.add_bonus_turns(5)
        _fail_phase = SECOND_FAIL
        게임 계속
      실패 → "젬이 부족합니다" 토스트

    "포기하기" 클릭:
      HeartManager.consume(1)
      로비 복귀

  fail_phase == SECOND_FAIL:
    ┌─────────────────────────────────┐
    │       턴이 부족합니다!           │
    │                                 │
    │   [💎200 → 5턴 추가]           │
    │   [포기하기]                     │
    └─────────────────────────────────┘
    "5턴 추가" 클릭:
      GemManager.spend(200) 성공 →
        ResultPopup 숨김
        GameManager.add_bonus_turns(5)
        _fail_phase = FINAL_FAIL
        게임 계속
      실패 → "젬이 부족합니다" 토스트

    "포기하기" 클릭:
      HeartManager.consume(1)
      로비 복귀

  fail_phase == FINAL_FAIL:
    ┌─────────────────────────────────┐
    │       스테이지 실패              │
    │                                 │
    │   [재도전] [로비로 돌아가기]      │
    └─────────────────────────────────┘
    어느 쪽이든 HeartManager.consume(1)
    "재도전" → 같은 스테이지 재시작
    "로비로" → 메인화면

시그널:
  continue_requested()         # 턴 추가 후 게임 계속
  retry_requested()            # 하트 소모 + 재도전
  main_menu_requested()        # 하트 소모 + 로비
```

### 3.4 GameManager 턴 추가 지원

**파일**: `scripts/game_manager.gd` (수정)

```
신규 API:
  add_bonus_turns(count: int) -> void
    StoryMode.remaining_turns += count
    _game_ended = false
    _grid_view.unlock_input()
    _hud.update_turns(...)

신규 상태:
  var _fail_phase: int = 0   # 0=FIRST, 1=SECOND, 2=FINAL

_on_stage_failed() 변경:
  기존: 즉시 game_over emit
  변경: ResultPopup.show_fail(_fail_phase) 호출
        continue_requested → add_bonus_turns(5), _fail_phase += 1
        retry/menu → HeartManager.consume(1) 후 이동
```

**삭제 항목**:
- `start_infinity()` 메서드 전체
- `InfinityModeScript` 관련 const/참조
- `_on_infinity_game_over()` 핸들러
- `INFINITY_GIMMICK_*` 상수 및 관련 메서드
- `Economy` 참조 전부 (`Economy.reset()`, `Economy.add_score()`, `Economy.add_rewards()`, `Economy.current_score`)
- `CurrencyConverter` 참조 전부
- `_on_time_updated()` 핸들러

### 3.5 StoryMode 변경

**파일**: `scripts/modes/story_mode.gd`

```
삭제:
  signal stage_cleared(stars, score, remaining_turns)
  → signal stage_cleared(remaining_turns: int)
  
  var _star_thresholds: Array
  func _calculate_stars()

변경:
  _check_clear_condition():
    기존: stars 계산 후 emit
    변경: stage_cleared.emit(remaining_turns)

유지:
  signal stage_failed()
  턴 관리, 목표 판정 로직 전부 유지
```

### 3.6 StageConfig 변경

**파일**: `scripts/data/stage_config.gd`

```
삭제:
  var star_thresholds: Array = [3, 6, 10]

유지:
  나머지 전부
```

### 3.7 SaveManager 스키마 변경

**파일**: `scripts/data/save_manager.gd`

```
[현재 스키마]
{
  "version": 1,
  "currency": 0,
  "stages": { "ch01_s01": { "cleared": bool, "stars": int, "best_score": int } },
  "chapters_unlocked": [1],
  "infinity": { "high_score": 0, "total_plays": 0 },
  "settings": { ... },
  "player_profile": { "nickname": "", "selected_icon": "default", "first_launch": true },
  "stamina": { ... },
  "ad": { ... },
  "shop_history": { ... },
  "unlocked_imagenes": [],
  "last_party": [],
  "collection": { ... },
  "achievements": { ... },
  "stats": { ... }
}

[변경 후 스키마]
{
  "version": 2,
  "stages": { "ch01_s01": { "cleared": bool } },
  "chapters_unlocked": [1],
  "gems": 0,
  "hearts": { "current": 5, "last_recovery": <unix_timestamp> },
  "settings": { ... },
  "player_profile": {
    "nickname": "",
    "selected_icon": "default",
    "first_launch": true,
    "created_at": <unix_timestamp>
  },
  "unlocked_imagenes": [],
  "last_party": [],
  "collection": { ... },
  "achievements": { ... },
  "stats": { ... }
}

삭제 필드:
  currency, infinity, stamina, ad, shop_history, stages.*.stars, stages.*.best_score

신규 필드:
  gems, hearts, player_profile.created_at

마이그레이션:
  version 1 → 2:
    - currency → gems로 이관 (기존 유저 보상 차원)
    - stars 필드 제거 (cleared만 유지)
    - infinity, stamina, ad, shop_history 키 삭제
    - hearts 초기값 { current: 5, last_recovery: now }
    - player_profile.created_at = now (기존 유저는 마이그레이션 시점)

API 변경:
  삭제:
    save_stage_result(stage_id, stars, score)
    get_stage_stars(stage_id)
    get_infinity_high_score()
    save_infinity_result(score)
    get_stamina_data() / save_stamina_data()
    get_ad_data() / save_ad_data()
    get_shop_history() / save_shop_history()

  변경:
    save_stage_result(stage_id) → cleared=true만 저장
    
  신규:
    get_gems() -> int
    save_gems(amount: int)
    get_hearts_data() -> Dictionary
    save_hearts_data(data: Dictionary)
    get_highest_cleared_stage() -> String    # 프로필 팝업용
```

### 3.8 파티 시스템 3슬롯

**파일**: `scripts/companion/party_manager.gd`

```
변경:
  MAX_PARTY_SIZE = 2 → 3

  set_party():
    imagen_ids.slice(0, 3)
```

**파일**: `scripts/companion/party_select.gd`

```
변경:
  슬롯 UI를 3개로 확장
  _is_mode_compatible() 에서 K10/K11 체크 제거 (해당 스킬 자체가 삭제됨)
```

**파일**: `scripts/companion/skill_manager.gd`

```
변경:
  setup_party()에서 최대 3개 슬롯 생성
  _get_target_type()에서 K1/K2/K3 case 제거
```

**파일**: `scripts/companion/skill_hud.gd`

```
변경:
  BTN_SIZE 조정 (3개가 화면 폭에 맞도록)
  BTN_SIZE = Vector2(60, 60) → Vector2(55, 55) 또는 동적 계산
```

### 3.9 스킬 정리

**삭제 파일 (5개)**:
- `skill_color_storm.gd` (K1 — COLOR_PAIR)
- `skill_rainbow_wave.gd` (K2 — CELL_AND_COLOR)
- `skill_color_swap.gd` (K3 — COLOR_PAIR)
- `skill_times_breath.gd` (K10 — story only)
- `skill_time_stop.gd` (K11 — infinity only)

**유지 스킬 (6개)**:
| ID | 이름 | Target | 효과 |
|---|---|---|---|
| K4 | 컬러봄 | COLOR (1번 터치) | 선택 색 블록 5개 즉시 제거 |
| K5 | 행청소 | ROW_OR_COL (1번 터치) | 행 or 열 전체 파괴 |
| K6 | 되감기 | NONE | 직전 보드 상태 복구 |
| K7 | 미래의눈 | NONE | 최적 수 힌트 표시 |
| K8 | 셔플 | NONE | 보드 블록 랜덤 재배치 |
| K9 | 큐뒤집기 | NONE | 큐 색상 순서 역전 |

**GameManager 스킬 핸들러 정리**:
```
_on_skill_button_pressed() 에서:
  삭제: CELL_AND_COLOR 분기 (K2 전용이었음)
  삭제: COLOR_PAIR 분기 (K1/K3 전용이었음)
  유지: NONE, COLOR, ROW_OR_COL 분기

_on_cell_touched() 에서:
  삭제: K2 셀 선택 처리 블록 (_is_target_selecting 관련)
```

**imagen.gd (ImagenData)**:
```
get_skill_name() 에서:
  삭제: K1, K2, K3, K10, K11 case
```

---

## 4. UI Design

### 4.1 메인화면 (MainMenu) 레이아웃

```
┌─────────────────────────────┐
│  [아이콘]  닉네임    💎 300  │  ← 상단바: 아이콘 클릭→프로필팝업
│  ♥♥♥♥♡  (28:30)            │  ← 하트 + 회복 타이머
├─────────────────────────────┤
│                             │
│                             │
│     [챕터 배경 영역]         │  ← 추후: 진행도 색칠
│     Chapter 1               │
│                             │
│  ◄                     ►   │  ← 챕터 좌우 화살표
│                             │
├─────────────────────────────┤
│                             │
│       [ 시 작 ]             │  ← 스테이지 프리뷰 팝업 열기
│                             │
├─────────────────────────────┤
│  [업적]  [동료]  [패션]      │  ← 하단 3버튼
│                             │
│       [상점]                │  ← 젬 상점
└─────────────────────────────┘
```

**변경점**:
- 인피니티 버튼 삭제
- 스테이지 선택 버튼 → "시작" 버튼 (현재 챕터의 다음 미클리어 스테이지)
- 챕터 좌우 화살표 추가
- 하트 표시 추가
- 컬렉션 버튼 → 업적/동료/패션 3개로 분리
- 상점 버튼 유지 (젬 상점으로 변경)

**로직**:
```
var current_chapter: int = 1   # 화살표로 전환

func _get_next_stage() -> String:
  # 현재 챕터에서 클리어하지 않은 첫 번째 스테이지
  for s in range(1, 11):
    var stage_id = "ch%02d_s%02d" % [current_chapter, s]
    if not SaveManager.is_stage_cleared(stage_id):
      return stage_id
  return ""  # 전부 클리어됨

func _on_start_pressed():
  var stage_id = _get_next_stage()
  if stage_id == "":
    # 챕터 완료 상태 — 토스트 또는 다음 챕터 안내
    return
  _show_stage_preview(stage_id)
```

### 4.2 스테이지 프리뷰 팝업 (신규)

**파일**: `scripts/ui/stage_preview_popup.gd` + `scenes/ui/stage_preview_popup.tscn`

```
┌─────────────────────────────┐
│      Chapter 1 - Stage 3    │
├─────────────────────────────┤
│                             │
│   목표: 블록 120개 파괴      │
│   턴:  25턴                 │
│   색상: 5색                  │
│   기믹: 얼음 🧊, 독 ☠️      │
│                             │
├─────────────────────────────┤
│  [동료 1] [동료 2] [동료 3]  │  ← PartySelect (3슬롯)
├─────────────────────────────┤
│                             │
│         [ 시 작 ]           │
│         [ 돌아가기 ]         │
│                             │
└─────────────────────────────┘

시그널:
  start_requested(stage_id: String)
  cancelled()

로직:
  func show_preview(stage_id: String):
    var config = LevelLoader.load_stage(stage_id)
    _stage_label.text = "Chapter %d - Stage %d" % [config.chapter, config.stage_number]
    _goal_label.text = "목표: 블록 %d개 파괴" % config.goal_target_count
    _turns_label.text = "턴: %d턴" % config.turn_limit
    _colors_label.text = "색상: %d색" % config.num_colors
    _gimmicks_label.text = _format_gimmicks(config.gimmick_placements)
    _party_select.setup("story")  # 3슬롯 파티 선택

  func _on_start():
    if HeartManager.current_hearts <= 0:
      # 하트 부족 — 상점으로 안내 또는 대기
      return
    start_requested.emit(_current_stage_id)
```

**참고**: 하트는 시작 시 소모하지 않고, 실패 확정 시에만 소모.
프리뷰에서 하트가 0이면 시작 불가 (실패 시 차감할 하트가 없으므로).

### 4.3 프로필 팝업 (신규)

**파일**: `scripts/ui/profile_popup.gd` + `scenes/ui/profile_popup.tscn`

```
┌─────────────────────────────┐
│          프로필              │
├─────────────────────────────┤
│                             │
│     [아이콘]                │  ← 클릭 시 아이콘 변경
│     닉네임: Cho Jun         │  ← 클릭 시 닉네임 변경
│                             │
│   가입일: 2026-03-15        │
│   최고 클리어: Ch3 Stage 7   │
│                             │
├─────────────────────────────┤
│         [ 닫기 ]            │
└─────────────────────────────┘

데이터 소스:
  PlayerProfile.get_nickname()
  PlayerProfile.get_created_at()     # 신규
  CollectionManager.get_selected_icon()
  SaveManager.get_highest_cleared_stage()  # 신규

닉네임 변경:
  팝업 내 LineEdit 표시 → PlayerProfile.set_nickname()

아이콘 변경:
  패션(컬렉션) 화면으로 이동 또는 인라인 선택
```

### 4.4 ResultPopup 변경

**파일**: `scripts/ui/result_popup.gd` + `scenes/ui/result_popup.tscn`

```
삭제:
  _stars_container, Star1/Star2/Star3
  _score_label, _currency_label, _destroyed_label, _high_score_label
  _next_stage_button
  show_clear(stars, score, currency, has_next)
  show_game_over(score, extra_data)
  _animate_stars(), _reset_stars()

신규 API:
  show_success() -> void
    ┌─────────────────────────────┐
    │     스테이지 클리어! 🎉     │
    │                             │
    │      [ 로비로 돌아가기 ]     │
    └─────────────────────────────┘

  show_fail(phase: int) -> void
    phase에 따라 턴 추가 UI 또는 최종 실패 UI

시그널:
  continue_requested()     # 턴 추가 후 게임 계속
  retry_requested()        # 재도전
  main_menu_requested()    # 로비 복귀
```

### 4.5 컬렉션 분리

**현재**: `collection.tscn` 내부에 탭 3개 (훈야, 이마젠, 아이콘)

**변경**: 메인화면에서 3개 별도 버튼으로 진입

| 버튼 | 진입 화면 | 내용 |
|------|-----------|------|
| 업적 | `achievement_popup.tscn` (기존) | 업적 목록 + 달성 현황 |
| 동료 | `collection_tab_imagen.tscn` (기존 탭 → 독립 씬) | 이마젠 도감 + 파티 편성 |
| 패션 | `collection_tab_icon.tscn` (기존 탭 → 독립 씬) | 아이콘 도감 + 장착 |

`collection.tscn` (탭 컨테이너)은 더 이상 불필요 — 삭제 후 개별 씬으로 직접 전환.
`collection_tab_hunya.tscn`은 용도 확인 후 업적/동료/패션 중 하나로 통합하거나 삭제.

### 4.6 젬 상점 (신규)

**파일**: `scripts/ui/gem_shop.gd` + `scenes/ui/gem_shop.tscn`

```
┌─────────────────────────────┐
│          젬 상점             │
├─────────────────────────────┤
│                             │
│   💎 100개    ─   ₩1,200   │
│   💎 500개    ─   ₩5,900   │
│   💎 1200개   ─  ₩11,000   │
│   💎 3000개   ─  ₩25,000   │
│                             │
├─────────────────────────────┤
│         [ 닫기 ]            │
└─────────────────────────────┘

구현 범위 (Phase 2):
  - UI + 상품 목록 표시
  - 결제 로직은 stub (즉시 지급)
  - 실제 IAP 연동은 Phase 4+

데이터:
  res://resources/shop/gem_products.json
  [
    { "id": "gem_100",  "gems": 100,  "price_krw": 1200 },
    { "id": "gem_500",  "gems": 500,  "price_krw": 5900 },
    { "id": "gem_1200", "gems": 1200, "price_krw": 11000 },
    { "id": "gem_3000", "gems": 3000, "price_krw": 25000 }
  ]
```

---

## 5. Data Changes

### 5.1 Stage JSON 변경

```json
// 변경 전
{
  "stage_id": "ch01_s03",
  "chapter": 1,
  "stage_number": 3,
  "grid_size": 7,
  "num_colors": 5,
  "turn_limit": 25,
  "goal_type": "destroy_blocks",
  "goal_target_count": 120,
  "star_thresholds": [3, 6, 10],
  "gimmick_placements": [ ... ]
}

// 변경 후
{
  "stage_id": "ch01_s03",
  "chapter": 1,
  "stage_number": 3,
  "grid_size": 7,
  "num_colors": 5,
  "turn_limit": 25,
  "goal_type": "destroy_blocks",
  "goal_target_count": 120,
  "gimmick_placements": [ ... ]
}
// star_thresholds 필드 제거
```

### 5.2 Imagen Database JSON 변경

K1, K2, K3, K10, K11 스킬을 가진 이마젠 데이터에서 skill_id를 유지 스킬(K4~K9)로 재할당 필요.

```
확인 필요:
  res://resources/imagenes/imagen_database.json 에서
  skill_id가 K1/K2/K3/K10/K11인 이마젠 목록 확인
  → 각각 K4~K9 중 적절한 스킬로 재할당
```

---

## 6. File Change Summary

### 6.1 삭제 파일 (19개)

| 파일 | 사유 |
|------|------|
| `scripts/modes/infinity_mode.gd` | 인피니티 삭제 |
| `scenes/ui/infinity_confirm_popup.tscn` | 인피니티 삭제 |
| `scripts/ui/infinity_confirm_popup.gd` | 인피니티 삭제 |
| `scripts/companion/skills/skill_color_storm.gd` | K1 삭제 |
| `scripts/companion/skills/skill_rainbow_wave.gd` | K2 삭제 |
| `scripts/companion/skills/skill_color_swap.gd` | K3 삭제 |
| `scripts/companion/skills/skill_times_breath.gd` | K10 삭제 |
| `scripts/companion/skills/skill_time_stop.gd` | K11 삭제 |
| `scripts/data/economy.gd` | 재화 시스템 교체 |
| `scripts/data/currency_converter.gd` | 재화 시스템 교체 |
| `scripts/data/shop_manager.gd` | 상점 교체 |
| `scripts/ui/shop.gd` | 상점 교체 |
| `scenes/ui/shop.tscn` | 상점 교체 |
| `scripts/ui/shop_item_card.gd` | 상점 교체 |
| `scenes/ui/shop_item_card.tscn` | 상점 교체 |
| `scripts/data/ad_manager.gd` | 광고 삭제 |
| `scripts/data/dev_ad_provider.gd` | 광고 삭제 |
| `scripts/ui/ad_purchase_popup.gd` | 광고 삭제 |
| `scenes/ui/ad_purchase_popup.tscn` | 광고 삭제 |

### 6.2 신규 파일 (6개)

| 파일 | 용도 |
|------|------|
| `scripts/data/heart_manager.gd` | 하트 시스템 (Autoload) |
| `scripts/data/gem_manager.gd` | 젬 시스템 (Autoload) |
| `scripts/ui/stage_preview_popup.gd` | 스테이지 프리뷰 |
| `scenes/ui/stage_preview_popup.tscn` | 스테이지 프리뷰 씬 |
| `scripts/ui/profile_popup.gd` | 프로필 팝업 |
| `scenes/ui/profile_popup.tscn` | 프로필 팝업 씬 |
| `scripts/ui/gem_shop.gd` | 젬 상점 |
| `scenes/ui/gem_shop.tscn` | 젬 상점 씬 |
| `resources/shop/gem_products.json` | 젬 상품 데이터 |

### 6.3 수정 파일 (14개)

| 파일 | 주요 변경 |
|------|-----------|
| `project.godot` | Autoload: Economy/AdManager 제거, HeartManager/GemManager 추가 |
| `scripts/game_manager.gd` | 인피니티 제거, Economy 제거, 턴 추가 API, 실패 흐름 변경 |
| `scripts/modes/story_mode.gd` | 별 시스템 제거, 시그널 변경 |
| `scripts/data/stage_config.gd` | star_thresholds 제거 |
| `scripts/data/save_manager.gd` | 스키마 v2, 삭제/신규 API |
| `scripts/data/player_profile.gd` | created_at 필드 추가 |
| `scripts/ui/result_popup.gd` | 별 UI 제거, 턴 추가 흐름 추가 |
| `scenes/ui/result_popup.tscn` | 별 노드 제거, 턴 추가 버튼 추가 |
| `scripts/main/main_menu.gd` | 인피니티 제거, 레이아웃 전면 변경 |
| `scenes/main/main_menu.tscn` | 레이아웃 전면 변경 |
| `scripts/companion/party_manager.gd` | MAX_PARTY_SIZE = 3 |
| `scripts/companion/party_select.gd` | 3슬롯, 모드 호환성 제거 |
| `scripts/companion/skill_manager.gd` | 삭제 스킬 참조 제거 |
| `scripts/companion/skill_hud.gd` | 3슬롯 UI |
| `scripts/companion/imagen.gd` | K1/K2/K3/K10/K11 case 제거 |
| `scripts/data/level_loader.gd` | star_thresholds 파싱 제거 |
| `scripts/main/stage_select_screen.gd` | 삭제 또는 대폭 축소 (노드맵 제거) |

### 6.4 Autoload 등록 변경 (project.godot)

```ini
[autoload]

SaveManager="*res://scripts/data/save_manager.gd"
PlayerProfile="*res://scripts/data/player_profile.gd"
LevelLoader="*res://scripts/data/level_loader.gd"
SceneManager="*res://scripts/ui/scene_manager.gd"
StoryFlowController="*res://scripts/story/story_flow_controller.gd"
ImagenDatabase="*res://scripts/companion/imagen_database.gd"
PartyManager="*res://scripts/companion/party_manager.gd"
CollectionManager="*res://scripts/collection/collection_manager.gd"
AchievementManager="*res://scripts/collection/achievement_manager.gd"
HeartManager="*res://scripts/data/heart_manager.gd"
GemManager="*res://scripts/data/gem_manager.gd"

# 삭제됨: Economy, AdManager, StaminaManager, TestBridge
```

---

## 7. Implementation Order

```
Phase 1: 삭제/정리
  1-1. project.godot에서 Economy, AdManager Autoload 제거
  1-2. infinity_mode.gd + infinity_confirm_popup 삭제
  1-3. game_manager.gd에서 인피니티 참조 전부 제거
  1-4. economy.gd, currency_converter.gd 삭제 + 참조 제거
  1-5. ad_manager.gd, dev_ad_provider.gd, ad_purchase_popup 삭제
  1-6. shop_manager.gd, shop.gd, shop_item_card 삭제
  1-7. 스킬 5개 파일 삭제 + imagen.gd, skill_manager.gd 참조 정리
  1-8. story_mode.gd 별 시스템 제거
  1-9. result_popup.gd 별 UI 제거, next_stage 버튼 제거
  1-10. save_manager.gd 삭제 필드 정리
  1-11. stage_config.gd, level_loader.gd star_thresholds 제거
  ──► 빌드 검증

Phase 2: 신규 시스템
  2-1. heart_manager.gd 작성 + Autoload 등록
  2-2. gem_manager.gd 작성 + Autoload 등록
  2-3. save_manager.gd v2 스키마 + 마이그레이션
  2-4. game_manager.gd 턴 추가 API (add_bonus_turns)
  2-5. result_popup.gd 실패 흐름 (3단계 턴 추가)
  2-6. party_manager.gd 3슬롯
  2-7. skill_manager.gd + skill_hud.gd 3슬롯
  2-8. player_profile.gd created_at 추가
  2-9. 챕터 클리어 보상 (game_manager → GemManager.add(100))
  ──► 게임 플레이 검증

Phase 3: UI 개편
  3-1. main_menu.gd/.tscn 전면 리뉴얼
  3-2. stage_preview_popup 신규 작성
  3-3. profile_popup 신규 작성
  3-4. gem_shop 신규 작성
  3-5. 컬렉션 분리 (업적/동료/패션)
  3-6. stage_select_screen 삭제 또는 리다이렉트
  ──► 전체 플로우 검증
```
