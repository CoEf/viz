class_name WaterPlot
extends Node3D
## 셰이더 하나가 서는 수영장 한 칸.
##
## 25개를 나란히 비교하려면 [b]물 말고 전부 같아야[/b] 한다. 그래서 칸마다
## 같은 형상을 만든다 — 10도 기울어진 바닥(수심 0.8~6), 수면을 뚫고 나온 기둥,
## 물에 반쯤 잠긴 바위, 정해진 궤도를 도는 주황 프로브. 원본 갤러리의 무대를
## 한 칸 크기로 줄인 것이고, 이유도 같다: 깊이 페이드는 수심 그라디언트가
## 있어야 보이고, 교차 포말은 뚫고 나온 물체가 있어야 보인다.
##
## 머티리얼은 칸마다 새로 만든다. 같은 셰이더를 텍스처만 바꿔 왼쪽·오른쪽에
## 놓는 비교(챕터 2의 능선 vs FBM, 챕터 6의 포팅 버그)가 그래야 가능하다.

const TILT_DEGREES := 10.0
const PROBE_RADIUS := 9.0

var entry: Dictionary
var material: ShaderMaterial
var water: MeshInstance3D
var backdrop: MeshInstance3D
var probe: MeshInstance3D
var scenery: Array[MeshInstance3D] = []
var plot_size := 30.0

var _probe_velocity := Vector3.FORWARD
var _label: Label3D


## spec 키: id(필수) / params / textures / shader / label / backdrop.
func build(spec: Dictionary, size: float, subdiv: int, foam_texture: Texture2D,
		foam_layer: int) -> void:
	plot_size = size
	entry = WaterShaderRegistry.by_id(int(spec["id"]))
	_build_basin(size, foam_layer)
	_build_probe(foam_layer)
	material = _build_material(spec, foam_texture)
	_build_water(spec, size, subdiv)
	_build_label(spec, size)


# --- 무대 --------------------------------------------------------------------

func _build_basin(size: float, foam_layer: int) -> void:
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_texture = WaterTextures.get_texture(&"checker")
	floor_material.uv1_scale = Vector3(8.0, 8.0, 1.0)
	floor_material.roughness = 0.95

	# 바닥을 10도 기울이면 한쪽 끝 수심 0.8, 반대쪽 6.0이 된다. 깊이 페이드와
	# Beer's law 계열은 이 그라디언트 위에서만 "깊이에 반응한다"가 눈에 보인다.
	var seabed := MeshInstance3D.new()
	seabed.name = "Seabed"
	var seabed_mesh := BoxMesh.new()
	seabed_mesh.size = Vector3(size * 1.12, 4.0, size * 1.12)
	seabed.mesh = seabed_mesh
	seabed.material_override = floor_material
	seabed.position = Vector3(0.0, -5.4, 0.0)
	seabed.rotation_degrees = Vector3(TILT_DEGREES, 0.0, 0.0)
	add_child(seabed)
	scenery.append(seabed)

	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.52, 0.50, 0.46)
	stone.roughness = 0.9

	for spot: Vector2 in [Vector2(-0.42, -0.30), Vector2(0.38, 0.12)] as Array[Vector2]:
		var pillar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.7
		cyl.bottom_radius = 0.95
		cyl.height = 12.0
		pillar.mesh = cyl
		pillar.material_override = stone
		pillar.position = Vector3(spot.x * size, -3.0, spot.y * size)
		add_child(pillar)
		scenery.append(pillar)
		_add_foam_blob(pillar, 1.6, foam_layer)

	for spot: Vector3 in [Vector3(0.14, -0.5, -0.40), Vector3(-0.24, -1.0, 0.30)] as Array[Vector3]:
		var rock := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1.5
		sphere.height = 2.6
		rock.mesh = sphere
		rock.material_override = stone
		rock.position = Vector3(spot.x * size, spot.y, spot.z * size)
		add_child(rock)
		scenery.append(rock)
		_add_foam_blob(rock, 2.6, foam_layer)


