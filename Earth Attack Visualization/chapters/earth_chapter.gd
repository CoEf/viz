@abstract
class_name EarthChapter
extends ChapterBase
## Earth Attack 시각화 전용 챕터 베이스.

@onready var world: EarthWorld = $EarthWorld


func reset_globals() -> void:
	EarthWorld.reset_globals()
