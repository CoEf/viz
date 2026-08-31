extends FireballChapter
## 챕터 6 — 조립(지휘자). 명중 한 번이 두 갈래 연출로 갈라지는 배선과,
## 이펙트 씬을 만들 때 밟기 쉬운 지뢰들. 모든 시스템을 만난 뒤에야 의미가 있다.

const STEPS: Array[Dictionary] = [
	{
		"title": "한 번의 충돌, 두 갈래 연출",
		"body": """HitZone3D가 시그널을 [b]양쪽에 동시에[/b] 쏜다.
맞은 쪽은 자기 리액션, 때린 쪽은 폭발.
서로의 존재를 모른 채 갈라진다.""",
		"chips": [
			{"icon": "script", "text": "hit_zone_3d.gd"},
			{"icon": "signal", "text": "hit"},
		],
		"code": """hit_box.hit.emit()          # 맞은 쪽
hit.emit(global_position, ...) # 때린 쪽""",
		"try": "명중 순간 → 폭발과 움찔이 동시에 나온다",
	},
	{
		"title": "폭발을 형제로 세우기",
		"body": """발사체는 곧 사라진다.
자식으로 붙이면 폭발도 같이 사라지므로 [b]형제로[/b].
충돌면 법선으로 look_at해 벽이면 옆으로 눕는다.""",
		"chips": [{"icon": "script", "text": "simple_projectile.gd"}],
		"code": """add_sibling(impact)
impact.look_at(origin + hit_normal, UP)""",
		"try": "캡슐 옆면 명중 → 폭발이 옆을 보고 선다",
	},
	{
		"title": "out() — 메시만 숨기고 방출만 끄기",
		"body": """명중 시 메시는 즉시 숨기되
파티클은 [b]emitting만 끈다[/b].
이미 나온 불티가 제 수명을 살다 사라진다.""",
		"chips": [{"icon": "script", "text": "fireball.gd out()"}],
		"code": """fireball_shell_mesh.hide()
fire_trail.emitting = false # 방출만""",
		"try": "통째로 숨기기 → 명중 순간 꼬리가 뚝 잘린다",
	},
	{
		"title": "맞은 쪽의 0.26초",
		"body": """스쿼시&스트레치 트윈 3연속 + 발광 2초.
Tween이 셰이더 uniform을 직접 못 만져
[b]프로퍼티 브릿지[/b]로 감싸 클램프까지 보장한다.""",
		"chips": [
			{"icon": "script", "text": "target.gd"},
			{"icon": "script", "text": "dummy_skin.gd"},
		],
		"code": """tween_property(skin, "scale",
    Vector3(1.2, 0.8, 1.2), 0.08)""",
		"try": "명중 → 납작→길쭉→복귀, 발광은 2초에 식는다",
	},
	{
		"title": "지뢰 — resource_local_to_scene",
		"body": """꼬리 휨은 스크립트가 매 프레임 쓰는 uniform이다.
플래그가 없으면 [b]두 발이 머티리얼을 공유[/b]해
뒤에 쏜 발이 앞 발의 꼬리까지 덮어쓴다.""",
		"chips": [{"icon": "resource", "text": "fireball_mat.tres"}],
		"code": "resource_local_to_scene = true",
		"try": "연사 중인 두 발의 꼬리가 따로 휘는지 보기",
	},
]


var _hard := false


func _ready() -> void:
	world.set_stationary_visible(false)
	world.set_target_visible(true)
	world.homing = true
	world.shoot.call_deferred()


func get_chapter_title() -> String:
	return "조립 — 명중의 배선"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.hard_kill = _hard if index == 2 else false
	match index:
		3:
			world.set_autofire(true, 1.8)
			world.camera_rig.position = Vector3(4.0, 1.0, 0.0)
			world.camera_rig.set_view(0.5, -0.2, 3.2)
		4:
			world.set_autofire(true, 0.7)
			_frame_wide()
		_:
			world.set_autofire(true, 1.8)
			_frame_wide()


func _frame_wide() -> void:
	world.camera_rig.position = Vector3(0.0, 1.0, 0.0)
	world.camera_rig.set_view(0.3, -0.25, 8.5)


func build_panel(parent: VBoxContainer) -> void:
	var shoot_button := Button.new()
	shoot_button.text = "한 발 쏘기"
	shoot_button.pressed.connect(func() -> void: world.shoot())
	parent.add_child(shoot_button)
	bind_steps([shoot_button], [])

	add_toggle(parent, "통째로 숨기기 (비교)", false, _on_hard_kill_toggled, [2])


func _on_hard_kill_toggled(pressed: bool) -> void:
	_hard = pressed
	if current_step == 2:
		world.hard_kill = pressed
