class_name MstWorld
extends Node3D
## 해부 대상. 원본 플러그인의 셀 생성기·색 헬퍼·잔디 심기·셰이더를 그대로 돌리고,
## 챕터가 스텝마다 켜고 끌 수 있도록 손잡이만 밖으로 낸다.
##
## 지형은 두 벌 둔다.
##   - `chunk`      20×20 셀. 완성된 지형과 브러시·텍스처·잔디를 보는 곳.
##   - `cell_chunk` 1셀. 네 꼭짓점 높이를 직접 만져 케이스가 갈리는 걸 보는 곳.
## 알고리즘 코드는 둘이 같은 것을 쓴다. 크기만 다르다.

const NOISE_GROUND: Texture2D = preload("res://assets/noise/grass_terrain_noise.res")
const NOISE_WALL: Texture2D = preload("res://assets/noise/wall_noise_texture.res")
const NOISE_RL: Texture2D = preload("res://assets/noise/rl_noise_texture.tres")
const NOISE_WIND: Texture2D = preload("res://assets/noise/wind_noise_texture.tres")
const TEX_VOID: Texture2D = preload("res://assets/noise/void_texture.tres")
const GRASS_SPRITE: Texture2D = preload("res://assets/grass_leaf_sprite.png")

const TERRAIN_SHADER: Shader = preload("res://mst/mst_terrain.gdshader")
const GRASS_SHADER: Shader = preload("res://mst/mst_grass.gdshader")

## 원본 기본값은 여섯 칸이 전부 비슷한 초록이다. 그 상태로는 "정점 색 두 장이
## 텍스처 번호를 가리킨다"는 4장을 눈으로 확인할 수 없어, 칸마다 색을 갈라 놓았다.
## 섞이는 방식과 인코딩은 원본 그대로고, 바뀐 건 tex_albedo_* 여섯 개뿐이다.
const SLOT_COLORS := [
	Color(0.36, 0.52, 0.28),  # 0 rr — 풀
	Color(0.74, 0.62, 0.38),  # 1 rg — 흙
	Color(0.55, 0.57, 0.60),  # 2 rb — 바위
	Color(0.86, 0.88, 0.92),  # 3 ra — 눈
	Color(0.33, 0.28, 0.24),  # 4 gr — 진흙
	Color(0.60, 0.54, 0.48),  # 5 gg — 벽돌
]

const CELL_SIZE := Vector2(2.0, 2.0)
const STUDY_CELL_SIZE := Vector2(6.0, 6.0)

var terrain: MstTerrain
var chunk: MarchingSquaresTerrainChunk
var study_terrain: MstTerrain
var study_chunk: MarchingSquaresTerrainChunk

var camera_rig: OrbitCamera
var sun: DirectionalLight3D
var world_env: WorldEnvironment

var terrain_material: ShaderMaterial
var grass_material: ShaderMaterial
var grass_mesh: QuadMesh
var study_grass_mesh: QuadMesh

var diagram: Node3D
var _corner_markers: Array[Node3D] = []
var _edge_bars: Array[MeshInstance3D] = []
var _wire: MeshInstance3D
var _wire_mesh: ImmediateMesh

var _scatter: Node3D
var _scatter_grid: MeshInstance3D
var _scatter_grid_mesh: ImmediateMesh
var _scatter_drops: MeshInstance3D
var _scatter_drops_mesh: ImmediateMesh
var _scatter_markers: MultiMeshInstance3D
var _scatter_tri: MeshInstance3D
var _scatter_tri_mesh: ImmediateMesh
var _scatter_arrow_u: Node3D
var _scatter_arrow_v: Node3D
var _scatter_corner_labels: Array[Label3D] = []
var _scatter_edge_labels: Array[Label3D] = []
var _scatter_u_label: Label3D
var _scatter_v_label: Label3D
var _scatter_question_label: Label3D
var _scatter_height_labels: Array[Label3D] = []
var _scatter_test_counts := {}
var _focus_tri := -1
var _dirty_overlay: MeshInstance3D
var _dirty_mesh: ImmediateMesh
var _scatter_counts := {}
var _scatter_plane_y := 0.0
var _scatter_focus := {}

## 5장 다이어그램 단계.
enum {
	SCATTER_FLAT,      ## 평면 위 후보 점만
	SCATTER_QUESTION,  ## 점 하나를 위로 쏘아 "이 높이는 얼마인가"를 묻기
	SCATTER_ONE,       ## 그 점을 a에서 출발한 u·v 벡터로 적기
	SCATTER_EDGES,     ## 세 부등호가 곧 세 변임을 보이기
	SCATTER_HEIGHT,    ## 같은 u·v가 왜 높이를 주는지 — 모서리를 타고 오르는 걸 보이기
	SCATTER_LIFT,      ## 제 자리 위로 수직으로 올리기
	SCATTER_VERDICT,   ## 판정별 색
	SCATTER_PLANT,     ## 풀 세우기
}

## 세 부등호가 각각 어느 변인지. u는 (c−a)의 몫이라 u=0이면 ab 변 위에 있다.
const TEST_COLORS := {
	0: Color(0.62, 1.00, 0.30),  # 통과
	1: Color(1.00, 0.55, 0.20),  # u < 0
	2: Color(0.35, 0.72, 1.00),  # v < 0
	3: Color(1.00, 0.32, 0.72),  # u + v > 1
}
const TEST_NAMES := ["통과", "u < 0", "v < 0", "u+v > 1"]

## 5장 판정별 색. 셀은 debug_mode 1(바닥 청록 / 벽 주황)로 두므로
## 그 둘과 겹치지 않는 색만 골랐다.
const VERDICT_COLORS := {
	0: Color(0.62, 1.00, 0.30),  # 심음
	1: Color(1.00, 0.30, 0.78),  # 능선·선반
	2: Color(0.45, 0.55, 1.00),  # 마스크
	3: Color(0.75, 0.72, 0.68),  # 풀 없는 텍스처
	4: Color(1.00, 0.16, 0.14),  # 벽 위 — 아무도 안 가져감
}
const VERDICT_NAMES := ["심음", "능선·선반", "마스크", "텍스처", "벽 위"]

## u 쪽 화살표는 주황, v 쪽은 하늘색. 셀 색(청록·주황)과 겹치지 않게 스텝 2는
## 디버그를 끄고 일반 렌더로 둔다.
const ARROW_U_COLOR := Color(1.00, 0.48, 0.16)
const ARROW_V_COLOR := Color(0.32, 0.72, 1.00)

var _sculpt_stage := -1


func _ready() -> void:
	_build_environment()
	_build_materials()
	_build_terrain()
	# 연구대는 만들자마자 꼭짓점 표시를 옮기므로 다이어그램이 먼저 있어야 한다.
	_build_diagram()
	_build_study()
	set_stage_terrain()
	sculpt_to(4)

#region 만들기

func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.42, 0.56, 0.74)
	sky_material.sky_horizon_color = Color(0.71, 0.76, 0.80)
	sky_material.ground_bottom_color = Color(0.24, 0.26, 0.29)
	sky_material.ground_horizon_color = Color(0.71, 0.76, 0.80)
	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 1.0
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	world_env = WorldEnvironment.new()
	world_env.environment = environment
	add_child(world_env)

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -128.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	camera_rig = OrbitCamera.new()
	camera_rig.name = "CameraRig"
	camera_rig.min_distance = 3.0
	camera_rig.max_distance = 90.0
	var camera := Camera3D.new()
	# OrbitCamera가 `$Camera3D` 로 찾는다. 이름을 안 주면 엔진이 `@Camera3D@12`
	# 같은 걸 붙여서 못 찾는다.
	camera.name = "Camera3D"
	camera.fov = 48.0
	camera_rig.add_child(camera)
	add_child(camera_rig)


