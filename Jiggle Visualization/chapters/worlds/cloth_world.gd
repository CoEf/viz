class_name ClothWorld
extends JiggleStage
## 챕터 4 월드 — Verlet 격자 천 (치마 / 커튼) + 하반신 마네킹.
## 원본 demos/04_cloth/cloth_demo.gd 이식.
## 사슬과 완전히 같은 솔버에 제약만 격자(구조 + 전단 + 굽힘)로 늘어난다.

const COLOR_CONTACT := Color(1.0, 0.25, 0.35)
const COLOR_STRUCTURAL := Color(1.0, 1.0, 1.0, 0.45)
const COLOR_SHEAR := Color(0.35, 0.75, 1.0, 0.40)
const COLOR_BEND := Color(1.0, 0.65, 0.25, 0.30)
const WIND_DIRECTION := Vector3(0.30, 0.10, 1.0)

## 천은 양면이 다 보인다. 컬링을 끄면 뒷면도 앞면과 같은 법선으로 그려져
## 새까맣게 나오므로, 뒷면일 때 법선을 뒤집어 준다.
const CLOTH_SHADER := """
shader_type spatial;
render_mode cull_disabled, diffuse_burley;

uniform vec3 cloth_color : source_color = vec3(0.72, 0.30, 0.38);
uniform float cloth_roughness : hint_range(0.0, 1.0) = 0.75;

void fragment() {
	ALBEDO = cloth_color;
	ROUGHNESS = cloth_roughness;
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
}
"""

enum Shape { SKIRT, CURTAIN }
enum PinMode { TOP_ROW, CORNERS }

var shape := Shape.CURTAIN
var pin_mode := PinMode.TOP_ROW
var columns := 16
var rows := 12

var iterations := 6
var structural_stiffness := 1.0
var shear_enabled := true
var shear_stiffness := 0.7
var bend_enabled := true
var bend_stiffness := 0.3

var gravity := 9.0
var drag := 0.02
var wind := 0.0
var wind_gust := 1.0

var collision_enabled := true
var collision_response := JiggleVerletBody.CollisionResponse.STABLE
var collision_friction := 0.3
var leg_swing := 0.45

var show_constraints := false
var show_particles := false
var show_colliders := true

var cloth := JiggleVerletCloth.new()
var _mesh := ArrayMesh.new()
var _mesh_instance: MeshInstance3D
var _body: ClothMannequin
var _material := ShaderMaterial.new()

var _rest_local := PackedVector3Array()
var _pinned := PackedInt32Array()
var _structure := Vector4.ZERO
var _no_colliders: Array[JiggleVerletBody.Collider] = []
var _wind_time := 0.0


func _build() -> void:
	stimulus.kind = Stimulus.Kind.WALK
	# 천은 파티클이 많아 120Hz 서브스텝이 비싸다. 60Hz로도 충분히 안정적이다.
	set_substep_hz(60.0)

	_body = ClothMannequin.new()
	_body.name = "Mannequin"
	add_child(_body)
	_body.build()

	var shader := Shader.new()
	shader.code = CLOTH_SHADER
	_material.shader = shader
	_material.set_shader_parameter("cloth_color", Color(0.66, 0.24, 0.31))
	_material.set_shader_parameter("cloth_roughness", 0.72)

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "Cloth"
	_mesh_instance.mesh = _mesh
	_mesh_instance.material_override = _material
	# 파티클 좌표가 곧 월드 좌표다. 노드는 반드시 원점에 있어야 한다.
	_mesh_instance.custom_aabb = AABB(Vector3(-3.0, -1.0, -3.0), Vector3(6.0, 5.0, 6.0))
	add_child(_mesh_instance)

	_rebuild_cloth()


func apply() -> void:
	var structure := Vector4(shape, columns, rows, pin_mode)
	if not structure.is_equal_approx(_structure):
		_rebuild_cloth()
		return
	_apply_simulation_params()


func reset_world() -> void:
	stimulus.reset()
	_wind_time = 0.0
	if _body == null:
		return
	_body.transform = Transform3D.IDENTITY
	_body.set_leg_swing(0.0)
	_body.refresh_colliders()
	cloth.reset_to(_rest_local)
	_update_mesh()


func _frame_update(delta: float) -> void:
	_wind_time += delta * wind_gust
	var transform := Transform3D(Basis.from_euler(stimulus.euler), stimulus.offset)
	_body.transform = transform
	_body.set_leg_swing(sin(stimulus.cycle * PI) * leg_swing)
	_body.refresh_colliders()

	# rest 위치와 고정점을 몸에 맞춰 옮긴다.
	# 고정점은 시뮬레이션이 아니라 애니메이션이 위치를 정하는 지점이다.
	var rest := PackedVector3Array()
	rest.resize(_rest_local.size())
	for i in _rest_local.size():
		rest[i] = transform * _rest_local[i]
	cloth.set_rest(rest)
	for index in _pinned:
		cloth.move_pinned(index, rest[index])

	# 돌풍. 세기만 흔들어 줘도 펄럭임이 훨씬 살아난다.
	var gust := 0.55 + 0.45 * sin(_wind_time * 1.7) * sin(_wind_time * 0.53 + 1.1)
	cloth.apply_wind(WIND_DIRECTION.normalized(), wind * gust)


