# Pictory Core Design Document

> **Summary**: 컬러 플러드 + 라인(행/열) 파괴 + 중력 + 연쇄 콤보 퍼즐 게임 전체 시스템 상세 설계
>
> **Project**: Pictory
> **Version**: 0.4.0
> **Author**: -
> **Date**: 2026-04-04
> **Status**: Draft
> **Planning Doc**: [pictory-core.plan.md](../01-plan/features/pictory-core.plan.md)

---

## 1. Overview

### 1.1 Design Goals

- **즉시 플레이 가능한 코어 루프**: 컬러 큐의 현재 색으로 셀 터치 → BFS 리컬러 → 라인(행/열) 파괴 → 중력 → 연쇄의 직관적 경험을 최우선 구현
- **확장 가능한 기믹 시스템**: 기믹은 TBD이나, 추가 시 코드 수정 최소화 가능한 데이터 주도 설계 유지
- **데이터-로직-뷰 분리**: 시뮬레이터가 게임 로직을 재사용할 수 있는 구조
- **모바일 최적화**: 60fps, 한 손 세로 조작, 터치 영역 44dp 이상

### 1.2 Design Principles

- **AI-only 구현**: 외부 리소스(이미지, 스프라이트, 사운드)나 수작업 애니메이션 없이 AI가 코드만으로 구현 가능한 범위로 설계. 비주얼은 Godot 내장 기능(ColorRect, 도형 draw, 셰이더, Tween, GPUParticles)으로 처리. UI는 Godot 컨트롤 노드로 구성.
- **데이터 주도**: 레벨, 이마젠 모두 JSON 외부 데이터로 관리. 코드 변경 없이 콘텐츠 추가.
- **단일 책임**: 각 스크립트는 하나의 역할만 담당 (grid = 데이터, flood_fill = 탐색, row_destroy = 라인(행/열) 파괴, gravity = 낙하).
- **신호(Signal) 기반 통신**: Godot 신호 시스템으로 컴포넌트 간 느슨한 결합.
- **테스트 가능성**: 핵심 로직(BFS, 라인 파괴, 중력, 콤보, 점수)은 씬/노드 독립적으로 테스트 가능하게 설계.
- **파이프라인 구조**: 리컬러 → 라인(행/열) 판정 → 파괴 → 중력 → 연쇄 재판정의 명확한 단계별 처리.

---

## 2. Architecture

### 2.1 System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────┐  │
│  │ GridView │ │   HUD    │ │ColorQueue│ │  ResultScreen │  │
│  │ (씬/노드) │ │(턴/시간/ │ │ (컬러 큐 │ │  (결과 화면)  │  │
│  │          │ │  점수)   │ │현재+다음) │ │               │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └───────────────┘  │
│       │            │            │                            │
├───────┼────────────┼────────────┼────────────────────────────┤
│       ▼            ▼            ▼        Game Logic          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                  GameManager                         │    │
│  │  (모드 관리, 턴/시간 진행, 클리어/게임오버 판정)       │    │
│  └────┬──────────┬──────────┬──────────┬───────────────┘    │
│       │          │          │          │                     │
│  ┌────▼───┐ ┌───▼────┐ ┌──▼───────┐ ┌▼──────────────┐     │
│  │  Grid  │ │Flood   │ │RowDestroy│ │   Companion   │     │
│  │ (Data) │ │Fill    │ │+ Gravity │ │   Manager     │     │
│  │ +Buffer│ │        │ │+ Chain   │ │               │     │
│  └────┬───┘ └────────┘ └──────────┘ └───────────────┘     │
│       │                                                     │
│  ┌────▼──────────┐                                          │
│  │  ColorQueue   │  ← 스트라이드 스케줄링 + 랜덤 오프셋     │
│  │  (버퍼 생성)  │    Inspector 파라미터 노출                │
│  └───────────────┘                                          │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                          Data Layer                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │  Level   │ │  Save    │ │ Economy  │ │  Collection  │  │
│  │  Loader  │ │ Manager  │ │ Manager  │ │  Manager     │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │
│       ▲                                                     │
│  ┌────┴─────────────────────────────────────────────────┐  │
│  │              JSON Resources (레벨/이마젠/컬렉션)        │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Tools (에디터 전용)                        │
│  ┌──────────────┐ ┌───────────────────────┐                 │
│  │  Simulator   │ │  Level Generator      │                 │
│  │ (밸런싱 시뮬) │ │  (자동 생성)           │                 │
│  └──────────────┘ └───────────────────────┘                 │
│  ※ Game Logic 레이어의 Grid/FloodFill/RowDestroy를 직접 재사용│
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Signal Flow (핵심 게임 루프)

