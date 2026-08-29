extends WaterfallChapter
## 챕터 0 — 완성된 폭포와 시스템 목록.

const STEPS: Array[Dictionary] = [
	{
		"title": "완성된 폭포 보기",
		"body": """물은 한 방울도 시뮬레이션하지 않는다.
[b]그림 한 장을 흘려보내는 셰이더 하나[/b]가
폭포와 웅덩이를 그리고, 파티클 둘이 물보라를 얹는다.""",
		"chips": [
			{"icon": "shader", "text": "displacement_n_uvscroll.gdshader"},
			{"icon": "node3d", "text": "GPUParticles3D ×2"},
		],
		"try": "드래그로 시점 회전 · 휠로 줌",
	},
	{
		"title": "뜯어 볼 일곱 시스템",
		"body": """[b]무대[/b] — 하늘·바위·해 · 챕터 1
[b]UV 스크롤[/b] — 그림을 흘려보내기 · 챕터 2
[b]물결 두 겹[/b] — 곱해서 반복 숨기기 · 챕터 3
[b]바탕색[/b] — 그라데이션 위에 더하기 · 챕터 4
[b]입체감[/b] — 정점 밀기 + 노멀맵 · 챕터 5
[b]웅덩이[/b] — 같은 셰이더, 다른 값 · 챕터 6
[b]물보라·거품[/b] — 파티클 둘 · 챕터 7""",
		"chips": [{"icon": "node3d", "text": "waterfall_scene.tscn"}],
		"try": "아래 '다음 챕터'로 분해 시작",
	},
]


func get_chapter_title() -> String:
	return "완성본 구경하기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(_index: int) -> void:
	world.reset_materials()
	world.show_water(true, true)
	world.set_effects(true, true)
	world.set_sky(true)
	world.sun.visible = true
	world.frame(Vector3(0, 0, 0.2), 0.55, -0.12, 4.6)
