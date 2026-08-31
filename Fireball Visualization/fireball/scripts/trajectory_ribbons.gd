class_name TrajectoryRibbons
extends MeshInstance3D
## 시각화 전용 — 비행 챕터의 궤적 리본. DiagramKit.rebuild_ribbons는 XY 평면
## 전용이라(오프셋이 z=0 고정), 3차원 궤적용으로 카메라를 향해 눕는 리본을
## 직접 만든다. 원본 저장소의 미사용 습작 trail_3d.gd와 같은 ImmediateMesh 방식.

const MAX_POINTS := 90

var paths := {} # Node3D(발사체) -> PackedVector3Array


func _ready() -> void:
	mesh = ImmediateMesh.new()
	material_override = DiagramKit.flat_material(Color(1.0, 0.75, 0.3, 0.85), true)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func track(projectile: Node3D) -> void:
	if not paths.has(projectile):
		paths[projectile] = PackedVector3Array()


func clear() -> void:
	paths.clear()
	(mesh as ImmediateMesh).clear_surfaces()


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	for projectile in paths.keys():
		# 발사체가 사라지면 궤적은 그대로 두고 더 이상 늘리지만 않는다.
		if not is_instance_valid(projectile) or not (projectile as Node3D).is_inside_tree():
			continue
		var path: PackedVector3Array = paths[projectile]
		path.append((projectile as Node3D).global_position)
		if path.size() > MAX_POINTS:
			path = path.slice(path.size() - MAX_POINTS)
		paths[projectile] = path
	_rebuild(camera)


func _rebuild(camera: Camera3D) -> void:
	var immediate := mesh as ImmediateMesh
	immediate.clear_surfaces()
	var drawable := false
	for path: PackedVector3Array in paths.values():
		if path.size() >= 2:
			drawable = true
			break
	if not drawable:
		return
	var view := camera.global_transform.basis.z
	immediate.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for path: PackedVector3Array in paths.values():
		var span := float(maxi(path.size() - 1, 1))
		for i in maxi(path.size() - 1, 0):
			var a := path[i]
			var b := path[i + 1]
			var tangent := b - a
			if tangent.length_squared() < 0.000001:
				continue
			var offset := tangent.normalized().cross(view).normalized() * 0.035
			var fade_a := float(i) / span
			var fade_b := float(i + 1) / span
			_quad(immediate, a, b, offset, fade_a, fade_b)
	immediate.surface_end()


func _quad(
		immediate: ImmediateMesh, a: Vector3, b: Vector3, offset: Vector3,
		fade_a: float, fade_b: float) -> void:
	var color_a := Color(1.0, 0.75, 0.3, 0.05 + 0.8 * fade_a)
	var color_b := Color(1.0, 0.75, 0.3, 0.05 + 0.8 * fade_b)
	for entry: Array in [
			[a + offset, color_a], [a - offset, color_a], [b + offset, color_b],
			[a - offset, color_a], [b - offset, color_b], [b + offset, color_b]]:
		immediate.surface_set_color(entry[1] as Color)
		immediate.surface_add_vertex(entry[0] as Vector3)
