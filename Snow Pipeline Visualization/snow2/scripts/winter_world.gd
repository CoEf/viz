class_name WinterWorld
extends Node3D
## Snow2 씬 이식본의 얇은 API 계층. 챕터들이 개별 노드 경로를 몰라도
## 조명·눈·자국 시스템을 켜고 끄고 조절할 수 있게 한다. 씬 안의 머티리얼과
## Environment는 resource_local_to_scene이라 챕터가 마음껏 만져도 서로 안 샌다.

const DAY_PRESET := {
	"sun_energy": 1.3,
	"sun_color": Color(1.0, 0.965, 0.9),
	"sky_energy": 1.0,
	"fog_color": Color(0.74, 0.78, 0.85),
}
const NIGHT_PRESET := {
	"sun_energy": 0.35,
	"sun_color": Color(0.62, 0.72, 1.0),
	"sky_energy": 0.05,
	"fog_color": Color(0.05, 0.07, 0.12),
}
const FOG_DENSITY_MAX := 0.03
const FLAKE_DAY_BRIGHTNESS := 1.15
const FLAKE_NIGHT_BRIGHTNESS := 0.6

var _cover_materials: Array[ShaderMaterial] = []

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
@onready var camera_rig: OrbitCamera = $CameraRig
@onready var ground: MeshInstance3D = $Ground
@onready var props: Node3D = $Props
@onready var snowfall: SnowfallFollower = $Snowfall
@onready var near_flakes: GPUParticles3D = $Snowfall/NearFlakes
@onready var far_haze: GPUParticles3D = $Snowfall/FarHaze
@onready var track_maker: TrackMaker = $TrackMaker
@onready var snow_deform: SnowDeform = $SnowDeform


static func set_global_cover(value: float) -> void:
	RenderingServer.global_shader_parameter_set("snow_amount", value)


static func set_global_sparkle(value: float) -> void:
	RenderingServer.global_shader_parameter_set("sparkle_strength", value)


static func set_global_sparkle_density(value: float) -> void:
	RenderingServer.global_shader_parameter_set("sparkle_density", value)


static func reset_globals() -> void:
	set_global_cover(0.7)
	set_global_sparkle(1.0)
	set_global_sparkle_density(12.0)


func _ready() -> void:
	track_maker.moved.connect(snow_deform.stamp)


func environment() -> Environment:
	return world_environment.environment


func ground_material() -> ShaderMaterial:
	return ground.material_override as ShaderMaterial


func flake_material() -> ShaderMaterial:
	return near_flakes.material_override as ShaderMaterial


func cover_materials() -> Array[ShaderMaterial]:
	if not _cover_materials.is_empty():
		return _cover_materials
	var stack: Array[Node] = [props, track_maker]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null:
			continue
		var material := mesh_instance.material_override as ShaderMaterial
		if material != null and not _cover_materials.has(material):
			_cover_materials.append(material)
	return _cover_materials


func set_fall_ratio(value: float) -> void:
	near_flakes.amount_ratio = value
	far_haze.amount_ratio = value


func set_snowfall_enabled(enabled: bool) -> void:
	snowfall.visible = enabled


func set_track_maker_enabled(enabled: bool) -> void:
	track_maker.visible = enabled
	track_maker.set_process(enabled)


func set_ground_debug(mode: int) -> void:
	ground_material().set_shader_parameter("debug_mode", mode)


func set_cover_debug(mode: int) -> void:
	for material: ShaderMaterial in cover_materials():
		material.set_shader_parameter("debug_mode", mode)


func set_fog(value: float) -> void:
	environment().fog_density = value * FOG_DENSITY_MAX


func set_night(night: bool) -> void:
	var preset: Dictionary = NIGHT_PRESET if night else DAY_PRESET
	sun.light_energy = preset["sun_energy"] as float
	sun.light_color = preset["sun_color"] as Color
	environment().background_energy_multiplier = preset["sky_energy"] as float
	environment().fog_light_color = preset["fog_color"] as Color
	flake_material().set_shader_parameter(
			"brightness",
			FLAKE_NIGHT_BRIGHTNESS if night else FLAKE_DAY_BRIGHTNESS)
