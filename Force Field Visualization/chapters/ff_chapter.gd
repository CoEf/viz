@abstract
class_name FFChapter
extends ChapterBase
## Force Field 시각화 전용 챕터 베이스.

@onready var world: FFWorld = $FFWorld


func reset_globals() -> void:
	FFWorld.reset_globals()
