class_name GimmickRegistry
extends RefCounted

## 기믹 타입 → 핸들러 매핑 레지스트리.
## 코어 로직은 이 레지스트리를 통해 훅을 호출한다.

const GimmickBaseScript = preload("res://scripts/gimmick/gimmick_base.gd")

static var _handlers: Dictionary = {}
static var _default_handler: GimmickBase = null

static func _ensure_default() -> void:
	if _default_handler == null:
		_default_handler = GimmickBaseScript.new()

static func register(type: int, handler: GimmickBase) -> void:
	_handlers[type] = handler

static func get_handler(type: int) -> GimmickBase:
	_ensure_default()
	return _handlers.get(type, _default_handler)

static func has_handler(type: int) -> bool:
	return _handlers.has(type)

static func initialize_all() -> void:
	## 모든 기믹 핸들러를 등록한다. 게임 시작 시 1회 호출.
	var locked = preload("res://scripts/gimmick/gimmick_locked.gd").new()
	var stone  = preload("res://scripts/gimmick/gimmick_stone.gd").new()
	var ice    = preload("res://scripts/gimmick/gimmick_ice.gd").new()
	var rainbow = preload("res://scripts/gimmick/gimmick_rainbow.gd").new()
	register(GimmickBase.GimmickType.LOCKED,  locked)
	register(GimmickBase.GimmickType.STONE,   stone)
	register(GimmickBase.GimmickType.ICE,     ice)
	register(GimmickBase.GimmickType.RAINBOW, rainbow)
