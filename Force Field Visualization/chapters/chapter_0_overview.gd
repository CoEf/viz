extends FFChapter
## 챕터 0 — 완성본과 지도. 셰이더 한 장짜리 이펙트 — 레이어를 하나씩 벗겨 본다.
## 블로그 시리즈에서 다루지 않은 이펙트라 이 워크스루가 첫 분석이다.

const STEPS: Array[Dictionary] = [
	{
		"title": "완성된 포스필드 보기",
		"body": """반구에 셰이더 한 장 — 그런데 그 안에
[b]프레넬, 뎁스 교차선, 육각 그리드 2채널,
셀 점멸, 스캔 밴드[/b]가 겹쳐 있다.""",
		"chips": [
			{"icon": "shader", "text": "force_field.gdshader"},
			{"icon": "texture", "text": "hexagon_grid_sampler.png"},
		],
		"try": "드래그 — 어느 각도든 가장자리가 밝다",
	},
	{
		"title": "세 챕터로 나눠 보기",
		"body": """①바탕 — 프레넬과 뎁스 교차.
②육각 그리드 — 텍스처 2채널.
③스캔 밴드와 파편 — 마무리 겹.""",
		"chips": [{"icon": "setting", "text": "챕터 1 → 3"}],
	},
]


func _ready() -> void:
	world.reset_params()


func get_chapter_title() -> String:
	return "개요 — 셰이더 한 장의 레이어들"


func get_steps() -> Array[Dictionary]:
	return STEPS
