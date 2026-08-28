extends Node3D
class_name WaterDepthField

## 해저 높이를 텍스처로 구워 물 셰이더에 넘긴다 (해변 쇄파용).
## docs/water-shader-analysis.md 5.2
##
## 파문 필드(water_ripple_field.gd)와 같은 매핑 규약을 쓴다:
## 월드 XZ 정사각형 하나 + 중심 + 한 변 길이. 셰이더 쪽 코드가 거의 같아진다.
##
## 레이캐스트로 굽기 때문에 대상에 콜리전이 있어야 한다.
## CSGShape3D 는 루트 노드에서 use_collision = true 로 켤 수 있다.
##
## ⚠ 실사용에서는 런타임에 굽지 말고 오프라인에서 텍스처로 저장할 것.
##   여기서 굽는 건 씬을 자기완결적으로 두기 위해서다.
##   (128² = 16384 회 레이캐스트, 한 프레임에 끝나지만 공짜는 아니다)

@export_group("Field")
## 필드가 덮는 월드 정사각형 한 변 (m)
@export var field_size: float = 320.0
@export var resolution: int = 128
@export var water_level: float = 0.0

@export_group("Raycast")
@export var ray_top: float = 300.0
@export var ray_bottom: float = -300.0
@export var collision_mask: int = 1
## 아무것도 안 맞았을 때 쓸 높이 (m). 아주 깊은 물로 취급된다.
@export var miss_height: float = -100.0

@export_group("Targets")
@export var water_meshes: Array[NodePath] = []

## CSG 콜리전은 지연 생성된다. 첫 물리 프레임에 쏘면 전부 빗나간다.
@export var bake_delay_frames: int = 6

var _baked: bool = false
var _frames: int = 0


func _physics_process(_delta: float) -> void:
	if _baked:
		return
	_frames += 1
	if _frames < bake_delay_frames:
		return
	_baked = true
	set_physics_process(false)
	_bake()


func _bake() -> void:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if space == null:
		push_warning("WaterDepthField: 물리 공간을 얻지 못했다")
		return

	var center := Vector2(global_position.x, global_position.z)
	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(resolution * resolution)

	var lo: float = INF
	var hi: float = -INF
	var step: float = field_size / float(resolution)
	var origin: Vector2 = center - Vector2.ONE * (field_size * 0.5) + Vector2.ONE * (step * 0.5)

	var query := PhysicsRayQueryParameters3D.new()
	query.collision_mask = collision_mask

	for y in resolution:
		for x in resolution:
			var wp := origin + Vector2(x, y) * step
			query.from = Vector3(wp.x, ray_top, wp.y)
			query.to = Vector3(wp.x, ray_bottom, wp.y)
			var hit: Dictionary = space.intersect_ray(query)
			var h: float = miss_height
			if not hit.is_empty():
				h = (hit["position"] as Vector3).y
			heights[y * resolution + x] = h
			lo = minf(lo, h)
			hi = maxf(hi, h)

	# 범위를 실측값으로 잡아야 8비트 정밀도를 낭비하지 않는다.
	# (-300~300 을 그대로 쓰면 텍셀당 2.4m — 해변 경사가 계단이 된다)
	if hi - lo < 0.001:
		hi = lo + 1.0
	var img := Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
	for y in resolution:
		for x in resolution:
			var n: float = (heights[y * resolution + x] - lo) / (hi - lo)
			img.set_pixel(x, y, Color(n, n, n, 1.0))

	var tex := ImageTexture.create_from_image(img)
	for path in water_meshes:
		var mesh := get_node_or_null(path) as MeshInstance3D
		if mesh == null:
			push_warning("WaterDepthField: %s 를 찾을 수 없음" % path)
			continue
		var mat := mesh.material_override as ShaderMaterial
		if mat == null:
			mat = mesh.get_active_material(0) as ShaderMaterial
		if mat == null:
			push_warning("WaterDepthField: %s 에 ShaderMaterial 이 없음" % path)
			continue
		mat.set_shader_parameter(&"seabed_tex", tex)
		mat.set_shader_parameter(&"seabed_center", center)
		mat.set_shader_parameter(&"seabed_size", field_size)
		mat.set_shader_parameter(&"seabed_min_y", lo)
		mat.set_shader_parameter(&"seabed_max_y", hi)
		mat.set_shader_parameter(&"water_level", water_level)

	print("WaterDepthField: baked %d^2 rays, seabed y %.2f .. %.2f" % [resolution, lo, hi])
	if hi <= miss_height + 0.001:
		push_warning("WaterDepthField: 레이가 전부 빗나갔다. 해저에 콜리전이 켜져 있는지"
			+ " (CSGShape3D.use_collision), collision_mask 가 맞는지 확인할 것.")