func _simulate(delta: float) -> void:
	cloth.step(delta)


func _post_simulate(_delta: float) -> void:
	_update_mesh()


func _draw_debug() -> void:
	if show_colliders and shape == Shape.SKIRT:
		for collider in cloth.colliders:
			debug.capsule(
				collider.point_a, collider.point_b, collider.radius, Color(0.35, 0.75, 1.0, 0.22)
			)
	if show_constraints:
		_draw_pairs(cloth.structural_pairs(), COLOR_STRUCTURAL)
		if shear_enabled:
			_draw_pairs(cloth.shear_pairs(), COLOR_SHEAR)
		if bend_enabled:
			_draw_pairs(cloth.bend_pairs(), COLOR_BEND)
	if not show_particles:
		return
	for i in cloth.positions.size():
		if cloth.contact_normals[i].length_squared() > 0.000001:
			debug.sphere(cloth.positions[i], 0.014, COLOR_CONTACT, 8)
		elif cloth.inverse_mass[i] <= 0.0:
			debug.cross_mark(cloth.positions[i], 0.014, JiggleDebugDraw.COLOR_TARGET)
		else:
			debug.cross_mark(cloth.positions[i], 0.008, JiggleDebugDraw.COLOR_ACTUAL)


## 그래프용: 평균 늘어남(mm).
func sample_plot() -> Dictionary:
	return {"stretch": cloth.average_stretch() * 1000.0}


## 구조 파라미터가 바뀌면 격자를 통째로 다시 만든다.
func _rebuild_cloth() -> void:
	var points := PackedVector3Array()
	var wrap := shape == Shape.SKIRT
	_pinned = PackedInt32Array()

	if wrap:
		_build_skirt(points)
	else:
		_build_curtain(points)

	_rest_local = points.duplicate()
	cloth.build(points, columns, rows, wrap)
	for index in _pinned:
		cloth.pin(index)

	_body.visible = wrap
	_structure = Vector4(shape, columns, rows, pin_mode)
	_apply_simulation_params()
	_update_mesh()


## 치마: 허리에서 밑단으로 갈수록 넓어지는 원통.
## 허리 반지름은 골반 충돌체 바깥에 오도록 잡았다 — rest 가 충돌체에 파묻히면
## 복원력과 충돌이 영원히 싸운다.
func _build_skirt(points: PackedVector3Array) -> void:
	var waist_y := 0.97
	var hem_y := 0.50
	var waist_radius := 0.180
	var hem_radius := 0.300
	for row in rows + 1:
		var t := float(row) / float(rows)
		var y := lerpf(waist_y, hem_y, t)
		var radius := lerpf(waist_radius, hem_radius, t)
		for column in columns:
			var angle := TAU * float(column) / float(columns)
			points.append(Vector3(cos(angle) * radius, y, sin(angle) * radius))
			if row == 0:
				_pinned.append(points.size() - 1)


## 커튼: 평면 격자. 제약 종류별 차이를 보기에는 이쪽이 훨씬 선명하다.
func _build_curtain(points: PackedVector3Array) -> void:
	var width := 0.85
	var height := 0.72
	var top := 1.18
	for row in rows + 1:
		for column in columns + 1:
			var x := (float(column) / float(columns) - 0.5) * width
			var y := top - float(row) / float(rows) * height
			points.append(Vector3(x, y, 0.0))
			if row != 0:
				continue
			# 윗변 전체를 고정하면 커튼, 모서리만 고정하면 늘어진 천이 된다.
			if pin_mode == PinMode.TOP_ROW or column == 0 or column == columns:
				_pinned.append(points.size() - 1)


func _apply_simulation_params() -> void:
	cloth.iterations = iterations
	cloth.structural_stiffness = structural_stiffness
	cloth.shear_enabled = shear_enabled
	cloth.shear_stiffness = shear_stiffness
	cloth.bend_enabled = bend_enabled
	cloth.bend_stiffness = bend_stiffness
	cloth.gravity = Vector3.DOWN * gravity
	cloth.drag = drag
	cloth.collision_response = collision_response
	cloth.collision_friction = collision_friction
	var use_colliders := collision_enabled and shape == Shape.SKIRT
	cloth.colliders = _body.colliders if use_colliders else _no_colliders


## 매 프레임 ArrayMesh 를 다시 굽는다. 인덱스와 UV는 안 변하므로 정점·법선만 갱신한다.
func _update_mesh() -> void:
	cloth.update_normals()
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, cloth.mesh_arrays())


func _draw_pairs(pairs: PackedInt32Array, color: Color) -> void:
	for k in pairs.size() / 2:
		debug.line(cloth.positions[pairs[k * 2]], cloth.positions[pairs[k * 2 + 1]], color)