```
User Touch
    │
    ▼
ColorQueue.advance()                     ← 큐 진행 (액션 후 자동)
    │
    ▼
GridView.cell_touched(x, y)
    │
    ▼
GameManager._on_cell_touched(x, y)
    ├── FloodFill.find_connected_group(grid, x, y)
    ├── Grid.apply_color(group, selected_color)       # BFS 리컬러
    ├── CompanionManager.update_cooldowns()            # 스킬 쿨타임 감소
    ├── GameManager.consume_turn()                     # 턴 소모 (스토리 모드)
    │
    ▼
ChainCombo.execute(grid)                              # 연쇄 루프 시작
    │
    ├── RowDestroy.check_and_destroy(grid)            # 완성된 라인(행/열) 탐색
    │     ├── 단일 색 행 발견 → 해당 행 파괴
    │     ├── 단일 색 열 발견 → 해당 열 파괴
    │     └── 파괴된 라인의 색과 연결된 그룹도 함께 파괴
    │
    ├── Gravity.apply(grid)                           # 중력 낙하
    │     ├── 빈 공간 위 블록 하강
    │     └── ColorQueue에서 버퍼 행 공급
    │
    ├── Economy.add_score(destroyed_count, combo)      # 점수 계산
    │
    └── 다시 행/열 완성 있으면 → 연쇄 반복 (콤보 +1)
        없으면 → 연쇄 종료
    │
    ▼
GameManager.check_state()
    ├── 스토리: 파괴 목표 달성? → emit clear_achieved(stars)
    ├── 스토리: 턴 == 0?       → emit game_over
    ├── 무한:   시간 == 0?     → emit game_over
    └── else                   → wait for next input
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| GameManager | Grid, FloodFill, RowDestroy, Gravity, ChainCombo, ColorQueue, CompanionManager, Economy | 게임 루프 오케스트레이션 |
| FloodFill | Grid (read-only) | 연결 그룹 BFS 탐색 |
| RowDestroy | Grid (read/write), FloodFill | 라인(행/열) 완성 판정 + 라인/그룹 파괴 |
| Gravity | Grid (read/write), ColorQueue | 중력 낙하 + 버퍼 공급 |
| ChainCombo | RowDestroy, Gravity, Economy | 라인 파괴 → 낙하 → 재판정 루프 |
| ColorQueue | - | 스트라이드 스케줄링으로 버퍼 색상 생성 |
| CompanionManager | Grid, FloodFill | 스킬 발동 시 게임 로직 호출 |
| GridView | Grid (read-only) | 그리드 데이터 시각화 |
| Simulator | Grid, FloodFill, RowDestroy, Gravity, ChainCombo, Economy | 밸런싱 시뮬레이션 |

---

## 3. Data Model

### 3.1 Cell (셀)

```gdscript
# cell.gd
class_name Cell
extends RefCounted

var x: int
var y: int
var color: int = -1              # 색상 인덱스 (-1 = 없음/빈칸)
var active: bool = true          # 활성 여부

# 기믹 관련 (TBD — 라인(행/열) 파괴 메커니즘에 맞게 재설계 예정)
# enum Gimmick { NONE, ... }
# var gimmick: Gimmick = Gimmick.NONE
# var gimmick_param: int = 0
```

### 3.2 Grid (그리드)

```gdscript
# grid.gd
class_name PuzzleGrid
extends RefCounted

const MAIN_ROWS: int = 7        # 메인 그리드 행 수
const MAIN_COLS: int = 7        # 메인 그리드 열 수
const BUFFER_ROWS: int = 7      # 버퍼 행 수

var width: int = MAIN_COLS
var height: int = MAIN_ROWS + BUFFER_ROWS  # 총 14행 (7 메인 + 7 버퍼)
var cells: Array[Array]          # 2D Array of Cell
var color_count: int             # 사용 색상 수

func get_cell(x: int, y: int) -> Cell
func set_cell_color(x: int, y: int, color: int) -> void
func is_valid(x: int, y: int) -> bool
func is_active(x: int, y: int) -> bool
func is_main_area(y: int) -> bool:
    return y >= BUFFER_ROWS      # 버퍼 아래가 메인 영역
func clear_cell(x: int, y: int) -> void:
    # 셀을 빈칸으로 (파괴 시 사용)
    var cell = get_cell(x, y)
    cell.color = -1
    cell.active = false
func get_all_active_cells() -> Array[Cell]
func get_main_row(row: int) -> Array[Cell]:
    # 메인 영역의 특정 행 반환 (row 0 = 메인 최상단)
    return _get_row(BUFFER_ROWS + row)
func clone() -> PuzzleGrid       # 시뮬레이터용 딥카피

## 초기 그리드 생성 시, 이미 완성된 행이나 열이 없도록 검증/수정 필요
## (v2 프로토타입의 fixRow/fixCol 참조)
func ensure_no_completed_lines() -> void:
    # 초기화 직후 호출하여 완성된 행/열이 있으면 해당 셀의 색을 교체
    pass
```

### 3.3 ColorQueue (컬러 큐)

```gdscript
# color_queue.gd
class_name ColorQueue
extends RefCounted

## 스트라이드 스케줄링 + 랜덤 오프셋으로 버퍼 색상 생성
## Godot Inspector에서 파라미터 조정 가능

@export var stride: int = 3          # 같은 색이 반복되는 주기
@export var offset_range: int = 1    # 랜덤 오프셋 범위 (-offset_range ~ +offset_range)
@export var color_count: int = 5     # 사용할 색상 수

var _sequence_index: int = 0

## 다음 색상 생성
func next_color() -> int:
    var base_color = (_sequence_index / stride) % color_count
    var offset = randi_range(-offset_range, offset_range)
    var result = (base_color + offset) % color_count
    if result < 0:
        result += color_count
    _sequence_index += 1
    return result

## 버퍼 행 하나를 생성 (7칸)
func generate_row(width: int) -> Array[int]:
    var row: Array[int] = []
    for i in range(width):
        row.append(next_color())
    return row

## 파라미터 리셋
func reset() -> void:
    _sequence_index = 0
