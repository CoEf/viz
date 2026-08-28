@abstract
class_name SnowChapter
extends ChapterBase
## Snow2 시각화 전용 챕터 베이스. 애드온이 정해 주지 않는 두 가지를 여기서 채운다.
## 1) 해부 대상 씬을 자기 타입으로 선언 — 챕터들이 world.* 를 타입 검사받으며 쓴다.
## 2) reset_globals 훅에 이 프로젝트의 전역 셰이더 파라미터 초기화를 문다.
## 새 프로젝트는 이 파일만 갈아끼우면 된다.

@onready var world: WinterWorld = $WinterWorld


func reset_globals() -> void:
	WinterWorld.reset_globals()
