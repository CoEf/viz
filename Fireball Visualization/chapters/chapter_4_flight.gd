extends FireballChapter
## 챕터 4 — 비행. 산포 발사 → move_toward 유도 → 셰이더 정점 회전 →
## 지연된 각속도. 이 이펙트의 백미인 "관성으로 휘는 꼬리"가 완성되는 순서.

const STEPS: Array[Dictionary] = [
	{
		"title": "흩뿌려 쏘기",
		"body": """기준 방향을 Y축·Z축으로 한 번씩 랜덤 회전.
표준편차가 [b]90도[/b]라 엉뚱한 데로 튄다.
유도가 없으면 이대로 끝 — 궤적이 직선이다.""",
		"chips": [{"icon": "script", "text": "fireball_preview.gd shoot()"}],
		"code": """b_y = base.rotated(UP, randfn(0, PI*0.5))
base = (b_y*0.4 + b_z*0.6).normalized()""",
		"try": "몇 발 지켜보기 → 방향이 제각각이다",
	},
	{
		"title": "move_toward로 되돌리기",
		"body": """매 프레임 속도를 [b]목표 방향으로 조금씩[/b] 당긴다.
즉시 꺾지 않아서 곡선 궤적이 남는다.
계수 하나가 선회 반경의 전부다.""",
		"chips": [{"icon": "script", "text": "simple_projectile.gd"}],
		"try": "계수를 1로 → 크게 원을 그리며 돌아온다",
	},
	{
		"title": "꼬리를 손으로 휘어 보기",
		"body": """휘는 건 본체가 아니라 [b]셰이더 속 정점 회전[/b]이다.
UV.y를 곱해 머리는 고정, 꼬리 끝이 가장 크게 휜다.""",
		"chips": [
			{"icon": "shader", "text": "fireball_shell vertex()"},
			{"icon": "shader", "text": "rotate_x.gdshaderinc"},
		],
		"try": "def_x를 끝까지 → 머리는 그대로, 꼬리만 말린다",
	},
	{
		"title": "관성은 지연에서 나온다",
		"body": """(방향 변화량)을 move_toward로 [b]느리게 추종[/b].
계속 꺾이는 동안 값이 쌓여 꼬리가 크게 휘고,
직진으로 돌아오면 서서히 풀리며 여운이 남는다.""",
		"chips": [
			{"icon": "script", "text": "fireball.gd angular_vel"},
			{"icon": "shader", "text": "def_x / def_z"},
		],
		"code": """angular_vel = angular_vel.move_toward(
    (direction - last_direction), 0.1*delta)""",
		"try": "명중 직전 급선회 순간의 꼬리를 관찰",
	},
]

var _turn := 4.0
var _def_x := 0.6
var _def_z := 0.0


func _ready() -> void:
	world.set_stationary_visible(false)
	world.set_target_visible(true)


func get_chapter_title() -> String:
	return "비행 — 유도와 관성 꼬리"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_autofire(false)
	world.clear_projectiles()
	world.turn_rate = _turn
	match index:
		0:
			world.set_stationary_visible(false)
			world.homing = false
			world.record_trajectories = true
			_frame_wide()
			world.set_autofire(true, 1.0)
			world.shoot()
			world.shoot()
		1:
			world.set_stationary_visible(false)
			world.homing = true
			world.record_trajectories = true
			_frame_wide()
			world.set_autofire(true, 1.3)
			world.shoot()
			update_code(_turn_code())
		2:
			world.homing = true
			world.record_trajectories = false
			world.set_stationary_visible(true)
			world.set_stationary_inertia(false)
			world.reset_shell_params()
			world.set_core_visible(true)
			world.set_trail_emitting(true)
			world.set_smoke_emitting(true)
			world.set_shell_param("def_x", _def_x)
			world.set_shell_param("def_z", _def_z)
			world.camera_rig.position = Vector3(0.0, 1.5, 0.0)
			world.camera_rig.set_view(0.9, -0.18, 2.6)
			update_code(_def_code())
		3:
			world.set_stationary_visible(false)
			world.homing = true
			world.record_trajectories = true
			_frame_wide()
			world.set_autofire(true, 1.3)
			world.shoot()


func _frame_wide() -> void:
	world.camera_rig.position = Vector3(0.0, 1.2, 0.0)
	world.camera_rig.set_view(0.35, -0.28, 9.5)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "선회 계수", 0.5, 10.0, _turn, _on_turn_changed, [1, 3])
	add_slider(parent, "def_x", -1.2, 1.2, _def_x, _on_def_x_changed, [2])
	add_slider(parent, "def_z", -1.2, 1.2, _def_z, _on_def_z_changed, [2])


func _on_turn_changed(value: float) -> void:
	_turn = value
	world.turn_rate = value
	if current_step == 1:
		update_code(_turn_code())


func _on_def_x_changed(value: float) -> void:
	_def_x = value
	world.set_shell_param("def_x", value)
	if current_step == 2:
		update_code(_def_code())


func _on_def_z_changed(value: float) -> void:
	_def_z = value
	world.set_shell_param("def_z", value)
	if current_step == 2:
		update_code(_def_code())


func _turn_code() -> String:
	return ("velocity = velocity.move_toward(\n"
			+ "  dir * speed, speed * %.1f * delta)\n" % _turn
			+ "// 원본 계수 4.0 ← 슬라이더")


func _def_code() -> String:
	return ("VERTEX *= rotateX(%.2f * UV.y)\n" % _def_x
			+ "    * rotateZ(%.2f * UV.y); ← 슬라이더" % _def_z)
