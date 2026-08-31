extends MstChapter
## 챕터 5 — 풀 한 포기를 어디에 세울지 정하는 과정.
##
## 순서는 목적 → 방법이다. 먼저 "높이를 몰라서 막힌다"는 문제를 세우고,
## 그다음에 무게중심 좌표가 그 문제를 어떻게 푸는지 본다.
## 점의 자리·색·판정은 이쪽에서 다시 계산한 게 아니라, 원본
## `generate_grass_on_cell()`이 돌면서 남긴 기록 그대로다.

const STEPS: Array[Dictionary] = [
	{
		"title": "셀 한 칸에 후보 점 뿌리기",
		"body": """셀을 subdivisions×subdivisions로 나누고
칸마다 무작위로 점 하나를 찍는다.
[b]바닥에 찍은 x, z뿐이다 — 높이는 아직 없다.[/b]""",
		"chips": [{"icon": "script", "text": "generate_grass_on_cell()"}],
		"code": """(cell.x + (x + randf_range(0, 1))
    / grass_subdivisions) * cell_size.x""",
		"try": "분할을 올리면 격자 칸과 점이 같이 는다",
	},
	{
		"title": "풀을 세우려면 그 자리 높이를 알아야 한다",
		"body": """지형은 삼각형 조각을 이어 붙인 것이다.
점의 높이는 [b]그 점을 덮고 있는 삼각형이 정한다.[/b]
그래서 어느 삼각형인지부터 찾아야 한다.""",
		"chips": [{"icon": "script", "text": "cell_geometry[\"verts\"]"}],
		"try": "노란 선이 답을 모르는 채로 뻗어 있는 자리다",
	},
	{
		"title": "점을 꼭짓점 a에서 출발한 벡터로 적기",
		"body": """점을 [b]a에서 뻗은 두 모서리의 합[/b]으로 적는다.
그 계수 u, v를 무게중심 좌표라 한다.
이렇게 적어 두면 다음 두 가지가 공짜로 나온다.""",
		"chips": [{"icon": "script", "text": "무게중심 좌표"}],
		"code": """v0 = c - a
v1 = b - a
점 = a + u*v0 + v*v1""",
		"try": "주황이 u, 하늘색이 v — 둘을 이어 붙이면 점에 닿는다",
	},
	{
		"title": "첫째, 부등호 세 줄로 안팎이 갈린다",
		"body": """u = 0은 ab 변, v = 0은 ac 변, u + v = 1은 bc 변이다.
그래서 [b]부등호 세 줄이면 삼각형 안인지 판정된다.[/b]
선분 교차 같은 걸 따로 계산하지 않는다.""",
		"chips": [{"icon": "script", "text": "generate_grass_on_cell()"}],
		"code": """if u < 0: continue      # ab 변 바깥
if v < 0: continue      # ac 변 바깥
if u + v <= 1:          # bc 변 안쪽 → 이 삼각형""",
		"try": "떨어진 점이 전부 u + v = 1 변 바깥에 모여 있다",
	},
	{
		"title": "둘째, 같은 u와 v가 높이를 준다",
		"body": """삼각형은 평평하다. 그래서 꼭짓점 셋의 높이가 정해지면
그 안쪽 어느 자리의 높이도 따라 정해진다.
[b]u, v는 그 안쪽 어디인지를 가리키는 좌표다.[/b]""",
		"chips": [{"icon": "script", "text": "cell_geometry[\"verts\"]"}],
		"code": """y = a.y + u*(c.y - a.y) + v*(b.y - a.y)
#   = a*(1-u-v) + c*u + b*v 의 y 성분""",
		"try": "점 기둥의 끝이 삼각형 면에 정확히 닿는다",
	},
	{
		"title": "그래서 점을 삼각형 위로 올릴 수 있다",
		"body": """x, z는 이미 알고 있었고 y만 몰랐다.
그 y를 방금 구했으니 [b]점을 제자리에서 위로만 올리면 된다.[/b]
선이 곧게 서 있다 — 가로로는 한 칸도 움직이지 않는다.""",
		"chips": [{"icon": "script", "text": "generate_grass_on_cell()"}],
		"code": """var p := a*(1-u-v) + c*u + b*v
# 이 한 줄이 x, y, z 를 한꺼번에 낸다""",
		"try": "위층에 앉은 점과 아래층에 앉은 점 — 선 길이가 다르다",
	},
	{
		"title": "구한 자리에 풀을 세운다",
		"body": """초록 점이 있던 자리에 풀이 선다.
[b]후보가 다 풀이 되지는 않는다[/b] — 분홍은 걸러진 자리다.
무엇이 왜 거르는지는 다음 장에서 하나씩 켠다.""",
		"chips": [
			{"icon": "script", "text": "_create_grass_instance()"},
			{"icon": "node3d", "text": "MultiMeshInstance3D"},
		],
		"code": """_create_grass_instance(index, p, a, b, c,
        texture_id)""",
		"try": "초록 점마다 풀이 하나씩 서 있다",
	},
]

