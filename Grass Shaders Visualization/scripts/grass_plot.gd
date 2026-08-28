@tool
class_name GrassPlot
extends Node3D
## Scatters one grass material over a square patch with a MultiMesh.
##
## Every demo that is "a shader on scattered cards" uses this, so the ten shaders are
## compared on identical geometry, identical density and an identical random layout - the
## only thing that differs between plots is the shader itself.
##
## The scatter is seeded, so two plots with the same seed put blades in the same places.
## That is deliberate: it makes an A/B render of two shaders line up blade for blade.

@export_group("Scatter")
@export var grass_material: Material
@export var grass_mesh: Mesh
@export var instance_count: int = 3000
@export var area: Vector2 = Vector2(11.0, 11.0)
@export var scale_min: float = 0.75
@export var scale_max: float = 1.25
@export var random_yaw: bool = true
@export var rng_seed: int = 20260826
## Splits the scatter across N MultiMeshInstance3D nodes, each carrying a different
## `variant_index` instance uniform. Shader 02 needs this: `instance uniform` is per
## *node*, not per multimesh instance, so four blade shapes means four nodes.
@export var variant_count: int = 1
@export var cast_shadow: bool = true

@export_group("Uniform plumbing")
## Instance uniform on each MultiMeshInstance3D that wants the walker's position (06).
@export var player_instance_uniform: String = ""
## Shader uniform on the shared material that wants the walker's position (04).
@export var player_material_uniform: String = ""
## Shaders 02 samples world-space colour maps. Anchoring the lookup on the plot's own
## origin keeps the patch inside the map's 0..1 range wherever the plot sits in the grid.
@export var world_position_uniform: String = ""
@export var world_size_uniform: String = "world_size"

var _instances: Array[MultiMeshInstance3D] = []


func _ready() -> void:
	_build()


func _build() -> void:
	for child: Node in get_children():
		if child is MultiMeshInstance3D:
			child.queue_free()
	_instances.clear()

	if grass_mesh == null:
		push_warning("GrassPlot %s: no mesh assigned" % name)
		return

	var groups: int = maxi(variant_count, 1)
	var per_group: int = instance_count / groups
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed

	# A single AABB covering the patch plus headroom. Without it Godot derives the bounds
	# from the untouched instance transforms, and every shader here moves vertices outside
	# them - the patch then pops out of view when its centre leaves the frustum.
	var bounds := AABB(
			Vector3(-area.x * 0.5 - 2.0, -1.0, -area.y * 0.5 - 2.0),
			Vector3(area.x + 4.0, 6.0, area.y + 4.0))

	for group: int in groups:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = grass_mesh
		multimesh.instance_count = per_group

		for i: int in per_group:
			var pos := Vector3(
					rng.randf_range(-area.x, area.x) * 0.5,
					0.0,
					rng.randf_range(-area.y, area.y) * 0.5)
			var basis := Basis.IDENTITY
			if random_yaw:
				basis = basis.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
			basis = basis.scaled(Vector3.ONE * rng.randf_range(scale_min, scale_max))
			multimesh.set_instance_transform(i, Transform3D(basis, pos))

		var node := MultiMeshInstance3D.new()
		node.name = "Grass%d" % group
		node.multimesh = multimesh
		node.material_override = grass_material
		node.custom_aabb = bounds
		node.cast_shadow = (
				GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		add_child(node)
		if groups > 1:
			node.set_instance_shader_parameter("variant_index", group)
		_instances.append(node)

	_anchor_world_maps()


## Shader 02 samples `grass_color` / `terrain_color` at
##     world_position + world.xz / world_size
## with repeat_disable, so a patch sitting at x = -30 lands outside 0..1 and clamps to a
## flat edge colour. Re-centring the anchor on this plot puts the patch back in the middle
## of the map wherever the gallery decides to place it.
func _anchor_world_maps() -> void:
	if world_position_uniform.is_empty() or grass_material == null:
		return
	var shader_material := grass_material as ShaderMaterial
	if shader_material == null:
		return
	var world_size: Vector2 = Vector2(10.0, 10.0)
	var declared: Variant = shader_material.get_shader_parameter(world_size_uniform)
	if declared is Vector2:
		world_size = declared
	var origin: Vector3 = global_position
	shader_material.set_shader_parameter(
			world_position_uniform,
			Vector2(0.5, 0.5) - Vector2(origin.x, origin.z) / world_size)


## Called every frame by the gallery for the plots that react to something walking on them.
func set_player_position(world_pos: Vector3) -> void:
	if not player_instance_uniform.is_empty():
		for node: MultiMeshInstance3D in _instances:
			node.set_instance_shader_parameter(player_instance_uniform, world_pos)
	if not player_material_uniform.is_empty() and grass_material is ShaderMaterial:
		(grass_material as ShaderMaterial).set_shader_parameter(
				player_material_uniform, world_pos)


func get_blade_count() -> int:
	var total := 0
	for node: MultiMeshInstance3D in _instances:
		total += node.multimesh.instance_count
	return total
