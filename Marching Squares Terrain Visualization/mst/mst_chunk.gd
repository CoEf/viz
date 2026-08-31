class_name MarchingSquaresTerrainChunk
extends MeshInstance3D
## 청크 하나. 원본 `marching_squares_terrain_chunk.gd`에서 에디터 저장·언두리도·
## 콜리전·GLB 굽기를 걷어내고, 메시를 짓는 경로만 남겼다.
##
## 남긴 것은 전부 원본과 같은 이름·같은 순서다. 특히 이 세 가지는 챕터의 주제라
## 한 줄도 바꾸지 않았다.
##   - `needs_update[z][x]`  더러운 셀 표시
##   - `cell_geometry`       안 더러운 셀을 다시 계산하지 않고 꺼내 쓰는 캐시
##   - `add_polygons`        바닥/벽에 따라 smooth_group을 갈아 끼우는 자리

enum Mode {CUBIC, POLYHEDRON, ROUNDED_POLYHEDRON, SEMI_ROUND, SPHERICAL}

const MERGE_MODE := {
	Mode.CUBIC: 0.6,
	Mode.POLYHEDRON: 1.3,
	Mode.ROUNDED_POLYHEDRON: 2.1,
	Mode.SEMI_ROUND: 5.0,
	Mode.SPHERICAL: 20.0,
}

var terrain_system: MstTerrain
var chunk_coords := Vector2i.ZERO

var merge_threshold: float = MERGE_MODE[Mode.POLYHEDRON]

var height_map: Array
var color_map_0: PackedColorArray
var color_map_1: PackedColorArray
var wall_color_map_0: PackedColorArray
var wall_color_map_1: PackedColorArray
var grass_mask_map: PackedColorArray

var grass_planter: MarchingSquaresGrassPlanter
var global_position_cached := Vector3.ZERO

var st: SurfaceTool
var cell_geometry: Dictionary = {}
var needs_update: Array[Array] = []

# 원본의 블렌드 구간. 높이가 섞이는 띠의 위/아래 경계다.
var lower_thresh := 0.3
var upper_thresh := 0.7
var blend_zone := upper_thresh - lower_thresh

## 마지막 regenerate에서 실제로 다시 계산한 셀 수와 캐시에서 꺼낸 셀 수.
## 6장(갱신 파이프라인)이 이 두 숫자를 화면에 띄운다.
var last_rebuilt_cells := 0
var last_cached_cells := 0
## 마지막 regenerate에 걸린 밀리초.
var last_rebuild_msec := 0
## 마지막으로 계산한 셀이 고른 케이스 번호. 셀이 하나뿐인 연구대에서 쓴다.
var last_cell_case := -1
## 이번 재생성에서 실제로 다시 계산한 칸 목록. 7장이 그걸 지형 위에 칠한다.
var last_dirty_cells: Array[Vector2i] = []

## 워크스루 전용. 풀 심기는 셀마다 삼각형 안쪽 판정을 도는 탓에 재생성 비용의
## 대부분을 차지한다. 풀이 안 보이는 스텝에서는 꺼서 슬라이더가 끊기지 않게 한다.
var grass_enabled := true

var dimensions: Vector3i:
	get:
		return terrain_system.dimensions

var cell_size: Vector2:
	get:
		return terrain_system.cell_size


func initialize_terrain() -> void:
	needs_update = []
	for z in range(dimensions.z - 1):
		needs_update.append([])
		for x in range(dimensions.x - 1):
			needs_update[z].append(true)

	if not height_map:
		generate_height_map()
	if not color_map_0 or not color_map_1:
		generate_color_maps()
	if not wall_color_map_0 or not wall_color_map_1:
		generate_wall_color_maps()
	if not grass_mask_map:
		generate_grass_mask_map()

	if not grass_planter:
		grass_planter = MarchingSquaresGrassPlanter.new()
		grass_planter.name = "GrassPlanter"
		add_child(grass_planter)
	grass_planter._chunk = self
	grass_planter.setup(self)


func regenerate_mesh() -> void:
	var start_time := Time.get_ticks_msec()
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	st.set_custom_format(1, SurfaceTool.CUSTOM_RGBA_FLOAT)
	st.set_custom_format(2, SurfaceTool.CUSTOM_RGBA_FLOAT)

	generate_terrain_cells()

	st.generate_normals()
	st.index()
	mesh = st.commit()

	if mesh and terrain_system:
		mesh.surface_set_material(0, terrain_system.terrain_material)
	last_rebuild_msec = Time.get_ticks_msec() - start_time


