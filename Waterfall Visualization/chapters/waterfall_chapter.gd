@abstract
class_name WaterfallChapter
extends ChapterBase
## 이 프로젝트의 챕터 베이스. 애드온이 정해 주지 않는 것을 채운다.
## 전역 상태(셰이더 글로벌·Autoload)가 없는 프로젝트라 reset_globals는
## 기본값 그대로 두고, 챕터마다 월드의 머티리얼을 되돌린 뒤 필요한 것만 끈다.

@onready var world: WaterfallWorld = $WaterfallWorld