```

### 3.4 Level Data (레벨 JSON)

```json
{
  "id": "story_1_3",
  "mode": "story",
  "chapter": 1,
  "stage": 3,
  "grid": {
    "width": 7,
    "height": 7,
    "initial_colors": [
      [0, 1, 2, 0, 1, 2, 0],
      [1, 0, 1, 2, 0, 1, 2],
      [2, 1, 0, 1, 2, 0, 1],
      [0, 2, 1, 0, 1, 2, 0],
      [1, 0, 2, 1, 0, 1, 2],
      [2, 1, 0, 2, 1, 0, 1],
      [0, 2, 1, 0, 2, 1, 0]
    ]
  },
  "colors": ["#FF4444", "#4444FF", "#44FF44", "#FFFF44", "#FF44FF"],
  "color_count": 5,
  "max_turns": 15,
  "destroy_goal": 30,
  "star_thresholds": {
    "star3_remaining_turns": 5,
    "star2_remaining_turns": 2,
    "star1_remaining_turns": 0
  },
  "color_queue": {
    "stride": 3,
    "offset_range": 1
  },
  "companion_slots": 1,
  "drops": [
    {"type": "hunya_skin", "id": "skin_chapter1", "chance": 0.3},
    {"type": "player_icon", "id": "icon_flame", "chance": 0.1}
  ],
  "story_before": "story_1_3_before",
  "story_after": "story_1_3_after"
}
```

### 3.5 Imagen (동료 이마젠)

```gdscript
# imagen.gd
class_name Imagen
extends RefCounted

enum SkillType {
    COLOR_CONVERT,   # 색 변환: 지정 색 → 다른 색
    TURN_RECOVER,    # 턴/시간 회복
    HINT,            # 힌트: 추천 수 1턴 표시
    AREA_FILL,       # 범위 효과: 지정 영역 단일 색
    ROW_CLEAR,       # 행 즉시 파괴
    # 기믹 관련 스킬은 기믹 시스템 재설계 후 추가 (TBD)
}

var id: String
var name: String
var description: String
var sprite_path: String
var skill_type: SkillType
var skill_name: String
var skill_description: String
var skill_param: Dictionary  # {"turns": 2, "range": 1, ...}
var cooldown_max: int        # 최대 쿨타임 (턴)
var cooldown_current: int    # 현재 남은 쿨타임
var unlocked: bool = false
```

### 3.6 Imagen Data (이마젠 JSON)

```json
{
  "id": "imagen_fireball",
  "name": "파이어볼",
  "description": "불꽃을 품은 이마젠. 뜨거운 열정으로 블록을 태운다.",
  "sprite": "res://assets/sprites/imagenes/fireball.png",
  "skill": {
    "type": "ROW_CLEAR",
    "name": "열정의 불꽃",
    "description": "지정한 행을 즉시 파괴한다.",
    "param": {"count": 1},
    "cooldown": 5
  },
  "unlock_chapter": 2,
  "unlock_stage": 5
}
```

### 3.7 Save Data (저장 데이터)

```json
{
  "version": 2,
  "currency": 1500,
  "infinity_high_score": 12400,
  "infinity_best_time": 185.5,
  "story": {
    "unlocked_chapters": [1, 2, 3],
    "stages": {
      "story_1_1": {"stars": 3, "best_remaining_turns": 5, "blocks_destroyed": 42},
      "story_1_2": {"stars": 2, "best_remaining_turns": 2, "blocks_destroyed": 35}
    }
  },
  "companions": {
    "unlocked": ["imagen_fireball", "imagen_aqua"],
    "party": ["imagen_fireball"]
  },
  "collection": {
    "hunya_skins": ["skin_default", "skin_chapter1"],
    "hunya_accessories": ["acc_ribbon"],
    "player_icons": ["icon_default", "icon_chapter1"]
  },
  "player_profile": {
    "nickname": "Player1",
    "icon": "icon_default"
  }
}
```

### 3.8 Entity Relationships

```
[SaveData] 1 ──── 1 [PlayerProgress]
    │
    ├── 1 ──── 1 [PlayerProfile]   (닉네임, 아이콘)
    ├── 1 ──── N [StageResult]     (스테이지별 별/최고기록/파괴수)
    ├── 1 ──── N [Imagen]          (해금된 동료)
    └── 1 ──── N [CollectionItem]  (후냐 스킨/액세서리, 플레이어 아이콘)

[Level] 1 ──── 1 [ColorQueueConfig]  (컬러 큐 파라미터)
[Level] 1 ──── N [DropItem]          (드롭 테이블)
[Imagen] 1 ──── 1 [Skill]           (이마젠별 고유 스킬)
```

---

## 4. Core Algorithm Design

### 4.1 FloodFill (BFS 연결 그룹 탐색)

```gdscript
# flood_fill.gd
class_name FloodFill

const DIRECTIONS = [
    Vector2i(0, -1),  # 상
    Vector2i(0, 1),   # 하
    Vector2i(-1, 0),  # 좌
    Vector2i(1, 0)    # 우
]

## 지정 셀과 연결된 동색 그룹을 BFS로 탐색
static func find_connected_group(grid: PuzzleGrid, start_x: int, start_y: int) -> Array[Cell]:
    var start_cell = grid.get_cell(start_x, start_y)
    if not start_cell or not start_cell.active:
        return []

    var target_color = start_cell.color
    var visited: Dictionary = {}  # "x,y" -> true
    var queue: Array[Vector2i] = [Vector2i(start_x, start_y)]
    var group: Array[Cell] = []

    visited[_key(start_x, start_y)] = true

    while queue.size() > 0:
        var pos = queue.pop_front()
        var cell = grid.get_cell(pos.x, pos.y)
        group.append(cell)

        for i in range(4):
            var dir = DIRECTIONS[i]
            var nx = pos.x + dir.x
            var ny = pos.y + dir.y
            var nkey = _key(nx, ny)

            if visited.has(nkey):
                continue
            if not grid.is_valid(nx, ny) or not grid.is_active(nx, ny):
                continue

            var neighbor = grid.get_cell(nx, ny)
            if neighbor.color == target_color:
                visited[nkey] = true
                queue.append(Vector2i(nx, ny))

    return group

