@abstract
class_name FurChapter
extends ChapterBase
## Fur 시각화 전용 챕터 베이스.

@onready var world: FurWorld = $FurWorld


func reset_globals() -> void:
	FurWorld.reset_globals()
