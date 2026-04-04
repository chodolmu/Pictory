extends Control

## 챕터 타이틀 카드를 표시하고 완료 시 pre 다이얼로그로 전환.

@onready var _title_card: ChapterTitle = $ChapterTitle

func _ready() -> void:
	var params = SceneManager.get_params()
	var chapter = params.get("chapter", 1)
	var stage = params.get("stage", 1)
	_title_card.title_finished.connect(_on_title_finished)
	_title_card.show_title(chapter)

func _on_title_finished() -> void:
	StoryFlowController.on_chapter_title_finished()
