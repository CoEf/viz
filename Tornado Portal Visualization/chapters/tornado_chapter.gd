@abstract
class_name TornadoChapter
extends ChapterBase
## Tornado Portal 시각화 전용 챕터 베이스.

@onready var world: TornadoWorld = $TornadoWorld


func reset_globals() -> void:
	TornadoWorld.reset_globals()
