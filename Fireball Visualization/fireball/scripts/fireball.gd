extends Node3D
## 이식본: effects/fireball/fireball_core/fireball.gd (무수정)

@onready var fireball_shell_mesh = %FireballShellMesh
@onready var fire_trail = %FireTrail
@onready var fire_smoke = %FireSmoke

signal is_out

var angular_vel : Vector3 = Vector3(0.0, 0.0, 0.0)
var last_direction : Vector3

func _process(_delta):
	var direction = global_transform.basis.y
	angular_vel = angular_vel.move_toward((direction - last_direction), 0.1 * _delta)
	last_direction = direction

	fireball_shell_mesh.material_override.set_shader_parameter("def_x", -angular_vel.x * 4.0)
	fireball_shell_mesh.material_override.set_shader_parameter("def_z", angular_vel.z * 4.0)


func out():
	fireball_shell_mesh.hide()
	fire_trail.emitting = false
	fire_smoke.emitting = false
	await get_tree().create_timer(4.0).timeout
	is_out.emit()
