extends JiggleChapter
## 챕터 6 — 실전 배선. 앞 챕터의 솔버를 실제 Rigify 리그(본 183개)에 붙일 때
## 필요한 나머지 전부: 모디파이어 노드 · 설정 리소스 · 씬 배치 충돌체 · 실측.

const STIMULUS_KINDS: Array[Stimulus.Kind] = [
	Stimulus.Kind.WALK, Stimulus.Kind.BOUNCE, Stimulus.Kind.SIDE_STEP,
	Stimulus.Kind.TWIST, Stimulus.Kind.SHOCK, Stimulus.Kind.IDLE,
]
const STIMULUS_NAMES := "걷기,점프,좌우 이동,몸통 회전,급정거,정지"

const STEPS: Array[Dictionary] = [
	{
		"title": "리그에 모디파이어 37개 꽂기",
		"body": """모디파이어는 [b]씬 노드[/b]로 Skeleton3D 직속에 있다.
가닥 하나 = 노드 하나. 본 이름 두 개로 사슬을 잡는다.
노랑 = 머리카락 17 · 초록 = 치마 12 · 자홍 = 리본 8.""",
		"chips": [
			{"icon": "node3d", "text": "JiggleChainModifier3D ×37"},
			{"icon": "node3d", "text": "Skeleton3D"},
		],
		"code": """root_bone_name = "Hair_Back.L.001"
end_bone_name  = "Hair_Back.L.009\"""",
		"try": "그룹 토글로 어느 노드가 어딜 흔드는지 확인",
	},
	{
		"title": "재질값을 리소스 하나로 묶기",
		"body": """치마 12가닥의 값 11개를 [b].tres 하나[/b]가 대신한다.
실행 중에 고치면 전 가닥에 즉시 반영된다 —
튜닝이 이 일의 90%라서 이 구조가 필요하다.""",
		"chips": [
			{"icon": "resource", "text": "JiggleChainSettings"},
			{"icon": "resource", "text": "dress_setting.tres"},
		],
		"code": """# dress_setting.tres — 12가닥 공유
shape_stiffness = 0.5
restore_frequency = 0.7""",
		"try": "치마 형태 유지를 0으로 → 밑단이 흐물해진다",
	},
	{
		"title": "충돌체를 본에 붙여 배치하기",
		"body": """JiggleCollider3D 를 BoneAttachment3D 아래에 두면
[b]본을 따라다니는 캡슐[/b]이 된다. 숫자가 아니라 눈으로 배치한다.
파란 캡슐 = 머리 · 골반 · 양쪽 허벅지.""",
		"chips": [
			{"icon": "node3d", "text": "BoneAttachment3D"},
			{"icon": "node3d", "text": "JiggleCollider3D ×4"},
		],
		"code": """bone_name = "thigh.L"
radius = 0.032   height = 0.207""",
		"try": "충돌을 끄면 치마가 다리를 뚫는다",
	},
	{
		"title": "실측으로 마무리하기",
		"body": """안 흔들리는 버그는 [b]에러를 안 낸다.[/b]
본 이름 오타 하나면 그 가닥만 조용히 굳는다.
그래서 마지막 확인은 눈이 아니라 헤드리스 실측이다.""",
		"chips": [{"icon": "script", "text": "tools/character_test.gd"}],
		"code": """godot --headless --path . --script
    tools/character_test.gd""",
		"try": "흔들림 토글을 껐다 켜서 차이를 몸에 새길 것",
	},
]

@onready var world: Rig4World = $World

var _group_toggles: Dictionary[String, CheckButton] = {}
var _dress_slider: HSlider
var _collision_toggle: CheckButton
var _stimulus_option: OptionButton
var _sim_on := true


func get_chapter_title() -> String:
	return "실전 배선 — 실제 캐릭터"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.show_chains = index == 0
	world.show_colliders = index == 2
	world.set_collision(true)
	for group in ["hair", "dress", "ribbon", "breast"]:
		world.set_group_active(group, true)
	world.set_simulating(_sim_on)
	world.set_stimulus(Stimulus.Kind.WALK)
	world.kick(0.6)
	_sync_controls()
	if index == 2:
		world.view_hips()
	else:
		world.view_full()
	if index == 1:
		update_code(_dress_code())


func build_panel(parent: VBoxContainer) -> void:
	for entry: Array in [["머리카락 17", "hair"], ["치마 12", "dress"], ["리본 8", "ribbon"], ["가슴 2", "breast"]]:
		var group: String = entry[1]
		_group_toggles[group] = add_toggle(
			parent, entry[0], true, _on_group_toggled.bind(group), [0]
		)
	_dress_slider = add_slider(parent, "치마 형태 유지", 0.0, 1.0, 0.5, _on_dress_changed, [1])
	_collision_toggle = add_toggle(parent, "충돌", true, _on_collision_toggled, [2])
	_stimulus_option = add_option(parent, "자극", STIMULUS_NAMES.split(","), 0, _on_stimulus_selected, [3])
	add_button(parent, "임펄스 (툭 치기)", world.trigger_impulse)
	add_toggle(parent, "흔들림 켜기", true, _on_sim_toggled, [3])
	add_slowmo(parent)


func _sync_controls() -> void:
	for group: String in _group_toggles:
		_group_toggles[group].set_pressed_no_signal(true)
	_collision_toggle.set_pressed_no_signal(true)
	# 스텝이 자극을 걷기로 되돌리므로 드롭다운도 같이 되돌린다.
	_stimulus_option.select(0)
	var settings := world.group_settings("dress")
	if settings != null:
		_dress_slider.set_value_no_signal(settings.shape_stiffness)


func _on_group_toggled(pressed: bool, group: String) -> void:
	world.set_group_active(group, pressed)


func _on_dress_changed(value: float) -> void:
	var settings := world.group_settings("dress")
	if settings != null:
		# 세터가 emit_changed() → 모디파이어 12개가 함께 다시 읽는다.
		settings.shape_stiffness = value
	if current_step == 1:
		update_code(_dress_code())


func _on_collision_toggled(pressed: bool) -> void:
	world.set_collision(pressed)


func _on_stimulus_selected(index: int) -> void:
	world.set_stimulus(STIMULUS_KINDS[index])
	world.reset_world()
	world.kick(0.6)


func _on_sim_toggled(pressed: bool) -> void:
	_sim_on = pressed
	world.set_simulating(pressed)


func _dress_code() -> String:
	var settings := world.group_settings("dress")
	var value := settings.shape_stiffness if settings != null else 0.5
	return (
		"# dress_setting.tres — 12가닥 공유\n"
		+ "shape_stiffness = %.2f  # ← 슬라이더\n" % value
		+ "restore_frequency = 0.7"
	)
