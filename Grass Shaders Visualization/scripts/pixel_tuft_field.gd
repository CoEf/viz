@tool
class_name PixelTuftField
extends Node3D
## Scatters individual MeshInstance3D tufts - deliberately NOT a MultiMesh.
##
## Shader 09 de-synchronises its sway with NODE_POSITION_WORLD, which is a property of the
## *node*, not of the instance. Put it on a MultiMesh and every blade in the patch shares
## one node position, so the whole field sways as a single rigid block. This script exists
## to make that constraint visible rather than hide it: it is the honest way to run that
## shader, and the reason its blade count is two orders of magnitude below its neighbours.

@export var tuft_material: Material
@export var tuft_mesh: Mesh
@export var count: int = 300
@export var area: Vector2 = Vector2(11.0, 11.0)
@export var scale_min: float = 0.9
@export var scale_max: float = 1.6
@export var rng_seed: int = 4242


func _ready() -> void:
	_build()


func _build() -> void:
	for child: Node in get_children():
		child.queue_free()
	if tuft_mesh == null:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for i: int in count:
		var tuft := MeshInstance3D.new()
		tuft.mesh = tuft_mesh
		tuft.material_override = tuft_material
		tuft.position = Vector3(
				rng.randf_range(-area.x, area.x) * 0.5,
				0.0,
				rng.randf_range(-area.y, area.y) * 0.5)
		tuft.rotation.y = rng.randf_range(0.0, TAU)
		tuft.scale = Vector3.ONE * rng.randf_range(scale_min, scale_max)
		tuft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tuft)


func get_blade_count() -> int:
	return get_child_count()