func generate_terrain_cells() -> void:
	if not cell_geometry:
		cell_geometry = {}

	global_position_cached = global_position if is_inside_tree() else position
	last_rebuilt_cells = 0
	last_cached_cells = 0
	last_dirty_cells.clear()

	for z in range(dimensions.z - 1):
		for x in range(dimensions.x - 1):
			var cell_coords := Vector2i(x, z)
			# 높이가 그대로인 셀은 지난번 삼각형을 그대로 다시 흘려 넣는다.
			if not needs_update[z][x] and cell_geometry.has(cell_coords):
				last_cached_cells += 1
				_replay_cached_cell(cell_coords)
				continue

			needs_update[z][x] = false
			last_rebuilt_cells += 1
			last_dirty_cells.append(cell_coords)

			cell_geometry[cell_coords] = {
				"verts": PackedVector3Array(),
				"uvs": PackedVector2Array(),
				"uv2s": PackedVector2Array(),
				"color_0s": PackedColorArray(),
				"color_1s": PackedColorArray(),
				"custom_1_values": PackedColorArray(),
				"mat_blend": PackedColorArray(),
				"is_floor": [],
			}

			var color_helper := MarchingSquaresTerrainVertexColorHelper.new()
			var cell := MarchingSquaresTerrainCell.new(
					self, color_helper,
					height_map[z][x], height_map[z][x + 1],
					height_map[z + 1][x], height_map[z + 1][x + 1],
					merge_threshold)
			color_helper.chunk = self
			color_helper.cell = cell

			cell.generate_geometry(cell_coords)
			last_cell_case = cell.last_case
			if grass_enabled and grass_planter and grass_planter.terrain_system:
				grass_planter.generate_grass_on_cell(cell_coords)

			# cell 과 color_helper 가 서로를 붙들고 있어 RefCounted 순환이 된다.
			# 에디터에서 한 번 굽고 마는 원본에서는 넘어가지만, 슬라이더로 셀
			# 400개를 매번 다시 짓는 여기서는 그대로 쌓인다. 다 쓴 뒤 끊어 준다.
			cell.color_helper = null
			color_helper.cell = null


func _replay_cached_cell(cell_coords: Vector2i) -> void:
	var cached: Dictionary = cell_geometry[cell_coords]
	var verts: PackedVector3Array = cached["verts"]
	var uvs: PackedVector2Array = cached["uvs"]
	var uv2s: PackedVector2Array = cached["uv2s"]
	var color_0s: PackedColorArray = cached["color_0s"]
	var color_1s: PackedColorArray = cached["color_1s"]
	var custom_1_values: PackedColorArray = cached["custom_1_values"]
	var mat_blend: PackedColorArray = cached["mat_blend"]
	var is_floor: Array = cached["is_floor"]

	for i in range(verts.size()):
		st.set_smooth_group(0 if is_floor[i] == true else -1)
		st.set_uv(uvs[i])
		st.set_uv2(uv2s[i])
		st.set_color(color_0s[i])
		st.set_custom(0, color_1s[i])
		st.set_custom(1, custom_1_values[i])
		st.set_custom(2, mat_blend[i])
		st.add_vertex(verts[i])


func add_polygons(
		cell_coords: Vector2i,
		pts: PackedVector3Array,
		uvs: PackedVector2Array,
		uv2s: PackedVector2Array,
		color_0s: PackedColorArray,
		color_1s: PackedColorArray,
		custom_1_values: PackedColorArray,
		mat_blends: PackedColorArray,
		floors: PackedByteArray) -> void:
	var floor_mode := true
	st.set_smooth_group(0)
	for i in range(pts.size()):
		if floor_mode and not floors[i]:
			floor_mode = false
			st.set_smooth_group(-1)
		elif not floor_mode and floors[i]:
			floor_mode = true
			st.set_smooth_group(0)
		_add_point(cell_coords, pts[i], uvs[i], uv2s[i], color_0s[i], color_1s[i],
				custom_1_values[i], mat_blends[i], floors[i])


func _add_point(cell_coords: Vector2i, vert: Vector3, uv: Vector2, uv2: Vector2,
		color_0: Color, color_1: Color, custom_1_value: Color, mat_blend: Color,
		is_floor: bool) -> void:
	st.set_color(color_0)
	st.set_custom(0, color_1)
	st.set_custom(1, custom_1_value)
	st.set_custom(2, mat_blend)
	st.set_uv(uv)
	st.set_uv2(uv2)
	st.add_vertex(vert)

	cell_geometry[cell_coords]["verts"].append(vert)
	cell_geometry[cell_coords]["uvs"].append(uv)
	cell_geometry[cell_coords]["uv2s"].append(uv2)
	cell_geometry[cell_coords]["color_0s"].append(color_0)
	cell_geometry[cell_coords]["color_1s"].append(color_1)
	cell_geometry[cell_coords]["custom_1_values"].append(custom_1_value)
	cell_geometry[cell_coords]["mat_blend"].append(mat_blend)
	cell_geometry[cell_coords]["is_floor"].append(is_floor)