static func _key(x: int, y: int) -> String:
    return str(x) + "," + str(y)
```

### 4.2 RowDestroy (라인(행/열) 파괴 판정)

```gdscript
# row_destroy.gd
class_name RowDestroy

## 메인 영역에서 완성된 라인(행 또는 열, 단일 색)을 탐색하고, 해당 라인 + 연결 그룹을 파괴
## 반환: 파괴된 셀 목록
static func check_and_destroy(grid: PuzzleGrid) -> Array[Cell]:
    var destroyed: Array[Cell] = []
    var destroyed_set: Dictionary = {}  # "x,y" -> true (중복 방지)

    # ── 가로(행) 완성 판정 ──
    for row in range(PuzzleGrid.MAIN_ROWS):
        var row_cells = grid.get_main_row(row)
        if _is_line_complete(row_cells):
            # 1. 해당 행의 모든 셀 파괴 대상에 추가
            for cell in row_cells:
                var key = FloodFill._key(cell.x, cell.y)
                if not destroyed_set.has(key):
                    destroyed_set[key] = true
                    destroyed.append(cell)

            # 2. 행의 각 셀에서 BFS로 같은 색 연결 그룹 탐색 → 함께 파괴
            for cell in row_cells:
                var connected = FloodFill.find_connected_group(grid, cell.x, cell.y)
                for c in connected:
                    var key = FloodFill._key(c.x, c.y)
                    if not destroyed_set.has(key):
                        destroyed_set[key] = true
                        destroyed.append(c)

    # ── 세로(열) 완성 판정 ──
    for col in range(grid.width):
        var col_cells: Array[Cell] = []
        for row in range(PuzzleGrid.BUFFER_ROWS, grid.height):
            col_cells.append(grid.get_cell(col, row))
        if _is_line_complete(col_cells):
            # 1. 해당 열의 모든 셀 파괴 대상에 추가
            for cell in col_cells:
                var key = FloodFill._key(cell.x, cell.y)
                if not destroyed_set.has(key):
                    destroyed_set[key] = true
                    destroyed.append(cell)

            # 2. 열의 각 셀에서 BFS로 같은 색 연결 그룹 탐색 → 함께 파괴
            for cell in col_cells:
                var connected = FloodFill.find_connected_group(grid, cell.x, cell.y)
                for c in connected:
                    var key = FloodFill._key(c.x, c.y)
                    if not destroyed_set.has(key):
                        destroyed_set[key] = true
                        destroyed.append(c)

    # 실제 파괴 적용
    for cell in destroyed:
        grid.clear_cell(cell.x, cell.y)

    return destroyed

## 라인(행 또는 열)이 완성되었는지 확인 (모든 칸이 활성이고 같은 색)
static func _is_line_complete(line_cells: Array[Cell]) -> bool:
    if line_cells.size() == 0:
        return false
    var first_color = line_cells[0].color
    if first_color < 0:
        return false
    for cell in line_cells:
        if not cell.active or cell.color != first_color:
            return false
    return true
```

### 4.3 Gravity (중력 낙하)

```gdscript
# gravity.gd
class_name Gravity

## 빈 공간 위의 블록을 아래로 떨어뜨리고, 버퍼에서 새 블록 공급
static func apply(grid: PuzzleGrid, color_queue: ColorQueue) -> void:
    # 각 열에 대해 아래에서 위로 처리
    for col in range(grid.width):
        _compact_column(grid, col)
        _fill_from_buffer(grid, col, color_queue)

## 열 내 빈칸을 아래로 압축 (중력)
static func _compact_column(grid: PuzzleGrid, col: int) -> void:
    var write_y = grid.height - 1  # 가장 아래부터

    # 아래에서 위로 스캔하며 활성 셀을 아래로 이동
    for read_y in range(grid.height - 1, -1, -1):
        var cell = grid.get_cell(col, read_y)
        if cell and cell.active:
            if read_y != write_y:
                # 셀을 write_y 위치로 이동
                var target = grid.get_cell(col, write_y)
                target.color = cell.color
                target.active = true
                cell.color = -1
                cell.active = false
            write_y -= 1

    # 남은 상단 칸을 비활성으로
    for y in range(write_y, -1, -1):
        var cell = grid.get_cell(col, y)
        cell.color = -1
        cell.active = false

## 버퍼 영역에 컬러 큐에서 새 블록 공급
static func _fill_from_buffer(grid: PuzzleGrid, col: int, color_queue: ColorQueue) -> void:
    for y in range(grid.height):
        var cell = grid.get_cell(col, y)
        if not cell.active:
            cell.color = color_queue.next_color()
            cell.active = true
        else:
            break  # 활성 셀을 만나면 중단
```

### 4.4 ChainCombo (연쇄 콤보 루프)

```gdscript
# chain_combo.gd
class_name ChainCombo

const MAX_CHAIN: int = 20  # 무한 루프 방지

## 파괴 → 낙하 → 재판정 연쇄 루프 실행
## 반환: {total_destroyed: int, max_combo: int, chain_results: Array}
static func execute(grid: PuzzleGrid, color_queue: ColorQueue) -> Dictionary:
    var total_destroyed: int = 0
    var combo: int = 0
    var chain_results: Array = []

    while combo < MAX_CHAIN:
        # 1. 라인(행/열) 파괴 판정
        var destroyed = RowDestroy.check_and_destroy(grid)
        if destroyed.size() == 0:
            break  # 더 이상 파괴할 라인 없음 → 연쇄 종료

        combo += 1
        total_destroyed += destroyed.size()
        chain_results.append({
            "combo": combo,
            "destroyed_count": destroyed.size(),
            "destroyed_cells": destroyed
        })

        # 2. 중력 낙하 + 버퍼 공급
        Gravity.apply(grid, color_queue)

    return {
        "total_destroyed": total_destroyed,
        "max_combo": combo,
        "chain_results": chain_results
    }
