@abstract
class_name FieldChapter
extends ChapterBase
## Flower Field 시각화 전용 챕터 베이스.

@onready var world: FieldWorld = $FieldWorld


func reset_globals() -> void:
	FieldWorld.reset_globals()
