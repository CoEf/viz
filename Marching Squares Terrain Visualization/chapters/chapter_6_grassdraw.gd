extends MstChapter
## 챕터 6 — 심을 자리를 고르고, 심은 풀을 그리고 흔든다.
##
## 5장이 "자리를 어떻게 구하나"였다면 여기는 "그중 무엇을 심고 어떻게 그리나"다.
## 무엇을 걸러내고(UV·마스크·텍스처), 무엇을 실어 보내고(인스턴스 색),
## 어떻게 세워서(빌보드) 어떻게 흔드는가(바람·fps).

const STEPS: Array[Dictionary] = [
	{
		"title": "셀 400칸에서 같은 판정 되풀이하기",
		"body": """옆 칸 지도는 셀마다 [b]실제로 심긴 풀 수[/b]다.
검은 자리와 3D의 절벽·구덩이가 같은 모양이다.
셀 하나짜리 규칙이 그대로 지형 전체를 칠한다.""",
		"chips": [{"icon": "texture", "text": "셀별 심은 수 지도"}],
		"code": """for z in range(dimensions.z-1):
    for x in range(dimensions.x-1):
        generate_grass_on_cell(Vector2i(x, z))""",
		"try": "분할을 올리면 지도가 통째로 밝아진다",
	},
	{
		"title": "절벽에 붙은 점은 UV 값을 보고 버린다",
		"body": """절벽 모서리에 풀이 반쯤 박히면 보기 싫다.
그래서 3장이 정점 UV에 적어 둔 절벽까지의 가까움을 읽어,
[b]0을 넘으면 능선, 0.5를 넘으면 선반으로 보고 버린다.[/b]""",
		"chips": [
			{"icon": "script", "text": "cell.add_point() UV"},
			{"icon": "script", "text": "generate_grass_on_cell()"},
		],
		"code": """var on_ledge_or_ridge :=
    uv.y > 0.0 or uv.x > 0.5""",
		"try": "절벽 위아래 한 줄이 통째로 비어 있다",
	},
	{
		"title": "마스크 맵으로 심을 자리 지우기",
		"body": """마스크는 꼭짓점마다 색 하나로 들고 있다.
[b]빨강이 1보다 조금이라도 작으면[/b] 그 자리는 건너뛴다.
초록은 반대다 — 텍스처 규칙을 무시하고 강제로 심는다.""",
		"chips": [
			{"icon": "script", "text": "chunk.grass_mask_map"},
			{"icon": "script", "text": "draw_grass_mask()"},
		],
		"code": """var is_masked := mask.r < 0.9999
var force_grass_on := mask.g >= 0.9999""",
		"try": "마스크를 켜면 지도 가운데에 구멍이 뚫린다",
	},
	{
		"title": "텍스처 칸마다 풀 여부 따로 두기",
		"body": """0번 칸(풀)은 언제나 심는다.
1~5번은 [b]칸마다 달린 스위치[/b]가 정하고,
6번부터는 아예 심지 않는다 — 열여섯 칸 중 여섯만 후보다.""",
		"chips": [
			{"icon": "script", "text": "_has_grass_for_texture()"},
			{"icon": "setting", "text": "tex2_has_grass"},
		],
		"code": """if texture_id == 1: return true
if texture_id < 2 or texture_id > 6: return false
return has_grass_flags[texture_id - 2]""",
		"try": "흙 칸을 켜면 언덕 중턱 띠에 풀이 돋는다",
	},
	{
		"title": "MultiMesh 한 벌에 인스턴스로 담기",
		"body": """풀잎마다 노드를 만들지 않는다.
[b]인스턴스 한 칸에 변환과 색을 써 넣을 뿐이다.[/b]
칸 수는 셀 수 × 분할² 로 미리 고정해 둔다.""",
		"chips": [
			{"icon": "node3d", "text": "MultiMeshInstance3D"},
			{"icon": "script", "text": "setup()"},
		],
		"code": """multimesh.instance_count =
    (dim.x-1) * (dim.z-1) * subdiv * subdiv""",
		"try": "지도가 어두워도 인스턴스 칸 수는 그대로다",
	},
	{
		"title": "인스턴스 색에 지형 색 실어 보내기",
		"body": """풀 색은 셰이더 상수가 아니다.
심는 자리의 [b]지형 텍스처를 픽셀로 읽어[/b] 실어 보낸다.
그래서 흙 위 풀과 잔디 위 풀의 색이 다르다.""",
		"chips": [
			{"icon": "script", "text": "set_instance_custom_data()"},
			{"icon": "shader", "text": "INSTANCE_CUSTOM"},
		],
		"code": """instance_color.a = _get_grass_alpha(texture_id)
set_instance_custom_data(index, instance_color)""",
		"try": "알파 칸에는 색이 아니라 텍스처 번호가 들어 있다",
	},
	{
		"title": "빌보드로 카메라를 향해 세우기",
		"body": """풀은 사각형 한 장이다. 옆에서 보면 종잇장이 된다.
그래서 [b]카메라 축 세 개로 기저를 새로 짜[/b] 정점에 곱한다.
POSITION을 직접 써서 원래 모델 행렬을 건너뛴다.""",
		"chips": [{"icon": "shader", "text": "mst_grass.gdshader vertex()"}],
		"code": """vec3 cam_x = normalize(cross(cam_y, cam_z));
mat3 bb = mat3(cam_x, cam_y, cam_z);
POSITION = PROJECTION_MATRIX * VIEW_MATRIX * ...""",
		"try": "빌보드를 끄고 화면을 돌려 보기 — 풀이 사라진다",
	},
	{
		"title": "바람 노이즈로 끝만 눕히기",
		"body": """노이즈 텍스처를 시간만큼 밀어 읽어 좌우로 민다.
미는 양에 [b]VERTEX.y를 곱해[/b] 뿌리는 붙들고 끝만 눕힌다.
읽는 좌표가 x와 z가 아니라 x와 높이(y)다.""",
		"chips": [
			{"icon": "texture", "text": "wind_texture"},
			{"icon": "shader", "text": "wind_speed · wind_scale"},
		],
		"code": """float bend = clamp(VERTEX.y, 0.0, 1.0);
VERTEX += vec3(wind, 0.0, 0.0) * bend;""",
		"try": "속도를 0으로 내리면 풀이 그 자리에 굳는다",
	},
	{
		"title": "fps를 올려 톡톡 튀게 바꾸기",
		"body": """fps가 0보다 크면 바람 쪽 길을 아예 안 탄다.
시간을 [b]fps 단위로 잘라 계단으로 만들고[/b],
인스턴스마다 다른 씨앗을 줘 서로 어긋나게 흔든다.""",
		"chips": [{"icon": "setting", "text": "animation_fps"}],
		"code": """float quantized_time =
    floor(TIME * fps * time_offset) / fps;
VERTEX.x += sin(quantized_time) * 0.2;""",
		"try": "fps를 올릴수록 딱딱 끊기는 픽셀아트식 움직임이 된다",
	},
]

