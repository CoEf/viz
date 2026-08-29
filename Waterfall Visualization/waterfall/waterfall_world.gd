class_name WaterfallWorld
extends Node3D
## 해부 대상 씬의 얇은 API 계층. 챕터가 유니폼 이름과 노드 경로를 일일이
## 몰라도 레이어를 끄고 켤 수 있게 한다.
##
## 원본 waterfall_scene.tscn은 glb 자식들에 머티리얼을 덮어씌우는 씬이다.
## 여기서는 같은 값을 코드로 조립한다 — 월드 인스턴스마다 머티리얼이 새로
## 생기므로, 챕터 A의 슬라이더가 챕터 B를 바꿔 놓는 공유 리소스 사고가 없다.

const SHADER := preload("res://waterfall/displacement_n_uvscroll.gdshader")
const TEX_FALL := preload("res://waterfall/assets/waterfall_texture.png")
const TEX_FALL_INV := preload("res://waterfall/assets/waterfall_texture_inv.png")
const TEX_STONE := preload("res://waterfall/assets/stone2.png")

## 원본 waterfall_scene.tscn의 폭포 ShaderMaterial 값 그대로.
const FALL_PARAMS := {
	&"uv_dis_scale": Vector2(2, 2),
	&"dis_scroll": Vector2(0, -1.5),
	&"displace_parameter": 0.05,
	&"uv_scale": Vector2(1, 1.5),
	&"scroll": Vector2(0.5, -2),
	&"uv_scale2": Vector2(1, 1.5),
	&"scroll2": Vector2(-0.5, -2),
	&"overlay_alpha": 1.0,
	&"normal_depth": 0.5,
}
## 원본의 웅덩이 ShaderMaterial 값 그대로. 셰이더는 폭포와 같고 값만 다르다.
const PUDDLE_PARAMS := {
	&"uv_dis_scale": Vector2(1, 1),
	&"dis_scroll": Vector2(0, 0.5),
	&"displace_parameter": 0.05,
	&"uv_scale": Vector2(2, 4),
	&"scroll": Vector2(0.5, -0.5),
	&"uv_scale2": Vector2(2, 4),
	&"scroll2": Vector2(-0.25, -0.5),
	&"overlay_alpha": 0.5,
	&"normal_depth": 0.25,
}

@onready var camera_rig: OrbitCamera = $CameraRig
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
@onready var stone: MeshInstance3D = $WaterfallScene/stone1
@onready var fall: MeshInstance3D = $WaterfallScene/waterfall
@onready var puddle: MeshInstance3D = $WaterfallScene/waterpuddle
@onready var mist: GPUParticles3D = $Effects/Mist
@onready var foam: GPUParticles3D = $Effects/Foam

var stone_material := StandardMaterial3D.new()
var fall_material := ShaderMaterial.new()
var puddle_material := ShaderMaterial.new()
## 챕터가 사이드 패널에 원본을 띄워 볼 수 있게 잡아 둔다.
var fall_base_texture: GradientTexture2D
var puddle_base_texture: GradientTexture2D


