extends BFChapter
## 챕터 3 — 4줄 셰이더. 방사 그라디언트 알파 + EMISSION 2.0 블룸.
## 이 저장소에서 가장 작은 이펙트의 가장 작은 셰이더.

const STEPS: Array[Dictionary] = [
	{
		"title": "방사 그라디언트로 점 만들기",
		"body": """UV 중심 거리를 그라디언트 텍스처 좌표로 —
[b]텍스처가 곧 페이드 프로파일[/b]이다.
그라디언트를 다시 칠하면 반짝이 모양이 바뀐다.""",
		"chips": [{"icon": "shader", "text": "spark_dust.gdshader"}],
		"code": """ALPHA = texture(gradient, vec2(
    distance(UV, vec2(.5)) * 2., 0)).x
    * COLOR.a;""",
	},
	{
		"title": "EMISSION 2.0 = 블룸",
		"body": """unshaded에서 EMISSION을 [b]1 이상[/b]으로 올리면
HDR로 넘어가 글로우가 잡는다 — 5편 빛기둥과 같은 요령.
환경의 glow_bloom 0.5가 유난히 높은 이유다.""",
		"chips": [{"icon": "setting", "text": "glow_bloom = 0.5"}],
		"code": "EMISSION = vec3(1.0) * 2.0;",
		"try": "반짝이가 실제 크기보다 크게 빛나 보인다",
	},
]


func get_chapter_title() -> String:
	return "4줄 셰이더 — 최소한의 반짝임"


func get_steps() -> Array[Dictionary]:
	return STEPS
