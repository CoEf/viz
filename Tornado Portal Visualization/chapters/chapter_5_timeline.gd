extends TornadoChapter
## 챕터 5 — 타임라인(지휘자). 오버슈트, 앤티시페이션, 488° —
## 애니메이션 원칙이 키 몇 개로 구현된 4초.

const STEPS: Array[Dictionary] = [
	{
		"title": "스크립트는 재생뿐",
		"body": """트랙 12개가 opening·pull·어트랙터·회전을 전부 몬다.
스크립트에 연출이 [b]한 줄도 없다[/b].""",
		"chips": [{"icon": "script", "text": "portal_preview.gd"}],
		"code": """if animation_player.is_playing(): return
animation_player.play("default")""",
		"try": "재생 → 4초를 통째로",
	},
	{
		"title": "4초를 손으로 훑기",
		"body": """0~0.7초 열림, 0~2.5초 파티클 상승,
1.5초 흡인 시작, 2.3초 어트랙터, [b]3.2초 낙하[/b],
3.4초 닫힘.""",
		"chips": [{"icon": "resource", "text": "Animation \"default\" 4.0s"}],
		"try": "2.3~2.7초 → 파티클이 꺾여 내려가는 순간",
	},
	{
		"title": "오버슈트와 앤티시페이션",
		"body": """열릴 때 scale이 [b]1.2로 지나쳤다가[/b] 1.0으로 — 탁 열린다.
떨어지기 전 y가 0.5→[b]1.0으로 살짝 떠오른다[/b] —
2.6초 걸려 떠오르고 0.4초 만에 -4로 떨어지는 대비.""",
		"chips": [{"icon": "node3d", "text": "Hole:scale / Target:position"}],
		"code": """scale : 1.0 → 1.2(0.5s) → 1.0(0.7s)
pos.y : 0.5 → 1.0(2.8s) → -4.0(3.2s)""",
		"try": "0.5초와 2.8초 근처를 천천히 훑어 보라",
	},
	{
		"title": "회전은 488도",
		"body": """360의 배수가 아니라 [b]한 바퀴 + 128°[/b].
정확히 제자리로 돌아오지 않아야
기계적으로 보이지 않는다.""",
		"chips": [{"icon": "node3d", "text": "Target:rotation_degrees"}],
		"code": """rotation.y: 0° → 488° (3.3s)
rotation.x: 0° → -180°""",
		"try": "3.0초 근처 → 어중간한 각도로 기울어 떨어진다",
	},
]

var _scrub_t := 2.5


func _ready() -> void:
	world.camera_rig.position = Vector3(0.0, 1.0, 0.0)
	world.camera_rig.set_view(0.5, -0.35, 9.0)
	world.play.call_deferred()


func get_chapter_title() -> String:
	return "타임라인 — 12트랙의 4초"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.spin_target = false
	world.solo(true, true, true, true)
	match index:
		0:
			world.stop()
			world.play()
		_:
			world.scrub(_scrub_t)
			update_code_for_scrub()


func build_panel(parent: VBoxContainer) -> void:
	var replay := Button.new()
	replay.text = "재생"
	replay.pressed.connect(func() -> void:
		world.stop()
		world.play())
	parent.add_child(replay)
	bind_steps([replay], [0])

	var scrub := add_slider(parent, "타임라인 (초)", 0.0, 4.0, _scrub_t, _on_scrub_changed, [1, 2, 3])
	scrub.step = 0.01


func _on_scrub_changed(value: float) -> void:
	_scrub_t = value
	if current_step >= 1:
		world.scrub(value)
		update_code_for_scrub()


func update_code_for_scrub() -> void:
	if current_step == 1:
		update_code("# t = %.2fs ← 슬라이더\n# %s" % [_scrub_t, _phase_for(_scrub_t)])


func _phase_for(t: float) -> String:
	if t < 0.5:
		return "구멍 열림 — scale 1.2 오버슈트로"
	if t < 0.7:
		return "바운스 — 1.2 → 1.0"
	if t < 1.5:
		return "파티클이 나선으로 상승"
	if t < 2.3:
		return "pull 시작 — 메시가 먼저 늘어난다"
	if t < 2.7:
		return "어트랙터 0→40 — 파티클 급강하"
	if t < 3.2:
		return "상자가 살짝 떠오른다 (앤티시페이션)"
	if t < 3.4:
		return "낙하 — y -4, 구멍이 닫히기 시작"
	return "닫힘 완료"
