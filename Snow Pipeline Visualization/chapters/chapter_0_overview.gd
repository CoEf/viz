extends SnowChapter
## 챕터 0 — 완성본과 여섯 시스템 소개.

const STEPS: Array[Dictionary] = [
	{
		"title": "완성본 먼저 보기",
		"body": """Snow2 완성본.
서로를 모르는 [b]시스템 여섯 개[/b]가
겹쳐서 만든 한 장면이다.""",
		"chips": [{"icon": "setting", "text": "Godot 4.7 · Forward+"}],
		"try": "드래그 회전 · 휠 줌 · 아래 슬라이더 조작",
	},
	{
		"title": "분해할 여섯 시스템",
		"body": """[b]무대[/b] — 하늘·안개·빛 · 챕터 1
[b]눈 내림[/b] — GPUParticles3D · 챕터 2
[b]눈 쌓임[/b] — snow_cover 셰이더 · 챕터 3
[b]발자국[/b] — DrawableTexture2D 높이맵 · 챕터 4
[b]반짝임[/b] — light() 글린트 · 챕터 5
[b]지휘자[/b] — 시그널 라우팅 · 챕터 6""",
		"try": "아래 '다음 챕터'로 분해 시작",
	},
]


func _ready() -> void:
	world.set_fall_ratio(0.6)
	world.camera_rig.set_view(0.65, -0.38, 14.0)


func get_chapter_title() -> String:
	return "완성본 구경하기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "눈 내림 (강도)", 0.0, 1.0, 0.6, _on_fall_changed)
	add_slider(parent, "눈 쌓임", 0.0, 1.0, 0.7, _on_cover_changed)
	add_slider(parent, "반짝임 세기", 0.0, 3.0, 1.0, _on_sparkle_changed)


func _on_fall_changed(value: float) -> void:
	world.set_fall_ratio(value)


func _on_cover_changed(value: float) -> void:
	WinterWorld.set_global_cover(value)


func _on_sparkle_changed(value: float) -> void:
	WinterWorld.set_global_sparkle(value)
