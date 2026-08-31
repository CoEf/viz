extends MstChapter
## 챕터 7 — 지휘자. 무엇을 고치면 무엇이 다시 도는가.
##
## "더러운 칸" 이야기는 숫자만 보면 와닿지 않는다. 그래서 스텝마다 다시 계산한
## 칸을 지형 위에 주황으로 덧칠한다 — 어디가 돌았는지가 곧 이 장의 내용이다.

const STEPS: Array[Dictionary] = [
	{
		"title": "꼭짓점 하나는 셀 네 개가 나눠 쓴다",
		"body": """격자 교차점 하나에 셀 네 칸의 모서리가 모인다.
그래서 높이 한 칸을 고치면 그 자리만으로 끝나지 않고
[b]칸 네 개의 모양이 같이 달라진다.[/b]""",
		"chips": [{"icon": "script", "text": "chunk.draw_height()"}],
		"code": """notify_needs_update(z, x)
notify_needs_update(z, x-1)
notify_needs_update(z-1, x)   # 그리고 z-1, x-1""",
		"try": "주황 네 칸이 한 교차점을 둘러싸고 있다",
	},
	{
		"title": "그 넷에만 다시 계산 표시를 남긴다",
		"body": """고칠 때 바로 굽지 않는다. [b]불 표시만 켜 둔다.[/b]
굽는 건 나중에 한꺼번에 하고, 그때 표시를 보고
누구를 다시 돌릴지 정한다.""",
		"chips": [{"icon": "script", "text": "needs_update[z][x]"}],
		"code": """func notify_needs_update(z: int, x: int):
    needs_update[z][x] = true""",
		"try": "표시만 켰을 뿐 화면은 아직 그대로다",
	},
	{
		"title": "표시 없는 칸은 캐시에서 그대로 꺼낸다",
		"body": """칸마다 지난번 정점 배열을 통째로 들고 있다.
표시가 없으면 알고리즘을 다시 돌리지 않고
[b]그 배열을 SurfaceTool에 도로 흘려 넣는다.[/b]""",
		"chips": [{"icon": "script", "text": "chunk.cell_geometry"}],
		"code": """if not needs_update[z][x]:
    # 캐시의 verts를 그대로 다시 넣는다
    st.add_vertex(verts[i])""",
		"try": "아무 데도 안 칠해졌다 — 400칸 전부 캐시에서 나왔다",
	},
	{
		"title": "버튼을 눌러 꼭짓점 하나를 올려 본다",
		"body": """가운데 꼭짓점 하나를 0.6 올리고 다시 굽는다.
[b]400칸 중 네 칸만 주황으로 칠해진다.[/b]
나머지 396칸은 캐시에서 그대로 나온다.""",
		"chips": [{"icon": "script", "text": "chunk.regenerate_mesh()"}],
		"code": """chunk.draw_height(x, z, y + 0.6)
chunk.regenerate_mesh()""",
		"try": "버튼을 누를 때마다 같은 네 칸만 다시 돈다",
	},
	{
		"title": "전체를 다시 굽는 값은 따로 있다",
		"body": """merge_threshold는 [b]모든 칸의 판정을 바꾼다.[/b]
그래서 건드리는 순간 표시를 전부 세우고
400칸이 다 다시 돈다 — 화면이 통째로 주황이 된다.""",
		"chips": [
			{"icon": "script", "text": "regenerate_all_cells()"},
			{"icon": "setting", "text": "merge_mode setter"},
		],
		"code": """for z in range(dimensions.z-1):
    for x in range(dimensions.x-1):
        needs_update[z][x] = true""",
		"try": "문턱을 조금만 움직여도 전부 다시 돈다",
	},
	{
		"title": "한 방향으로 흐르는 다섯 단계를 되짚는다",
		"body": """높이맵 → 셀 → 정점 속성 → 셰이더 → 풀.
[b]되돌아가는 화살표가 없다.[/b]
그래서 앞 단계만 고치면 뒤는 알아서 따라온다.""",
		"chips": [
			{"icon": "script", "text": "height_map → Cell"},
			{"icon": "shader", "text": "COLOR·CUSTOM0~2 → mst_terrain"},
			{"icon": "node3d", "text": "cell_geometry → GrassPlanter"},
		],
		"try": "풀은 셀이 만든 삼각형을 다시 읽는다 — 두 번째 소비자다",
	},
]

## 화면 한가운데 꼭짓점. 스텝 1·2·4가 같은 자리를 가리켜야 이야기가 이어진다.
const PROBE := Vector2i(10, 10)

var _threshold := 1.3
var _stats: Label


func get_chapter_title() -> String:
	return "고친 데만 다시 굽기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_stage_terrain()
	world.set_scatter_visible(false)
	world.set_grass_visible(index == 5)
	world.set_corner_markers(false)
	world.set_edge_bars(false)
	world.set_wireframe(false)
	world.set_terrain_visible(true)
	world.set_ridge_ledge_enabled(true)
	world.set_merge_threshold(_threshold)
	world.sculpt_to(4)
	world.set_debug_mode(6 if index <= 3 else 0)
	world.hide_dirty_cells()

	match index:
		0, 1:
			# 교차점 하나를 둘러싼 네 칸. 아직 굽지 않았고 표시만 한 상태다.
			world.show_dirty_cells(world.cells_touching_vertex(PROBE.x, PROBE.y))
			world.set_pivot(Vector3(PROBE.x * 2.0, 1.0, PROBE.y * 2.0))
			world.camera_rig.set_view(0.30, -0.95, 24.0)
		2:
			# 아무것도 안 고치고 한 번 더 굽는다 → 다시 돈 칸이 0이다.
			world.rebuild_dirty_only()
			world.set_pivot(Vector3(20.0, 1.0, 20.0))
			world.camera_rig.set_view(0.36, -0.92, 40.0)
		3:
			world.set_pivot(Vector3(20.0, 1.0, 20.0))
			world.camera_rig.set_view(0.36, -0.92, 40.0)
		4:
			world.rebuild()
			world.show_dirty_cells()
			world.set_pivot(Vector3(20.0, 1.0, 20.0))
			world.camera_rig.set_view(0.36, -0.92, 44.0)
		5:
			world.set_pivot(Vector3(20.0, 1.0, 20.0))
			world.camera_rig.set_view(0.72, -0.38, 50.0)
	_sync_stats()


func build_panel(parent: VBoxContainer) -> void:
	var button := Button.new()
	button.text = "가운데 꼭짓점 0.6 올리기"
	button.pressed.connect(func() -> void:
		world.bump_one_vertex(0.6)
		world.show_dirty_cells()
		_sync_stats())
	parent.add_child(button)
	bind_steps([button], [3])

	add_slider(parent, "merge_threshold", 0.4, 3.0, _threshold,
			func(value: float) -> void:
				_threshold = value
				world.set_merge_threshold(value)
				world.rebuild()
				world.show_dirty_cells()
				_sync_stats(),
			[4])

	_stats = add_caption(parent, "", [2, 3, 4])


func _sync_stats() -> void:
	if not _stats:
		return
	var stats := world.rebuild_stats()
	_stats.text = "마지막 재생성 — 다시 계산 %d칸 · 캐시 %d칸 · %dms" % [
		stats["rebuilt"], stats["cached"], stats["msec"]]
