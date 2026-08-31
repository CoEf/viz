extends FireballChapter
## 챕터 0 — 완성본과 지도. 자동 발사로 전체 릴레이를 보여주고,
## 이 워크스루가 그걸 어떻게 쪼갰는지 알려준다.

const STEPS: Array[Dictionary] = [
	{
		"title": "완성된 파이어볼 보기",
		"body": """발사대가 파이어볼을 계속 쏜다.
[b]발사 → 유도 비행 → 명중 → 폭발 → 피격 반응[/b].
이 릴레이 전체가 셰이더 5장과 씬 4개다.""",
		"chips": [{"icon": "node3d", "text": "SimpleProjectile"}],
		"try": "드래그로 돌려 명중 순간을 관찰",
	},
	{
		"title": "씬 4개로 쪼개 담기",
		"body": """총구 화염·비행체·폭발이 서로를 모른다.
각 씬이 제 수명을 스스로 끝내는 [b]fire-and-forget[/b].
호출부는 instantiate()와 위치 지정뿐이다.""",
		"chips": [
			{"icon": "script", "text": "simple_projectile.gd"},
			{"icon": "node3d", "text": "fireball_impact.tscn"},
		],
		"code": """var impact = impact_scene.instantiate()
add_sibling(impact) # 자식이 아니라 형제""",
	},
	{
		"title": "여섯 챕터로 나눠 보기",
		"body": """①껍질 ②코어 ③꼬리 파티클 — 몸.
④비행 ⑤임팩트 — 움직임.
⑥조립 — 명중의 배선.""",
		"chips": [{"icon": "setting", "text": "챕터 1 → 6"}],
	},
]


func _ready() -> void:
	world.set_stationary_visible(false)
	world.set_autofire(true, 1.6)
	world.camera_rig.position = Vector3(0.0, 1.2, 0.0)
	world.camera_rig.set_view(0.35, -0.28, 9.5)
	world.shoot.call_deferred()


func get_chapter_title() -> String:
	return "개요 — 파이어볼 한 발의 전체"


func get_steps() -> Array[Dictionary]:
	return STEPS
