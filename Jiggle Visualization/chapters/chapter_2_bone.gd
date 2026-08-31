extends JiggleChapter
## 챕터 2 — 본 하나 흔들기 (가슴·엉덩이). 챕터 1의 스프링을 그대로 쓰되
## 결과를 위치가 아니라 본의 회전으로 읽는다.

const STIMULUS_KINDS: Array[Stimulus.Kind] = [
	Stimulus.Kind.WALK, Stimulus.Kind.BOUNCE, Stimulus.Kind.SHOCK, Stimulus.Kind.TWIST,
]
const STIMULUS_NAMES := "걷기,점프,급정거,몸통 회전"

const STEPS: Array[Dictionary] = [
	{
		"title": "코드로 스켈레톤과 스킨 만들기",
		"body": """본 8개를 손으로 조립하고 가중치를 정점에 구웠다.
[b]빨간 부위 = Jiggle 본에 묶인 정점.[/b]
뿌리의 부드러운 전이 구간이 없으면 표면이 꺾인다.""",
		"chips": [
			{"icon": "node3d", "text": "Skeleton3D"},
			{"icon": "script", "text": "proc_skin.gd"},
		],
		"code": """skeleton.add_bone("BreastL")
skin = create_skin_from_rest_transforms()""",
		"try": "지금은 rest 자세 그대로 — 아직 아무도 안 흔든다",
	},
	{
		"title": "파티클로 목표를 뒤쫓게 하기",
		"body": """파란 반투명 몸 = 흔들림이 없다면 있었을 자세.
파티클은 [b]월드 공간[/b]에 있어 몸이 움직이면 뒤처진다.
그 뒤처짐이 곧 관성 — 가속도를 재는 코드가 없다.""",
		"chips": [
			{"icon": "node3d", "text": "JiggleBoneModifier3D"},
			{"icon": "node3d", "text": "Skeleton3D"},
		],
		"code": "_spring.step(SUBSTEP, target_position)",
		"try": "임펄스 → 두 몸이 어긋나는 정도가 곧 Jiggle",
	},
	{
		"title": "구면에 붙여 길이 지키기",
		"body": """본은 늘어나지 않는다.
파티클을 본 원점 기준 [b]구면에 투영[/b]하고
반경 방향 속도까지 지워야 떨리지 않는다.""",
		"chips": [{"icon": "script", "text": "_project_to_sphere()"}],
		"code": """position = origin + normal * tip_length
velocity -= normal * velocity.dot(normal)""",
		"try": "길이 유지를 끄면 덩어리가 고무줄이 된다",
	},
	{
		"title": "방향을 본 회전으로 바꾸고 각도 묶기",
		"body": """rest 방향 → 파티클 방향 회전이 곧 본 포즈다.
빨간 구 = [b]최대 각도 울타리.[/b]
제한이 없으면 급정거에서 본이 뒤집히며 메쉬가 터진다.""",
		"chips": [{"icon": "script", "text": "set_bone_pose_rotation()"}],
		"code": "swing = Quaternion(rest_dir, current)",
		"try": "각도를 0(무제한)으로, 자극을 급정거로 → 터진다",
	},
	{
		"title": "축마다 강성 달리하기",
		"body": """위아래보다 좌우로 잘 흔들리게 — [b]비등방 스프링.[/b]
강성을 바꿨으면 감쇠도 √k에 맞춰 같이 바꿔야
축마다 감쇠비가 유지된다. 빼먹기 아주 쉬운 버그다.""",
		"chips": [{"icon": "script", "text": "_configure_spring()"}],
		"code": """scale = Vector3(horiz, vert, horiz)
stiffness = base * scale""",
		"try": "좌우 강성 0.3 → 옆으로만 출렁인다",
	},
	{
		"title": "휜 만큼 늘려 살아 보이게 하기",
		"body": """물리가 아니라 애니메이션 연출이다.
많이 휠수록 축으로 늘리고 옆으로 줄여
[b]부피가 보존되는 것처럼[/b] 속인다.""",
		"chips": [{"icon": "script", "text": "set_bone_pose_scale()"}],
		"code": """stretch = 1 + squash * angle / limit
lateral = 1 / sqrt(stretch)""",
		"try": "스쿼시 0.7 → 물풍선이 된다",
	},
]

@onready var world: BoneWorld = $World

var _stimulus_option: OptionButton
var _keep_toggle: CheckButton
var _angle_slider: HSlider
var _horizontal_slider: HSlider
var _squash_slider: HSlider


