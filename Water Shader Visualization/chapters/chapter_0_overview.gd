extends WaterChapter
## 챕터 0 — 완성된 물과 레이어 스택 소개.

const STEPS: Array[Dictionary] = [
	{
		"title": "완성된 물 보기",
		"body": """이 물은 효과 하나가 아니라
[b]레이어 일곱 겹[/b]을 쌓은 결과다.
지금부터 한 겹씩 벗겨 낸다.""",
		"chips": [{"icon": "shader", "text": "water_surface.gdshader"}],
		"try": "드래그로 시점 회전 · 휠로 줌",
	},
	{
		"title": "벗겨 낼 일곱 겹",
		"body": """[b]L0 Domain[/b] — 어느 좌표로 샘플할지
[b]L1 Shape[/b] — Gerstner 파로 정점을 밀기 · 챕터 1
[b]L2 Detail[/b] — 노멀맵 2장 스크롤 · 챕터 2
[b]L3 Refraction[/b] — 화면을 굴절시켜 훔쳐 오기 · 챕터 3
[b]L7 Light[/b] — Fresnel로 반사와 투과를 배분 · 챕터 3
[b]L4 Volume[/b] — 수심만큼 색을 빼기 · 챕터 4
[b]L6 Foam[/b] — 교차선과 마루를 하얗게 · 챕터 5

프로젝트 목표는 이 레이어들을 [b]모듈로 켜고 끄는[/b] 범용 셰이더다 · 챕터 6""",
		"chips": [{"icon": "setting", "text": "docs/water-shader-analysis.md 2장"}],
		"try": "아래 '다음 챕터'로 분해 시작",
	},
]


func get_chapter_title() -> String:
	return "완성본 구경하기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(_index: int) -> void:
	world.reset_layers()
	world.camera_rig.set_view(2.95, -0.30, 34.0)
