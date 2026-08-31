extends WaterChapter
## 챕터 6 — 조립. 스켈레탈 애니메이션의 메서드 트랙이 시그널을 쏘고,
## 프리뷰가 받아 이펙트를 배선한다. 타이밍이 코드에 하나도 없는 구조.

const STEPS: Array[Dictionary] = [
	{
		"title": "애니메이션이 시그널을 쏜다",
		"body": """Slap 타임라인의 [b]메서드 호출 트랙[/b]이
0.2초에 raised, 1.6초에 slaped를 emit한다.
타이밍이 코드에 없다 — 모션을 늦추면 이펙트도 따라온다.""",
		"chips": [
			{"icon": "signal", "text": "raised / slaped"},
			{"icon": "script", "text": "water_hand.gd"},
		],
		"code": """t=0.2 → emit_signal("raised")
t=1.6 → emit_signal("slaped")""",
		"try": "재생 → 손이 물을 뚫는 순간 물보라가 뜬다",
	},
	{
		"title": "모션과 이벤트를 분리해 가산",
		"body": """본 애니메이션(Slap)과 이벤트 전용 애니메이션(events)을
[b]Add2로 가산 블렌드[/b]해 하나처럼 재생한다.
glTF 재임포트로 Slap이 덮여도 이벤트가 살아남는다.""",
		"chips": [{"icon": "node3d", "text": "AnimationTree BlendTree"}],
		"code": """Slap ──┐
       ├→ Add2 → Transition → out
events─┘""",
	},
	{
		"title": "받는 쪽의 배선",
		"body": """raised → 손 물보라 + 젖은 자국 시작.
slaped → 더미 스쿼시 + 충격 물보라 + [b]카메라 셰이크[/b]
+ 물방울. 한 시그널이 여러 연출로 갈라진다.""",
		"chips": [{"icon": "script", "text": "water_hand_preview.gd"}],
		"code": """water_hand.slaped.connect(func():
    target.hit(); impact_splash.splash()
    camera.shake(); droplet.emitting = true)""",
		"try": "재생 → 내려찍는 순간 화면이 흔들린다",
	},
]


func _ready() -> void:
	world.solo(true, true, true, true, true)
	world.camera_rig.position = Vector3(-0.5, 2.0, 0.0)
	world.camera_rig.set_view(0.5, -0.3, 11.0)
	world.play_sequence.call_deferred()


func get_chapter_title() -> String:
	return "조립 — 타임라인이 쏘는 시그널"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	if index == 0 or index == 2:
		world.play_sequence()


func build_panel(parent: VBoxContainer) -> void:
	var replay := Button.new()
	replay.text = "시퀀스 재생"
	replay.pressed.connect(func() -> void: world.play_sequence())
	parent.add_child(replay)
	bind_steps([replay], [])