func _ready() -> void:
	stone_material.albedo_texture = TEX_STONE
	stone_material.metallic = 0.5
	stone_material.roughness = 0.75
	stone.material_override = stone_material

	fall_base_texture = _make_gradient(
			PackedFloat32Array([0.0, 0.54918, 1.0]),
			PackedColorArray([
				Color(1, 1, 1),
				Color(0.06, 0.796333, 1),
				Color(0.06, 0.357667, 1),
			]),
			Vector2(0, 0))
	fall_material.shader = SHADER
	fall_material.set_shader_parameter(&"displacement_tut", TEX_FALL)
	fall_material.set_shader_parameter(&"base_color_texture", fall_base_texture)
	fall_material.set_shader_parameter(&"water_texture", TEX_FALL)
	fall_material.set_shader_parameter(&"water_texture2", TEX_FALL)
	fall.material_override = fall_material

	puddle_base_texture = _make_gradient(
			PackedFloat32Array([0.0, 0.360656, 0.737705, 1.0]),
			PackedColorArray([
				Color(0.06, 0.686666, 1),
				Color(0.03, 0.1755, 1),
				Color(0, 0.666667, 1),
				Color(1, 1, 1),
			]),
			Vector2(0, 0.11828))
	puddle_material.shader = SHADER
	puddle_material.set_shader_parameter(&"displacement_tut", TEX_FALL)
	puddle_material.set_shader_parameter(&"base_color_texture", puddle_base_texture)
	puddle_material.set_shader_parameter(&"water_texture", TEX_FALL_INV)
	puddle_material.set_shader_parameter(&"water_texture2", TEX_FALL_INV)
	puddle.material_override = puddle_material

	reset_materials()


## 아래(1) → 위(fill_to.y) 세로 그라데이션. 원본 씬의 GradientTexture2D 값 그대로.
func _make_gradient(
		offsets: PackedFloat32Array,
		colors: PackedColorArray,
		fill_to: Vector2) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = offsets
	gradient.colors = colors
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 1)
	texture.fill_to = fill_to
	return texture


## 두 머티리얼을 원본 값으로 되돌린다. 스텝은 여기서 시작해 필요한 것만 끈다.
func reset_materials() -> void:
	for key: StringName in FALL_PARAMS:
		fall_material.set_shader_parameter(key, FALL_PARAMS[key])
	for key: StringName in PUDDLE_PARAMS:
		puddle_material.set_shader_parameter(key, PUDDLE_PARAMS[key])
	fall_material.set_shader_parameter(&"debug_view", 0)
	puddle_material.set_shader_parameter(&"debug_view", 0)


func set_fall_param(key: StringName, value: Variant) -> void:
	fall_material.set_shader_parameter(key, value)


func set_puddle_param(key: StringName, value: Variant) -> void:
	puddle_material.set_shader_parameter(key, value)


## 폭포 머티리얼의 중간값 보기. 0 정상 · 1 물결1 · 2 물결2 · 3 곱 · 4 베이스 · 5 변위.
func set_debug(mode: int) -> void:
	fall_material.set_shader_parameter(&"debug_view", mode)


func show_water(fall_on: bool, puddle_on: bool) -> void:
	fall.visible = fall_on
	puddle.visible = puddle_on


func set_sky(on: bool) -> void:
	world_environment.environment.background_mode = (
			Environment.BG_SKY if on else Environment.BG_COLOR)


func set_sky_fov(degrees: float) -> void:
	world_environment.environment.sky_custom_fov = degrees


func set_effects(mist_on: bool, foam_on: bool) -> void:
	mist.visible = mist_on
	mist.emitting = mist_on
	foam.visible = foam_on
	foam.emitting = foam_on


## 웅덩이에 폭포의 유니폼 값을 통째로 꽂아 본다. 텍스처는 그대로 둔다 —
## 값이 물의 성격을 정한다는 것을 보이는 챕터 6의 토글용.
func swap_puddle_params(to_fall: bool) -> void:
	var source: Dictionary = FALL_PARAMS if to_fall else PUDDLE_PARAMS
	for key: StringName in source:
		puddle_material.set_shader_parameter(key, source[key])


## 물보라 튀는 속도 배율. 원본 값 2.0~3.0에 배율을 곱한다.
func set_mist_speed(factor: float) -> void:
	var material := mist.process_material as ParticleProcessMaterial
	material.initial_velocity_min = 2.0 * factor
	material.initial_velocity_max = 3.0 * factor


## 스텝마다 시점을 통째로 지정한다 — 궤도 중심(target)까지 함께.
func frame(target: Vector3, yaw: float, pitch: float, distance: float) -> void:
	camera_rig.position = target
	camera_rig.set_view(yaw, pitch, distance)