```

### 4.5 GameManager (게임 루프 관리)

```gdscript
# game_manager.gd
class_name GameManager
extends Node

signal turn_consumed(remaining: int)
signal time_updated(remaining: float)
signal score_changed(score: int)
signal blocks_destroyed(count: int, combo: int)
signal clear_achieved(stars: int)
signal game_over()
signal cells_changed(cells: Array[Cell])

var grid: PuzzleGrid
var color_queue: ColorQueue
var current_color: int = 0       # 컬러 큐의 현재 배정 색상
var turns_remaining: int         # 스토리 모드: 남은 턴
var max_turns: int               # 스토리 모드: 최대 턴
var time_remaining: float        # 무한 모드: 남은 시간
var destroy_goal: int            # 스토리 모드: 파괴 목표
var total_destroyed: int = 0     # 누적 파괴 블록 수
var score: int = 0
var mode: String                 # "story" or "infinity"
var star_thresholds: Dictionary  # 스토리 모드: 별 기준
var companion_manager: CompanionManager

func load_level(level_data: Dictionary) -> void:
    grid = LevelLoader.parse_grid(level_data)
    color_queue = ColorQueue.new()
    color_queue.color_count = level_data.color_count
    if level_data.has("color_queue"):
        color_queue.stride = level_data.color_queue.stride
        color_queue.offset_range = level_data.color_queue.offset_range
    max_turns = level_data.get("max_turns", 0)
    turns_remaining = max_turns
    destroy_goal = level_data.get("destroy_goal", 0)
    star_thresholds = level_data.get("star_thresholds", {})
    total_destroyed = 0
    score = 0

func select_color(color_index: int) -> void:
    current_color = color_index

func touch_cell(x: int, y: int) -> void:
    var cell = grid.get_cell(x, y)
    if not cell or not cell.active:
        return
    if not grid.is_main_area(y):
        return  # 버퍼 영역은 터치 불가

    # 1. 연결 그룹 탐색
    var group = FloodFill.find_connected_group(grid, x, y)

    # 2. BFS 리컬러
    for c in group:
        c.color = current_color

    # 3. 턴 소모 (스토리 모드)
    if mode == "story":
        turns_remaining -= 1
        turn_consumed.emit(turns_remaining)

    # 4. 스킬 쿨타임 감소
    if companion_manager:
        companion_manager.update_cooldowns()

    # 5. 연쇄 콤보 실행 (라인(행/열) 파괴 → 중력 → 재판정 루프)
    var chain_result = ChainCombo.execute(grid, color_queue)

    # 6. 점수 계산
    if chain_result.total_destroyed > 0:
        total_destroyed += chain_result.total_destroyed
        var turn_score = Economy.calculate_destruction_score(
            chain_result.total_destroyed, chain_result.max_combo)
        score += turn_score
        score_changed.emit(score)
        blocks_destroyed.emit(chain_result.total_destroyed, chain_result.max_combo)

        # 무한 모드: 대량 파괴 보너스 시간
        if mode == "infinity":
            var bonus_time = Economy.calculate_bonus_time(chain_result.total_destroyed)
            time_remaining += bonus_time
            time_updated.emit(time_remaining)

    # 7. 변경 알림 (뷰 업데이트용)
    cells_changed.emit(grid.get_all_active_cells())

    # 8. 상태 확인
    _check_state()

func use_skill(imagen_index: int) -> void:
    if companion_manager:
        companion_manager.activate_skill(imagen_index, grid)
        # 스킬 후에도 연쇄 콤보 확인
        var chain_result = ChainCombo.execute(grid, color_queue)
        if chain_result.total_destroyed > 0:
            total_destroyed += chain_result.total_destroyed
            score += Economy.calculate_destruction_score(
                chain_result.total_destroyed, chain_result.max_combo)
            score_changed.emit(score)
        cells_changed.emit(grid.get_all_active_cells())
        _check_state()

func _check_state() -> void:
    if mode == "story":
        if total_destroyed >= destroy_goal:
            var stars = _calculate_stars(turns_remaining)
            clear_achieved.emit(stars)
        elif turns_remaining <= 0:
            game_over.emit()
    elif mode == "infinity":
        if time_remaining <= 0:
            game_over.emit()

func _calculate_stars(remaining_turns: int) -> int:
    var s3 = star_thresholds.get("star3_remaining_turns", 5)
    var s2 = star_thresholds.get("star2_remaining_turns", 2)
    var s1 = star_thresholds.get("star1_remaining_turns", 0)
    if remaining_turns >= s3:
        return 3
    elif remaining_turns >= s2:
        return 2
    elif remaining_turns >= s1:
        return 1
    else:
        return 1  # 목표 달성했으면 최소 1성
```

---

## 5. UI/UX Design

### 5.1 Screen Layout (인게임)

```
┌─────────────────────────────────────┐
│ ← 일시정지    ♦ 1,500    ⟳ 턴: 8/15 │  ← 상단 HUD (48dp)
│              목표: 30블록 파괴        │     스토리: 턴/목표 표시
│              (또는 ⏱ 2:30)          │     무한: 시간/점수 표시
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │      버퍼 영역 (7행)         │    │  ← 버퍼 (일부만 보임, 스크롤)
│  │      (반투명 / 축소 표시)     │    │
│  ├─────────────────────────────┤    │
│  │                             │    │
│  │                             │    │
│  │      메인 그리드 (7x7)       │    │  ← 메인 영역 (터치 가능)
│  │      (최대 320dp)           │    │     정사각형, 화면 중앙
│  │                             │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌───┐ ┌───┐                        │
│  │ A │ │ B │     쿨타임: 2턴         │  ← 동료 이마젠 슬롯 (56dp)
│  └───┘ └───┘                        │
│                                     │
│  🔴  🔵  🟢  🟡  🟣               │  ← 컬러 큐 (현재 색 + 다음 3색) (64dp)
│                                     │     현재 배정 색 강조
└─────────────────────────────────────┘
     총 높이: 화면 세로 기준 배치
     여백: 좌우 16dp
