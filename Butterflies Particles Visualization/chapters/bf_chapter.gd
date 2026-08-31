@abstract
class_name BFChapter
extends ChapterBase
## Butterflies Particles 시각화 전용 챕터 베이스.

@onready var world: BFWorld = $BFWorld


func reset_globals() -> void:
	BFWorld.reset_globals()
