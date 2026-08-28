extends RoomsChapter
## 챕터 0 — 완성된 연결 그래프와 분해할 단계들.

const STEPS: Array[Dictionary] = [
	{
		"title": "완성된 방 연결 보기",
		"body": """흩어진 방 14개를 이어 던전을 만든다.
[color=#ffd16b]노란 선[/color] = 모든 방을 잇는 최소 연결,
[color=#fa729e]분홍 선[/color] = 되돌아오는 길을 만드는 여분 간선.""",
		"chips": [{"icon": "script", "text": "rooms_connector.gd"}],
		"try": "드래그로 각도 회전 · 휠로 줌",
	},
	{
		"title": "분해할 세 단계",
		"body": """[b]삼각분할[/b] — 이을 만한 후보 간선 뽑기 · 챕터 1
[b]최소 신장 트리[/b] — 그중 최소한만 남기기 · 챕터 2
[b]여분 간선[/b] — 순환로 되살리기 · 챕터 2

셋 다 방 좌표만 보고 도는 순수 기하 알고리즘이다.""",
		"chips": [
			{"icon": "script", "text": "delaunay_triangulator.gd"},
			{"icon": "script", "text": "mst_generator.gd"},
			{"icon": "script", "text": "edge_selector.gd"},
		],
		"try": "아래 '다음 챕터'로 분해 시작",
	},
]


func get_chapter_title() -> String:
	return "완성본 구경하기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(_index: int) -> void:
	world.show_stage(&"loop")
	world.camera_rig.set_view(0.0, -0.06, 22.0)
