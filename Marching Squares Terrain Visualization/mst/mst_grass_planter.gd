extends MultiMeshInstance3D
class_name MarchingSquaresGrassPlanter


# Alpha values for grass sprites by texture ID (1-6)
const GRASS_ALPHA_VALUES := [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]

var _chunk : MarchingSquaresTerrainChunk
var terrain_system : MstTerrain

## 워크스루 전용 계측. 후보 점 하나하나가 어떤 판정을 받았는지 밖에서 읽으려고 붙였다.
## debug_record가 꺼져 있으면 아무것도 쌓이지 않고, 알고리즘은 이 배열을 읽지 않는다.
enum {VERDICT_PLANTED, VERDICT_RIDGE, VERDICT_MASKED, VERDICT_TEXTURE, VERDICT_WALL}

## 삼각형 하나에 점 하나를 대 본 결과. 통과한 것과 떨어진 것을 다 남긴다.
## 어느 부등호에서 떨어졌는지가 5장 "세 조건이 곧 세 변이다" 그림의 재료다.
enum {TEST_INSIDE, TEST_U_NEG, TEST_V_NEG, TEST_SUM_OVER}

var debug_record := false
var debug_points : Array[Dictionary] = []
var debug_tests : Array[Dictionary] = []


func _record_test(point: Vector2, tri: int, u: float, v: float, outcome: int,
		a: Vector3, b: Vector3, c: Vector3) -> void:
	if debug_record:
		debug_tests.append({
			"point": point, "tri": tri, "u": u, "v": v, "outcome": outcome,
			"a": a, "b": b, "c": c,
		})


## 후보 점 하나가 어떤 삼각형에 어떤 u·v로 걸렸고 어디에 심겼는지를 통째로 남긴다.
##   sampled  흩뿌린 원래 2차원 좌표
##   pos      코드가 무게중심으로 되돌린 자리
##   tri      가져간 삼각형의 첫 정점 인덱스 (삼각형 식별용)
##   a b c    그 삼각형의 세 꼭짓점
##   u v      구해진 무게중심 가중치
## 5장이 이 전부를 그림으로 쓴다.
func _record(p: Vector3, sampled: Vector2, verdict: int,
		tri := -1, a := Vector3.ZERO, b := Vector3.ZERO, c := Vector3.ZERO,
		u := 0.0, v := 0.0) -> void:
	if debug_record:
		debug_points.append({
			"pos": p, "sampled": sampled, "verdict": verdict,
			"tri": tri, "a": a, "b": b, "c": c, "u": u, "v": v,
		})


## 다음 재생성부터 판정을 기록한다. 쌓인 기록은 비운다.
func debug_begin() -> void:
	debug_record = true
	debug_points.clear()
	debug_tests.clear()


func debug_end() -> void:
	debug_record = false
	debug_points.clear()
	debug_tests.clear()


func setup(chunk: MarchingSquaresTerrainChunk, redo: bool = true):
	_chunk = chunk
	terrain_system = _chunk.terrain_system
	
	if not _chunk or not terrain_system:
		push_error("SETUP FAILED - no chunk or terrain system found for GrassPlanter")
		return
	
	if (redo and multimesh) or !multimesh:
		multimesh = MultiMesh.new()
	multimesh.instance_count = 0
	
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.instance_count = (_chunk.dimensions.x-1) * (_chunk.dimensions.z-1) * terrain_system.grass_subdivisions * terrain_system.grass_subdivisions
	if terrain_system.grass_mesh:
		multimesh.mesh = terrain_system.grass_mesh
	else:
		multimesh.mesh = QuadMesh.new() # Create a temporary quad
	multimesh.mesh.size = terrain_system.grass_size * (terrain_system.cell_size.x + terrain_system.cell_size.y) / 4.0
	
	cast_shadow = SHADOW_CASTING_SETTING_OFF


func regenerate_all_cells() -> void:
	# Safety checks
	if not _chunk:
		push_error("_chunk not set while regenerating cells")
		return
	
	if not terrain_system:
		push_error("terrain_system not set while regenerating cells")
		return
	
	if not multimesh:
		setup(_chunk)
	
	if not _chunk.cell_geometry:
		_chunk.regenerate_mesh()
	
	for z in range(terrain_system.dimensions.z-1):
		for x in range(terrain_system.dimensions.x-1):
			generate_grass_on_cell(Vector2i(x, z))