var _subdivisions := 3
var _masked := false
var _dirt_grass := false
var _billboard := true
var _wind_speed := 0.14
var _fps := 0.0
var _map_view: TextureRect
var _map_caption: Label


func get_chapter_title() -> String:
	return "풀을 고르고 흔들기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_stage_terrain()
	world.set_scatter_visible(false)
	world.set_corner_markers(false)
	world.set_edge_bars(false)
	world.set_wireframe(false)
	world.set_terrain_visible(true)
	world.set_ridge_ledge_enabled(true)
	world.set_debug_mode(0)
	world.set_merge_threshold(1.3)
	world.sculpt_to(4)
	world.set_grass_visible(true)
	world.set_grass_mask_patch(_masked)
	# 색 비교 스텝은 흙 칸에도 풀을 심어 둔다. 잔디 위 풀과 흙 위 풀이 한 화면에
	# 같이 있어야 "지형 색을 물려받는다"가 보인다.
	world.set_dirt_has_grass(_dirt_grass or index == 5)
	world.set_grass_subdivisions(_subdivisions)
	world.set_grass_billboard(_billboard if index >= 6 else true)
	world.set_grass_wind_speed(_wind_speed if index == 7 else 0.14)
	world.set_grass_wind_fps(_fps if index == 8 else 0.0)

	if index == 1:
		# 절벽 하나를 바짝 잡는다. 위아래로 한 줄씩 비어 있는 게 보여야 한다.
		world.set_pivot(Vector3(26.0, 1.6, 14.0))
		world.camera_rig.set_view(0.88, -0.34, 13.0)
	elif index <= 4:
		world.set_pivot(Vector3(20.0, 1.0, 20.0))
		world.camera_rig.set_view(0.0, -1.30, 46.0)
		_refresh_map()
	elif index == 5:
		# 흙 띠(높이 1.0~2.4)가 잔디를 두르는 언덕. 두 색이 한눈에 붙어 있다.
		world.set_pivot(Vector3(28.0, 1.4, 27.0))
		world.camera_rig.set_view(0.95, -0.34, 15.0)
	else:
		world.set_pivot(Vector3(26.0, 0.9, 12.0))
		world.camera_rig.set_view(1.05, -0.16, 6.0)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "grass_subdivisions", 1.0, 5.0, float(_subdivisions),
			func(value: float) -> void:
				_subdivisions = int(round(value))
				world.set_grass_subdivisions(_subdivisions)
				_refresh_map(),
			[0, 4])
	add_toggle(parent, "마스크로 가운데 지우기", _masked,
			func(pressed: bool) -> void:
				_masked = pressed
				world.set_grass_mask_patch(pressed)
				_refresh_map(),
			[2])
	add_toggle(parent, "흙 칸에도 풀 심기 (tex2_has_grass)", _dirt_grass,
			func(pressed: bool) -> void:
				_dirt_grass = pressed
				world.set_dirt_has_grass(pressed)
				_refresh_map(),
			[3])
	add_toggle(parent, "빌보드 켜기", _billboard,
			func(pressed: bool) -> void:
				_billboard = pressed
				world.set_grass_billboard(pressed),
			[6])
	add_slider(parent, "wind_speed", 0.0, 1.0, _wind_speed,
			func(value: float) -> void:
				_wind_speed = value
				world.set_grass_wind_speed(value),
			[7])
	add_slider(parent, "animation_fps", 0.0, 20.0, _fps,
			func(value: float) -> void:
				_fps = value
				world.set_grass_wind_fps(value),
			[8])

	_map_view = TextureRect.new()
	_map_view.custom_minimum_size = Vector2(0.0, 240.0)
	_map_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# 셀 한 칸이 픽셀 한 개다. 보간하면 격자가 뭉개져 지도로 읽히지 않는다.
	_map_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(_map_view)
	_map_caption = add_caption(parent, "", [0, 2, 3, 4])
	bind_steps([_map_view], [0, 2, 3, 4])

	add_caption(parent, "풀 스프라이트 여섯 장은 텍스처 칸 0~5번에 짝지어 있다.",
			[5, 6])


func _refresh_map() -> void:
	if not _map_view or current_step > 4:
		return
	_map_view.texture = world.planted_map_texture()
	var cells := (world.terrain.dimensions.x - 1) * (world.terrain.dimensions.z - 1)
	_map_caption.text = "셀 %d칸 · 인스턴스 %d칸 — 밝을수록 그 칸에 심긴 풀이 많다" % [
		cells, cells * _subdivisions * _subdivisions]
