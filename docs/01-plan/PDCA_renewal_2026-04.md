# PDCA: Pictory 대규모 리뉴얼 (2026-04)

> **Date**: 2026-04-05
> **Scope**: 회의 결과 기반 시스템 전면 개편
> **Status**: Plan 단계

---

## Plan (계획)

### 배경
기존 구조(인피니티 모드, 별 시스템, 다중 재화, 노드맵 등)를 정리하고,
로얄매치 스타일의 간결한 게임 루프로 전환한다.

### 변경 목표 요약

| # | 항목 | 현재 | 목표 |
|---|------|------|------|
| 1 | 인피니티 모드 | 존재 (시간제한 모드) | **삭제** |
| 2 | 별(star) 시스템 | 1~3성 평가 | **삭제** — 성공/실패만 |
| 3 | 재화 | 코인(점수변환) + 스태미나(30/5분) | **하트**(5/30분) + **젬**(턴 구매용) 2종류만 |
| 4 | 실패 흐름 | 실패 → 결과 팝업 | 실패 → 50젬 5턴추가 → 200젬 5턴추가 → 하트 차감 |
| 5 | 이마젠 파티 | 2슬롯 | **3슬롯** |
| 6 | 스킬 | 11개 (K1~K11) | **6개** (K4,K5,K6,K7,K8,K9) |
| 7 | 스테이지 선택 | 노드맵 (스크롤, 노드 클릭) | **삭제** — 시작 버튼 → 프리뷰 팝업 → 게임 |
| 8 | 챕터 네비게이션 | stage_select 내 좌우 버튼 | **메인화면** 좌우 화살표 |
| 9 | 결과 후 이동 | 다음 스테이지 or 로비 | **무조건 로비** |
| 10 | 프로필 팝업 | 없음 | 아이콘 클릭 → 가입일, 최고 스테이지, 아이콘/닉네임 변경 |
| 11 | 컬렉션 | 탭 3개 (훈야/이마젠/아이콘) | **업적, 동료, 패션** 별도 버튼 3개 |
| 12 | 상점 | 코인IAP + 스태미나 + 챕터해금 | **젬 실결제 상점**으로 교체 |
| 13 | 메인화면 색칠 | 없음 | 스테이지 클리어에 따라 배경 색칠 (추후) |
| 14 | 재화 획득 | 인피니티 모드 점수 변환 | 챕터 클리어 시 100젬 + 상점 구매 |

---

### 작업 분해 (Work Breakdown)

#### Phase 1: 삭제/정리 (파괴적 변경)

| Task | 설명 | 영향 파일 |
|------|------|-----------|
| 1-1 | 인피니티 모드 삭제 | `infinity_mode.gd`, `infinity_confirm_popup.*`, `game_manager.gd`, `main_menu.gd`, `stage_select_screen.gd` |
| 1-2 | 별(star) 시스템 삭제 | `story_mode.gd`, `result_popup.gd/.tscn`, `save_manager.gd`, `stage_select_screen.gd` |
| 1-3 | 기존 재화 시스템 삭제 | `economy.gd`, `currency_converter.gd`, `shop_manager.gd`, `shop.gd/.tscn`, `shop_item_card.*`, `ad_purchase_popup.*`, `ad_manager.gd`, `dev_ad_provider.gd` |
| 1-4 | 삭제된 스킬 제거 | `skill_color_storm.gd`, `skill_rainbow_wave.gd`, `skill_color_swap.gd`, `skill_times_breath.gd`, `skill_time_stop.gd`, `imagen.gd`, `skill_manager.gd` |
| 1-5 | 노드맵 제거 | `stage_select_screen.gd/.tscn` (대폭 축소 or 삭제) |
| 1-6 | 결과 팝업 "다음 스테이지" 버튼 제거 | `result_popup.gd/.tscn` |

#### Phase 2: 신규 시스템 구축

