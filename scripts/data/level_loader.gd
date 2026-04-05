extends Node
## LevelLoader — Autoload 싱글턴.
## JSON 레벨 파일을 읽어 StageConfig 오브젝트로 변환한다.

const StageConfigScript = preload("res://scripts/data/stage_config.gd")

## type 문자열 → GimmickType 매핑
const GIMMICK_TYPE_MAP: Dictionary = {
	"locked":       1,
	"stone":        2,
	"ice":          3,
	"rainbow":      4,
	"anchor":       5,
	"paint_bucket": 6,
	"coin":         7,
	"chain_mult":   8,
	"star":         10,
	"spread":       11,
	"fade":         12,
	"time":         20,
	"poison":       21,
}

const REQUIRED_FIELDS: Array[String] = [
	"stage_id", "grid_size", "num_colors", "turn_limit", "goal", "star_thresholds"
]

# ─────────────────────────────────────────
# 공개 API
# ─────────────────────────────────────────

func load_stage(stage_id: String):
	## stage_id 형식: "ch01_s01"
	var parts = stage_id.split("_")
	if parts.size() < 2:
		push_error("LevelLoader: invalid stage_id format: " + stage_id)
		return null

	var chapter_str = parts[0].trim_prefix("ch")
	var stage_str = parts[1].trim_prefix("s")

	if not chapter_str.is_valid_int() or not stage_str.is_valid_int():
		push_error("LevelLoader: cannot parse chapter/stage from: " + stage_id)
		return null

	var chapter = chapter_str.to_int()
	var stage_num = stage_str.to_int()
	var path = "res://resources/levels/story/chapter_%02d/stage_%02d.json" % [chapter, stage_num]

	return _load_from_path(path)

func apply_gimmicks_to_grid(config, grid: Grid) -> void:
	## StageConfig의 gimmick_placements를 Grid의 셀에 적용한다.
	for placement in config.gimmick_placements:
		var x = placement.get("x", -1)
		var y = placement.get("y", -1)
		var type_str = placement.get("type", "")
		var durability = placement.get("durability", 0)
		var data = placement.get("data", {})

		if not GIMMICK_TYPE_MAP.has(type_str):
			push_warning("LevelLoader: unknown gimmick type: " + type_str)
			continue

		if not grid.is_valid_coord(x, y):
			push_warning("LevelLoader: gimmick coord out of bounds: (%d,%d)" % [x, y])
			continue

		var gimmick_type = GIMMICK_TYPE_MAP[type_str]
		var cell = grid.get_cell(x, y)
		if cell:
			cell.set_gimmick(gimmick_type, durability, data)
			# 돌 칸은 색상 강제 -1
			if type_str == "stone":
				cell.color = -1

func load_chapter_stages(chapter: int):
	var result: Array = []
	for i in range(1, 11):  # 스테이지는 1~10 고정
		var path = "res://resources/levels/story/chapter_%02d/stage_%02d.json" % [chapter, i]
		var config = _load_from_path(path)
		if config != null:
			result.append(config)

	result.sort_custom(func(a, b): return a.stage_number < b.stage_number)
	return result

# ─────────────────────────────────────────
# 내부 파싱
# ─────────────────────────────────────────

func _load_from_path(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		# Export 빌드에서 res:// 파일이 .pck 내부에 있으므로 file_exists 대신 open으로 확인
		return null

	var text = file.get_as_text()
	file.close()

	var json = JSON.parse_string(text)
	if json == null:
		push_error("LevelLoader: JSON parse failed: " + path)
		return null

	if not _validate_required_fields(json):
		return null

	return _parse_json(json)

func _validate_required_fields(json_data: Dictionary) -> bool:
	for field in REQUIRED_FIELDS:
		if not json_data.has(field):
			push_error("LevelLoader: missing required field: " + field)
			return false
	return true

func _parse_json(json_data: Dictionary):
	var config = StageConfigScript.new()

	config.stage_id = json_data.get("stage_id", "")
	config.chapter = json_data.get("chapter", 1)
	config.stage_number = json_data.get("stage_number", 1)
	config.grid_size = json_data.get("grid_size", 7)
	config.num_colors = json_data.get("num_colors", 5)
	config.turn_limit = json_data.get("turn_limit", 30)

	var goal = json_data.get("goal", {})
	config.goal_type = goal.get("type", "destroy_blocks")
	config.goal_target_count = goal.get("target_count", 100)

	var raw_thresholds = json_data.get("star_thresholds", [3, 6, 10])
	config.star_thresholds.clear()
	for v in raw_thresholds:
		config.star_thresholds.append(int(v))

	var cq = json_data.get("color_queue_config", {})
	config.color_queue_stride = cq.get("stride", 3)
	config.color_queue_random_offset = cq.get("random_offset", 1)

	var gimmicks = json_data.get("gimmick_placements", [])
	config.gimmick_placements.clear()
	for g in gimmicks:
		config.gimmick_placements.append(g)

	config.buffer_rows = json_data.get("buffer_rows", config.grid_size)
	config.metadata = json_data.get("metadata", {})

	return config