```

### 5.2 Screen Flow

```
App Launch
    │
    ├── [최초 실행] ──→ 닉네임 입력 화면 ──→ 타이틀 화면
    │
    ▼
타이틀 화면 (좌상단: 닉네임 + 아이콘)
    ├── [무한 모드] ──→ 편성 화면 ──→ 게임 플레이 (시간 기반)
    │                                      │
    │                                      └── 시간 종료 ──→ 결과 ──→ 타이틀
    │
    ├── [스토리 모드] ──→ 챕터 선택 ──→ 스테이지 선택 ──→ 편성 화면
    │                                                      │
    │                      ┌───────────────────────────────┘
    │                      ▼
    │                  스토리 대화 (시작 전)
    │                      │
    │                      ▼
    │                  게임 플레이 (턴 제한 + N블록 파괴 목표)
    │                      │
    │                      ├── 클리어 ──→ 스토리 대화 (종료 후) ──→ 결과 (별) ──→ 스테이지 선택
    │                      └── 게임 오버 ──→ 결과 ──→ 스테이지 선택
    │
    ├── [컬렉션] ──→ 후냐 커스터마이징 / 이마젠 동료 편성 / 플레이어 아이콘
    │
    └── [설정]

※ 메인 메뉴 좌상단에 플레이어 닉네임 + 아이콘 표시
※ 최초 실행 시 닉네임 입력 화면 → 타이틀 화면으로 이동
```

### 5.3 Scene & Node Structure

| Scene | Path | Responsibility |
|-------|------|----------------|
| Main | `scenes/main/main.tscn` | 씬 전환 관리 (SceneTree) |
| Title | `scenes/main/title.tscn` | 타이틀 화면, 모드 선택 |
| Game | `scenes/game/game.tscn` | 인게임 (GridView + BufferView + HUD + ColorQueue) |
| GridView | `scenes/game/grid_view.tscn` | 메인 그리드 렌더링 |
| BufferView | `scenes/game/buffer_view.tscn` | 버퍼 영역 렌더링 (반투명) |
| CellView | `scenes/game/cell_view.tscn` | 개별 셀 (ColorRect) |
| StoryDialog | `scenes/story/story_dialog.tscn` | 대화 씬 |
| ChapterSelect | `scenes/main/chapter_select.tscn` | 챕터 선택 |
| StageSelect | `scenes/main/stage_select.tscn` | 스테이지 선택 (별 표시) |
| PartySelect | `scenes/main/party_select.tscn` | 이마젠 편성 |
| Collection | `scenes/main/collection.tscn` | 컬렉션 화면 (3탭: 후냐 커스터마이징 / 이마젠 편성 / 플레이어 아이콘) |
| NicknameInput | `scenes/main/nickname_input.tscn` | 닉네임 입력 (최초 실행) |
| Result | `scenes/ui/result.tscn` | 결과 화면 |
| Settings | `scenes/main/settings.tscn` | 설정 |

---

## 6. Mode Design

### 6.1 Infinity Mode (무한 모드 -- 시간 기반)

```gdscript
# modes/infinity_mode.gd
class_name InfinityMode
extends Node

var total_score: int = 0
var game_manager: GameManager
var initial_time: float = 60.0  # 초기 시간 (초)

func start() -> void:
    total_score = 0
    game_manager.mode = "infinity"
    game_manager.time_remaining = initial_time
    _load_stage()

func _process(delta: float) -> void:
    if game_manager.time_remaining > 0:
        game_manager.time_remaining -= delta
        game_manager.time_updated.emit(game_manager.time_remaining)
        if game_manager.time_remaining <= 0:
            game_manager.game_over.emit()

func _on_game_over() -> void:
    var currency = Economy.score_to_currency(game_manager.score)
    Economy.add_currency(currency)
    SaveManager.save()
    # 결과 화면 표시

func _load_stage() -> void:
    var level_data = LevelGenerator.generate_infinity(
        7,  # 7x7 고정
        _get_color_count(),
        _get_color_queue_params()
    )
    game_manager.load_level(level_data)
```

### 6.2 Story Mode (스토리 모드 -- 턴 제한 + N블록 파괴)

```gdscript
# modes/story_mode.gd
class_name StoryMode
extends Node

var current_chapter: int
var current_stage: int
var game_manager: GameManager

func start_stage(chapter: int, stage: int) -> void:
    current_chapter = chapter
    current_stage = stage
    var level_id = "story_%d_%d" % [chapter, stage]
    var level_data = LevelLoader.load_level(level_id)
    game_manager.load_level(level_data)
    game_manager.mode = "story"

func _on_clear(stars: int) -> void:
    # 결과 저장
    var level_id = "story_%d_%d" % [current_chapter, current_stage]
    SaveManager.update_stage_result(
        level_id, stars,
        game_manager.turns_remaining,
        game_manager.total_destroyed
    )

    # 동료 이마젠 합류 체크
    var new_imagen = ImagenDatabase.check_unlock(current_chapter, current_stage)
    if new_imagen:
        SaveManager.unlock_imagen(new_imagen.id)

    # 컬렉션 드롭 처리
    CollectionManager.process_drops(level_id)

    SaveManager.save()

