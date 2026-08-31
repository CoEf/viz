extends BFChapter
## 챕터 0 — 완성본과 지도. flower_field 나비 16마리의 대량 확장판.
## 블로그 시리즈에서 다루지 않은 이펙트라 이 워크스루가 첫 분석이다.

const STEPS: Array[Dictionary] = [
	{
		"title": "나비 1024마리 보기",
		"body": """flower_field의 나비(16마리)와 [b]같은 셰이더·같은 메시[/b]를
1024마리로 늘리고, 서브이미터로 반짝이 2048개를 붙였다.
새 셰이더는 spark_dust 4줄뿐이다.""",
		"chips": [
			{"icon": "node3d", "text": "Butterfly ×1024"},
			{"icon": "shader", "text": "spark_dust.gdshader (4줄)"},
		],
		"try": "드래그 — 나비마다 반짝이 궤적이 따라온다",
	},
	{
		"title": "세 챕터로 나눠 보기",
		"body": """①1024마리 — 난류 비행의 확장.
②서브이미터 — 반짝이 흘리기.
③4줄 셰이더 — 방사 그라디언트와 블룸.""",
		"chips": [{"icon": "setting", "text": "챕터 1 → 3"}],
	},
]


func get_chapter_title() -> String:
	return "개요 — 재사용의 대량 확장"


func get_steps() -> Array[Dictionary]:
	return STEPS