func _build_probe(foam_layer: int) -> void:
	# 4·5번은 boat_position, 10번은 player_position 전역 파라미터를 읽는다.
	# 읽을 위치가 없으면 그 셰이더들은 아무 일도 안 하므로 칸마다 하나씩 돈다.
	probe = MeshInstance3D.new()
	probe.name = "Probe"
	var mesh := SphereMesh.new()
	mesh.radius = 0.85
	mesh.height = 1.7
	probe.mesh = mesh
	var probe_material := StandardMaterial3D.new()
	probe_material.albedo_color = Color(1.0, 0.45, 0.12)
	probe_material.emission_enabled = true
	probe_material.emission = Color(1.0, 0.35, 0.05)
	probe_material.emission_energy_multiplier = 1.4
	probe.material_override = probe_material
	add_child(probe)
	_add_foam_blob(probe, 3.0, foam_layer)


## 포말 마스크 카메라만 보는 흰 원반. 본 카메라의 cull_mask에서 빠져 있다.
func _add_foam_blob(parent: Node3D, radius: float, foam_layer: int) -> void:
	var blob := MeshInstance3D.new()
	blob.name = "FoamBlob"
	var quad := QuadMesh.new()
	quad.size = Vector2(radius * 2.0, radius * 2.0)
	blob.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color.WHITE
	mat.albedo_texture = WaterTextures.get_texture(&"blob")
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	blob.material_override = mat
	blob.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	blob.layers = 1 << (foam_layer - 1)
	parent.add_child(blob)


# --- 물 ----------------------------------------------------------------------

func _build_material(spec: Dictionary, foam_texture: Texture2D) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	var path: String = spec.get("shader", WaterShaderRegistry.shader_path(entry))
	mat.shader = load(path) as Shader

	var textures: Dictionary = entry["textures"].duplicate()
	textures.merge(spec.get("textures", {}), true)
	for uniform_name: String in textures:
		var tex: Texture2D = WaterTextures.get_texture(textures[uniform_name])
		if tex != null:
			mat.set_shader_parameter(uniform_name, tex)

	for uniform_name: String in entry["params"]:
		mat.set_shader_parameter(uniform_name, entry["params"][uniform_name])

	if int(entry["id"]) == 3:
		mat.set_shader_parameter("caustic_sampler", WaterTextures.get_caustic_array())

	var feeds: Array = entry["feeds"]
	if feeds.has(WaterShaderRegistry.Feed.FOAM_MASK):
		mat.set_shader_parameter("foam_mask", foam_texture)
		mat.set_shader_parameter("foam_mask_size", plot_size)

	var overrides: Dictionary = spec.get("params", {})
	for uniform_name: String in overrides:
		mat.set_shader_parameter(uniform_name, overrides[uniform_name])
	return mat


func _build_water(spec: Dictionary, size: float, subdiv: int) -> void:
	var mesh_kind: WaterShaderRegistry.MeshKind = spec.get("mesh", entry["mesh"])
	var mesh_overrides: Dictionary = entry.get("mesh_overrides", {})
	if mesh_overrides.has(mesh_kind):
		var values: Dictionary = mesh_overrides[mesh_kind]
		for uniform_name: String in values:
			material.set_shader_parameter(uniform_name, values[uniform_name])

	water = MeshInstance3D.new()
	water.name = "Water"
	# 챕터 1의 마지막 스텝은 같은 셰이더를 분할 수만 바꿔 나란히 놓는다.
	water.mesh = _mesh_for(mesh_kind, size, int(spec.get("subdiv", subdiv)))
	water.material_override = material
	# 정점 셰이더가 메시를 원래 AABB 밖으로 밀어내면 비스듬한 각도에서 판 전체가
	# 통째로 컬링돼 사라진다. 박스를 손으로 키워 둔다.
	water.custom_aabb = AABB(
			Vector3(-size, -10.0, -size), Vector3(size * 2.0, 20.0, size * 2.0))
	match mesh_kind:
		WaterShaderRegistry.MeshKind.SPHERE:
			water.position = Vector3(0.0, 2.5, 0.0)
		WaterShaderRegistry.MeshKind.CYLINDER:
			water.position = Vector3(0.0, 1.2, 0.0)
	add_child(water)

	# 항적 리본이나 파문 링처럼 "효과만" 그리는 셰이더는 아래에 물이 없으면
	# 마른 바닥에 붙인 데칼로 보인다. 그런 칸에는 기본 수면을 한 장 깔아준다.
	var wants_backdrop: bool = bool(spec.get("backdrop", entry.get("backdrop", false)))
	if mesh_kind != WaterShaderRegistry.MeshKind.PLANE:
		wants_backdrop = true
	if wants_backdrop:
		_build_backdrop(size, subdiv)


