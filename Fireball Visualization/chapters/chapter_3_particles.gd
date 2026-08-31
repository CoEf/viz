extends FireballChapter
## 챕터 3 — 꼬리 파티클. 불티/연기 두 겹의 역할 분담과,
## 쿼드 한 장을 해부해 마스크·수명 디졸브를 눈으로 확인한다.

const STEPS: Array[Dictionary] = [
	{
		"title": "불티 겹 깔기",
		"body": """본체 뒤 z=-0.13에서 쿼드 16장이 나온다.
수명 0.5초, 위로 뜨며 뒤로 처진다.
[b]그림 파일 없이[/b] 셰이더가 형태를 깎는다.""",
		"chips": [
			{"icon": "node3d", "text": "FireTrail (GPUParticles3D)"},
			{"icon": "shader", "text": "fireball_particles.gdshader"},
		],
		"try": "드래그로 꽁무니 쪽에서 보기",
	},
	{
		"title": "쿼드 한 장 해부하기",
		"body": """원형 마스크에서 보로노이를 뺀 값 하나가
[b]알파와 색 좌표를 동시에[/b] 맡는다.
나이를 먹을수록 노이즈가 커져 형태가 삭는다.""",
		"chips": [{"icon": "shader", "text": "INSTANCE_CUSTOM.y = 수명"}],
		"try": "수명 슬라이더 끝까지 → 다 삭아 사라진다",
	},
	{
		"title": "연기 겹 더하기",
		"body": """연기는 같은 구조에서 그라디언트만 뺐다.
불티 anim_speed 0.1, 연기 0.01 —
[b]무늬가 꿈틀대는 속도[/b]가 재질감을 가른다.""",
		"chips": [
			{"icon": "node3d", "text": "FireSmoke"},
			{"icon": "resource", "text": "ParticleProcessMaterial"},
		],
		"try": "연기만 보기 → 거의 정지한 무늬를 확인",
	},
	{
		"title": "중력을 위로 걸기",
		"body": """두 파티클 다 gravity가 [b](0, 1, 0)[/b]다.
불꽃과 연기는 떨어지는 게 아니라 떠올라야 한다.""",
		"chips": [{"icon": "resource", "text": "ParticleProcessMaterial"}],
		"code": "gravity = Vector3(0, 1, 0)",
		"try": "중력을 아래로 → 불티가 비처럼 떨어진다",
	},
]

var _age := 0.3
var _show_mask := false
var _smoke_only := false
var _gravity_up := true


func _ready() -> void:
	world.set_autofire(false)
	world.set_target_visible(false)
	world.set_stationary_visible(true)
	world.set_stationary_inertia(false)
	world.reset_shell_params()
	_frame_body()


func get_chapter_title() -> String:
	return "꼬리 파티클 — 불티와 연기 두 겹"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_particles_gravity_up(true if index != 3 else _gravity_up)
	match index:
		0:
			_show_body(true, false)
		1:
			world.set_stationary_visible(false)
			world.set_anatomy_visible(true)
			world.set_anatomy_param("demo_age", _age)
			world.set_anatomy_param("debug_mode", 3 if _show_mask else 0)
			world.camera_rig.position = Vector3(0.0, 1.5, 0.0)
			world.camera_rig.set_view(0.0, -0.06, 2.0)
			update_code(_age_code())
		2:
			_show_body(not _smoke_only, true)
		3:
			_show_body(true, true)


## 정지 본체 + 파티클 조합을 한 번에 세팅한다.
func _show_body(trail: bool, smoke: bool) -> void:
	world.set_anatomy_visible(false)
	world.set_stationary_visible(true)
	world.set_trail_emitting(trail)
	world.set_smoke_emitting(smoke)
	_frame_body()


func _frame_body() -> void:
	world.camera_rig.position = Vector3(0.0, 1.5, 0.0)
	world.camera_rig.set_view(0.7, -0.15, 2.8)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "수명 진행도 (custom.y)", 0.0, 1.0, _age, _on_age_changed, [1])
	add_toggle(parent, "최종 마스크 보기", _show_mask, _on_mask_toggled, [1])
	add_toggle(parent, "연기만 보기", _smoke_only, _on_smoke_only_toggled, [2])
	add_toggle(parent, "중력 아래로 (비교)", not _gravity_up, _on_gravity_toggled, [3])


func _on_age_changed(value: float) -> void:
	_age = value
	world.set_anatomy_param("demo_age", value)
	if current_step == 1:
		update_code(_age_code())


func _on_mask_toggled(pressed: bool) -> void:
	_show_mask = pressed
	if current_step == 1:
		world.set_anatomy_param("debug_mode", 3 if pressed else 0)


func _on_smoke_only_toggled(pressed: bool) -> void:
	_smoke_only = pressed
	if current_step == 2:
		world.set_trail_emitting(not pressed)


func _on_gravity_toggled(pressed: bool) -> void:
	_gravity_up = not pressed
	if current_step == 3:
		world.set_particles_gravity_up(_gravity_up)


func _age_code() -> String:
	return ("voronoi = texture(noise, UV*s + c.z).x\n"
			+ "    - 0.5 + %.2f; // 수명 ← 슬라이더" % _age)
