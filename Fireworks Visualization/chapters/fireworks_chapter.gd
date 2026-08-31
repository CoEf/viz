@abstract
class_name FireworksChapter
extends ChapterBase
## Fireworks 시각화 전용 챕터 베이스.

@onready var world: FireworksWorld = $FireworksWorld


func reset_globals() -> void:
	FireworksWorld.reset_globals()
