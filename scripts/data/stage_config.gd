class_name StageConfig
extends RefCounted

## 레벨 JSON에서 파싱된 스테이지 설정 데이터.

var stage_id: String = ""
var chapter: int = 1
var stage_number: int = 1
var grid_size: int = 7
var num_colors: int = 5
var turn_limit: int = 30
var goal_type: String = "destroy_blocks"
var goal_target_count: int = 100
var color_queue_stride: int = 3
var color_queue_random_offset: int = 1
var gimmick_placements: Array = []
var buffer_rows: int = 7
var metadata: Dictionary = {}
