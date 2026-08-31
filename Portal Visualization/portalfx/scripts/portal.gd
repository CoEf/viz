class_name Portal
extends Area3D
## 이식본: effects/portal/portal/portal.gd
## 원본과의 차이 (시각화용):
##  - world_camera를 매 프레임 재확인 — 워크스루는 카메라를 코드에서 늦게 만든다.
##  - flip: scaled_local(-1,1,-1) 뒤집기를 꺼서 왜 필요한지 비교하는 토글.
##  - copy_projection: 블로그에서 지적한 "투영 파라미터도 복사" 수리를 토글로.

@onready var local_camera = %Camera3D
@export var other_portal : Portal

@export var flip := true
@export var copy_projection := false

var world_camera : Camera3D

func _process(_delta):
	if world_camera == null or not is_instance_valid(world_camera):
		world_camera = get_viewport().get_camera_3d()
		if world_camera == null:
			return
	if copy_projection:
		local_camera.fov = world_camera.fov
		local_camera.near = world_camera.near
		local_camera.far = world_camera.far
		local_camera.keep_aspect = world_camera.keep_aspect
	local_camera.global_transform = get_other_side_transform(world_camera.global_transform)

func get_other_side_transform(base_origin : Transform3D) -> Transform3D:
	var flip_scale := Vector3(-1.0, 1.0, -1.0) if flip else Vector3(1.0, 1.0, 1.0)
	var relative_transform = other_portal.global_transform.scaled_local(flip_scale) * global_transform.inverse()
	return relative_transform * base_origin
