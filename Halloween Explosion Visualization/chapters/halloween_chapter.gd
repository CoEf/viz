@abstract
class_name HalloweenChapter
extends ChapterBase
## Halloween 폭발 시각화 전용 챕터 베이스. 해부 대상 씬을 자기 타입으로
## 선언해 챕터들이 world.* 를 타입 검사받으며 쓰게 한다.

@onready var world: HalloweenWorld = $HalloweenWorld


func reset_globals() -> void:
	HalloweenWorld.reset_globals()
