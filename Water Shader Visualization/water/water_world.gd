class_name WaterWorld
extends Node3D
## 해부 대상 씬의 얇은 API 계층. 챕터가 셰이더 유니폼 이름을 일일이 몰라도
## 레이어를 끄고 켤 수 있게 한다.
##
## 이 셰이더는 레이어마다 세기 유니폼이 이미 있어서, 대부분의 레이어는
## 값을 0으로 만드는 것만으로 꺼진다. 원본을 건드리지 않고 분해할 수 있는
## 이유다. 중간 계산값을 색으로 꺼내 보는 debug_view만 이식본에 추가했다.

## 켜진 상태의 기본값. 레이어를 되돌릴 때 이 값으로 복구한다.
const DEFAULTS := {
	"wave_amplitude": 0.85,
	"detail_strength": 1.1,
	"refraction_strength": 0.6,
	"scatter_k": 0.13,
	"foam_crest_gain": 1.25,
	"foam_edge_distance": 1.6,
	"foam_shore_depth": 0.8,
	"fresnel_f0": 0.02,
	"alpha_k": 1.6,
}
const ABSORPTION_ON := Vector3(0.38, 0.065, 0.028)

## 같은 본문(wt_surface_body)을 include하고 #define 조합만 다른 프리셋들.
const SHADER_REALISTIC := preload("res://water/water_surface.gdshader")
const SHADER_TOON := preload("res://water/water_toon.gdshader")

@onready var camera_rig: OrbitCamera = $CameraRig
@onready var water: MeshInstance3D = $Water
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var props: Node3D = $Props


func material() -> ShaderMaterial:
	return water.material_override as ShaderMaterial


func set_param(name: StringName, value: Variant) -> void:
	material().set_shader_parameter(name, value)


func get_param(name: StringName) -> Variant:
	return material().get_shader_parameter(name)


func set_debug_view(mode: int) -> void:
	set_param(&"debug_view", mode)


## 모든 레이어를 기본값으로 되돌린다. 스텝은 여기서 시작해 필요한 것만 끈다.
func reset_layers() -> void:
	for key: String in DEFAULTS:
		set_param(key, DEFAULTS[key])
	set_param(&"absorption", ABSORPTION_ON)
	set_debug_view(0)


func set_waves(on: bool) -> void:
	set_param(&"wave_amplitude", DEFAULTS["wave_amplitude"] if on else 0.0)


func set_detail(on: bool) -> void:
	set_param(&"detail_strength", DEFAULTS["detail_strength"] if on else 0.0)


func set_refraction(on: bool) -> void:
	set_param(&"refraction_strength", DEFAULTS["refraction_strength"] if on else 0.0)


## 흡수를 끄면 물이 뒤 화면을 그대로 통과시켜 유리처럼 보인다.
func set_volume(on: bool) -> void:
	set_param(&"absorption", ABSORPTION_ON if on else Vector3.ZERO)
	set_param(&"scatter_k", DEFAULTS["scatter_k"] if on else 0.0)


func set_foam(on: bool) -> void:
	set_param(&"foam_crest_gain", DEFAULTS["foam_crest_gain"] if on else 0.0)
	set_param(&"foam_edge_distance", DEFAULTS["foam_edge_distance"] if on else 0.05)
	set_param(&"foam_shore_depth", DEFAULTS["foam_shore_depth"] if on else 0.05)


func set_fresnel(on: bool) -> void:
	set_param(&"fresnel_f0", DEFAULTS["fresnel_f0"] if on else 0.0)


## 셰이더를 통째로 갈아 끼운다. 본문은 같고 켜진 모듈만 다르다.
## 텍스처 유니폼은 교체 과정에서 날아가므로 직접 되돌려 준다.
func set_toon(toon: bool) -> void:
	var target := SHADER_TOON if toon else SHADER_REALISTIC
	if material().shader == target:
		return
	var normal_map: Variant = get_param(&"normal_map")
	var foam_noise: Variant = get_param(&"foam_noise")
	material().shader = target
	set_param(&"normal_map", normal_map)
	set_param(&"foam_noise", foam_noise)
