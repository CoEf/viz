extends WaterChapter
## 챕터 0 — 수면에 붙는 19개를 한 무대에 놓고, 비교할 축을 소개한다.

## 25개 중 수면(spatial)에 붙는 것들. 나머지 6개는 붙는 자리가 달라서 여기
## 세울 수 없다 — 그게 챕터 6의 첫 스텝이다. 격자에서는 카탈로그 제목이 길어
## 이름표끼리 겹치므로 번호 + 짧은 별명으로 줄인다.
const SURFACE_PLOTS: Array = [
	{"id": 1, "label": "01 Pixel Art"},
	{"id": 2, "label": "02 PSX"},
	{"id": 3, "label": "03 Realistic"},
	{"id": 4, "label": "04 Trail"},
	{"id": 5, "label": "05 Ripples"},
	{"id": 6, "label": "06 Cylinder"},
	{"id": 7, "label": "07 Hotspring"},
	{"id": 8, "label": "08 Toon"},
	{"id": 9, "label": "09 Banded"},
	{"id": 10, "label": "10 Absorption"},
	{"id": 11, "label": "11 Wind Waker"},
	{"id": 12, "label": "12 Ortho"},
	{"id": 13, "label": "13 Toon 3D"},
	{"id": 14, "label": "14 DepthFade"},
	{"id": 15, "label": "15 Cartoon"},
	{"id": 16, "label": "16 CS2 Flow"},
	{"id": 17, "label": "17 Toon 4.4"},
	{"id": 22, "label": "22 FBM Toon"},
	{"id": 23, "label": "23 Snell"},
]

const STEPS: Array[Dictionary] = [
	{
		"title": "열아홉을 같은 무대에 올리기",
		"body": """godotshaders.com에서 가져온 물 셰이더 [b]25개[/b] 중,
수면에 붙는 19개다.
해·하늘·바닥 기울기·프로브 궤도가 전부 같다.
그래서 칸 사이의 차이는 [b]전부 셰이더 차이[/b]다.""",
		"chips": [
			{"icon": "script", "text": "water_shader_registry.gd"},
			{"icon": "node3d", "text": "WaterPlot ×19"},
		],
		"try": "드래그로 회전 · 휠로 줌 — 이름표는 카탈로그 번호",
	},
	{
		"title": "칸마다 같은 무대를 깔기",
		"body": """물만 다르게 하려면 나머지가 같아야 한다.
바닥을 [b]10도 기울여[/b] 수심을 0.8에서 6까지 만들고,
기둥이 수면을 뚫고, 프로브가 같은 궤도를 돈다.
깊이 페이드도 교차 포말도 이게 없으면 안 보인다.""",
		"chips": [
			{"icon": "node3d", "text": "Seabed · Pillar · Probe"},
			{"icon": "script", "text": "water_plot.gd"},
		],
		"code": """seabed.rotation_degrees.x = 10.0
# 수심 0.8 -> 6.0 그라디언트""",
		"try": "수면 색이 한쪽으로 짙어진다 — 그게 바닥 경사다",
	},
	{
		"title": "비교할 다섯 축 정하기",
		"body": """열아홉을 하나씩 훑는 대신 [b]갈리는 지점[/b]을 본다.

[b]파도[/b] — 정점을 무엇으로 미는가 · 챕터 1
[b]법선[/b] — 반짝임을 어디서 얻는가 · 챕터 2
[b]깊이[/b] — 수심을 어떻게 아는가 · 챕터 3
[b]굴절[/b] — 수면 아래를 어떻게 가져오는가 · 챕터 4
[b]포말[/b] — 경계선을 어떻게 그리는가 · 챕터 5

챕터 6은 셰이더가 아니라, 이 25개를 4.7로 옮기며 걸린 것들이다.""",
		"chips": [{"icon": "setting", "text": "README.md"}],
		"try": "아래 '다음 챕터'로 축별 비교 시작",
	},
]


func get_chapter_title() -> String:
	return "열아홉 나란히 보기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_dive(false)
	world.set_canvas(null)
	world.set_postfx(null)
	world.set_overlay(null)
	if index == 1:
		# 무대 자체를 보는 스텝이라 칸 하나만 세운다. 17번은 수심을 색으로
		# 바꾸므로, 바닥 경사가 수면 위에 그대로 그려진다.
		world.show_plots([17])
		world.frame(0.35, -0.40, 0.92)
	else:
		world.show_plots(SURFACE_PLOTS)
		world.frame(-0.15, -0.68, 1.02)
