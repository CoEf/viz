@abstract
class_name PortalChapter
extends ChapterBase
## Portal 시각화 전용 챕터 베이스.

@onready var world: PortalWorld = $PortalWorld


func reset_globals() -> void:
	PortalWorld.reset_globals()
