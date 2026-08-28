@tool
class_name HeightmapTerrain
extends MeshInstance3D
## Rebuilds a ground mesh from the same heightmap, with the same world mapping, that
## shaders 07 and 08 sample.
##
## Without this the clipmap demos are a lie: the particle process shader lifts every blade
## to `texture(heightmap, uv).r * height_scale`, so on a flat plane half the grass floats
## and half is buried. The mapping below is copied from the shader verbatim, half-texel
## offset included - if the two ever disagree, the grass will visibly sink into the hill.
##
## Contract shared with tools/gen_assets.gd:
##   uv = world.xz / (heightmap_scale * heightmap_size) + 0.5 + half_texel

@export var heightmap: Texture2D:
	set(value):
		heightmap = value
		_rebuild()
@export var heightmap_scale: float = 0.35:
	set(value):
		heightmap_scale = value
		_rebuild()
@export var height_scale: float = 1.2:
	set(value):
		height_scale = value
		_rebuild()
@export var size: Vector2 = Vector2(13.0, 13.0):
	set(value):
		size = value
		_rebuild()
@export var subdivisions: int = 64:
	set(value):
		subdivisions = value
		_rebuild()


func _ready() -> void:
	_rebuild()


func sample_height(world_x: float, world_z: float) -> float:
	if heightmap == null:
		return 0.0
	var image: Image = heightmap.get_image()
	if image == null:
		return 0.0
	return _sample(image, world_x, world_z)


func _sample(image: Image, world_x: float, world_z: float) -> float:
	var map_size: float = float(image.get_width())
	var half_texel: float = 0.5 / map_size
	var u: float = world_x / (heightmap_scale * map_size) + 0.5 + half_texel
	var v: float = world_z / (heightmap_scale * map_size) + 0.5 + half_texel
	var px: int = clampi(int(u * map_size), 0, image.get_width() - 1)
	var py: int = clampi(int(v * map_size), 0, image.get_height() - 1)
	return image.get_pixel(px, py).r * height_scale


func _rebuild() -> void:
	if not is_inside_tree() or heightmap == null:
		return
	var image: Image = heightmap.get_image()
	if image == null:
		return

	var origin: Vector3 = global_position
	var steps: int = maxi(subdivisions, 2)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for row: int in steps + 1:
		for col: int in steps + 1:
			var fx: float = float(col) / float(steps) - 0.5
			var fz: float = float(row) / float(steps) - 0.5
			var local := Vector3(fx * size.x, 0.0, fz * size.y)
			local.y = _sample(image, origin.x + local.x, origin.z + local.z)
			verts.append(local)
			normals.append(Vector3.UP)
			uvs.append(Vector2(float(col) / float(steps), float(row) / float(steps)))

	for row: int in steps:
		for col: int in steps:
			var a: int = row * (steps + 1) + col
			var b: int = a + 1
			var c: int = a + steps + 1
			var d: int = c + 1
			indices.append_array([a, c, b, b, c, d])

	# Recompute normals from the finished surface so the terrain shades like a hill and
	# not like a flat plane with a bumpy silhouette.
	for i: int in range(0, indices.size(), 3):
		var ia: int = indices[i]
		var ib: int = indices[i + 1]
		var ic: int = indices[i + 2]
		var face: Vector3 = (verts[ib] - verts[ia]).cross(verts[ic] - verts[ia])
		normals[ia] += face
		normals[ib] += face
		normals[ic] += face
	for i: int in normals.size():
		normals[i] = normals[i].normalized()

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = array_mesh
