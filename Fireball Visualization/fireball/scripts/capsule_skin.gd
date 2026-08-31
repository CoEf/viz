extends Node3D
## 이식본: assets/dummy/dummy_skin.gd 의 캡슐용 축약판.
## 리그 모델 대신 캡슐 메시에 같은 emission_blend 브릿지를 단다 — Tween이
## 셰이더 uniform을 직접 못 만지므로 프로퍼티 setter로 감싸는 원본 패턴 그대로.

@onready var skin_mat : ShaderMaterial = $Mesh.material_override

var emission_blend : float = 0.0 : set = _set_emission_blend

func _set_emission_blend(value : float = 0.0):
	emission_blend = clamp(value, 0.0, 1.0)
	if skin_mat:
		skin_mat.set_shader_parameter("emission_blend", emission_blend)