| Task | 설명 | 신규/수정 파일 |
|------|------|----------------|
| 2-1 | 하트 시스템 (stamina 리뉴얼) | `stamina_manager.gd` → max 5, 30분 회복, 실패 시 차감 |
| 2-2 | 젬 시스템 | `gem_manager.gd` (신규) — 잔액 관리, 챕터 클리어 보상 |
| 2-3 | 실패 시 턴 추가 흐름 | `result_popup.gd` — 50젬/200젬 턴 추가 UI + 로직 |
| 2-4 | 파티 3슬롯 | `party_manager.gd`, `party_select.gd`, `skill_manager.gd`, `skill_hud.gd/.tscn` |
| 2-5 | 젬 상점 (실결제) | `gem_shop.gd/.tscn` (신규) |
| 2-6 | 챕터 클리어 보상 | `story_mode.gd` or `game_manager.gd` — 챕터 마지막 스테이지 클리어 시 100젬 |

#### Phase 3: UI 개편

| Task | 설명 | 신규/수정 파일 |
|------|------|----------------|
| 3-1 | 메인화면 리뉴얼 | `main_menu.gd/.tscn` — 시작 버튼, 챕터 좌우 화살표, 업적/동료/패션 버튼 |
| 3-2 | 스테이지 프리뷰 팝업 | `stage_preview_popup.gd/.tscn` (신규) — 목표, 턴 수, 기믹 정보 |
| 3-3 | 프로필 팝업 | `profile_popup.gd/.tscn` (신규) — 가입일, 최고 스테이지, 아이콘/닉네임 변경 |
| 3-4 | 컬렉션 분리 (업적/동료/패션) | 기존 `collection.*` 리팩터 or 3개 별도 씬 |
| 3-5 | 클리어/실패 후 로비 복귀 강제 | `game_manager.gd`, `result_popup.gd` |

#### Phase 4: 추후 (별도 스프린트)

| Task | 설명 |
|------|------|
| 4-1 | 메인화면 진행도 색칠 시스템 |
| 4-2 | 챕터별 배경 아트 교체 |

---

### 우선순위 및 순서

```
Phase 1 (삭제/정리)  ←  먼저: 불필요한 코드 제거로 작업 기반 정리
    ↓
Phase 2 (신규 시스템)  ←  재화/스킬 등 핵심 로직
    ↓
Phase 3 (UI 개편)  ←  새 시스템 위에 UI 얹기
    ↓
Phase 4 (추후)  ←  아트 리소스 필요, 별도 진행
```

### 리스크

| 리스크 | 대응 |
|--------|------|
| Phase 1에서 대량 삭제 시 참조 누락으로 빌드 깨짐 | 삭제 후 즉시 빌드 검증, Autoload 등록 확인 |
| 기존 세이브 데이터 호환성 깨짐 | save_data.json 마이그레이션 or 리셋 정책 결정 필요 |
| 실결제 상점은 플랫폼 SDK 연동 필요 | Phase 2에서는 UI/로직만, 실제 결제 연동은 Phase 4 이후 |

---

## Do (실행)

> Phase별 작업 진행 시 여기에 기록

| 날짜 | 작업 | 결과 |
|------|------|------|
| 2026-04-06 | Phase 1 전체 완료: 인피니티/별/기존재화/삭제스킬/노드맵참조 제거 | 파일 24개 삭제, 18개 수정. SaveManager v2 마이그레이션 포함 |
| 2026-04-06 | Phase 2 전체 완료: HeartManager, GemManager, 턴추가흐름, 파티3슬롯, 챕터보상 | 신규 2파일, 수정 6파일. 실패→50젬→200젬→하트차감 흐름 구현 |
| 2026-04-06 | Phase 3 전체 완료: 메인화면 리뉴얼, 프리뷰/프로필/젬상점 팝업, 컬렉션 분리, 라우팅 통합 | 신규 6파일(씬+스크립트), 모든 stage_select 라우팅→main_menu 전환 |
| 2026-04-06 | Phase 4 완료: 진행도 색칠 셰이더 + ChapterBackground 컴포넌트 + 메인화면 통합 | grayscale_wipe.gdshader, chapter_background.gd 신규. 프로시저럴 그라데이션 fallback 포함 |

