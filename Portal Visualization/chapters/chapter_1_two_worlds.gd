extends PortalChapter
## 챕터 1 — 두 개의 세계. 포탈 너머의 공간은 100유닛 아래에 실제로 존재한다.

const STEPS: Array[Dictionary] = [
	{
		"title": "100유닛 아래의 진짜 공간",
		"body": """포탈 B와 마네킹, 별도의 바닥이
[b]y = -100[/b]에 통째로 놓여 있다.
포탈 A로 보이는 그림은 이 공간의 실사다.""",
		"chips": [{"icon": "node3d", "text": "SecondPlane (0, -100, 0)"}],
		"try": "반대편 공간 보기 → 마네킹이 정말로 서 있다",
	},
	{
		"title": "포탈은 재사용 부품이다",
		"body": """portal.tscn 하나에 뷰포트·카메라·테두리·라이트가 다 있다.
A와 B는 [b]서로를 other_portal로 참조[/b]하는
같은 씬의 인스턴스 두 개다.""",
		"chips": [
			{"icon": "node3d", "text": "Portal (Area3D)"},
			{"icon": "script", "text": "@export other_portal"},
		],
		"code": """PortalA.other_portal = ../PortalB
PortalB.other_portal = ../PortalA""",
		"try": "양쪽 공간 어디서 봐도 서로가 비친다",
	},
]

var _in_second := false


func _ready() -> void:
	world.frame_portal()


func get_chapter_title() -> String:
	return "두 개의 세계 — 텍스처가 아니다"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	_in_second = false
	if index == 0:
		world.frame_portal()
	else:
		world.frame_second_plane()


func build_panel(parent: VBoxContainer) -> void:
	var travel := Button.new()
	travel.text = "반대편 공간 보기 / 돌아오기"
	travel.pressed.connect(_on_travel_pressed)
	parent.add_child(travel)
	bind_steps([travel], [0])


func _on_travel_pressed() -> void:
	_in_second = not _in_second
	if _in_second:
		world.frame_second_plane()
	else:
		world.frame_portal()
