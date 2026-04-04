# Handoff: Pictory 퍼즐 게임 — 기획/설계/스프린트 계획 완료, 구현 미착수

**Generated**: 2026-04-04
**Branch**: (no git repo initialized)
**Status**: In Progress — 기획/설계/스프린트 계획 문서 완료, Godot 구현 미착수

## Goal

니노쿠니 IP 기반 "컬러 플러드 + 라인(행/열) 파괴 + 중력 + 연쇄 콤보" 모바일 퍼즐 게임을 Godot 4.6으로 구현한다. 외부 리소스 없이 AI가 코드만으로 구현 가능하게 만든다.

## Completed

- [x] 핵심 메카닉 재설계 (구: 색 통일 퍼즐 → 신: 라인 파괴 콤보 퍼즐)
- [x] HTML 프로토타입 v2로 코어 루프 검증 (`pictory-puzzle-prototype_2.html`)
- [x] UI 플로우 다이어그램 작성 (`pictory ui flow.png`)
- [x] GDD 전면 재작성 (`docs/game-design-document.md`)
- [x] 구현 계획 문서 갱신 (`docs/01-plan/features/pictory-core.plan.md`)
- [x] 설계 문서 갱신 (`docs/02-design/features/pictory-core.design.md`)
- [x] 기믹 & 동료 스킬 리스트 v1 확정 (`docs/gimmick-candidates.md`)
- [x] 모든 문서에 "AI-only 구현" 원칙 반영
- [x] v2 프로토타입 기준 문서 갱신 (팔레트→컬러 큐, 행 파괴→라인(행/열) 파괴)
- [x] 마일스톤 → 스프린트 → 일감 로드맵 작성 (`docs/01-plan/sprint-roadmap.md`)
- [x] S01~S12 스프린트별 상세 계획 문서 작성 (`docs/01-plan/sprints/S01~S12.plan.md`)
- [x] GDD 수정사항 반영: 챕터 단위 해금, 컬렉션 3탭(후냐/이마젠/아이콘), 플레이어 프로필
- [x] `/sprint` 스킬 작성 (스프린트 구현 자동화)

## Not Yet Done

### Godot 구현

- [ ] git 초기화 + 초기 커밋
- [ ] S01~S12 순서대로 코어 퍼즐 → 게임 루프 → 기믹 → 스토리 → 이마젠 → 컬렉션 → 수익화 → 툴 구현
- [ ] S13~S16 폴리싱 + QA + 출시

## Failed Approaches (Don't Repeat These)

### 기믹 설계 — 여러 기믹이 새 메카닉과 맞지 않아 삭제됨

라인 파괴 + 중력 메카닉에서 "한 번에 연결 그룹 전체가 파괴"되기 때문에 아래 기믹들은 효과가 없거나 중복:

| 삭제된 기믹 | 사유 |
|------------|------|
| **벽** | "연결 차단하지만 파괴 가능"은 컨셉 모순 |
| **얼음(구)** | 너무 불쾌한 경험. 강화 칸이 같은 역할을 더 깔끔하게 → 얼음으로 명칭 변경 |
| **블랙홀/폭탄** | 라인 파괴 시 연결 그룹이 이미 대량 파괴되므로 추가 범위 파괴가 무의미 |
| **분열** | 버퍼에서 계속 새 블록이 떨어지므로 "2개로 분열"이 의미 없음 |
| **무거운** | 중력으로 이미 끝까지 낙하하므로 2배 중력 무의미 |
| **화살** | 가로+세로 모두 라인 파괴 가능하므로 "세로 파괴 가능성"이란 고유 가치 없음 |
| **거울** | 대칭 위치 색 변경은 체감 너무 약함 |

### 동료 스킬 — 기믹 대응 스킬 삭제

"잠금 해제", "강화 깨기", "앵커 해제" 등 특정 기믹에 종속된 스킬은 범용성이 없어 전부 삭제. 동료 스킬은 어떤 보드 상태에서든 유용한 범용 스킬로만 구성.

### 프로토타입 버전 혼동