func _build_materials() -> void:
	terrain_material = ShaderMaterial.new()
	terrain_material.resource_local_to_scene = true
	terrain_material.shader = TERRAIN_SHADER
	terrain_material.render_priority = -1

	# 16칸 중 0~5만 실제로 쓴다. 15번은 원본과 같이 "안 보이는 칸"이다.
	var slot_names := ["rr", "rg", "rb", "ra", "gr", "gg", "gb", "ga",
			"br", "bg", "bb", "ba", "ar", "ag", "ab", "aa"]
	for i in range(slot_names.size()):
		var tex: Texture2D = NOISE_GROUND
		if i == 5:
			tex = NOISE_WALL
		elif i == 15:
			tex = TEX_VOID
		terrain_material.set_shader_parameter("vc_tex_%s" % slot_names[i], tex)
	for i in range(SLOT_COLORS.size()):
		terrain_material.set_shader_parameter("tex_albedo_%d" % (i + 1), SLOT_COLORS[i])
	for i in range(15):
		terrain_material.set_shader_parameter("tex_scale_%d" % (i + 1), 1.0)

	terrain_material.set_shader_parameter("rl_noise_texture", NOISE_RL)
	terrain_material.set_shader_parameter("rl_noise_tile_size", 0.075)
	terrain_material.set_shader_parameter("rl_noise_strength", 0.0)
	terrain_material.set_shader_parameter("use_ridge_texture", true)
	terrain_material.set_shader_parameter("use_ledge_texture", true)
	terrain_material.set_shader_parameter("ridge_threshold", 1.0)
	terrain_material.set_shader_parameter("ledge_threshold", 1.0)
	terrain_material.set_shader_parameter("use_hard_textures", false)
	terrain_material.set_shader_parameter("blend_mode", 0)
	terrain_material.set_shader_parameter("blend_sharpness", 5.0)
	terrain_material.set_shader_parameter("blend_noise_scale", 10.0)
	terrain_material.set_shader_parameter("blend_noise_strength", 0.0)
	terrain_material.set_shader_parameter("wall_threshold", 0.0)
	terrain_material.set_shader_parameter("shadow_color", Color(0.36, 0.41, 0.52))
	terrain_material.set_shader_parameter("bands", 5)
	terrain_material.set_shader_parameter("shadow_intensity", 0.2)
	terrain_material.set_shader_parameter("debug_mode", 0)

	grass_material = ShaderMaterial.new()
	grass_material.resource_local_to_scene = true
	grass_material.shader = GRASS_SHADER
	for i in range(SLOT_COLORS.size()):
		grass_material.set_shader_parameter("grass_color_%d" % (i + 1), SLOT_COLORS[i])
		grass_material.set_shader_parameter("grass_texture_%d" % (i + 1), GRASS_SPRITE)
		if i >= 1:
			grass_material.set_shader_parameter("use_grass_tex_%d" % (i + 1), true)
			grass_material.set_shader_parameter("use_base_color_%d" % (i + 1), false)
	grass_material.set_shader_parameter("use_base_color_1", false)
	grass_material.set_shader_parameter("animate_active", true)
	grass_material.set_shader_parameter("fps", 0.0)
	grass_material.set_shader_parameter("wind_texture", NOISE_WIND)
	grass_material.set_shader_parameter("wind_direction", Vector2(1.0, 1.0))
	grass_material.set_shader_parameter("wind_scale", 0.02)
	grass_material.set_shader_parameter("wind_speed", 0.14)
	grass_material.set_shader_parameter("is_merge_round", false)
	grass_material.set_shader_parameter("wall_threshold", 0.0)
	grass_material.set_shader_parameter("shadow_color", Color(0.36, 0.41, 0.52))
	grass_material.set_shader_parameter("bands", 5)
	grass_material.set_shader_parameter("shadow_intensity", 0.2)

	grass_mesh = QuadMesh.new()
	grass_mesh.resource_local_to_scene = true
	grass_mesh.material = grass_material
	grass_mesh.center_offset = Vector3(0.0, 0.5, 0.0)


func _build_terrain() -> void:
	terrain = MstTerrain.new()
	terrain.name = "Terrain"
	terrain.dimensions = MstTerrain.CHUNK_DIMENSIONS
	terrain.cell_size = CELL_SIZE
	terrain.grass_mesh = grass_mesh
	terrain.grass_size = Vector2(0.42, 0.42)
	terrain.terrain_material = terrain_material
	add_child(terrain)

	terrain_material.set_shader_parameter("chunk_size", terrain.dimensions)
	terrain_material.set_shader_parameter("cell_size", terrain.cell_size)

	chunk = MarchingSquaresTerrainChunk.new()
	chunk.name = "Chunk"
	chunk.terrain_system = terrain
	terrain.add_child(chunk)
	chunk.initialize_terrain()
	chunk.regenerate_mesh()


func _build_study() -> void:
	study_terrain = MstTerrain.new()
	study_terrain.name = "StudyTerrain"
	study_terrain.dimensions = Vector3i(2, 32, 2)
	study_terrain.cell_size = STUDY_CELL_SIZE
	# 잔디 메시는 따로 둔다. `setup()`이 `multimesh.mesh.size`를 terrain_system의
	# grass_size와 cell_size로 다시 쓰는데, 한 벌을 공유하면 연구대(셀 6칸)가
	# 본무대(셀 2칸)의 풀 크기까지 세 배로 키워 버린다.
	study_grass_mesh = grass_mesh.duplicate() as QuadMesh
	study_grass_mesh.resource_local_to_scene = true
	study_grass_mesh.material = grass_material
	study_terrain.grass_mesh = study_grass_mesh
	study_terrain.grass_size = Vector2(0.30, 0.30)
	study_terrain.terrain_material = terrain_material
	add_child(study_terrain)

	study_chunk = MarchingSquaresTerrainChunk.new()
	study_chunk.name = "StudyChunk"
	study_chunk.terrain_system = study_terrain
	study_terrain.add_child(study_chunk)
	study_chunk.initialize_terrain()
	study_chunk.grass_planter.visible = false
	study_chunk.grass_enabled = false
	set_study_corners(0.0, 0.0, 0.0, 0.0)


func _build_diagram() -> void:
	diagram = Node3D.new()
	diagram.name = "Diagram"
	add_child(diagram)

	# A B C D 꼭짓점 표시. 원본 코드가 쓰는 이름 그대로 붙인다.
	var labels := ["A", "B", "C", "D"]
	var colors := [
		Color(1.00, 0.42, 0.38), Color(1.00, 0.78, 0.30),
		Color(0.40, 0.82, 1.00), Color(0.62, 0.90, 0.45),
	]
	for i in range(4):
		var marker := Node3D.new()
		var ball := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.34
		sphere.height = 0.68
		ball.mesh = sphere
		var ball_material := DiagramKit.flat_material(colors[i])
		# 네 꼭짓점 중 둘은 늘 메시 뒤에 숨는다. 표시는 주석이지 물체가 아니므로
		# 깊이 검사를 끄고 항상 보이게 둔다 — 라벨과 짝이 맞아야 읽힌다.
		ball_material.no_depth_test = true
		ball_material.render_priority = 2
		ball.material_override = ball_material
		marker.add_child(ball)
		var text := Label3D.new()
		text.text = labels[i]
		text.font_size = 128
		text.pixel_size = 0.006
		text.position = Vector3(0.0, 0.95, 0.0)
		text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		text.no_depth_test = true
		text.modulate = colors[i]
		text.outline_size = 32
		text.outline_modulate = Color(0.05, 0.06, 0.09, 1.0)
		marker.add_child(text)
		diagram.add_child(marker)
		_corner_markers.append(marker)

	# 네 변이 이어졌는지(ab bd cd ac)를 막대 색으로 보여 준다.
	for i in range(4):
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.0, 0.12, 0.12)
		bar.mesh = box
		bar.material_override = DiagramKit.flat_material(Color(0.5, 0.9, 0.6))
		diagram.add_child(bar)
		_edge_bars.append(bar)

	_wire_mesh = ImmediateMesh.new()
	_wire = MeshInstance3D.new()
	_wire.mesh = _wire_mesh
	var wire_material := DiagramKit.flat_material(Color(0.06, 0.07, 0.10))
	wire_material.no_depth_test = false
	_wire.material_override = wire_material
	diagram.add_child(_wire)

	_build_scatter()

	# 7장 전용. 다시 계산한 칸을 지형 위에 덧칠한다. "더러운 칸" 이야기는 숫자만
	# 봐서는 와닿지 않고, 어디가 다시 돌았는지 보여야 한다.
	_dirty_mesh = ImmediateMesh.new()
	_dirty_overlay = MeshInstance3D.new()
	_dirty_overlay.mesh = _dirty_mesh
	var dirty_material := DiagramKit.flat_material(Color(1.0, 0.55, 0.18, 0.55))
	dirty_material.no_depth_test = true
	_dirty_overlay.material_override = dirty_material
	diagram.add_child(_dirty_overlay)
	_dirty_overlay.visible = false

	set_corner_markers(false)
	set_edge_bars(false)
	set_wireframe(false)