func _build_backdrop(size: float, subdiv: int) -> void:
	backdrop = MeshInstance3D.new()
	backdrop.name = "Backdrop"
	backdrop.mesh = _mesh_for(WaterShaderRegistry.MeshKind.PLANE, size, subdiv)
	backdrop.position = Vector3(0.0, -0.06, 0.0)
	backdrop.custom_aabb = water.custom_aabb
	var plain := ShaderMaterial.new()
	var base: Dictionary = WaterShaderRegistry.by_id(11)
	plain.shader = load(WaterShaderRegistry.shader_path(base)) as Shader
	for uniform_name: String in base["params"]:
		plain.set_shader_parameter(uniform_name, base["params"][uniform_name])
	backdrop.material_override = plain
	add_child(backdrop)


func _mesh_for(kind: WaterShaderRegistry.MeshKind, size: float, subdiv: int) -> Mesh:
	match kind:
		WaterShaderRegistry.MeshKind.SPHERE:
			var sphere := SphereMesh.new()
			sphere.radius = size * 0.22
			sphere.height = size * 0.44
			sphere.radial_segments = 96
			sphere.rings = 48
			return sphere
		WaterShaderRegistry.MeshKind.CYLINDER:
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = size * 0.26
			cylinder.bottom_radius = size * 0.26
			cylinder.height = 5.0
			cylinder.radial_segments = 96
			cylinder.rings = 16
			cylinder.cap_top = false
			cylinder.cap_bottom = false
			return cylinder
		WaterShaderRegistry.MeshKind.RIBBON:
			var ribbon := PlaneMesh.new()
			ribbon.size = Vector2(4.5, 15.0)
			ribbon.subdivide_width = 8
			ribbon.subdivide_depth = 32
			return ribbon
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	# 정점 변위 셰이더는 밀어낼 진짜 기하가 필요하다. 2삼각형 판이면 1~5·9·
	# 11~13번의 파도가 통째로 평평해진다.
	plane.subdivide_width = subdiv
	plane.subdivide_depth = subdiv
	return plane


func _build_label(spec: Dictionary, size: float) -> void:
	_label = Label3D.new()
	_label.text = spec.get("label", "%02d. %s" % [entry["id"], entry["title"]])
	_label.font_size = 96
	_label.pixel_size = 0.011
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.modulate = Color(0.94, 0.97, 1.0)
	_label.outline_modulate = Color(0.05, 0.07, 0.09, 0.9)
	_label.outline_size = 22
	_label.position = Vector3(0.0, size * 0.14, 0.0)
	add_child(_label)


# --- 매 프레임 ---------------------------------------------------------------

## 프로브 궤도. 칸마다 위상이 같아서 두 칸을 나란히 놓아도 비교가 성립한다.
func advance(elapsed: float) -> void:
	var previous: Vector3 = probe.position
	var t: float = elapsed * 0.35
	probe.position = Vector3(sin(t * 1.3) * PROBE_RADIUS, 0.0, cos(t) * PROBE_RADIUS)
	var moved: Vector3 = probe.position - previous
	if moved.length_squared() > 0.000001:
		_probe_velocity = moved.normalized()

	var feeds: Array = entry["feeds"]
	if feeds.has(WaterShaderRegistry.Feed.SYNC_TIME):
		material.set_shader_parameter("sync_time", elapsed)
	if feeds.has(WaterShaderRegistry.Feed.BOAT):
		material.set_shader_parameter("boat_position", probe.global_position)

	if entry["mesh"] == WaterShaderRegistry.MeshKind.RIBBON:
		water.position = probe.position - _probe_velocity * 7.5 + Vector3(0.0, 0.05, 0.0)
		water.rotation.y = atan2(_probe_velocity.x, _probe_velocity.z)


func set_overlay(overlay: Material) -> void:
	for node: MeshInstance3D in scenery:
		node.material_overlay = overlay


func set_label(text: String) -> void:
	_label.text = text


## 격자로 접혀 멀리서 볼 때는 이름표도 같이 커져야 읽힌다.
func set_label_size(pixel_size: float) -> void:
	_label.pixel_size = pixel_size
	_label.position.y = plot_size * 0.14 + pixel_size * 60.0


## 카메라 맞춤(WaterStage.frame)이 이름표까지 화면에 넣으려면 글자 윗변이
## 어디인지 알아야 한다. Label3D 높이는 폰트 크기 x pixel_size다.
func label_top() -> float:
	return _label.position.y + float(_label.font_size) * _label.pixel_size