func generate_grass_on_cell(cell_coords: Vector2i) -> void:
	# Safety checks
	if not _chunk:
		push_error("Couldn't find a reference to _chunk")
		return
	
	if not terrain_system:
		push_error("Couldn't find a reference to terrain_system")
		return
	
	if not _chunk.cell_geometry:
		push_error("Couldn't find a reference to cell_geometry")
		return
	
	if not _chunk.cell_geometry.has(cell_coords):
		push_error("Couldn't find a reference to cell_coords")
		return
	
	var cell_geometry = _chunk.cell_geometry[cell_coords]
	
	if not cell_geometry.has("verts") or not cell_geometry.has("uvs") or not cell_geometry.has("color_0s") or not cell_geometry.has("color_1s") or not cell_geometry.has("custom_1_values") or not cell_geometry.has("is_floor"):
		push_error("cell_geometry doesn't have one of the following required data: 1) verts, 2) uvs, 3) colors, 4) custom_1_values, 5) is_floor")
		return
	
	var points : PackedVector2Array = []
	var count = terrain_system.grass_subdivisions * terrain_system.grass_subdivisions
	
	for z in range(terrain_system.grass_subdivisions):
		for x in range(terrain_system.grass_subdivisions):
			points.append(Vector2(
				(cell_coords.x + (x + randf_range(0, 1)) / terrain_system.grass_subdivisions) * terrain_system.cell_size.x,
				(cell_coords.y + (z + randf_range(0, 1)) / terrain_system.grass_subdivisions) * terrain_system.cell_size.y
			))
	
	var index : int = (cell_coords.y * (_chunk.dimensions.x-1) + cell_coords.x) * count
	var end_index : int = index + count
	
	var verts : PackedVector3Array = cell_geometry["verts"]
	var uvs : PackedVector2Array = cell_geometry["uvs"]
	var color_0s : PackedColorArray = cell_geometry["color_0s"]
	var color_1s : PackedColorArray = cell_geometry["color_1s"]
	var custom_1_values : PackedColorArray = cell_geometry["custom_1_values"]
	var is_floor : Array = cell_geometry["is_floor"]
	
	for i in range(0, len(verts), 3):
		if i+2 >= len(verts):
			continue # Skip incomplete triangle
		# Only place grass on floors
		if not is_floor[i]:
			continue
		
		var a := verts[i]
		var b := verts[i+1]
		var c := verts[i+2]
		
		var v0 := Vector2(c.x - a.x, c.z - a.z)
		var v1 := Vector2(b.x - a.x, b.z - a.z)
		
		var dot00 := v0.dot(v0)
		var dot01 := v0.dot(v1)
		var dot11 := v1.dot(v1)
		var invDenom := 1.0/(dot00 * dot11 - dot01 * dot01)
		
		var point_index := 0
		while (point_index < len(points)):
			var v2 = Vector2(points[point_index].x - a.x, points[point_index].y - a.z)
			var dot02 := v0.dot(v2)
			var dot12 := v1.dot(v2)
			
			var u := (dot11 * dot02 - dot01 * dot12) * invDenom
			if u < 0:
				# 워크스루 전용: v는 아직 계산도 안 했다. u 하나로 벌써 탈락이다.
				_record_test(points[point_index], i, u, NAN, TEST_U_NEG, a, b, c)
				point_index += 1
				continue
			
			var v := (dot00 * dot12 - dot01 * dot02) * invDenom
			if v < 0:
				_record_test(points[point_index], i, u, v, TEST_V_NEG, a, b, c)
				point_index += 1
				continue
			
			if u + v <= 1:
				# 워크스루 전용: 목록에서 지워지기 전에 원래 후보 좌표를 붙든다.
				var sampled := points[point_index] if debug_record else Vector2.ZERO
				_record_test(sampled, i, u, v, TEST_INSIDE, a, b, c)
				# Point is inside triangle, won't be inside any other floor triangle
				points.remove_at(point_index)
				var p := a*(1-u-v) + c*u + b*v
				
				# Don't place grass on ledges or ridges
				var uv := uvs[i]*(1-u-v) + uvs[i+1]*v + uvs[i+2]*u
				var on_ledge_or_ridge : bool = uv.y > 0.0 or uv.x > 0.5
				
				var color_0 := MarchingSquaresTerrainVertexColorHelper.get_dominant_color(color_0s[i]*(1-u-v) + color_0s[i+1]*v + color_0s[i+2]*u)
				var color_1 := MarchingSquaresTerrainVertexColorHelper.get_dominant_color(color_1s[i]*(1-u-v) + color_1s[i+1]*v + color_1s[i+2]*u)
				
				# Check grass mask first - green channel forces grass ON, red channel masks grass OFF
				var mask := custom_1_values[i]*(1-u-v) + custom_1_values[i+1]*v + custom_1_values[i+2]*u
				var is_masked : bool = mask.r < 0.9999
				var force_grass_on : bool = mask.g >= 0.9999  # Preset override: force grass regardless of texture
				
				var texture_id := _get_texture_id(color_0, color_1)
				var on_grass_tex := _has_grass_for_texture(texture_id, force_grass_on)
				
				if on_grass_tex and not on_ledge_or_ridge and not is_masked:
					_create_grass_instance(index, p, a, b, c, texture_id)
					_record(p, sampled, VERDICT_PLANTED, i, a, b, c, u, v)
				else:
					_hide_grass_instance(index)
					if is_masked:
						_record(p, sampled, VERDICT_MASKED, i, a, b, c, u, v)
					elif on_ledge_or_ridge:
						_record(p, sampled, VERDICT_RIDGE, i, a, b, c, u, v)
					else:
						_record(p, sampled, VERDICT_TEXTURE, i, a, b, c, u, v)
				index += 1
			else:
				_record_test(points[point_index], i, u, v, TEST_SUM_OVER, a, b, c)
				point_index += 1

	# 워크스루 전용. 여기까지 남은 후보는 어느 바닥 삼각형도 가져가지 않은 점들이다.
	# 벽 삼각형 위에 떨어졌다는 뜻 — 벽은 애초에 위 루프가 건너뛴다.
	if debug_record:
		for leftover in points:
			_record(Vector3(leftover.x, 0.0, leftover.y), leftover, VERDICT_WALL)

	# Fill remaining points with hidden instances
	while index < end_index:
		if index >= multimesh.instance_count:
			return
		_hide_grass_instance(index)
		index += 1

