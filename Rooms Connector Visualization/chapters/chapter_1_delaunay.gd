extends RoomsChapter
## 챕터 1 — 방 배치와 Delaunay 삼각분할. 후보 간선이 어디서 오는지 보여준다.

const STEPS: Array[Dictionary] = [
	{
		"title": "방을 흩뿌리고 중심점만 남기기",
		"body": """알고리즘은 방의 크기나 모양을 보지 않는다.
[b]중심점 하나[/b]로 줄여 놓고 시작한다.""",
		"chips": [{"icon": "script", "text": "room_data.gd"}],
		"code": """var center: Vector2
var bounds: Rect2""",
		"try": "회색 사각형 = 방, 알고리즘이 보는 건 그 중심뿐",
	},
	{
		"title": "삼각분할로 후보 간선 뽑기",
		"body": """중심점들을 삼각형으로 빈틈없이 덮는다.
그 삼각형 변들이 곧 [b]이을 만한 후보[/b]다.
멀리 떨어진 방끼리는 애초에 후보가 되지 않는다.""",
		"chips": [
			{"icon": "script", "text": "delaunay_triangulator.gd"},
			{"icon": "setting", "text": "Geometry2D"},
		],
		"code": """var points := PackedVector2Array()
# ... 방 중심 채우기
Geometry2D.triangulate_delaunay(points)""",
		"try": "파란 선이 후보 간선 — 아직 다 쓰지는 않는다",
	},
	{
		"title": "중복 변 걸러 간선 목록 만들기",
		"body": """삼각형끼리 변을 공유하므로 같은 간선이 두 번 나온다.
방 번호 쌍을 키로 써서 [b]한 번만 남긴다.[/b]""",
		"chips": [{"icon": "script", "text": "edge_data.gd"}],
		"code": """func get_rooms_key() -> String:
    # 작은 id를 앞에 둬 방향 무시""",
		"try": "선 개수가 삼각형 수보다 적은 이유",
	},
]


func get_chapter_title() -> String:
	return "후보 간선 뽑기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.show_stage(&"none" if index == 0 else &"delaunay")
	world.camera_rig.set_view(0.0, -0.06, 22.0)
	if index == 2:
		update_code(_edge_count_code())


func build_panel(parent: VBoxContainer) -> void:
	add_caption(parent, "방 %d개 · 후보 간선 %d개"
			% [world.room_count(), world.delaunay_edges.size()])


func _edge_count_code() -> String:
	return ("_edges[edge.get_rooms_key()] = edge\n"
			+ "// 중복 제거 후 %d개 남음" % world.delaunay_edges.size())