## 5장 전용. 후보 점이 어디 찍히고, 어느 삼각형이 가져가고, 무엇이 걸러지는지를
## 셀 한 칸 위에 그린다. 이 셋은 코드로만 존재하고 화면에는 흔적이 없는 단계라
## 다이어그램 없이는 스텝이 그림 없는 설명이 된다.
func _build_scatter() -> void:
	_scatter = Node3D.new()
	_scatter.name = "Scatter"
	diagram.add_child(_scatter)

	_scatter_grid_mesh = ImmediateMesh.new()
	_scatter_grid = MeshInstance3D.new()
	_scatter_grid.mesh = _scatter_grid_mesh
	_scatter_grid.material_override = DiagramKit.flat_material(Color(0.45, 0.52, 0.62))
	_scatter.add_child(_scatter_grid)

	_scatter_drops_mesh = ImmediateMesh.new()
	_scatter_drops = MeshInstance3D.new()
	_scatter_drops.mesh = _scatter_drops_mesh
	var drop_material := DiagramKit.flat_material(Color.WHITE, true)
	drop_material.no_depth_test = true
	_scatter_drops.material_override = drop_material
	_scatter.add_child(_scatter_drops)

	# 강조할 삼각형 한 장. 무게중심 이야기는 삼각형 하나로 좁혀야 읽힌다.
	_scatter_tri_mesh = ImmediateMesh.new()
	_scatter_tri = MeshInstance3D.new()
	_scatter_tri.mesh = _scatter_tri_mesh
	var tri_material := DiagramKit.flat_material(Color(1.0, 0.92, 0.45, 0.30))
	tri_material.no_depth_test = true
	_scatter_tri.material_override = tri_material
	_scatter.add_child(_scatter_tri)

	# a → a+u·v0 → P 두 도막. 길이가 매번 달라 _rebuild_arrow가 새로 짓는다.
	_scatter_arrow_u = DiagramKit.arrow(
			DiagramKit.flat_material(ARROW_U_COLOR), 1.0, 0.055)
	_scatter_arrow_v = DiagramKit.arrow(
			DiagramKit.flat_material(ARROW_V_COLOR), 1.0, 0.055)
	_scatter.add_child(_scatter_arrow_u)
	_scatter.add_child(_scatter_arrow_v)

	for name_ in ["a", "b", "c"]:
		_scatter_corner_labels.append(_make_label(name_, 110, Color.WHITE))
	# 화살표에 u·v를 글자로 박는다. 이 그림의 주인공이 그 둘이다.
	_scatter_u_label = _make_label("u", 132, ARROW_U_COLOR)
	_scatter_v_label = _make_label("v", 132, ARROW_V_COLOR)
	# 변마다 어떤 부등호가 걸리는지.
	for i in range(3):
		_scatter_edge_labels.append(_make_label("", 84, Color(0.92, 0.94, 1.0)))
	_scatter_question_label = _make_label("y = ?", 132, Color(1.0, 0.86, 0.35))
	# 세 지점의 높이를 숫자로 박는다. "섞으면 y가 나온다"를 눈으로 세어 보게.
	for i in range(4):
		_scatter_height_labels.append(_make_label("", 84, Color(1.0, 0.90, 0.55)))

	# 점 하나마다 노드를 만들지 않는다 — 5장이 설명하는 것과 같은 이유다.
	_scatter_markers = MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	var ball := SphereMesh.new()
	ball.radius = 0.16
	ball.height = 0.32
	ball.radial_segments = 10
	ball.rings = 6
	multi.mesh = ball
	multi.instance_count = 0
	_scatter_markers.multimesh = multi
	var marker_material := DiagramKit.flat_material(Color.WHITE, true)
	marker_material.no_depth_test = true
	marker_material.render_priority = 3
	_scatter_markers.material_override = marker_material
	_scatter.add_child(_scatter_markers)

	_scatter.visible = false