#region 맵 생성

func generate_height_map() -> void:
	height_map = []
	height_map.resize(dimensions.z)
	for z in range(dimensions.z):
		height_map[z] = []
		height_map[z].resize(dimensions.x)
		for x in range(dimensions.x):
			height_map[z][x] = 0.0


func generate_color_maps() -> void:
	color_map_0 = PackedColorArray()
	color_map_1 = PackedColorArray()
	color_map_0.resize(dimensions.z * dimensions.x)
	color_map_1.resize(dimensions.z * dimensions.x)
	for i in range(dimensions.z * dimensions.x):
		color_map_0[i] = Color(1, 0, 0, 0)
		color_map_1[i] = Color(1, 0, 0, 0)


func generate_wall_color_maps() -> void:
	wall_color_map_0 = PackedColorArray()
	wall_color_map_1 = PackedColorArray()
	wall_color_map_0.resize(dimensions.z * dimensions.x)
	wall_color_map_1.resize(dimensions.z * dimensions.x)
	for i in range(dimensions.z * dimensions.x):
		wall_color_map_0[i] = Color(1, 0, 0, 0)
		wall_color_map_1[i] = Color(1, 0, 0, 0)


func generate_grass_mask_map() -> void:
	grass_mask_map = PackedColorArray()
	grass_mask_map.resize(dimensions.z * dimensions.x)
	for i in range(dimensions.z * dimensions.x):
		grass_mask_map[i] = Color(1.0, 1.0, 1.0, 1.0)

#endregion

#region 읽기

func get_height(cc: Vector2i) -> float:
	return height_map[cc.y][cc.x]


func get_color_0(cc: Vector2i) -> Color:
	return color_map_0[cc.y * dimensions.x + cc.x]


func get_color_1(cc: Vector2i) -> Color:
	return color_map_1[cc.y * dimensions.x + cc.x]


func get_wall_color_0(cc: Vector2i) -> Color:
	return wall_color_map_0[cc.y * dimensions.x + cc.x]


func get_wall_color_1(cc: Vector2i) -> Color:
	return wall_color_map_1[cc.y * dimensions.x + cc.x]


func get_grass_mask(cc: Vector2i) -> Color:
	return grass_mask_map[cc.y * dimensions.x + cc.x]

#endregion

#region 쓰기 — 꼭짓점 하나를 고치면 그 꼭짓점을 쓰는 셀 네 개가 더러워진다

func draw_height(x: int, z: int, y: float) -> void:
	height_map[z][x] = y
	notify_needs_update(z, x)
	notify_needs_update(z, x - 1)
	notify_needs_update(z - 1, x)
	notify_needs_update(z - 1, x - 1)


func draw_color_0(x: int, z: int, color: Color) -> void:
	color_map_0[z * dimensions.x + x] = color
	_dirty_around(x, z)


func draw_color_1(x: int, z: int, color: Color) -> void:
	color_map_1[z * dimensions.x + x] = color
	_dirty_around(x, z)


func draw_wall_color_0(x: int, z: int, color: Color) -> void:
	wall_color_map_0[z * dimensions.x + x] = color
	_dirty_around(x, z)


func draw_wall_color_1(x: int, z: int, color: Color) -> void:
	wall_color_map_1[z * dimensions.x + x] = color
	_dirty_around(x, z)


func draw_grass_mask(x: int, z: int, masked: Color) -> void:
	grass_mask_map[z * dimensions.x + x] = masked
	_dirty_around(x, z)


func _dirty_around(x: int, z: int) -> void:
	notify_needs_update(z, x)
	notify_needs_update(z, x - 1)
	notify_needs_update(z - 1, x)
	notify_needs_update(z - 1, x - 1)


func notify_needs_update(z: int, x: int) -> void:
	if z < 0 or z >= dimensions.z - 1 or x < 0 or x >= dimensions.x - 1:
		return
	needs_update[z][x] = true


func mark_all_dirty() -> void:
	for z in range(dimensions.z - 1):
		for x in range(dimensions.x - 1):
			needs_update[z][x] = true


func regenerate_all_cells() -> void:
	mark_all_dirty()
	regenerate_mesh()

#endregion
