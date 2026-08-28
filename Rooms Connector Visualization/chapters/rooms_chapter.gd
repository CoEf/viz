@abstract
class_name RoomsChapter
extends ChapterBase
## 이 프로젝트의 챕터 베이스. 애드온이 정해 주지 않는 두 가지를 채운다.
## 1) 해부 대상 씬을 자기 타입으로 선언 — 챕터가 world.* 를 타입 검사받으며 쓴다.
## 2) reset_globals 훅. 이 프로젝트는 전역 상태를 쓰지 않으므로 비어 있다.

@onready var world: DungeonGraph = $DungeonGraph