---

## Check (검증)

> 각 Phase 완료 후 검증 항목

### Phase 1 검증
- [ ] 인피니티 관련 코드/씬 완전 제거 확인
- [ ] 별 시스템 코드/UI 완전 제거 확인
- [ ] 기존 재화 시스템 완전 제거 확인
- [ ] 삭제된 스킬 5개 제거 확인
- [ ] 노드맵 코드/UI 제거 확인
- [ ] 빌드 성공 (파싱 에러 없음)
- [ ] 기존 스토리 모드 정상 플레이 가능

### Phase 2 검증
- [ ] 하트 소모/회복 정상 동작
- [ ] 젬 잔액 저장/로드 정상
- [ ] 실패 → 50젬 턴 추가 → 200젬 턴 추가 → 하트 차감 흐름 정상
- [ ] 파티 3슬롯 선택 및 인게임 스킬 3개 표시 정상
- [ ] 챕터 클리어 시 100젬 지급 확인

### Phase 3 검증
- [ ] 메인화면 시작 → 프리뷰 팝업 → 게임 진입 흐름 정상
- [ ] 챕터 좌우 화살표 동작
- [ ] 프로필 팝업 정상 표시
- [ ] 업적/동료/패션 각각 진입 가능
- [ ] 클리어/실패 후 로비 복귀 확인

---

## Act (개선)

> 검증 후 발견된 문제 및 개선사항 기록

| 날짜 | 발견 사항 | 조치 |
|------|-----------|------|
| | | |

---

## 참고: 삭제 대상 파일 목록

### 완전 삭제
- `scripts/modes/infinity_mode.gd`
- `scenes/ui/infinity_confirm_popup.tscn`
- `scripts/ui/infinity_confirm_popup.gd`
- `scripts/companion/skills/skill_color_storm.gd`
- `scripts/companion/skills/skill_rainbow_wave.gd`
- `scripts/companion/skills/skill_color_swap.gd`
- `scripts/companion/skills/skill_times_breath.gd`
- `scripts/companion/skills/skill_time_stop.gd`
- `scripts/data/economy.gd`
- `scripts/data/currency_converter.gd`
- `scripts/data/shop_manager.gd`
- `scripts/ui/shop.gd`
- `scenes/ui/shop.tscn`
- `scripts/ui/shop_item_card.gd`
- `scenes/ui/shop_item_card.tscn`
- `scripts/data/ad_manager.gd`
- `scripts/data/dev_ad_provider.gd`
- `scripts/ui/ad_purchase_popup.gd`
- `scenes/ui/ad_purchase_popup.tscn`

### 대폭 수정
- `scripts/game_manager.gd` — 인피니티 참조 제거
- `scripts/main/main_menu.gd` — 인피니티 버튼 제거, 리뉴얼
- `scripts/main/stage_select_screen.gd` — 노드맵 제거 or 전체 삭제
- `scripts/ui/result_popup.gd/.tscn` — 별 제거, 턴 추가 흐름 추가
- `scripts/data/save_manager.gd` — stars/currency/shop_history 제거, 젬/하트 추가
- `scripts/data/stamina_manager.gd` — 하트 시스템으로 리뉴얼
- `scripts/companion/skill_manager.gd` — 3슬롯, 삭제된 스킬 참조 제거
- `scripts/companion/party_manager.gd` — 3슬롯
- `scripts/companion/party_select.gd` — 3슬롯, 모드 호환성 체크 제거
- `scripts/companion/skill_hud.gd/.tscn` — 3슬롯 UI
- `scripts/companion/imagen.gd` — K1~K3, K10, K11 참조 제거
- `scripts/modes/story_mode.gd` — 별 계산 제거
- `scripts/data/player_profile.gd` — 가입일 필드 추가
