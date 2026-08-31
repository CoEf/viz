class_name PortalWorld
extends Node3D
## 포탈 프리뷰 이식본의 얇은 API 계층. 원본 프리뷰에는 스크립트가 아예 없다 —
## 포탈은 트리거가 필요 없는 상시 이펙트라서다. 여기서는 카메라와
## 챕터용 접근자, 그리고 비율 정합 수리(뷰포트 크기 추종)만 더한다.

var camera_rig: OrbitCamera
var camera: Camera3D

@onready var portal_a: Portal = $PortalA
@onready var portal_b: Portal = $SecondPlane/PortalB
@onready var world_environment: WorldEnvironment = $WorldEnvironment


static func reset_globals() -> void:
	pass # 이 프로젝트는 전역 셰이더 파라미터를 쓰지 않는다


func _ready() -> void:
	camera_rig = OrbitCamera.new()
	camera_rig.min_distance = 0.6
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera_rig.add_child(camera)
	add_child(camera_rig)
	frame_portal()
	# 원본은 창(16:9)과 SubViewport(1280×720)의 비율이 우연히 일치했다.
	# 워크스루의 3D 칸은 비율이 달라 SCREEN_UV 정합이 깨지므로,
	# 블로그 7장에서 제안한 수리 — 메인 뷰포트 크기 추종 — 를 적용한다.
	_sync_viewport_sizes()
	get_viewport().size_changed.connect(_sync_viewport_sizes)


func _sync_viewport_sizes() -> void:
	var size: Vector2i = get_viewport().size
	(portal_a.get_node("SubViewport") as SubViewport).size = size
	(portal_b.get_node("SubViewport") as SubViewport).size = size


func environment() -> Environment:
	return world_environment.environment


## 1번 공간 — 포탈 A 정면.
func frame_portal() -> void:
	camera_rig.position = Vector3(0.0, 1.3, 1.0)
	camera_rig.set_view(0.25, -0.12, 6.0)


## 2번 공간 — 100유닛 아래로 카메라를 옮겨 "진짜로 있다"를 보여준다.
func frame_second_plane() -> void:
	camera_rig.position = Vector3(0.0, -98.7, 1.0)
	camera_rig.set_view(0.5, -0.15, 7.0)


# --- 포탈 A 접근자 (관찰 대상은 항상 A쪽) ----------------------------------

func portal_mesh_material() -> ShaderMaterial:
	return (portal_a.get_node("PortalMesh") as MeshInstance3D).material_override


func set_portal_param(param: String, value: Variant) -> void:
	portal_mesh_material().set_shader_parameter(param, value)


func deform_material() -> ShaderMaterial:
	return (portal_a.get_node("Deform") as MeshInstance3D).material_override


func inner_edge_material() -> ShaderMaterial:
	return (portal_a.get_node("InnerEdge") as MeshInstance3D).material_override


func outer_edge_material() -> ShaderMaterial:
	return (portal_a.get_node("OuterEdge") as MeshInstance3D).material_override


func set_ring_visible(deform: bool, outer: bool, inner: bool, particles: bool) -> void:
	portal_a.get_node("Deform").visible = deform
	portal_a.get_node("OuterEdge").visible = outer
	portal_a.get_node("InnerEdge").visible = inner
	portal_a.get_node("GPUParticles3D").visible = particles


func set_spotlight_enabled(value: bool) -> void:
	(portal_a.get_node("SpotLight3D") as SpotLight3D).visible = value


func set_flip(value: bool) -> void:
	portal_a.flip = value
	portal_b.flip = value


func set_copy_projection(value: bool) -> void:
	portal_a.copy_projection = value
	portal_b.copy_projection = value


func set_main_camera_fov(value: float) -> void:
	camera.fov = value


## B쪽 서브뷰포트 갱신을 끄면 A 포탈 안 그림이 얼어붙는다 — 비용 체감용.
func set_b_viewport_updating(value: bool) -> void:
	var viewport := portal_b.get_node("SubViewport") as SubViewport
	viewport.render_target_update_mode = (
			SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_DISABLED)
