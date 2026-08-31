@abstract
class_name FireballChapter
extends ChapterBase
## Fireball 시각화 전용 챕터 베이스. 해부 대상 씬을 자기 타입으로 선언해
## 챕터들이 world.* 를 타입 검사받으며 쓰게 한다.

@onready var world: FireballWorld = $FireballWorld


func reset_globals() -> void:
	FireballWorld.reset_globals()
