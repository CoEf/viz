@tool
extends Node3D
## Keeps shader 07's dithered distance fade visible at any camera distance.
##
## `fadeout_envelope` is an absolute pair of world distances. In its original setting - a
## camera walking a clipmap terrain - it never moves, because the camera never leaves the
## grass. In a gallery you look at the same patch from three metres and from sixty, and a
## fixed envelope means the patch is either fully solid or entirely dithered away, i.e. the
## shader's headline feature is invisible exactly when you are trying to compare it.
##
## So the envelope is re-centred on the patch each frame. The fade you see is the real
## shader doing its real work; only the window has been slid to where you are standing.

@export var target_material: ShaderMaterial
## Where the solid band ends, relative to the patch centre. Negative = in front of it.
@export var near_offset: float = -2.0
## How far past that the dither reaches zero. Both are offsets from the CENTRE of the
## patch, not fractions of the distance: the patch is 13 units deep whether you are
## standing in it or looking at it from sixty metres, so a fixed band tracks it at
## every distance while a proportional one collapses up close and overshoots far away.
@export var span: float = 9.0


func _process(_delta: float) -> void:
	if target_material == null:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var distance: float = camera.global_position.distance_to(global_position)
	target_material.set_shader_parameter(
			"fadeout_envelope", Vector2(distance + near_offset, distance + near_offset + span))