#region grass property getters

## 워크스루 전용 캐시. 원본은 풀잎 하나마다 get_image()+decompress()를 새로 부르는데,
## 에디터에서 한 번 심을 때는 넘어가도 슬라이더로 매번 다시 심는 여기서는 못 버틴다.
## 돌려주는 이미지는 같으므로 결과는 원본과 동일하다.
var _terrain_image_cache: Dictionary = {}


func _get_terrain_image(texture_id: int) -> Image:
	if _terrain_image_cache.has(texture_id):
		return _terrain_image_cache[texture_id]
	var img_cached := _load_terrain_image(texture_id)
	_terrain_image_cache[texture_id] = img_cached
	return img_cached


func _load_terrain_image(texture_id: int) -> Image:
	var terrain_texture : Texture2D = null
	var material := terrain_system.terrain_material
	match texture_id:
		2:
			terrain_texture = material.get_shader_parameter("vc_tex_rg")
		3:
			terrain_texture = material.get_shader_parameter("vc_tex_rb")
		4:
			terrain_texture = material.get_shader_parameter("vc_tex_ra")
		5:
			terrain_texture = material.get_shader_parameter("vc_tex_gr")
		6:
			terrain_texture = material.get_shader_parameter("vc_tex_gg")
		_: # Base grass
			terrain_texture = material.get_shader_parameter("vc_tex_rr")
	if terrain_texture == null:
		return null
	
	var img : Image = terrain_texture.get_image()
	if img:
		img.decompress()
	return img


func _get_texture_id(vc_col_0: Color, vc_col_1: Color) -> int:
	var id : int = 1;
	if vc_col_0.r > 0.9999:
		if vc_col_1.r > 0.9999:
			id = 1;
		elif vc_col_1.g > 0.9999:
			id = 2;
		elif vc_col_1.b > 0.9999:
			id = 3;
		elif vc_col_1.a > 0.9999:
			id = 4;
	elif vc_col_0.g > 0.9999:
		if vc_col_1.r > 0.9999:
			id = 5;
		elif vc_col_1.g > 0.9999:
			id = 6;
		elif vc_col_1.b > 0.9999:
			id = 7;
		elif vc_col_1.a > 0.9999:
			id = 8;
	elif vc_col_0.b > 0.9999:
		if vc_col_1.r > 0.9999:
			id = 9;
		elif vc_col_1.g > 0.9999:
			id = 10;
		elif vc_col_1.b > 0.9999:
			id = 11;
		elif vc_col_1.a > 0.9999:
			id = 12;
	elif vc_col_0.a > 0.9999:
		if vc_col_1.r > 0.9999:
			id = 13;
		elif vc_col_1.g > 0.9999:
			id = 14;
		elif vc_col_1.b > 0.9999:
			id = 15;
		elif vc_col_1.a > 0.9999:
			id = 16;
	return id;