v1 프로토타입(`pictory-puzzle-prototype.html`)은 구버전(가로만 파괴, 팔레트 선택 방식). **반드시 v2(`pictory-puzzle-prototype_2.html`)를 참조**해야 함. v2는 가로+세로 파괴, 컬러 큐 방식.

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| 메카닉: 색 통일 → 라인(행/열) 파괴 콤보 | 더 액션감 있고 매치퍼즐 유저에게 친숙한 루프 |
| 그리드 가변 크기 (5×5 ~ 7×7) | 초반 쉽게, 챕터 진행에 따라 확장 |
| 컬러 큐: 스트라이드 스케줄링 + 랜덤 오프셋 | 순수 랜덤은 불쾌 → 색상 균등 출현 보장 + 미세 변동 |
| 별 시스템: 남은 턴 기준 | 최적해 솔버 필요 없음, 스테이지별 수동 조절 가능 |
| 인피니티 모드: 대량 파괴 시 보너스 시간 | 콤보 추구 동기 부여, n개 임계치/비례 계수는 밸런싱 파라미터 |
| 하우징 시스템 삭제 | 스코프 축소 |
| AI-only 구현 | 외부 리소스 없이 Godot 내장 기능(도형, Tween, 셰이더, 파티클)만 사용 |
| 기믹/스킬을 맵 기믹 vs 동료 스킬로 분리 | 환경 요소와 플레이어 능동 발동을 명확히 구분 |
| 기믹/스킬을 모드별 분류 (공용/스토리/인피니티) | 턴 기반 vs 시간 기반 차이에 맞는 설계 |
| S12까지 기능 개발 완료, S13+ 폴리싱/QA만 | 명확한 기능 동결선 |
| 챕터 단위 해금 (스테이지별 아님) | 유저 피드백 |
| 컬렉션 3탭: 후냐 커스텀/이마젠 편성/아이콘 | 유저 피드백 |
| 플레이어 프로필: 닉네임+아이콘, 최초 접속 시 입력 | 유저 피드백 |

## Current State

**Working**: HTML 프로토타입 v2(`pictory-puzzle-prototype_2.html`)에서 코어 루프 플레이 가능 (7×7 고정, 스토리 10스테이지 + 타임어택 60초)

**Broken**: 없음 (Godot 구현 자체가 아직 시작 안 됨)

**Uncommitted Changes**: git repo가 초기화되지 않음. 모든 파일이 새로 생성된 상태.

## Files to Know

| File | Why It Matters |
|------|----------------|
| `docs/game-design-document.md` | 전체 GDD — 메카닉, 모드, 기믹, 스토리, 재화, 이마젠, 로드맵 |
| `docs/01-plan/features/pictory-core.plan.md` | 구현 계획 — 아키텍처, 페이즈별 작업, 스크립트 구조 |
| `docs/02-design/features/pictory-core.design.md` | 상세 설계 — 알고리즘, 데이터 구조, 스크립트별 설계 |
| `docs/gimmick-candidates.md` | 확정된 기믹 13종 + 동료 스킬 11종 (모드별 분류) |
| `docs/01-plan/sprint-roadmap.md` | **전체 스프린트 로드맵** — M1~M8, S01~S16, 마일스톤/스프린트/일감 구조 |
| `docs/01-plan/sprints/S01~S12.plan.md` | **스프린트별 상세 계획** — 일감별 설명, 수락 기준, 의존성, 구현 노트 |
| `pictory-puzzle-prototype_2.html` | HTML 프로토타입 v2 — 코어 루프 참조 구현 (JS, 가로+세로 파괴, 컬러 큐) |
| `pictory ui flow.png` | UI 플로우 다이어그램 |
| `project.godot` | Godot 4.6, Forward Plus, Jolt Physics, D3D12 |

## Code Context

### HTML 프로토타입 v2 핵심 구조 (JS — Godot 이식 참조)

```javascript
// 그리드: 7×7 메인 + 7행 버퍼
const COLS = 7, ROWS = 7, BUFFER_ROWS = 7;

// 컬러 큐: active 1 + next 3
let colorQueue = [];  // [0] = active, [1..3] = next
const QUEUE_SIZE = 4;

// BFS 연결 그룹 탐색 (버퍼 포함 전체 범위)
function getConnectedGroup(startR, startC) { /* BFS 4방향, 같은 색 */ }

// 행 + 열 완성 판정
function findFullRows() { /* 메인 영역 행 중 모든 칸이 같은 색인 행 */ }
function findFullCols() { /* 메인 영역 열 중 모든 칸이 같은 색인 열 */ }

// 파괴 대상: 완성된 행/열의 각 칸에서 BFS로 연결된 동색 그룹 전체
function findDestroyTargets(fullRows, fullCols) { /* Set으로 중복 제거 */ }

// 중력 + 버퍼 충전 (열별 아래→위 압축)
function applyGravityAndFill() { /* 열별 compaction + 빈 칸 랜덤 색 */ }

// 초기 그리드 보정: 시작 시 완성 행/열 방지
function fixRow(r) { /* 모든 칸 동색이면 1칸 변경 */ }
function fixCol(c) { /* 모든 칸 동색이면 1칸 변경 */ }

// 게임 루프: 색칠 → 연쇄 파괴 (while 완성 라인 존재) → 승리/패배 판정
async function onCellClick(r, c) {
  if (grid[r][c] === getActiveColor()) return;  // 같은 색 터치 무효
  // 1. BFS 리컬러
  // 2. 큐 진행
  // 3. 연쇄: while(fullRows+fullCols) { destroy → gravity → recheck }
  // 4. 클리어/게임오버 판정
}
```

