class_name SnowfallFollower
extends Node3D
## Keeps the snowfall emitters above the active camera. Particles simulate
## in world space, so moving the emitter never disturbs flakes already falling.

@export var height_offset := 6.0


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var pos := camera.global_position
	global_position = Vector3(pos.x, pos.y + height_offset, pos.z)
