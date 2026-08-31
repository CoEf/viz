extends FurChapter
## 챕터 1 — 셸 굽기. MeshDataTool로 15번 복제해 쌓고,
## 정점 컬러를 색이 아니라 데이터 채널로 쓴다.

const STEPS: Array[Dictionary] = [
	{
		"title": "메시를 15번 복제해 쌓기",
		"body": """고양이 메시를 복제해 [b]하나의 ArrayMesh에
15개 서피스로[/b] 쌓는다. 층마다 다른 건
정점 컬러 R 채널 하나뿐이다.""",
		"chips": [{"icon": "script", "text": "fur_builder.gd"}],
		"code": """for i in resolution:
    percent = (i + 1) / float(resolution)
    ... Color(percent * 0.5, g, 0.0)""",
		"try": "1층으로 줄이면 → 털이 양파 껍질 한 장이 된다",
	},
	{
		"title": "정점 컬러는 데이터다",
		"body": """[b]R = 셸 깊이[/b](0.033~0.5, 몇 번째 층인가),
[b]G = 퍼 마스크[/b](블렌더에서 칠한 "털 나는 곳").
파랑=뿌리, 주황=끝 — 깊이가 눈에 보인다.""",
		"chips": [{"icon": "shader", "text": "COLOR.r / COLOR.g"}],
		"try": "G 마스크 보기 → 얼굴·발은 검다(털 없음)",
	},
	{
		"title": "남의 스켈레톤에 스키닝하기",
		"body": """Fur는 Cat의 자식이 아니라 [b]형제[/b]다.
skeleton 경로와 skin 바인딩만 복사하면
glb 밖의 메시도 같은 뼈대로 움직인다 — 재임포트 안전.""",
		"chips": [
			{"icon": "node3d", "text": "MeshInstance3D.skeleton"},
			{"icon": "script", "text": "skin = target.skin"},
		],
		"code": """skeleton = ../Cat/Rig/Skeleton3D
skin = target_mesh_instance.skin""",
		"try": "걷기 애니메이션과 15겹이 함께 움직인다",
	},
]

var _resolution := 15.0
var _color_debug := false


func _ready() -> void:
	world.reset_fur_params()


func get_chapter_title() -> String:
	return "셸 굽기 — 15겹과 정점 컬러"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_fur_params()
	match index:
		0:
			world.rebuild_fur(int(_resolution))
			update_code(_resolution_code())
		1:
			world.rebuild_fur(15)
			world.set_fur_param("debug_mode", 2 if _color_debug else 1)
		2:
			world.rebuild_fur(15)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "resolution (셸 개수)", 1.0, 24.0, _resolution, _on_resolution_changed, [0])
	add_toggle(parent, "G 마스크 보기 (기본: 셸 깊이)", _color_debug, _on_debug_toggled, [1])


func _on_resolution_changed(value: float) -> void:
	_resolution = roundf(value)
	world.rebuild_fur(int(_resolution))
	if current_step == 0:
		update_code(_resolution_code())


func _on_debug_toggled(pressed: bool) -> void:
	_color_debug = pressed
	if current_step == 1:
		world.set_fur_param("debug_mode", 2 if pressed else 1)


func _resolution_code() -> String:
	return ("resolution = %.0f ← 슬라이더\n" % _resolution
			+ "// 서피스 %.0f개 = 드로우콜 %.0f회" % [_resolution, _resolution])