## Checks if the given texture ID should have grass placed on it.
func _has_grass_for_texture(texture_id: int, force_grass_on: bool) -> bool:
	if force_grass_on:
		return true
	if texture_id == 1:
		return true  # Base grass always has grass
	if texture_id < 2 or texture_id > 6:
		return false
	
	# Data-driven lookup instead of match
	var has_grass_flags := [
		terrain_system.tex2_has_grass,
		terrain_system.tex3_has_grass,
		terrain_system.tex4_has_grass,
		terrain_system.tex5_has_grass,
		terrain_system.tex6_has_grass
	]
	return has_grass_flags[texture_id - 2]


## Gets the texture scale for the given texture ID.
func _get_texture_scale(texture_id: int) -> float:
	var scales := [
		terrain_system.texture_scale_1,
		terrain_system.texture_scale_2,
		terrain_system.texture_scale_3,
		terrain_system.texture_scale_4,
		terrain_system.texture_scale_5,
		terrain_system.texture_scale_6
	]
	var idx := clampi(texture_id - 1, 0, 5)
	return scales[idx]


## Gets the grass sprite alpha value for the given texture ID.
func _get_grass_alpha(texture_id: int) -> float:
	var idx := clampi(texture_id - 1, 0, 5)
	return GRASS_ALPHA_VALUES[idx]


## Samples the terrain texture color at the given world position.
func _sample_terrain_texture_color(world_pos: Vector3, texture_id: int, tex_scale: float) -> Color:
	var terrain_image := _get_terrain_image(texture_id)
	if not terrain_image:
		return Color.WHITE
	
	var uv_x : float = clamp(world_pos.x / ((terrain_system.dimensions.x - 1) * terrain_system.cell_size.x), 0.0, 1.0)
	var uv_y : float = clamp(world_pos.z / ((terrain_system.dimensions.z - 1) * terrain_system.cell_size.y), 0.0, 1.0)
	
	uv_x = abs(fmod(uv_x * tex_scale, 1.0))
	uv_y = abs(fmod(uv_y * tex_scale, 1.0))
	
	var px := int(uv_x * (terrain_image.get_width() - 1))
	var py := int(uv_y * (terrain_image.get_height() - 1))
	var color := terrain_image.get_pixelv(Vector2(px, py))
	if _format_needs_conversion(terrain_image.get_format()):
		return color.srgb_to_linear()
	return color


func _format_needs_conversion(fmt: Image.Format) -> bool:
	match(fmt):
		Image.FORMAT_RGB8, \
		Image.FORMAT_RGBA8, \
		Image.FORMAT_DXT1, \
		Image.FORMAT_DXT3, \
		Image.FORMAT_DXT5, \
		Image.FORMAT_BPTC_RGBA, \
		Image.FORMAT_ETC2_RGB8 , \
		Image.FORMAT_ETC2_RGBA8 , \
		Image.FORMAT_ETC2_RGB8A1 : return true
	return false

#endregion

#region grass placement helpers

## Creates a grass instance at the given position with proper transform and color.
func _create_grass_instance(index: int, world_pos: Vector3, a: Vector3, b: Vector3, c: Vector3, texture_id: int) -> void:
	var edge1 := b - a
	var edge2 := c - a
	var normal := edge1.cross(edge2).normalized()
	
	var right := Vector3.FORWARD.cross(normal).normalized()
	var forward := normal.cross(Vector3.RIGHT).normalized()
	var instance_basis := Basis(right, forward, -normal)
	
	multimesh.set_instance_transform(index, Transform3D(instance_basis, world_pos))
	multimesh.mesh.center_offset.y = multimesh.mesh.size.y / 2
	
	var tex_scale := _get_texture_scale(texture_id)
	var instance_color := _sample_terrain_texture_color(world_pos, texture_id, tex_scale)
	instance_color.a = _get_grass_alpha(texture_id)
	
	multimesh.set_instance_custom_data(index, instance_color)


## Hides a grass instance by scaling it to zero.
func _hide_grass_instance(index: int) -> void:
	multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))

#endregion
