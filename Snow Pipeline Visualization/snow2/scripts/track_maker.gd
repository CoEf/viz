class_name TrackMaker
extends Node3D
## Wanders the snowfield on a Lissajous path, reporting stamp positions
## upward via a signal so the parent can route them to the deformation map.

signal moved(world_position: Vector3)

@export var roam_extent := Vector2(13.0, 10.5)
@export var speed := 0.28
@export var stamp_spacing := 0.3

var _time := randf() * TAU
var _last_stamp := Vector3(INF, 0.0, 0.0)


func _process(delta: float) -> void:
	_time += delta * speed
	# 1.618 keeps the two axes incommensurate so the path never repeats.
	var x := sin(_time) * roam_extent.x
	var z := sin(_time * 1.618 + 1.3) * roam_extent.y
	position = Vector3(x, position.y, z)
	if _last_stamp.distance_to(global_position) >= stamp_spacing:
		_last_stamp = global_position
		moved.emit(global_position)