func get_chapter_title() -> String:
	return "본 하나 흔들기 — 가슴·엉덩이"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.frequency = 2.4
	world.damping_ratio = 0.22
	world.vertical_ratio = 1.0
	world.horizontal_ratio = 0.7
	world.gravity = 3.0
	world.max_angle_degrees = 26.0
	world.keep_length = true
	world.squash = 0.25
	world.jiggle_enabled = index > 0
	world.show_weights = index == 0
	world.show_ghost = index == 1
	world.show_gizmos = index > 0
	world.apply()
	world.set_stimulus(Stimulus.Kind.IDLE if index == 0 else Stimulus.Kind.WALK)
	if index > 0:
		world.kick(0.5)
		world.trigger_impulse()
	_sync_controls()
	if index == 0:
		# 웨이트를 볼 때는 정면 근접이 낫다.
		world.set_view(Vector3(0.0, 1.12, 0.0), 0.35, -0.06, 1.15)
	else:
		world.set_view(Vector3(0.0, 1.12, 0.0), 0.5, -0.08, 1.35)
	match index:
		3:
			update_code(_angle_code())
		4:
			update_code(_horizontal_code())
		5:
			update_code(_squash_code())


func build_panel(parent: VBoxContainer) -> void:
	var live: Array[int] = [1, 2, 3, 4, 5]
	add_button(parent, "임펄스 (툭 치기)", world.trigger_impulse, live)
	_stimulus_option = add_option(parent, "자극", STIMULUS_NAMES.split(","), 0, _on_stimulus_selected, live)
	add_slider(parent, "진동수 (Hz)", 0.5, 8.0, 2.4, _on_frequency_changed, live)
	add_slider(parent, "감쇠비 ζ", 0.02, 1.2, 0.22, _on_damping_changed, live)
	_keep_toggle = add_toggle(parent, "길이 유지", true, _on_keep_toggled, [2])
	_angle_slider = add_slider(parent, "최대 각도 (0=무제한)", 0.0, 80.0, 26.0, _on_angle_changed, [3])
	_horizontal_slider = add_slider(
		parent, "좌우 강성 배율", 0.2, 3.0, 0.7, _on_horizontal_changed, [4]
	)
	_squash_slider = add_slider(parent, "스쿼시", 0.0, 1.0, 0.25, _on_squash_changed, [5])
	add_slowmo(parent, live)
	add_caption(
		parent,
		"기즈모: 초록 = 목표 · 노랑 = 파티클 · 자홍 = 속도 · 빨강 = 각도 울타리 · 흰 선 = 본",
		live
	)


func _sync_controls() -> void:
	# 스텝이 자극을 걷기로 되돌리므로 드롭다운도 같이 되돌린다.
	_stimulus_option.select(0)
	_keep_toggle.set_pressed_no_signal(world.keep_length)
	_angle_slider.set_value_no_signal(world.max_angle_degrees)
	_horizontal_slider.set_value_no_signal(world.horizontal_ratio)
	_squash_slider.set_value_no_signal(world.squash)


func _on_stimulus_selected(index: int) -> void:
	world.set_stimulus(STIMULUS_KINDS[index])
	world.reset_world()
	world.kick(0.5)


func _on_frequency_changed(value: float) -> void:
	world.frequency = value
	world.apply()


func _on_damping_changed(value: float) -> void:
	world.damping_ratio = value
	world.apply()


func _on_keep_toggled(pressed: bool) -> void:
	world.keep_length = pressed
	world.apply()


func _on_angle_changed(value: float) -> void:
	world.max_angle_degrees = value
	world.apply()
	if current_step == 3:
		update_code(_angle_code())


func _on_horizontal_changed(value: float) -> void:
	world.horizontal_ratio = value
	world.apply()
	if current_step == 4:
		update_code(_horizontal_code())


func _on_squash_changed(value: float) -> void:
	world.squash = value
	world.apply()
	if current_step == 5:
		update_code(_squash_code())


func _angle_code() -> String:
	var line := "swing = Quaternion(rest_dir, current)\n"
	if world.max_angle_degrees <= 0.0:
		return line + "# 제한 없음 — 뒤집힐 수 있다 ← 슬라이더"
	return line + "max_angle_degrees = %.0f  # ← 슬라이더" % world.max_angle_degrees


func _horizontal_code() -> String:
	return (
		"scale = Vector3(horiz, vert, horiz)\n"
		+ "stiffness = base * scale\n"
		+ "# horizontal_ratio = %.2f ← 슬라이더" % world.horizontal_ratio
	)


func _squash_code() -> String:
	return (
		"stretch = 1 + squash * angle / limit\n"
		+ "lateral = 1 / sqrt(stretch)\n"
		+ "# squash = %.2f ← 슬라이더" % world.squash
	)
