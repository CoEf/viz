@abstract
class_name WaterChapter
extends ChapterBase
## 이 프로젝트의 챕터 베이스. 애드온이 정해 주지 않는 것을 채운다.
## 이 프로젝트는 전역 상태를 쓰지 않으므로 reset_globals는 비어 있고,
## 대신 챕터마다 레이어를 기본값으로 되돌린 뒤 필요한 것만 끈다.

@onready var world: WaterWorld = $WaterWorld