func _make_label(text: String, size: int, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = color
	label.outline_size = 30
	label.outline_modulate = Color(0.05, 0.06, 0.09, 1.0)
	_scatter.add_child(label)
	return label

#endregion

#region 무대 전환

func set_stage_terrain() -> void:
	terrain.visible = true
	study_terrain.visible = false
	terrain_material.set_shader_parameter("chunk_size", terrain.dimensions)
	terrain_material.set_shader_parameter("cell_size", terrain.cell_size)
	camera_rig.position = Vector3(20.0, 1.5, 20.0)


## 카메라가 도는 중심. OrbitCamera는 자기 원점을 축으로 돌기 때문에
## 무엇을 볼지는 이 위치로 정한다.
func set_pivot(position_: Vector3) -> void:
	camera_rig.position = position_


func set_stage_study() -> void:
	terrain.visible = false
	study_terrain.visible = true
	terrain_material.set_shader_parameter("chunk_size", study_terrain.dimensions)
	terrain_material.set_shader_parameter("cell_size", study_terrain.cell_size)
	camera_rig.position = Vector3(3.0, 1.8, 3.0)

#endregion

#region 지형 손잡이

func set_debug_mode(mode: int) -> void:
	terrain_material.set_shader_parameter("debug_mode", mode)


func set_grass_visible(on: bool) -> void:
	if chunk.grass_planter:
		chunk.grass_planter.visible = on
	# 안 보이면 심지도 않는다. 재생성 비용의 대부분이 여기서 빠진다.
	chunk.grass_enabled = on


func set_terrain_visible(on: bool) -> void:
	chunk.visible = on


## 연구대 셀 메시만 끈다. 5장 첫 스텝은 "아직 높이가 없는 평면 위 좌표"를
## 보여 주는 자리라, 셀이 같이 보이면 점이 표면에 붙은 것처럼 읽힌다.
func set_study_mesh_visible(on: bool) -> void:
	study_chunk.visible = on


func set_merge_threshold(value: float) -> void:
	chunk.merge_threshold = value
	study_chunk.merge_threshold = value


func set_blend_mode(mode: int) -> void:
	terrain.blend_mode = mode
	terrain_material.set_shader_parameter("blend_mode", mode)
	terrain_material.set_shader_parameter("use_hard_textures", mode == 1 or mode == 2)


func set_blend_sharpness(value: float) -> void:
	terrain_material.set_shader_parameter("blend_sharpness", value)


func set_ridge_threshold(value: float) -> void:
	terrain_material.set_shader_parameter("ridge_threshold", value)


func set_ledge_threshold(value: float) -> void:
	terrain_material.set_shader_parameter("ledge_threshold", value)


func set_rl_noise_strength(value: float) -> void:
	terrain_material.set_shader_parameter("rl_noise_strength", value)


func set_ridge_ledge_enabled(on: bool) -> void:
	terrain_material.set_shader_parameter("use_ridge_texture", on)
	terrain_material.set_shader_parameter("use_ledge_texture", on)


func set_grass_wind_fps(value: float) -> void:
	grass_material.set_shader_parameter("fps", value)


func set_grass_wind_speed(value: float) -> void:
	grass_material.set_shader_parameter("wind_speed", value)


func set_grass_wind_scale(value: float) -> void:
	grass_material.set_shader_parameter("wind_scale", value)


func set_grass_billboard(on: bool) -> void:
	grass_material.set_shader_parameter("debug_disable_billboard", not on)


func set_grass_animate(on: bool) -> void:
	grass_material.set_shader_parameter("animate_active", on)


## 흙 칸(1번)에도 풀을 심을지. 원본 지형 설정의 tex2_has_grass 그대로다.
func set_dirt_has_grass(on: bool) -> void:
	terrain.tex2_has_grass = on
	chunk.regenerate_all_cells()


func set_grass_subdivisions(value: int) -> void:
	terrain.grass_subdivisions = value
	chunk.grass_planter.setup(chunk)
	chunk.regenerate_all_cells()


func rebuild() -> void:
	chunk.regenerate_all_cells()


func rebuild_dirty_only() -> void:
	chunk.regenerate_mesh()

#endregion

#region 높이맵 만들기 — 1장이 단계별로 부른다

## 0 = 평평, 1 = 브러시로 올리고 내리기, 2 = 레벨로 고원,
## 3 = 스무드로 다듬기, 4 = 브리지로 잇기
func sculpt_to(stage: int) -> void:
	if _sculpt_stage == stage:
		return
	_sculpt_stage = stage
	chunk.generate_height_map()
	if stage >= 1:
		_apply_hills()
	if stage >= 2:
		_apply_plateau()
	if stage >= 3:
		_apply_smooth()
	if stage >= 4:
		_apply_bridge()
	_paint_by_height()
	chunk.regenerate_all_cells()


func _apply_hills() -> void:
	var strokes := [
		{"center": Vector2(13.0, 13.0), "size": 17.0, "diff": 5.2},
		{"center": Vector2(28.0, 27.0), "size": 15.0, "diff": 4.4},
		{"center": Vector2(31.0, 10.0), "size": 11.0, "diff": -3.2},
		{"center": Vector2(8.0, 30.0), "size": 12.0, "diff": 2.6},
		{"center": Vector2(20.0, 20.0), "size": 9.0, "diff": 1.6},
	]
	for stroke in strokes:
		var pattern := MstSculpt.gather(chunk, stroke["center"], stroke["size"], 0, true)
		MstSculpt.brush(chunk, pattern, stroke["diff"])


func _apply_plateau() -> void:
	var pattern := MstSculpt.gather(chunk, Vector2(13.0, 13.0), 10.0, 1, false)
	MstSculpt.level(chunk, pattern, 4.9)


func _apply_smooth() -> void:
	var pattern := MstSculpt.gather(chunk, Vector2(28.0, 27.0), 13.0, 0, true)
	MstSculpt.smooth(chunk, pattern, 0.9)


func _apply_bridge() -> void:
	var start := Vector3(15.0, 4.9, 15.0)
	var end := Vector3(26.0, 2.6, 25.0)
	var pattern := MstSculpt.gather_line(
			chunk, Vector2(start.x, start.z), Vector2(end.x, end.z), 5.0)
	MstSculpt.bridge(chunk, pattern, start, end, 2.4)


## 1장의 슬라이더가 쓴다. 언덕 하나만 다시 그려 브러시 크기의 효과를 보여 준다.
func sculpt_single_brush(brush_size: float, height_diff: float, use_falloff: bool,
		brush_index: int) -> void:
	_sculpt_stage = -1
	chunk.generate_height_map()
	var pattern := MstSculpt.gather(
			chunk, Vector2(20.0, 20.0), brush_size, brush_index, use_falloff)
	MstSculpt.brush(chunk, pattern, height_diff)
	_paint_by_height()
	chunk.regenerate_all_cells()


## 브리지 곡선만 다시 그린다. ease 값이 진행도를 어떻게 굽히는지 보려고.
func sculpt_bridge_with_ease(ease_value: float) -> void:
	_sculpt_stage = -1
	chunk.generate_height_map()
	_apply_hills()
	_apply_plateau()
	_apply_smooth()
	var start := Vector3(15.0, 4.9, 15.0)
	var end := Vector3(26.0, 2.6, 25.0)
	var pattern := MstSculpt.gather_line(
			chunk, Vector2(start.x, start.z), Vector2(end.x, end.z), 5.0)
	MstSculpt.bridge(chunk, pattern, start, end, ease_value)
	_paint_by_height()
	chunk.regenerate_all_cells()


## 6장이 쓴다. 꼭짓점 하나만 올리고, 더러워진 셀만 다시 굽는다.
func bump_one_vertex(delta: float) -> Dictionary:
	var mid := chunk.dimensions.x / 2
	chunk.draw_height(mid, mid, chunk.get_height(Vector2i(mid, mid)) + delta)
	chunk.regenerate_mesh()
	return rebuild_stats()


## 방금 다시 계산한 칸을 지형 위에 덧칠한다. 인자를 비우면 마지막 재생성 결과를 쓴다.
func show_dirty_cells(cells: Array[Vector2i] = []) -> void:
	var target := cells if not cells.is_empty() else chunk.last_dirty_cells
	_dirty_mesh.clear_surfaces()
	_dirty_overlay.visible = not target.is_empty()
	if target.is_empty():
		return
	var cs := CELL_SIZE
	var lift := Vector3(0.0, 0.06, 0.0)
	_dirty_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for cell in target:
		# 칸 네 귀퉁이를 그 자리 높이로 띄운다 — 지형에 딱 붙어야 어디인지 읽힌다.
		var p00 := Vector3(cell.x * cs.x, chunk.height_map[cell.y][cell.x], cell.y * cs.y)
		var p10 := Vector3((cell.x + 1) * cs.x, chunk.height_map[cell.y][cell.x + 1], cell.y * cs.y)
		var p01 := Vector3(cell.x * cs.x, chunk.height_map[cell.y + 1][cell.x], (cell.y + 1) * cs.y)
		var p11 := Vector3((cell.x + 1) * cs.x, chunk.height_map[cell.y + 1][cell.x + 1], (cell.y + 1) * cs.y)
		for v in [p00, p10, p11, p00, p11, p01]:
			_dirty_mesh.surface_add_vertex(v + lift)
	_dirty_mesh.surface_end()


func hide_dirty_cells() -> void:
	_dirty_mesh.clear_surfaces()
	_dirty_overlay.visible = false


## 꼭짓점 하나를 쓰는 칸 넷. 7장 첫 스텝이 표시만 해 두고 아직 굽지는 않는다.
func cells_touching_vertex(x: int, z: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dz in [0, -1]:
		for dx in [0, -1]:
			var cell := Vector2i(x + dx, z + dz)
			if cell.x >= 0 and cell.y >= 0 and cell.x < chunk.dimensions.x - 1 					and cell.y < chunk.dimensions.z - 1:
				out.append(cell)
	return out


func rebuild_stats() -> Dictionary:
	return {
		"rebuilt": chunk.last_rebuilt_cells,
		"cached": chunk.last_cached_cells,
		"msec": chunk.last_rebuild_msec,
	}


## 높이에 따라 텍스처 칸을 칠한다. 원본의 "퀵 페인트"가 하는 일과 같은 자리
## (`draw_color_0` / `draw_color_1`)에 쓴다.
func _paint_by_height() -> void:
	var encoder := MarchingSquaresTerrainVertexColorHelper.new()
	# 벽은 전부 벽돌 칸으로 둔다 — 능선/선반이 바닥으로 흘러나오는 걸 보려면
	# 벽 색이 바닥 색과 달라야 한다.
	var wall_pair := encoder.texture_index_to_colors(5)
	var dim := chunk.dimensions
	for z in range(dim.z):
		for x in range(dim.x):
			var h: float = chunk.height_map[z][x]
			var slot := 0       # 풀 — 넓은 바닥이 여기 걸린다
			if h > 4.3:
				slot = 3        # 눈
			elif h > 2.4:
				slot = 2        # 바위
			elif h > 1.0:
				slot = 1        # 흙
			elif h < -1.2:
				slot = 4        # 진흙
			var pair := encoder.texture_index_to_colors(slot)
			chunk.draw_color_0(x, z, pair[0])
			chunk.draw_color_1(x, z, pair[1])
			chunk.draw_wall_color_0(x, z, wall_pair[0])
			chunk.draw_wall_color_1(x, z, wall_pair[1])


func set_all_one_texture() -> void:
	var dim := chunk.dimensions
	var pair := MarchingSquaresTerrainVertexColorHelper.new().texture_index_to_colors(0)
	for z in range(dim.z):
		for x in range(dim.x):
			chunk.draw_color_0(x, z, pair[0])
			chunk.draw_color_1(x, z, pair[1])
	chunk.regenerate_all_cells()


func restore_painting() -> void:
	_paint_by_height()
	chunk.regenerate_all_cells()


## 잔디 마스크를 원 모양으로 지운다 — 5장에서 마스크가 무엇을 막는지 본다.
func set_grass_mask_patch(on: bool) -> void:
	var dim := chunk.dimensions
	var center := Vector2(20.0, 20.0)
	for z in range(dim.z):
		for x in range(dim.x):
			var d := Vector2(x * CELL_SIZE.x, z * CELL_SIZE.y).distance_to(center)
			var masked := on and d < 9.0
			chunk.draw_grass_mask(x, z, Color(0.0, 0.0, 0.0, 0.0) if masked
					else Color(1.0, 1.0, 1.0, 1.0))
	chunk.regenerate_all_cells()

#endregion

#region 1셀 연구대 — 2장이 쓴다

func set_study_corners(a: float, b: float, c: float, d: float) -> void:
	study_chunk.height_map[0][0] = a
	study_chunk.height_map[0][1] = b
	study_chunk.height_map[1][0] = c
	study_chunk.height_map[1][1] = d
	study_chunk.regenerate_all_cells()
	_sync_study_diagram(a, b, c, d)


## 연구대 셀이 방금 고른 케이스 번호와, 그 케이스가 뱉은 삼각형 수.
func study_case() -> int:
	return study_chunk.last_cell_case


func study_triangle_count() -> int:
	if not study_chunk.cell_geometry.has(Vector2i(0, 0)):
		return 0
	var verts: PackedVector3Array = study_chunk.cell_geometry[Vector2i(0, 0)]["verts"]
	@warning_ignore("integer_division")
	var count := verts.size() / 3
	return count


func study_wall_triangle_count() -> int:
	if not study_chunk.cell_geometry.has(Vector2i(0, 0)):
		return 0
	var is_floor: Array = study_chunk.cell_geometry[Vector2i(0, 0)]["is_floor"]
	var walls := 0
	for i in range(0, is_floor.size() - 2, 3):
		if not is_floor[i]:
			walls += 1
	return walls


func study_edges() -> Dictionary:
	var a: float = study_chunk.height_map[0][0]
	var b: float = study_chunk.height_map[0][1]
	var c: float = study_chunk.height_map[1][0]
	var d: float = study_chunk.height_map[1][1]
	var t := _effective_threshold()
	return {
		"ab": absf(a - b) < t, "bd": absf(b - d) < t,
		"cd": absf(c - d) < t, "ac": absf(a - c) < t,
		"threshold": t,
	}


## 셀이 실제로 쓰는 문턱값. 원본 `_init`이 셀 크기와 청크 크기로 한 번 더 곱한다.
func _effective_threshold() -> float:
	var cs := study_terrain.cell_size
	var cell_scale: float = clampf((cs.x + cs.y) / 4.0, 0.3, 1.0)
	@warning_ignore("integer_division")
	var dim_scale: float = clampf(
			float(study_terrain.dimensions.x / 33 + study_terrain.dimensions.z / 33) / 2.0,
			0.5, 2.0)
	return study_chunk.merge_threshold * dim_scale * cell_scale


func _sync_study_diagram(a: float, b: float, c: float, d: float) -> void:
	var cs := STUDY_CELL_SIZE
	var spots := [
		Vector3(0.0, a, 0.0), Vector3(cs.x, b, 0.0),
		Vector3(0.0, c, cs.y), Vector3(cs.x, d, cs.y),
	]
	for i in range(4):
		_corner_markers[i].position = spots[i]

	# 막대 네 개를 변 위에 눕히고, 이어졌으면 초록 끊겼으면 빨강으로 칠한다.
	var edges := study_edges()
	var pairs := [[0, 1, "ab"], [1, 3, "bd"], [2, 3, "cd"], [0, 2, "ac"]]
	for i in range(4):
		var from: Vector3 = spots[pairs[i][0]]
		var to: Vector3 = spots[pairs[i][1]]
		var bar := _edge_bars[i]
		var box := bar.mesh as BoxMesh
		box.size = Vector3(maxf(from.distance_to(to), 0.01), 0.12, 0.12)
		bar.position = (from + to) * 0.5
		bar.look_at_from_position(bar.position, to, Vector3.UP)
		bar.rotate_object_local(Vector3.UP, PI * 0.5)
		var linked: bool = edges[pairs[i][2]]
		var material := bar.material_override as StandardMaterial3D
		material.albedo_color = (Color(0.36, 0.88, 0.52) if linked
				else Color(1.00, 0.36, 0.32))

	_rebuild_wire(study_chunk, Vector2i(0, 0))

#endregion

#region 후보 점 뿌리기 다이어그램 — 5장이 쓴다

## 연구대 셀 하나에 실제로 풀을 심어 보고, 후보 점마다 어떤 판정을 받았는지 그린다.
## 판정은 이쪽에서 다시 계산하지 않는다 — 원본 `generate_grass_on_cell()`이 돌면서
## 남긴 기록을 그대로 읽는다. 그래야 화면의 점과 코드의 분기가 어긋나지 않는다.
##
## stage 0 = 후보 점만(아직 높이를 모르는 평면 위 좌표)
## stage 1 = 어느 삼각형이 가져갔는지 — 평면에서 표면까지 선을 긋는다
## stage 2 = 판정별로 색을 나눈다
func scatter_study(subdivisions: int, corners: Array, stage: int) -> void:
	study_terrain.grass_subdivisions = subdivisions
	study_chunk.grass_enabled = true
	var planter := study_chunk.grass_planter
	planter.setup(study_chunk)
	# 원본은 후보 점을 randf_range로 흩뿌린다. 그대로 두면 스텝을 오갈 때마다
	# 점이 새로 튀어 앞 스텝에서 보던 그림이 사라진다. 씨앗을 고정해 같은 그림이
	# 나오게 한다 — 뿌리는 방식은 그대로다.
	seed(20260831)
	planter.debug_begin()
	set_study_corners(corners[0], corners[1], corners[2], corners[3])
	planter.debug_record = false
	# 후보 점은 셀 바닥보다 조금 아래에 깔아 둔다. 아래에서 위로 올라가는 선이
	# "2차원 좌표가 3차원 표면을 만나는" 순서와 맞는다.
	var lowest := INF
	for corner: float in corners:
		lowest = minf(lowest, corner)
	_scatter_plane_y = lowest - 1.2

	_rebuild_scatter_grid(subdivisions)
	# 어느 삼각형을 주인공으로 삼을지 먼저 정한다. 스텝 2와 3이 같은 삼각형을
	# 써야 "이 삼각형 안이더라" 다음에 "왜 안인지"가 이어진다.
	_focus_tri = _pick_focus_tri(planter.debug_tests)
	_rebuild_scatter_points(planter.debug_points, stage)
	if stage == SCATTER_EDGES:
		_rebuild_edge_test(planter.debug_tests)
	planter.visible = stage >= SCATTER_PLANT
	_scatter.visible = true


## 세 부등호가 각각 어느 변인지 보이려면, 서로 다른 부등호에서 떨어진 점이 한
## 삼각형에 다 있어야 한다. 그래서 결과 종류가 가장 다양한 삼각형을 고르고,
## 같으면 표본이 많은 쪽을 쓴다. (셀 가장자리에 붙은 변 바깥에는 애초에 후보가
## 없으므로, 안쪽 변을 많이 가진 삼각형이 뽑힌다.)
func _pick_focus_tri(tests: Array[Dictionary]) -> int:
	var kinds := {}
	var counts := {}
	for test in tests:
		var tri: int = test["tri"]
		counts[tri] = counts.get(tri, 0) + 1
		if not kinds.has(tri):
			kinds[tri] = {}
		kinds[tri][test["outcome"]] = true
	var best := -1
	var best_kinds := -1
	var best_count := -1
	for tri in counts:
		var kind_count: int = (kinds[tri] as Dictionary).size()
		if kind_count > best_kinds or (kind_count == best_kinds
				and counts[tri] > best_count):
			best_kinds = kind_count
			best_count = counts[tri]
			best = tri
	return best


func _rebuild_scatter_grid(subdivisions: int) -> void:
	_scatter_grid_mesh.clear_surfaces()
	var cs := STUDY_CELL_SIZE
	_scatter_grid_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(subdivisions + 1):
		var t := float(i) / float(subdivisions)
		_scatter_grid_mesh.surface_add_vertex(Vector3(t * cs.x, _scatter_plane_y, 0.0))
		_scatter_grid_mesh.surface_add_vertex(Vector3(t * cs.x, _scatter_plane_y, cs.y))
		_scatter_grid_mesh.surface_add_vertex(Vector3(0.0, _scatter_plane_y, t * cs.y))
		_scatter_grid_mesh.surface_add_vertex(Vector3(cs.x, _scatter_plane_y, t * cs.y))
	_scatter_grid_mesh.surface_end()


## u가 (c−a)의 가중치, v가 (b−a)의 가중치다. 원래 점은 이렇게 돌아온다.
## (원본에도 같은 식이 들어 있다 — b·c가 뒤바뀌어 있던 것을 바로잡았다.)
static func _reconstruct(record: Dictionary) -> Vector3:
	var a: Vector3 = record["a"]
	var b: Vector3 = record["b"]
	var c: Vector3 = record["c"]
	var u: float = record["u"]
	var v: float = record["v"]
	return a * (1.0 - u - v) + c * u + b * v


func _rebuild_scatter_points(records: Array[Dictionary], stage: int) -> void:
	_scatter_counts = {}
	_scatter_drops_mesh.clear_surfaces()
	_scatter_focus = {}

	var multi := _scatter_markers.multimesh
	# 올리는 스텝부터는 점 하나가 둘로 보인다 — 평면 위 자리와 표면 위 자리.
	var per_point := 2 if stage >= SCATTER_LIFT else 1
	multi.instance_count = records.size() * per_point

	# 앞 세 스텝은 점 하나에만 매달린다. 뿌린 격자와 나머지 점은 이 이야기와
	# 상관이 없어서 오히려 방해가 된다.
	if stage == SCATTER_QUESTION or stage == SCATTER_ONE or stage == SCATTER_HEIGHT:
		var only := (_pick_sloped_focus_index(records) if stage == SCATTER_HEIGHT
				else _pick_focus_index(records))
		_scatter_grid.visible = false
		multi.instance_count = 0 if only < 0 else 2
		if only >= 0:
			_scatter_focus = records[only]
			var sampled: Vector2 = _scatter_focus["sampled"]
			var flat_point := Vector3(sampled.x, _scatter_plane_y, sampled.y)
			var landed := _reconstruct(_scatter_focus)
			# 바닥에 찍힌 x·z 와, 그게 표면에서 만나는 자리.
			multi.set_instance_transform(0, Transform3D(
					Basis.from_scale(Vector3.ONE * 1.2), flat_point))
			multi.set_instance_color(0, Color(0.75, 0.79, 0.88))
			multi.set_instance_transform(1, Transform3D(
					Basis.from_scale(Vector3.ONE * 1.5), landed))
			multi.set_instance_color(1, Color(0.97, 0.98, 1.0))
			if stage == SCATTER_QUESTION:
				_draw_scatter_lines([{"from": flat_point, "to": landed,
						"color": Color(1.0, 0.86, 0.35), "alpha": 0.9}])
		_sync_decomposition(stage)
		return

	if stage == SCATTER_EDGES:
		# 이 단계의 점은 "가져간 결과"가 아니라 "대 본 결과"라서 다른 목록을 쓴다.
		# _rebuild_edge_test가 이어서 채운다.
		_scatter_grid.visible = false
		return
	# 후보를 뿌리는 스텝과 올리는 스텝에서만 나눈 칸을 보여 준다.
	_scatter_grid.visible = stage == SCATTER_FLAT or stage == SCATTER_LIFT

	var focus_index := -1
	var lines: Array[Dictionary] = []
	var slot := 0
	for record_index in range(records.size()):
		var record := records[record_index]
		var verdict: int = record["verdict"]
		_scatter_counts[verdict] = _scatter_counts.get(verdict, 0) + 1
		var sampled: Vector2 = record["sampled"]
		var flat := Vector3(sampled.x, _scatter_plane_y, sampled.y)

		var color := Color(0.90, 0.93, 0.98)
		if stage >= SCATTER_VERDICT:
			color = VERDICT_COLORS[verdict]

		# 그 스텝은 점 하나에만 집중한다. 나머지는 흐리게 깔아 둔다.
		var focused := focus_index < 0 or record_index == focus_index

		multi.set_instance_transform(slot, Transform3D(
				Basis.from_scale(Vector3.ONE * (1.0 if focused else 0.55)), flat))
		multi.set_instance_color(slot, Color(color, 1.0 if focused else 0.35))
		slot += 1

		if stage < SCATTER_LIFT:
			continue

		# 벽 위에 떨어진 점은 가져간 삼각형이 없어 표면 좌표 자체가 없다.
		if record["tri"] < 0:
			for _extra in range(per_point - 1):
				multi.set_instance_transform(slot,
						Transform3D(Basis.from_scale(Vector3.ZERO), flat))
				multi.set_instance_color(slot, color)
				slot += 1
			continue

		# u·v 로 되돌린 자리 — x·z 는 그대로고 y 만 삼각형을 따라간다.
		var lifted := _reconstruct(record)
		multi.set_instance_transform(slot, Transform3D(
				Basis.from_scale(Vector3.ONE * 1.35), lifted))
		multi.set_instance_color(slot, color)
		slot += 1
		lines.append({"from": flat, "to": lifted, "color": color, "alpha": 0.95})

	_draw_scatter_lines(lines)
	_sync_decomposition(stage)


## 높이 스텝 전용. 세 꼭짓점의 높이 차가 가장 큰 삼각형을 고른다 — 평평한 단을
## 고르면 화살표가 하나도 오르지 않아 "경사를 탄다"는 말이 그림에 없다.
func _pick_sloped_focus_index(records: Array[Dictionary]) -> int:
	var best := -1
	var best_score := -1.0
	for i in range(records.size()):
		var record := records[i]
		if record["tri"] < 0:
			continue
		var a: Vector3 = record["a"]
		var b: Vector3 = record["b"]
		var c: Vector3 = record["c"]
		var spread: float = maxf(maxf(a.y, b.y), c.y) - minf(minf(a.y, b.y), c.y)
		var u: float = record["u"]
		var v: float = record["v"]
		var depth: float = minf(minf(u, v), 1.0 - u - v)
		var score := spread * (0.25 + depth)
		if score > best_score:
			best_score = score
			best = i
	return best


## 화살표 둘이 또렷하게 보일 점을 고른다. 모서리에 바짝 붙은 점은 한쪽 화살표가
## 점으로 뭉개지고, 납작한 삼각형은 통째로 선처럼 보인다. 둘 다 피한다.
## 주인공 삼각형 하나에 후보를 전부 대 본 결과를 그린다. 통과한 점과, 세 부등호
## 중 어디서 떨어진 점인지를 색으로 나눈다 — 떨어진 점들이 각각 어느 변 바깥에
## 모이는지가 곧 "부등호 = 변"의 증거다.
func _rebuild_edge_test(tests: Array[Dictionary]) -> void:
	_scatter_test_counts = {}
	_scatter_drops_mesh.clear_surfaces()
	var mine: Array[Dictionary] = []
	for test in tests:
		if test["tri"] == _focus_tri:
			mine.append(test)

	var multi := _scatter_markers.multimesh
	multi.instance_count = mine.size()
	if mine.is_empty():
		_sync_decomposition(SCATTER_EDGES)
		return

	_scatter_focus = mine[0]
	# 점은 바닥에 찍힌 x·z 그대로 둔다. 판정은 위에서 내려다본 평면 문제다.
	var plane_y: float = (mine[0]["a"] as Vector3).y + 0.03
	for i in range(mine.size()):
		var outcome: int = mine[i]["outcome"]
		_scatter_test_counts[outcome] = _scatter_test_counts.get(outcome, 0) + 1
		var point: Vector2 = mine[i]["point"]
		multi.set_instance_transform(i, Transform3D(
				Basis.from_scale(Vector3.ONE * (1.4 if outcome == 0 else 1.0)),
				Vector3(point.x, plane_y, point.y)))
		multi.set_instance_color(i, TEST_COLORS[outcome])
	_sync_decomposition(SCATTER_EDGES)


func edge_test_summary() -> String:
	var parts := PackedStringArray()
	for outcome in range(TEST_NAMES.size()):
		if _scatter_test_counts.has(outcome):
			parts.append("%s %d" % [TEST_NAMES[outcome], _scatter_test_counts[outcome]])
	if parts.is_empty():
		return ""
	return "이 삼각형에 대 본 점 — " + " · ".join(parts)


func _pick_focus_index(records: Array[Dictionary]) -> int:
	var best := -1
	var best_score := -1.0
	for i in range(records.size()):
		var record := records[i]
		if record["tri"] < 0:
			continue
		var u: float = record["u"]
		var v: float = record["v"]
		var a: Vector3 = record["a"]
		var b: Vector3 = record["b"]
		var c: Vector3 = record["c"]
		var area: float = (c - a).cross(b - a).length() * 0.5
		var depth: float = minf(minf(u, v), 1.0 - u - v)
		var score := depth * sqrt(maxf(area, 0.0))
		if score > best_score:
			best_score = score
			best = i
	return best


func _draw_scatter_lines(lines: Array[Dictionary]) -> void:
	if lines.is_empty():
		return
	_scatter_drops_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for line in lines:
		var color: Color = line["color"]
		var alpha: float = line["alpha"]
		_scatter_drops_mesh.surface_set_color(Color(color, alpha * 0.25))
		_scatter_drops_mesh.surface_add_vertex(line["from"])
		_scatter_drops_mesh.surface_set_color(Color(color, alpha))
		_scatter_drops_mesh.surface_add_vertex(line["to"])
	_scatter_drops_mesh.surface_end()


## 주인공 삼각형과, 그 위에서 u·v가 무엇인지를 그린다.
##   SCATTER_QUESTION 삼각형 없이 "y = ?" 만
##   SCATTER_ONE      삼각형 + 화살표 둘 + u·v 글자
##   SCATTER_EDGES    삼각형 + 변마다 걸리는 부등호 글자
func _sync_decomposition(stage: int) -> void:
	var has_focus := not _scatter_focus.is_empty()
	var show_tri := has_focus and (stage == SCATTER_ONE or stage == SCATTER_EDGES
			or stage == SCATTER_HEIGHT)
	var show_arrows := has_focus and stage == SCATTER_ONE
	var show_edges := has_focus and stage == SCATTER_EDGES
	var show_height := has_focus and stage == SCATTER_HEIGHT
	for label in _scatter_height_labels:
		label.visible = show_height

	_scatter_tri.visible = show_tri
	_scatter_arrow_u.visible = show_arrows
	_scatter_arrow_v.visible = show_arrows
	_scatter_u_label.visible = show_arrows
	_scatter_v_label.visible = show_arrows
	for label in _scatter_corner_labels:
		label.visible = show_tri
	for label in _scatter_edge_labels:
		label.visible = show_edges
	_scatter_question_label.visible = has_focus and stage == SCATTER_QUESTION

	if has_focus and stage == SCATTER_QUESTION:
		_scatter_question_label.position = (_reconstruct(_scatter_focus)
				+ Vector3(0.0, 0.75, 0.0))
	if not show_tri:
		_scatter_tri_mesh.clear_surfaces()
		return

	var a: Vector3 = _scatter_focus["a"]
	var b: Vector3 = _scatter_focus["b"]
	var c: Vector3 = _scatter_focus["c"]
	var u: float = _scatter_focus["u"]
	var v: float = _scatter_focus["v"]

	var lift := Vector3(0.0, 0.02, 0.0)
	_scatter_tri_mesh.clear_surfaces()
	_scatter_tri_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in [a, b, c]:
		_scatter_tri_mesh.surface_add_vertex(vertex + lift)
	_scatter_tri_mesh.surface_end()

	# 라벨을 꼭짓점 바로 위에 두면 a 라벨이 화살표 출발점을 덮는다.
	# 삼각형 무게중심 반대쪽으로 조금 밀어 낸다.
	var corners: Array[Vector3] = [a, b, c]
	var centroid := (a + b + c) / 3.0
	for i in range(3):
		var outward := corners[i] - centroid
		outward.y = 0.0
		if outward.length() > 0.001:
			outward = outward.normalized() * 0.42
		_scatter_corner_labels[i].position = (corners[i] + outward
				+ Vector3(0.0, 0.45, 0.0))

	var mid := a + (c - a) * u
	var target := mid + (b - a) * v

	if show_edges:
		# u는 (c−a)의 몫이다. 그러니 u = 0 은 c 쪽으로 하나도 안 간 자리, 곧 ab 변이다.
		# 같은 식으로 v = 0 은 ac 변, u+v = 1 은 bc 변이 된다.
		var edges := [
			{"from": a, "to": b, "text": "u = 0"},
			{"from": a, "to": c, "text": "v = 0"},
			{"from": b, "to": c, "text": "u + v = 1"},
		]
		for i in range(3):
			var midpoint: Vector3 = (edges[i]["from"] + edges[i]["to"]) * 0.5
			var outward := midpoint - centroid
			outward.y = 0.0
			if outward.length() > 0.001:
				outward = outward.normalized() * 0.85
			_scatter_edge_labels[i].text = edges[i]["text"]
			_scatter_edge_labels[i].position = midpoint + outward + Vector3(0.0, 0.3, 0.0)
		return

	# a ──u·(c−a)──▶ 중간점 ──v·(b−a)──▶ 원래 점
	_scatter_arrow_u = _rebuild_arrow(_scatter_arrow_u, ARROW_U_COLOR, a, mid)
	_scatter_arrow_v = _rebuild_arrow(_scatter_arrow_v, ARROW_V_COLOR, mid, target)
	# 화살표 중간에 글자를 얹는다. 이 그림의 주인공이 u와 v라는 걸 그림만 봐도
	# 알 수 있어야 한다.
	_scatter_u_label.position = (a + mid) * 0.5 + Vector3(0.0, 0.42, 0.0)
	_scatter_v_label.position = (mid + target) * 0.5 + Vector3(0.0, 0.42, 0.0)

	if not show_height:
		return
	# 왜 u·v로 섞으면 높이가 나오는가: 삼각형이 평평하기 때문이다. 세 꼭짓점
	# 높이가 정해지면 그 안쪽 높이는 따라 정해진다 — 삼각형 면이 곧 "맞는 높이"의
	# 집합이다. 꼭짓점 셋과 점, 넷에 기둥을 세우면 점 기둥 끝이 그 면에 닿는다.
	var base_y: float = minf(minf(a.y, b.y), c.y) - 1.6
	var stops: Array[Vector3] = [a, b, c, target]
	var guides: Array[Dictionary] = []
	for i in range(4):
		var stop := stops[i]
		var foot := Vector3(stop.x, base_y, stop.z)
		var is_point := i == 3
		guides.append({"from": foot, "to": stop,
				"color": Color(1.0, 0.90, 0.55) if is_point else Color(0.70, 0.76, 0.88),
				"alpha": 0.95 if is_point else 0.45})
		_scatter_height_labels[i].text = "y %.2f" % stop.y
		_scatter_height_labels[i].modulate = (Color(1.0, 0.90, 0.55) if is_point
				else Color(0.78, 0.83, 0.92))
		_scatter_height_labels[i].position = foot.lerp(stop, 0.5) + Vector3(0.0, 0.0, 0.55)
	_draw_scatter_lines(guides)


## DiagramKit.aim()이 basis를 통째로 갈아 끼워 scale이 날아간다. 그래서 길이를
## 나중에 곱하지 않고 화살표를 그 길이로 새로 짓는다.
func _rebuild_arrow(old: Node3D, color: Color, from: Vector3, to: Vector3) -> Node3D:
	if is_instance_valid(old):
		old.queue_free()
	var delta := to - from
	var length := delta.length()
	# DiagramKit은 머리 높이를 radius*7.5로 잡는다. 굵기를 고정하면 짧은 화살표가
	# 머리만 남아 방향이 안 읽히므로 길이에 맞춰 줄인다.
	var radius: float = clampf(length * 0.055, 0.022, 0.075)
	var arrow := DiagramKit.arrow(DiagramKit.flat_material(color),
			maxf(length, 0.02), radius)
	_scatter.add_child(arrow)
	arrow.position = from
	if length >= 0.001:
		DiagramKit.aim(arrow, delta / length)
	else:
		arrow.visible = false
	return arrow


## 5장 5번 스텝의 산수를 그대로 적어 준다. 그림의 기둥 셋과 숫자가 맞아야 한다.
## 주인공 삼각형의 무게중심. 카메라가 셀 전체가 아니라 그 삼각형을 보게 한다.
func scatter_focus_center() -> Vector3:
	if _scatter_focus.is_empty():
		return Vector3(STUDY_CELL_SIZE.x, 0.0, STUDY_CELL_SIZE.y) * 0.5
	return ((_scatter_focus["a"] as Vector3) + (_scatter_focus["b"] as Vector3)
			+ (_scatter_focus["c"] as Vector3)) / 3.0


func height_summary() -> String:
	if _scatter_focus.is_empty():
		return ""
	var a: Vector3 = _scatter_focus["a"]
	var b: Vector3 = _scatter_focus["b"]
	var c: Vector3 = _scatter_focus["c"]
	var u: float = _scatter_focus["u"]
	var v: float = _scatter_focus["v"]
	return "y = %.2f + %.2f×%.2f + %.2f×%.2f = %.2f" % [
		a.y, u, c.y - a.y, v, b.y - a.y,
		a.y + u * (c.y - a.y) + v * (b.y - a.y)]


func scatter_focus() -> Dictionary:
	return _scatter_focus


func scatter_counts() -> Dictionary:
	return _scatter_counts


func scatter_summary() -> String:
	var total := 0
	for key in _scatter_counts:
		total += _scatter_counts[key]
	var parts := PackedStringArray()
	for verdict in range(VERDICT_NAMES.size()):
		if _scatter_counts.has(verdict):
			parts.append("%s %d" % [VERDICT_NAMES[verdict], _scatter_counts[verdict]])
	return "후보 %d개 — %s" % [total, " · ".join(parts)]


func set_scatter_visible(on: bool) -> void:
	if _scatter:
		_scatter.visible = on


## 20×20 셀마다 실제로 심긴 풀 수를 그림 한 장으로 만든다. 옆 칸에 띄워 두면
## 지도의 빈 자리와 3D의 절벽·마스크가 같은 모양이라는 게 눈에 들어온다.
func planted_map_texture() -> ImageTexture:
	var dim := chunk.dimensions
	var cells_x := dim.x - 1
	var cells_z := dim.z - 1
	var per_cell := terrain.grass_subdivisions * terrain.grass_subdivisions

	var planter := chunk.grass_planter
	planter.debug_begin()
	chunk.regenerate_all_cells()
	var records := planter.debug_points.duplicate()
	planter.debug_end()

	var counts := PackedInt32Array()
	counts.resize(cells_x * cells_z)
	for record in records:
		if record["verdict"] != 0:
			continue
		var pos: Vector3 = record["pos"]
		var cx := clampi(int(pos.x / CELL_SIZE.x), 0, cells_x - 1)
		var cz := clampi(int(pos.z / CELL_SIZE.y), 0, cells_z - 1)
		counts[cz * cells_x + cx] += 1

	var image := Image.create_empty(cells_x, cells_z, false, Image.FORMAT_RGB8)
	for z in range(cells_z):
		for x in range(cells_x):
			var ratio := float(counts[z * cells_x + x]) / float(maxi(per_cell, 1))
			image.set_pixel(x, z, Color(0.10, 0.12, 0.16).lerp(
					Color(0.55, 0.95, 0.40), clampf(ratio, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)

#endregion

#region 다이어그램 손잡이

func set_corner_markers(on: bool) -> void:
	for marker in _corner_markers:
		marker.visible = on


func set_edge_bars(on: bool) -> void:
	for bar in _edge_bars:
		bar.visible = on


func set_wireframe(on: bool) -> void:
	_wire.visible = on


## 셀 하나가 뱉은 삼각형의 변을 선으로 긋는다. 케이스가 어떤 조각으로
## 짜였는지 보려면 삼각형 경계가 보여야 한다.
func _rebuild_wire(target: MarchingSquaresTerrainChunk, cell: Vector2i) -> void:
	_wire_mesh.clear_surfaces()
	if not target.cell_geometry.has(cell):
		return
	var verts: PackedVector3Array = target.cell_geometry[cell]["verts"]
	if verts.is_empty():
		return
	_wire_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var lift := Vector3(0.0, 0.012, 0.0)
	for i in range(0, verts.size() - 2, 3):
		for e in range(3):
			_wire_mesh.surface_add_vertex(verts[i + e] + lift)
			_wire_mesh.surface_add_vertex(verts[i + (e + 1) % 3] + lift)
	_wire_mesh.surface_end()

#endregion