func is_chapter_unlocked(chapter: int) -> bool:
    return SaveManager.data.story.unlocked_chapters.has(chapter)

func unlock_chapter(chapter: int) -> bool:
    var cost = _get_unlock_cost(chapter)
    if Economy.get_currency() >= cost:
        Economy.spend_currency(cost)
        SaveManager.data.story.unlocked_chapters.append(chapter)
        SaveManager.save()
        return true
    return false

func _get_unlock_cost(chapter: int) -> int:
    return chapter * 500  # 챕터 번호 x 500 (밸런싱 필요)
```

---

## 7. Companion Skill Design

### 7.1 Skill Execution

```gdscript
# companion/skill_manager.gd
class_name SkillManager

static func execute_skill(imagen: Imagen, grid: PuzzleGrid, params: Dictionary) -> Dictionary:
    if imagen.cooldown_current > 0:
        return {"success": false, "reason": "cooldown"}

    var result = {"success": true, "changed_cells": []}

    match imagen.skill_type:
        Imagen.SkillType.COLOR_CONVERT:
            result = _skill_color_convert(grid, params)
        Imagen.SkillType.TURN_RECOVER:
            result = _skill_turn_recover(imagen)
        Imagen.SkillType.HINT:
            result = _skill_hint(grid)
        Imagen.SkillType.AREA_FILL:
            result = _skill_area_fill(grid, params)
        Imagen.SkillType.ROW_CLEAR:
            result = _skill_row_clear(grid, params)

    if result.success:
        imagen.cooldown_current = imagen.cooldown_max

    return result

## 색 변환: from_color의 모든 칸을 to_color로
static func _skill_color_convert(grid: PuzzleGrid, params: Dictionary) -> Dictionary:
    var from_color = params.get("from_color", -1)
    var to_color = params.get("to_color", -1)
    var changed = []
    for cell in grid.get_all_active_cells():
        if cell.color == from_color:
            cell.color = to_color
            changed.append(cell)
    return {"success": true, "changed_cells": changed}

## 턴/시간 회복
static func _skill_turn_recover(imagen: Imagen) -> Dictionary:
    var turns = imagen.skill_param.get("turns", 2)
    return {"success": true, "extra_turns": turns}

## 힌트: 추천 수 1턴 표시
static func _skill_hint(grid: PuzzleGrid) -> Dictionary:
    # 행 완성에 가장 가까운 수를 추천
    # TODO: 휴리스틱 기반 추천 알고리즘
    return {"success": false, "reason": "not_implemented"}

## 범위 효과: 지정 영역 단일 색
static func _skill_area_fill(grid: PuzzleGrid, params: Dictionary) -> Dictionary:
    var center_x = params.get("x", 0)
    var center_y = params.get("y", 0)
    var range_val = params.get("range", 1)
    var color = params.get("color", 0)
    var changed = []
    for dx in range(-range_val, range_val + 1):
        for dy in range(-range_val, range_val + 1):
            var nx = center_x + dx
            var ny = center_y + dy
            if grid.is_valid(nx, ny) and grid.is_active(nx, ny):
                var cell = grid.get_cell(nx, ny)
                cell.color = color
                changed.append(cell)
    return {"success": true, "changed_cells": changed}

## 행 즉시 파괴
static func _skill_row_clear(grid: PuzzleGrid, params: Dictionary) -> Dictionary:
    var row = params.get("row", 0)
    var destroyed = []
    var row_cells = grid.get_main_row(row)
    for cell in row_cells:
        if cell.active:
            destroyed.append(cell)
            grid.clear_cell(cell.x, cell.y)
    return {"success": true, "destroyed_cells": destroyed}
```

---

## 8. Economy & Score

### 8.1 Score Calculation

```gdscript
# data/economy.gd
class_name Economy

const BASE_SCORE_PER_BLOCK = 10
const COMBO_MULTIPLIER = 1.5          # 콤보당 배율 증가
const LARGE_DESTROY_THRESHOLD = 10    # 대량 파괴 기준
const LARGE_DESTROY_BONUS = 2.0       # 대량 파괴 보너스 배율
const BONUS_TIME_PER_BLOCK = 0.5      # 블록당 보너스 시간 (초) — 무한 모드
const BONUS_TIME_THRESHOLD = 7        # 보너스 시간 발동 최소 파괴 수

static var currency: int = 0

## 파괴 점수 계산 (파괴 블록 수 + 콤보 보너스)
static func calculate_destruction_score(destroyed_count: int, combo: int) -> int:
    var base = destroyed_count * BASE_SCORE_PER_BLOCK
    # 콤보 보너스
    var combo_mult = 1.0 + (combo - 1) * (COMBO_MULTIPLIER - 1.0)
    # 대량 파괴 보너스
    if destroyed_count >= LARGE_DESTROY_THRESHOLD:
        combo_mult *= LARGE_DESTROY_BONUS
    return int(base * combo_mult)

## 무한 모드: 대량 파괴 시 보너스 시간 계산
static func calculate_bonus_time(destroyed_count: int) -> float:
    if destroyed_count >= BONUS_TIME_THRESHOLD:
        return (destroyed_count - BONUS_TIME_THRESHOLD + 1) * BONUS_TIME_PER_BLOCK
    return 0.0

static func score_to_currency(total_score: int) -> int:
    return total_score / 10  # 점수 10당 재화 1

static func add_currency(amount: int) -> void:
    currency += amount

static func spend_currency(amount: int) -> bool:
    if currency >= amount:
        currency -= amount
        return true
    return false

static func get_currency() -> int:
    return currency
