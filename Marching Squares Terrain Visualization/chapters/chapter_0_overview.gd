extends MstChapter
## 챕터 0 — 완성된 지형과, 그것을 만드는 여섯 조각의 이름.

const STEPS: Array[Dictionary] = [
	{
		"title": "완성된 지형 보기",
		"body": """블렌더 없이 에디터 안에서 깎은 지형이다.
계단처럼 끊긴 절벽과 매끈한 비탈이
[b]같은 높이 격자 하나[/b]에서 나온다.""",
		"chips": [
			{"icon": "node3d", "text": "MarchingSquaresTerrain"},
			{"icon": "node3d", "text": "MarchingSquaresTerrainChunk"},
		],
		"try": "왼쪽 드래그로 돌려 보기 · 휠로 확대",
	},
	{
		"title": "높이 격자만 남기고 벗기기",
		"body": """텍스처와 풀을 걷으면 남는 건 숫자판 하나다.
21×21 칸에 [b]높이 값 하나씩[/b].
브러시가 만지는 것도 이 숫자뿐이다.""",
		"chips": [{"icon": "script", "text": "chunk.height_map"}],
		"code": """height_map[z][x] = 0.0""",
		"try": "절벽도 비탈도 여기서는 그냥 숫자 차이",
	},
	{
		"title": "이 뼈대 위에 층이 얹힌다",
		"body": """지형 자체는 바닥과 벽 두 종류로만 갈린다.
[b]그 뼈대를 짓는 것이 2·3장[/b]이고,
위에 텍스처(4장)와 풀(5·6장)이 얹힌다.""",
		"chips": [
			{"icon": "script", "text": "height_map → Cell → shader → grass"},
		],
		"try": "1 높이맵 · 2 셀 · 3 바닥과 벽 · 4 텍스처 · 5 풀 자리 · 6 풀 그리기 · 7 갱신",
	},
]


func get_chapter_title() -> String:
	return "완성된 지형 훑기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_stage_terrain()
	world.set_merge_threshold(1.3)
	world.set_debug_mode(0)
	world.set_corner_markers(false)
	world.set_edge_bars(false)
	world.set_wireframe(false)
	world.set_terrain_visible(true)
	world.set_ridge_ledge_enabled(true)
	world.sculpt_to(4)

	match index:
		0:
			world.set_grass_visible(true)
			world.camera_rig.set_view(0.72, -0.46, 54.0)
		1:
			world.set_grass_visible(false)
			world.set_debug_mode(6)
			world.camera_rig.set_view(0.30, -0.95, 44.0)
		2:
			world.set_grass_visible(false)
			world.set_debug_mode(1)
			world.camera_rig.set_view(1.05, -0.34, 46.0)


func build_panel(parent: VBoxContainer) -> void:
	add_caption(parent, "청크 %d×%d 꼭짓점 · 셀 %d개"
			% [world.terrain.dimensions.x, world.terrain.dimensions.z,
			(world.terrain.dimensions.x - 1) * (world.terrain.dimensions.z - 1)])