## 연구대 셀의 네 꼭짓점과 문턱값.
##
## 두 가지를 동시에 만족해야 한다.
##   - 바닥이 기울어 있을 것 — 5번 스텝은 삼각형 면이 기울어 있어야 성립한다.
##     (평평한 단만 있으면 기둥 넷의 키가 다 같아 보여 줄 게 없다)
##   - 절벽이 하나 있을 것 — 마지막 스텝에서 걸러지는 점이 나오려면 필요하다.
## ab·cd 차는 문턱 아래(이어짐 → 비탈), ac·bd 차는 문턱 위(끊김 → 벽)로 잡았다.
const STUDY_CORNERS := [2.6, 4.2, 0.0, 1.6]
const STUDY_THRESHOLD := 4.0

var _subdivisions := 5
var _caption: Label


func get_chapter_title() -> String:
	return "풀의 자리를 구하는 법"


func get_steps() -> Array[Dictionary]:
	return STEPS


func _stage_for(index: int) -> int:
	match index:
		0: return MstWorld.SCATTER_FLAT
		1: return MstWorld.SCATTER_QUESTION
		2: return MstWorld.SCATTER_ONE
		3: return MstWorld.SCATTER_EDGES
		4: return MstWorld.SCATTER_HEIGHT
		5: return MstWorld.SCATTER_LIFT
		_: return MstWorld.SCATTER_PLANT


func apply_step(index: int) -> void:
	world.set_stage_study()
	world.set_corner_markers(false)
	world.set_edge_bars(false)
	world.set_grass_visible(false)
	world.set_grass_billboard(true)
	world.set_grass_wind_fps(0.0)
	world.set_merge_threshold(STUDY_THRESHOLD)
	# 삼각형 하나를 강조하는 스텝은 일반 렌더로 둔다. 디버그 색(청록·주황)이
	# 화살표·판정 색과 부딪히기 때문이다.
	world.set_debug_mode(0 if index <= 4 else 1)
	world.set_wireframe(index >= 1)
	world.set_study_mesh_visible(index >= 1)
	world.scatter_study(_subdivisions, STUDY_CORNERS, _stage_for(index))

	match index:
		0:
			world.set_pivot(Vector3(3.0, -1.2, 3.0))
			world.camera_rig.set_view(0.0, -1.35, 13.0)
		1, 2:
			world.set_pivot(Vector3(3.0, 1.4, 3.0))
			world.camera_rig.set_view(0.55, -0.86, 12.0)
		3:
			# 판정은 위에서 내려다본 평면 문제다. 그 각도로 봐야 변과 점이 맞물린다.
			world.set_pivot(Vector3(3.0, 0.8, 3.0))
			world.camera_rig.set_view(0.0, -1.35, 12.0)
		4:
			# 높이 이야기는 옆에서 봐야 한다. 위에서 보면 오르내림이 안 보인다.
			# 셀 전체가 아니라 주인공 삼각형을 중심에 놓고 바짝 붙는다.
			world.set_pivot(world.scatter_focus_center() - Vector3(0.0, 0.5, 0.0))
			world.camera_rig.set_view(0.95, -0.30, 13.0)
		_:
			world.set_pivot(Vector3(3.0, 1.2, 3.0))
			world.camera_rig.set_view(0.62, -0.46, 16.0)
	_sync_caption()


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "grass_subdivisions", 1.0, 6.0, float(_subdivisions),
			func(value: float) -> void:
				_subdivisions = int(round(value))
				world.scatter_study(_subdivisions, STUDY_CORNERS,
						_stage_for(current_step))
				_sync_caption(),
			[0, 3, 5, 6])
	_caption = add_caption(parent, "")


func _sync_caption() -> void:
	if not _caption:
		return
	match current_step:
		1:
			_caption.text = "바닥의 x, z는 안다. 모르는 건 y 하나다."
		2:
			var focus := world.scatter_focus()
			if focus.is_empty():
				_caption.text = ""
				return
			var u: float = focus["u"]
			var v: float = focus["v"]
			_caption.text = "이 점 = a + %.2f·(c−a) + %.2f·(b−a)" % [u, v]
		3:
			_caption.text = world.edge_test_summary()
		4:
			_caption.text = world.height_summary()
		_:
			_caption.text = world.scatter_summary()
