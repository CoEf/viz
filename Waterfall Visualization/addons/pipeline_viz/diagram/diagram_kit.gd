class_name DiagramKit
extends RefCounted
## 3D 장면 위에 얹는 설명용 도해 부품 모음.
##
## 핵심 규칙 하나: 도해는 장면의 일부가 아니라 그 위에 얹힌 설명이다.
## 그래서 여기서 만드는 머티리얼은 전부 unshaded + disable_fog다. 밝은 장면
## 위에 그대로 그리면 얇은 선과 화살표는 예외 없이 묻히므로, backdrop()으로
## 어두운 판을 깔고 그 위에 그릴 것.

const HDR_FLASH := Color(2.0, 1.6, 0.75)
const BACKDROP_COLOR := Color(0.06, 0.08, 0.13, 0.95)


## 도해용 기본 머티리얼. vertex_colors를 켜면 MultiMesh 인스턴스 색과
## ImmediateMesh 정점 색이 먹는다(끄면 albedo만 쓴다).
static func flat_material(color: Color, vertex_colors := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_fog = true
	material.vertex_color_use_as_albedo = vertex_colors
	# vertex_colors를 쓰는 쪽은 정점·인스턴스 알파로 페이드를 준다. albedo가
	# 불투명해도 투명도를 켜 두지 않으면 그 알파가 통째로 무시된다.
	if color.a < 1.0 or vertex_colors:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	return material


## 로컬 +Y를 향하는 입체 화살표. aim()으로 방향을 준다.
static func arrow(material: StandardMaterial3D, length: float, radius: float) -> Node3D:
	var root := Node3D.new()
	var head_height := radius * 7.5
	var shaft_length := maxf(length - head_height, 0.01)
	root.add_child(_cylinder(material, radius, radius, shaft_length, shaft_length * 0.5))
	root.add_child(_cylinder(
			material, 0.0, radius * 3.0, head_height, shaft_length + head_height * 0.5))
	return root


## 노드의 로컬 +Y가 direction을 향하게 한다(전역 기준).
static func aim(node: Node3D, direction: Vector3) -> void:
	var y := direction.normalized()
	var x := y.cross(Vector3.BACK)
	if x.length_squared() < 0.001:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	node.global_transform.basis = Basis(x, y, x.cross(y).normalized())


## 도해 뒤에 깔 어두운 판. billboard를 켜면 카메라를 따라 돌아
## 시점이 바뀌는 기즈모 도해에도 쓸 수 있다.
static func backdrop(size: Vector2, billboard := false) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = size
	var material := flat_material(BACKDROP_COLOR)
	if billboard:
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## billboard backdrop을 target 뒤에 세운다. 시선 방향 그대로 밀면 판이 지면
## 아래로 내려가 잘리므로 수평 성분만 쓰고, 높이는 lift로 따로 올린다.
static func place_behind(
		panel: Node3D, target: Node3D, camera: Camera3D, distance: float,
		lift := 0.0) -> void:
	if camera == null:
		return
	var away := target.global_position - camera.global_position
	away.y = 0.0
	if away.length_squared() < 0.0001:
		return
	panel.global_position = (target.global_position
			+ away.normalized() * distance + Vector3(0.0, lift, 0.0))


## 임계각 원뿔 — 이 각도 안에 들어야 통과라는 조건을 눈으로 보여줄 때 쓴다.
## 뚜껑면이 있으면 정면에서 원반처럼 꽉 차 보이므로 옆면만 남기고,
## 열린 끝에 테두리 링을 둘러 경계를 준다.
static func cone_gizmo(angle_deg: float, length: float, color: Color) -> Node3D:
	var root := Node3D.new()
	var radius := tan(deg_to_rad(angle_deg)) * length
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = 0.0
	mesh.top_radius = radius
	mesh.height = length
	mesh.radial_segments = 28
	mesh.rings = 1
	mesh.cap_top = false
	mesh.cap_bottom = false
	var haze := MeshInstance3D.new()
	haze.mesh = mesh
	haze.material_override = flat_material(Color(color.r, color.g, color.b, 0.07))
	haze.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	haze.position = Vector3(0.0, length * 0.5, 0.0)
	root.add_child(haze)
	var rim := TorusMesh.new()
	rim.inner_radius = radius - 0.014
	rim.outer_radius = radius + 0.014
	rim.rings = 32
	rim.ring_segments = 6
	var rim_instance := MeshInstance3D.new()
	rim_instance.mesh = rim
	rim_instance.material_override = flat_material(color)
	rim_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rim_instance.position = Vector3(0.0, length, 0.0)
	root.add_child(rim_instance)
	return root


## 벡터 필드용 MultiMesh. set_field_arrow()로 칸마다 방향과 길이를 쓴다.
static func vector_field(count: int, color: Color) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = flat_arrow_mesh()
	multimesh.instance_count = count
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	# use_colors는 vertex_color_use_as_albedo가 켜져 있어야 실제로 먹는다.
	instance.material_override = flat_material(color, true)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## XY 평면에 눕힌 납작한 화살표(+X 방향, 길이 1). vector_field 인스턴스용.
static func flat_arrow_mesh() -> ArrayMesh:
	var points := PackedVector3Array([
		Vector3(0.0, -0.08, 0.0), Vector3(0.58, -0.08, 0.0), Vector3(0.58, 0.08, 0.0),
		Vector3(0.0, -0.08, 0.0), Vector3(0.58, 0.08, 0.0), Vector3(0.0, 0.08, 0.0),
		Vector3(0.52, -0.26, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.52, 0.26, 0.0),
	])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## XY 평면 벡터 필드 한 칸을 갱신한다. flow의 길이가 곧 화살표 길이다.
static func set_field_arrow(
		field: MultiMeshInstance3D, index: int, origin: Vector2, flow: Vector2,
		color: Color) -> void:
	var magnitude := flow.length()
	var length := maxf(magnitude, 0.0001)
	var dir := flow.normalized() if magnitude > 0.0001 else Vector2.RIGHT
	field.multimesh.set_instance_transform(index, Transform3D(
			Basis(Vector3(dir.x, dir.y, 0.0) * length,
					Vector3(-dir.y, dir.x, 0.0) * length,
					Vector3(0.0, 0.0, 1.0)),
			Vector3(origin.x, origin.y, 0.0)))
	field.multimesh.set_instance_color(index, color)


## 궤적 리본용 ImmediateMesh 홀더. rebuild_ribbons()로 매 프레임 다시 그린다.
static func ribbon_surface() -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = ImmediateMesh.new()
	instance.material_override = flat_material(Color.WHITE, true)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## 여러 경로를 XY 평면 리본으로 그린다. fade를 켜면 오래된 점일수록 투명해져
## 궤적처럼 보이고, 끄면 균일한 굵기의 선이 된다(그래프 간선은 이쪽).
## Godot 4의 선 굵기는 1px 고정이라, 읽히는 두께를 얻으려면 이렇게 직접
## 사각형을 이어 붙여야 한다.
static func rebuild_ribbons(
		surface: MeshInstance3D, paths: Array, width: float, color: Color,
		fade := true) -> void:
	var mesh := surface.mesh as ImmediateMesh
	mesh.clear_surfaces()
	var drawable := false
	for path: PackedVector3Array in paths:
		if path.size() >= 2:
			drawable = true
			break
	if not drawable:
		return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for path: PackedVector3Array in paths:
		var span := float(maxi(path.size() - 1, 1))
		for i in maxi(path.size() - 1, 0):
			var a := path[i]
			var b := path[i + 1]
			var tangent := b - a
			if tangent.length_squared() < 0.000001:
				continue
			tangent = tangent.normalized()
			var offset := Vector3(-tangent.y, tangent.x, 0.0) * width
			var fade_a := float(i) / span if fade else 1.0
			var fade_b := float(i + 1) / span if fade else 1.0
			_ribbon_quad(mesh, a, b, offset, color, fade_a, fade_b)
	mesh.surface_end()


static func _ribbon_quad(
		mesh: ImmediateMesh, a: Vector3, b: Vector3, offset: Vector3, color: Color,
		fade_a: float, fade_b: float) -> void:
	var color_a := Color(color.r, color.g, color.b, color.a * (0.05 + 0.95 * fade_a))
	var color_b := Color(color.r, color.g, color.b, color.a * (0.05 + 0.95 * fade_b))
	for entry: Array in [
			[a + offset, color_a], [a - offset, color_a], [b + offset, color_b],
			[a - offset, color_a], [b - offset, color_b], [b + offset, color_b]]:
		mesh.surface_set_color(entry[1] as Color)
		mesh.surface_add_vertex(entry[0] as Vector3)


static func _cylinder(
		material: StandardMaterial3D, top: float, bottom: float, height: float,
		offset: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position = Vector3(0.0, offset, 0.0)
	return instance
