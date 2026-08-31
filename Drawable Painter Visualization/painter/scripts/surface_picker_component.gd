extends Node

## Pure raycast/UV-picking API.
##
## Bakes a TriangleMesh copy of the target mesh and converts screen-space
## points into either a UV coordinate (for painting) or a world-space
## position+normal (for cursor placement). Knows nothing about painting,
## brushes, or UI.

class Pose:
	var position: Vector3
	var normal: Vector3

	## Snaps [param n] onto this pose: moves it to [member position] and
	## orients its up axis to [member normal], preserving scale.
	func apply(n: Node3D) -> void:
		n.global_position = position

		var node_scale: Vector3 = n.scale
		n.global_basis = align_up(n.global_basis, normal)
		n.scale = node_scale

	static func align_up(basis: Basis, up_direction: Vector3) -> Basis:
		basis.y = up_direction
		basis.x = -basis.z.cross(up_direction)
		return basis.orthonormalized()


var _plushy: MeshInstance3D
var _faces: PackedVector3Array = PackedVector3Array()
var _uvs: PackedVector2Array = PackedVector2Array()
var _hit_mesh: TriangleMesh = TriangleMesh.new()


func setup(plushy: MeshInstance3D) -> void:
	_plushy = plushy

	var surface: Array = plushy.mesh.surface_get_arrays(0)

	var vertices: PackedVector3Array = surface[Mesh.ARRAY_VERTEX]
	var tex_uvs: PackedVector2Array = surface[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = surface[Mesh.ARRAY_INDEX]

	var index_count: int = indices.size()
	_uvs.resize(index_count)
	_faces.resize(index_count)

	for index in range(index_count):
		var vertex_idx: int = indices[index]
		_uvs[index] = tex_uvs[vertex_idx]
		_faces[index] = vertices[vertex_idx]

	_hit_mesh.create_from_faces(_faces)


func _raycast(camera: Camera3D, screen_position: Vector2) -> Dictionary:
	var origin_ray: Vector3 = camera.project_ray_origin(screen_position)
	var normal_ray: Vector3 = camera.project_ray_normal(screen_position)

	var inverse_transform: Transform3D = _plushy.global_transform.inverse()

	origin_ray = inverse_transform * origin_ray
	normal_ray = inverse_transform.basis * normal_ray

	return _hit_mesh.intersect_ray(origin_ray, normal_ray)


## Returns the texture UV at [param screen_position], or null if the ray
## misses the mesh.
func get_uv(camera: Camera3D, screen_position: Vector2):
	var intersect: Dictionary = _raycast(camera, screen_position)

	if intersect.is_empty():
		return null

	var index: int = intersect.face_index * 3
	var f: Vector3 = intersect.position

	var p1: Vector3 = _faces[index]
	var p2: Vector3 = _faces[index + 1]
	var p3: Vector3 = _faces[index + 2]

	# calculate vectors from point f to vertices p1, p2 and p3:
	var f1: Vector3 = p1 - f
	var f2: Vector3 = p2 - f
	var f3: Vector3 = p3 - f

	# calculate the areas and factors (order of parameters doesn't matter):
	var a: float = (p1 - p2).cross(p1 - p3).length() # main triangle area a
	var a1: float = f2.cross(f3).length() / a # p1's triangle area / a
	var a2: float = f3.cross(f1).length() / a # p2's triangle area / a
	var a3: float = f1.cross(f2).length() / a # p3's triangle area / a

	# find the uv corresponding to point f (uv1/uv2/uv3 are associated to p1/p2/p3):
	return _uvs[index] * a1 + _uvs[index + 1] * a2 + _uvs[index + 2] * a3


## Visualization helper (walkthrough copy only). One raycast returning
## everything the diagram steps draw: UV, barycentric weights, the hit
## triangle's vertices, and the world pose. Mirrors get_uv()'s math exactly.
func get_hit_info(camera: Camera3D, screen_position: Vector2):
	var intersect: Dictionary = _raycast(camera, screen_position)

	if intersect.is_empty():
		return null

	var index: int = intersect.face_index * 3
	var f: Vector3 = intersect.position

	var p1: Vector3 = _faces[index]
	var p2: Vector3 = _faces[index + 1]
	var p3: Vector3 = _faces[index + 2]

	var f1: Vector3 = p1 - f
	var f2: Vector3 = p2 - f
	var f3: Vector3 = p3 - f

	var a: float = (p1 - p2).cross(p1 - p3).length()
	var a1: float = f2.cross(f3).length() / a
	var a2: float = f3.cross(f1).length() / a
	var a3: float = f1.cross(f2).length() / a

	return {
		"uv": _uvs[index] * a1 + _uvs[index + 1] * a2 + _uvs[index + 2] * a3,
		"weights": Vector3(a1, a2, a3),
		"local_positions": [p1, p2, p3],
		"triangle_uvs": [_uvs[index], _uvs[index + 1], _uvs[index + 2]],
		"local_pos": intersect.position,
		"world_pos": _plushy.to_global(intersect.position),
		"world_normal": (_plushy.global_basis * intersect.normal).normalized(),
	}


## Returns a [Pose] (world position + normal) at [param screen_position],
## or null if the ray misses the mesh.
func get_pose(camera: Camera3D, screen_position: Vector2):
	var intersect: Dictionary = _raycast(camera, screen_position)

	if intersect.is_empty():
		return null

	var pose := Pose.new()

	pose.position = _plushy.to_global(intersect.position)
	pose.normal = _plushy.global_basis * intersect.normal

	return pose


## Returns [code]{"uv": Vector2, "world_pos": Vector3}[/code] in a single
## raycast, or null on miss. Use instead of calling get_uv + get_pose
## separately when both are needed (e.g. seam detection).
func get_uv_and_world(camera: Camera3D, screen_position: Vector2):
	var intersect: Dictionary = _raycast(camera, screen_position)

	if intersect.is_empty():
		return null

	var index: int = intersect.face_index * 3
	var f: Vector3 = intersect.position

	var p1: Vector3 = _faces[index]
	var p2: Vector3 = _faces[index + 1]
	var p3: Vector3 = _faces[index + 2]

	var f1: Vector3 = p1 - f
	var f2: Vector3 = p2 - f
	var f3: Vector3 = p3 - f

	var a: float = (p1 - p2).cross(p1 - p3).length()
	var a1: float = f2.cross(f3).length() / a
	var a2: float = f3.cross(f1).length() / a
	var a3: float = f1.cross(f2).length() / a

	return {
		"uv": _uvs[index] * a1 + _uvs[index + 1] * a2 + _uvs[index + 2] * a3,
		"world_pos": _plushy.to_global(intersect.position)
	}


## Returns all triangles of the mesh as
## [code]{"positions": [Vector3 ×3], "uvs": [Vector2 ×3]}[/code] dictionaries
## in model-local space. Used to build the UV coverage mask at setup time.
func get_all_triangles() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(0, _faces.size(), 3):
		result.append({
			"positions": [_faces[i], _faces[i + 1], _faces[i + 2]],
			"uvs": [_uvs[i], _uvs[i + 1], _uvs[i + 2]]
		})
	return result


## Returns every triangle whose surface lies within [param radius] (world
## units) of the brush capsule [param world_a]..[param world_b], as
## [code]{"positions": [Vector3 ×3], "uvs": [Vector2 ×3]}[/code] dictionaries
## in model-local space. Pass [param world_a] == [param world_b] for a single
## point. Used by the 3D-projected erase path to avoid UV-space interpolation
## (and therefore UV seam artifacts) entirely.
func get_triangles_in_capsule(world_a: Vector3, world_b: Vector3, radius: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _faces.is_empty():
		return result

	var inverse_transform: Transform3D = _plushy.global_transform.inverse()
	var local_a: Vector3 = inverse_transform * world_a
	var local_b: Vector3 = inverse_transform * world_b

	# Convert the world-space radius into local space (assumes uniform scale).
	var model_scale: float = _plushy.global_basis.get_scale().x
	var local_radius: float = radius / maxf(model_scale, 1e-6)
	var radius_sq: float = local_radius * local_radius

	# Sample along the segment so a fast stroke still catches every triangle
	# between the endpoints without needing exact segment-triangle distance.
	var seg_length: float = local_a.distance_to(local_b)
	var sample_count: int = maxi(1, ceili(seg_length / maxf(local_radius, 1e-5)))

	for i in range(0, _faces.size(), 3):
		var pa: Vector3 = _faces[i]
		var pb: Vector3 = _faces[i + 1]
		var pc: Vector3 = _faces[i + 2]

		for s in range(sample_count + 1):
			var t: float = float(s) / float(sample_count)
			var sample_point: Vector3 = local_a.lerp(local_b, t)
			var closest: Vector3 = _closest_point_on_triangle(sample_point, pa, pb, pc)
			if sample_point.distance_squared_to(closest) <= radius_sq:
				result.append({
					"positions": [pa, pb, pc],
					"uvs": [_uvs[i], _uvs[i + 1], _uvs[i + 2]]
				})
				break # one hit is enough; move to next triangle

	return result


## Average world-units per UV unit across the whole mesh, used to convert a
## pixel/UV brush size into a 3D brush radius. Computed as
## [code]sqrt(total_3d_area / total_uv_area)[/code] times the model scale.
func get_uv_to_world_scale() -> float:
	var total_3d: float = 0.0
	var total_uv: float = 0.0

	for i in range(0, _faces.size(), 3):
		total_3d += (_faces[i + 1] - _faces[i]).cross(_faces[i + 2] - _faces[i]).length()

		var u1: Vector2 = _uvs[i + 1] - _uvs[i]
		var u2: Vector2 = _uvs[i + 2] - _uvs[i]
		total_uv += absf(u1.x * u2.y - u1.y * u2.x)

	if total_uv <= 0.0:
		return 1.0

	var local_scale: float = sqrt(total_3d / total_uv)
	return local_scale * _plushy.global_basis.get_scale().x


## Closest point to [param p] on triangle [param a][param b][param c]
## (Ericson, Real-Time Collision Detection §5.1.5). All in the same space.
func _closest_point_on_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab: Vector3 = b - a
	var ac: Vector3 = c - a
	var ap: Vector3 = p - a

	var d1: float = ab.dot(ap)
	var d2: float = ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return a # vertex region A

	var bp: Vector3 = p - b
	var d3: float = ab.dot(bp)
	var d4: float = ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return b # vertex region B

	var vc: float = d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		return a + ab * (d1 / (d1 - d3)) # edge region AB

	var cp: Vector3 = p - c
	var d5: float = ab.dot(cp)
	var d6: float = ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return c # vertex region C

	var vb: float = d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		return a + ac * (d2 / (d2 - d6)) # edge region AC

	var va: float = d3 * d6 - d5 * d4
	if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
		return b + (c - b) * ((d4 - d3) / ((d4 - d3) + (d5 - d6))) # edge region BC

	# inside face region — barycentric combination
	var denom: float = 1.0 / (va + vb + vc)
	return a + ab * (vb * denom) + ac * (vc * denom)