### Godot 설계 문서에 정의된 핵심 스크립트 (아직 미구현)

```
scripts/
├── core/
│   ├── grid.gd          # N×N + N버퍼 그리드 데이터, 셀 CRUD, ensure_no_completed_lines
│   ├── cell.gd          # 색상, 좌표, 활성, 기믹 슬롯
│   ├── flood_fill.gd    # BFS 연결 그룹 탐색
│   ├── row_destroy.gd   # 행+열 완성 판정 + 파괴 대상 산출
│   ├── gravity.gd       # 중력 낙하 + 버퍼 충전
│   ├── chain_combo.gd   # 연쇄 루프 오케스트레이션
│   ├── color_queue.gd   # 스트라이드 스케줄링 + 랜덤 오프셋
│   └── turn_manager.gd  # 턴/시간/클리어 판정
├── modes/
│   ├── story_mode.gd    # 턴 제한, N블록 목표, 별 시스템
│   └── infinity_mode.gd # 시간 제한, 보너스 시간
├── data/
│   ├── level_loader.gd  # 레벨 JSON 로드
│   ├── save_manager.gd  # 저장/불러오기
│   └── economy.gd       # 점수/재화 관리
└── ui/
    ├── color_queue_ui.gd # 컬러 큐 표시
    ├── hud.gd            # HUD
    └── result_screen.gd  # 결과 화면
```

### 확정된 기믹 요약

```
공용(8): 잠긴칸, 돌칸, 얼음칸, 무지개칸, 앵커칸, 페인트통, 코인칸, 연쇄칸
스토리 전용(3): 별칸(+1턴), 번짐칸, 퇴색칸
인피니티 전용(2): 시간칸(+N초), 독칸(시간감소 가속)
```

### 확정된 동료 스킬 요약

```
공용(9): 단색폭풍, 무지개파동, 컬러스왑, 컬러봄, 행청소, 되감기, 미래의눈, 셔플, 큐뒤집기
스토리 전용(1): 시간의숨결(+N턴)
인피니티 전용(1): 시간정지(N초 타이머 정지)
```

## Resume Instructions

1. **git 초기화** — 프로젝트에 git repo가 없음. `git init` + 초기 커밋

2. **코어 퍼즐 구현 시작** — `/sprint S01` 스킬 사용 또는 S01부터 순서대로:
   - S01: 그리드 기반 (cell.gd, grid.gd, 렌더링, 터치)
   - S02: 코어 메카닉 (BFS, 리컬러, 라인 파괴, 중력)
   - S03: 연쇄 + 큐 + HUD
   - ...S12까지 순서대로
   - 각 스프린트 상세 계획은 `docs/01-plan/sprints/S##.plan.md` 참조

3. **폴리싱 + QA** — S13~S16 (기능 개발 완료 후)

## Warnings

- **반드시 v2 프로토타입 참조** — `pictory-puzzle-prototype_2.html`. v1(`pictory-puzzle-prototype.html`)은 구버전이므로 무시
- **가로+세로 모두 라인 파괴** — 프로토타입 v2에 이미 구현되어 있음
- **그리드 크기 가변** — 프로토타입은 7×7 고정이지만 실제는 스테이지별 5×5~7×7. 버퍼 행 수 = 그리드 행 수
- **AI-only 원칙** — 외부 이미지/사운드 임포트 금지. 모든 비주얼은 Godot 내장 기능으로
- **앵커 칸 동작** — 중력 무시하고 위치 고정. 앵커 아래 빈 공간은 버퍼에서 정상 충전
- **인피니티 모드 기믹 틱** — 시간 기반이 아니라 액션(터치) 횟수 기준으로 트리거
- **S08~S12 스프린트 계획 문서** — 에이전트 rate limit으로 일부 상세도가 S01~S07보다 낮을 수 있음. 구현 전 검증 권장
