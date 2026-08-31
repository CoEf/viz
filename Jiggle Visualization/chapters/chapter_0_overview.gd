extends JiggleChapter
## 챕터 0 — 완성본(실제 캐릭터)과 분해할 시스템 소개.

const STIMULUS_KINDS: Array[Stimulus.Kind] = [
	Stimulus.Kind.WALK, Stimulus.Kind.BOUNCE, Stimulus.Kind.SIDE_STEP,
	Stimulus.Kind.TWIST, Stimulus.Kind.SHOCK, Stimulus.Kind.IDLE,
]
const STIMULUS_NAMES := "걷기,점프,좌우 이동,몸통 회전,급정거,정지"

const STEPS: Array[Dictionary] = [
	{
		"title": "완성본 먼저 보기",
		"body": """실제 Rigify 리그(본 183개)가 걷고 있다.
머리카락·치마·리본을 [b]씬 속 모디파이어 39개[/b]가 흔든다.
엔진 내장 기능이 아니라 이 프로젝트의 자작 솔버다.""",
		"chips": [
			{"icon": "node3d", "text": "JiggleChainModifier3D ×37"},
			{"icon": "node3d", "text": "JiggleBoneModifier3D ×2"},
		],
		"try": "드래그 회전 · 휠 줌 · 아래에서 자극 바꾸기",
	},
	{
		"title": "분해할 시스템 훑기",
		"body": """[b]수학은 하나 — 목표를 지연·오버슈트하며 쫓는 2차 시스템.[/b]
챕터 1 스프링-댐퍼 → 챕터 2 본 하나 (가슴·엉덩이)
챕터 3 본 사슬 (머리카락, 노랑) → 챕터 4 천 (치마, 초록)
챕터 5 본 없이 셰이더로 → 챕터 6 실전 배선 (리본, 자홍)""",
		"chips": [{"icon": "script", "text": "jiggle/ (솔버 본체)"}],
		"try": "색선 = 각 모디파이어가 흔드는 사슬. '다음 챕터'로 분해 시작",
	},
]

@onready var world: Rig4World = $World

var _sim_on := true


func get_chapter_title() -> String:
	return "완성본 구경하기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.show_chains = index == 1
	world.show_colliders = false
	world.set_collision(true)
	for group in ["hair", "dress", "ribbon", "breast"]:
		world.set_group_active(group, true)
	world.set_simulating(_sim_on)
	# 스텝에 들어서자마자 움직임이 보이도록 자극 위상을 당겨 둔다.
	world.kick(0.6)


func build_panel(parent: VBoxContainer) -> void:
	add_option(parent, "자극", STIMULUS_NAMES.split(","), 0, _on_stimulus_selected)
	add_slider(parent, "자극 세기", 0.0, 2.5, 1.0, _on_amount_changed)
	add_button(parent, "임펄스 (툭 치기)", _on_impulse)
	add_toggle(parent, "흔들림 켜기", true, _on_sim_toggled)
	add_slowmo(parent)


func _on_stimulus_selected(index: int) -> void:
	world.set_stimulus(STIMULUS_KINDS[index])
	world.reset_world()
	world.kick(0.6)


func _on_amount_changed(value: float) -> void:
	world.stimulus.amount = value


func _on_impulse() -> void:
	world.trigger_impulse()


func _on_sim_toggled(pressed: bool) -> void:
	_sim_on = pressed
	world.set_simulating(pressed)
