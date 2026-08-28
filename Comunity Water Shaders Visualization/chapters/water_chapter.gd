@abstract
class_name WaterChapter
extends ChapterBase
## 이 프로젝트의 챕터 베이스.
##
## 10번이 읽는 player_position은 전역 셰이더 파라미터라 씬 밖에 산다. 챕터를
## 넘길 때 되돌려 두지 않으면, 앞 챕터에서 프로브가 서 있던 자리가 다음 챕터의
## 첫 프레임에 그대로 남는다.

@onready var world: WaterStage = $WaterStage


func reset_globals() -> void:
	RenderingServer.global_shader_parameter_set(&"player_position", Vector3.ZERO)
