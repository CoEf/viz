@abstract
class_name WaterChapter
extends ChapterBase
## Water Hand 시각화 전용 챕터 베이스.

@onready var world: WaterWorld = $WaterWorld


func reset_globals() -> void:
	WaterWorld.reset_globals()
