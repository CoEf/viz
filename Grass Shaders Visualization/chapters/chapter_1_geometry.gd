extends GrassChapter
## 챕터 1 — 기하 축. 잎이 무엇으로 존재하는가. 네 가지가 전혀 다른 선택을 한다.

const STEPS: Array[Dictionary] = [
	{
		"title": "MultiMesh로 한 번에 그리기",
		"body": """열 개 중 일곱이 이 방식이다.
카드(사각형) 하나를 [b]드로우콜 한 번[/b]에 수천 장 그린다.
왼쪽은 카드, 오른쪽은 잎 모양 메시.""",
		"chips": [
			{"icon": "node3d", "text": "MultiMeshInstance3D"},
			{"icon": "script", "text": "grass_plot.gd"},
		],
		"code": """multimesh.instance_count = 4000
# 인스턴스마다 위치·회전·스케일만 다름""",
		"try": "잎 4,000장이 드로우콜 하나",
	},
	{
		"title": "개별 노드로 흩기",
		"body": """9번은 잎마다 [b]MeshInstance3D를 따로[/b] 둔다.
그래서 잎이 300장뿐이다 — 열 개 중 최저.
비싼 선택을 한 이유는 챕터 2에서 드러난다.""",
		"chips": [
			{"icon": "node3d", "text": "MeshInstance3D ×300"},
			{"icon": "script", "text": "pixel_tuft_field.gd"},
		],
		"try": "왼쪽 4,000장 vs 오른쪽 300장",
	},
	{
		"title": "파티클 프로세스로 배치 넘기기",
		"body": """8번은 배치를 [b]GPU에 맡긴다.[/b]
파티클 프로세스 셰이더가 5,184장의 자리를 정하고,
CPU는 아무것도 안 한다.""",
		"chips": [
			{"icon": "node3d", "text": "GPUParticles3D"},
			{"icon": "shader", "text": "foliage_process.gdshader"},
		],
		"code": """shader_type particles;
// 잎 위치를 CPU가 아니라 여기서 정한다""",
		"try": "5,184장 배치에 CPU 비용 0",
	},
	{
		"title": "기하 없이 그리기",
		"body": """10번은 잎이 [b]하나도 없다.[/b]
canvas_item 셰이더가 SubViewport에 잔디를 그리고,
그 텍스처를 지면 쿼드에 입힌다.
비용이 잎 수와 무관하게 고정이다.""",
		"chips": [
			{"icon": "shader", "text": "grass_patch.gdshader"},
			{"icon": "node3d", "text": "SubViewport"},
		],
		"code": """shader_type canvas_item;
// 3D 기하가 아니라 2D 그림이다""",
		"try": "가까이 가면 평면이라는 게 드러난다",
	},
]


func get_chapter_title() -> String:
	return "기하 — 잎을 무엇으로 놓는가"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	match index:
		0:
			world.show_patches([2, 6])
		1:
			world.show_patches([2, 9])
		2:
			world.show_patches([9, 8])
		_:
			world.show_patches([2, 10])
	world.camera_rig.position = Vector3(0.0, 1.6, 0.0)
	world.camera_rig.set_view(0.0, -0.26, 26.0)
