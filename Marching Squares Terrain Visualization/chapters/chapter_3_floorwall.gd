extends MstChapter
## 챕터 3 — 같은 메시 안에서 바닥과 벽을 가르고, 그 경계를 UV에 적어 셰이더에 넘긴다.

const STEPS: Array[Dictionary] = [
	{
		"title": "바닥과 벽은 칠하는 법이 달라야 한다",
		"body": """벽은 수직이라 바닥과 같은 방식으로 칠하면 늘어난다.
그런데 셀은 둘을 한 메시에 같이 넣는다.
그래서 [b]법선이 위를 보는지[/b] 하나로 갈라 다른 길로 보낸다.""",
		"chips": [{"icon": "shader", "text": "mst_terrain.gdshaderinc"}],
		"code": """bool is_floor = dot(vertex_normal,
    vec3(0.0, 1.0, 0.0)) > wall_threshold;""",
		"try": "청록 = 바닥, 주황 = 벽",
	},
	{
		"title": "스무딩 그룹을 갈아 끼워 모서리 세우기",
		"body": """바닥은 0번 그룹, 벽은 -1.
[b]-1은 그 정점을 아무와도 안 합친다.[/b]
그래서 절벽 모서리가 뭉개지지 않고 각진다.""",
		"chips": [
			{"icon": "script", "text": "chunk.add_polygons()"},
			{"icon": "setting", "text": "SurfaceTool.set_smooth_group"},
		],
		"code": """if floor_mode and not floors[i]:
    floor_mode = false
    st.set_smooth_group(-1)""",
		"try": "벽마다 색이 뚝 끊긴다 — 법선이 안 섞였다는 뜻",
	},
	{
		"title": "UV에 절벽까지의 가까움 적어 두기",
		"body": """바닥 정점의 UV는 텍스처 좌표가 아니다.
x는 선반까지, y는 능선까지의 가까움.
[b]벽 정점은 무조건 (1,1)로 박는다.[/b]""",
		"chips": [{"icon": "script", "text": "cell.add_point()"}],
		"code": """var uv := Vector2(u, v) if floor_mode
        else Vector2(1, 1)""",
		"try": "빨강이 선반 쪽, 초록이 능선 쪽 — 벽은 둘 다 켜져 노랗다",
	},
	{
		"title": "그 UV를 잘라 벽 텍스처를 바닥에 흘리기",
		"body": """셰이더가 UV를 문턱으로 자른다.
잘려 나온 띠에만 [b]가장 가까운 벽 텍스처[/b]를
덧칠해, 절벽 색이 위로 이어져 보이게 한다.""",
		"chips": [
			{"icon": "shader", "text": "ridge_threshold"},
			{"icon": "shader", "text": "nearest_wall_color_idx"},
		],
		"code": """float f = step(ridge_threshold,
    max(UV.x, UV.y));""",
		"try": "문턱을 내리면 절벽 색이 바닥으로 번진다",
	},
	{
		"title": "노이즈를 문턱에 더해 경계 흐트리기",
		"body": """문턱이 일정하면 띠가 자로 잰 듯 나온다.
[b]월드 좌표에서 뽑은 노이즈를 문턱에 더해[/b]
가장자리를 들쭉날쭉하게 만든다.""",
		"chips": [{"icon": "texture", "text": "rl_noise_texture"}],
		"code": """float nv = (blend_noise - 0.5)
    * rl_noise_strength;
step(ridge_threshold + nv, max(UV.x, UV.y))""",
		"try": "세기를 올리면 띠 가장자리가 너덜해진다",
	},
]

var _ridge := 0.55
var _noise := 4.0


func get_chapter_title() -> String:
	return "바닥과 벽 가르기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_stage_terrain()
	world.set_merge_threshold(1.3)
	world.set_grass_visible(false)
	world.set_corner_markers(false)
	world.set_edge_bars(false)
	world.set_wireframe(false)
	world.set_terrain_visible(true)
	world.sculpt_to(4)
	# 능선·선반 띠는 절벽 가장자리 한 줄이라 멀리서는 안 보인다. 그 두 스텝만
	# 바짝 붙는다.
	if index >= 3:
		world.set_pivot(Vector3(14.0, 3.0, 14.0))
		world.camera_rig.set_view(0.92, -0.40, 18.0)
	else:
		world.set_pivot(Vector3(20.0, 1.0, 20.0))
		world.camera_rig.set_view(0.86, -0.34, 34.0)

	match index:
		0:
			world.set_debug_mode(1)
			world.set_ridge_ledge_enabled(false)
		1:
			world.set_debug_mode(5)
			world.set_ridge_ledge_enabled(false)
		2:
			world.set_debug_mode(2)
			world.set_ridge_ledge_enabled(false)
		3:
			world.set_debug_mode(0)
			world.set_ridge_ledge_enabled(true)
			world.set_ridge_threshold(_ridge)
			world.set_ledge_threshold(_ridge)
			world.set_rl_noise_strength(0.0)
			update_code(_ridge_code())
		4:
			world.set_debug_mode(0)
			world.set_ridge_ledge_enabled(true)
			world.set_ridge_threshold(_ridge)
			world.set_ledge_threshold(_ridge)
			world.set_rl_noise_strength(_noise)
			update_code(_noise_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "ridge / ledge 문턱", 0.0, 1.0, _ridge,
			func(value: float) -> void:
				_ridge = value
				world.set_ridge_threshold(value)
				world.set_ledge_threshold(value)
				update_code(_ridge_code() if current_step == 3 else _noise_code()),
			[3, 4])
	add_slider(parent, "노이즈 세기", 0.0, 10.0, _noise,
			func(value: float) -> void:
				_noise = value
				world.set_rl_noise_strength(value)
				update_code(_noise_code()),
			[4])
	add_caption(parent, "문턱 1.0 = 아무 데도 안 번진다. 0에 가까울수록 넓게 번진다.",
			[3, 4])


func _ridge_code() -> String:
	return ("float f = step(%.2f,\n" % _ridge
			+ "    max(UV.x, UV.y));  // ← 슬라이더")


func _noise_code() -> String:
	return ("float nv = (blend_noise - 0.5)\n"
			+ "    * %.1f;  // ← 슬라이더\n" % _noise
			+ "step(%.2f + nv, max(UV.x, UV.y))" % _ridge)