```

---

## 9. Error Handling

| 상황 | 처리 |
|------|------|
| 비활성 칸 터치 | 무시 (아무 동작 없음) |
| 버퍼 영역 터치 | 무시 (메인 영역만 터치 가능) |
| 쿨타임 중 스킬 사용 | 버튼 비활성 + 쿨타임 표시 |
| 연쇄 콤보 MAX_CHAIN 도달 | 강제 중단 + 경고 로그 |
| JSON 파싱 오류 | 기본 레벨로 폴백 + 에러 로그 |
| 세이브 파일 손상 | 백업에서 복구 또는 초기화 (확인 팝업) |

---

## 10. Implementation Order

### Phase 1: Core Prototype (MVP) -- 우선 구현 대상

```
1-1. Cell 데이터 구조 (cell.gd)
 │
 ├─► 1-2. Grid 데이터 모델 (grid.gd) [7x7 + 7행 버퍼]
 │     │
 │     ├─► 1-3. ColorQueue (color_queue.gd) [스트라이드 + 랜덤 오프셋]
 │     │
 │     ├─► 1-4. GridView + BufferView 렌더링
 │     │
 │     └─► 1-5. FloodFill BFS (flood_fill.gd)
 │           │
 │           └─► 1-6. 리컬러 로직
 │                 │
 │                 └─► 1-7. RowDestroy (row_destroy.gd) [라인(행/열) 완성 → 파괴]
 │                       │
 │                       └─► 1-8. Gravity (gravity.gd) [중력 + 버퍼 공급]
 │                             │
 │                             └─► 1-9. ChainCombo (chain_combo.gd) [연쇄 루프]
 │
 ├─► 1-10. ColorQueue UI (큐 현재 색 + 다음 표시)
 │
 ├─► 1-11. HUD (턴/시간/점수/목표 표시)
 │
 └─► 1-12. 클리어/게임오버 판정 + 결과 화면
```

**Phase 1 완료 기준**: 7x7 그리드 + 컬러 큐(스트라이드 스케줄링)로 리컬러 → 라인(행/열) 파괴 → 중력 → 연쇄 콤보 한 판 플레이 가능

### 이후 Phase 순서

| Phase | 내용 | 의존 |
|-------|------|------|
| 2 | Game Loop (레벨 로드, 스토리/무한 모드, 점수/재화) | Phase 1 |
| 3 | Gimmicks (TBD -- 라인(행/열) 파괴 메커니즘에 맞게 재설계 후 구현) | Phase 1 |
| 4 | Story Mode Content (챕터/스테이지/별/대화) | Phase 2 |
| 4.5 | Companion Imagen (동료/스킬/편성) | Phase 4 |
| 4.6 | Collection & Player Profile (후냐 커스터마이징/이마젠 편성/플레이어 아이콘 + 닉네임/프로필) | Phase 4 |
| 5 | Tools (시뮬레이터/에디터/생성기) | Phase 2 |
| 6 | Polish (애니메이션/사운드/튜토리얼) | All |
| 7 | QA & Balancing | All |

---

## 11. Naming Convention (Godot/GDScript)

| Target | Rule | Example |
|--------|------|---------|
| 클래스 | PascalCase | `PuzzleGrid`, `FloodFill`, `GameManager`, `RowDestroy`, `ChainCombo` |
| 변수/함수 | snake_case | `turns_remaining`, `find_connected_group()`, `total_destroyed` |
| 상수 | UPPER_SNAKE_CASE | `BASE_SCORE_PER_BLOCK`, `MAX_CHAIN`, `MAIN_ROWS` |
| 시그널 | snake_case | `turn_consumed`, `clear_achieved`, `blocks_destroyed` |
| Enum | PascalCase.UPPER_SNAKE | `Imagen.SkillType.HINT`, `Imagen.SkillType.ROW_CLEAR` |
| 파일 (스크립트) | snake_case.gd | `game_manager.gd`, `flood_fill.gd`, `row_destroy.gd` |
| 파일 (씬) | snake_case.tscn | `grid_view.tscn`, `cell_view.tscn`, `buffer_view.tscn` |
| 폴더 | snake_case | `scenes/game/`, `scripts/core/` |
| JSON 키 | snake_case | `max_turns`, `destroy_goal`, `star_thresholds` |
| 프라이빗 함수 | _snake_case | `_check_state()`, `_compact_column()` |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-03 | Initial draft - Full system design | - |
| 0.2 | 2026-04-04 | 메커니즘 오버홀: 색상 통일 → 행 파괴 + 중력 + 연쇄 콤보. 하우징 제거. 솔버 제거. 기믹 TBD 전환. 컬러 큐(스트라이드 스케줄링) 추가. 무한 모드 시간 기반으로 변경. 스토리 모드 N블록 파괴 목표로 변경. | - |
| 0.3 | 2026-04-04 | v2 프로토타입(pictory-puzzle-prototype_2.html) 반영: 팔레트 → 컬러 큐(ColorQueue) 전환, 행 파괴 → 라인(행/열) 파괴로 확장 (RowDestroy에 열 완성 판정 추가), _is_row_complete → _is_line_complete 리네임, 초기 그리드 완성 라인 방지 로직(fixRow/fixCol) 노트 추가. | - |
| 0.4 | 2026-04-04 | 컬렉션 3탭 구조(후냐 커스터마이징/이마젠 편성/플레이어 아이콘)로 변경. 세이브 데이터 컬렉션 필드 업데이트. 플레이어 프로필(닉네임+아이콘) 추가: Screen Flow, Scene 목록, Entity Relationships, Phase 4.6 반영. 닉네임 입력 화면 추가. | - |
