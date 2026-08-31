extends FireballChapter
## 챕터 5 — 임팩트. 0.075초짜리 플래시를 정지시켜 놓고 뜯는다.
## 극좌표 별 → 커브 변조 → 타임라인 스크럽 → 리본 불티.

const STEPS: Array[Dictionary] = [
	{
		"title": "실속도로 한 번 보기",
		"body": """지휘자는 스크립트가 아니라 [b]AnimationPlayer[/b]다.
play("default") 한 줄이면 파티클 셋의 emitting과
플래시의 uniform이 타임라인대로 움직인다.""",
		"chips": [
			{"icon": "node3d", "text": "AnimationPlayer"},
			{"icon": "script", "text": "fireball_impact.gd"},
		],
		"code": "animation_player.play(\"default\")",
		"try": "폭발 재생 → 눈 깜빡하면 놓친다, 0.075초다",
	},
	{
		"title": "극좌표로 별 만들기",
		"body": """각도를 0~1로 편 뒤 [b]8배로 감아[/b] 커브를 읽는다.
뾰족 커브가 원 둘레를 8번 반복 → 8갈래 별.
기본 반지름 0.25가 가시 없이도 원판을 남긴다.""",
		"chips": [
			{"icon": "shader", "text": "polar_coordinates()"},
			{"icon": "resource", "text": "CurveXYZTexture"},
		],
		"try": "갈래 수를 6으로 → 6갈래 별이 된다",
	},
	{
		"title": "커브 하나로 비대칭 주기",
		"body": """같은 텍스처의 [b].y 커브는 한 바퀴만[/b] 읽는다.
갈래 길이를 각도마다 다르게 변조해
기계적인 대칭을 깬다.""",
		"chips": [{"icon": "resource", "text": "CurveXYZTexture curve_y"}],
		"code": """offset = curve(p_uv.y).y  // 1바퀴
wave = (spikes*0.1 + 0.25) * offset""",
		"try": "변조를 끄면 → 정확히 대칭인 별이 된다",
	},
	{
		"title": "0.075초 타임라인 스크럽하기",
		"body": """키는 세 개뿐 — 0 / 0.05 / 0.075초.
transition [b]-2 = ease in-out[/b]이라
선형이 아니라 확 부풀었다 확 꺼진다.""",
		"chips": [
			{"icon": "resource", "text": "Animation \"default\""},
			{"icon": "shader", "text": "intensity / scale"},
		],
		"try": "천천히 끌어 보기 → 0.05초에 최대로 부푼다",
	},
	{
		"title": "리본 불티 튕기기",
		"body": """불티 4개가 [b]리본 트레일[/b]을 끌고 튄다.
초속 6~16에 감쇠 4~6 — 확 나가서 급감속.
씬의 콜리전 박스 덕에 바닥에서 실제로 튕긴다.""",
		"chips": [
			{"icon": "resource", "text": "RibbonTrailMesh"},
			{"icon": "node3d", "text": "GPUParticlesCollisionBox3D"},
		],
		"code": """initial_velocity = 6~16   damping = 4~6
collision_bounce = 0.45""",
		"try": "폭발 재생 → 리본이 바닥에 맞고 튀어 오른다",
	},
]

var _repeat := 8.0
var _scrub_t := 0.03
var _show_polar := false
var _use_offset := true


func _ready() -> void:
	world.set_autofire(false)
	world.set_target_visible(false)
	world.set_stationary_visible(false)


func get_chapter_title() -> String:
	return "임팩트 — 0.075초의 지휘"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.clear_impacts()
	world.set_flash_visible(false)
	match index:
		0:
			_frame_impact(4.0)
			world.play_impact()
		1:
			_frame_flash()
			world.set_flash_visible(true)
			world.set_flash_param("spikes_repeat", _repeat)
			world.set_flash_param("use_offset", 1.0)
			world.set_flash_param("debug_mode", 1 if _show_polar else 0)
			update_code(_repeat_code())
		2:
			_frame_flash()
			world.set_flash_visible(true)
			world.set_flash_param("spikes_repeat", _repeat)
			world.set_flash_param("debug_mode", 0)
			world.set_flash_param("use_offset", 1.0 if _use_offset else 0.0)
		3:
			_frame_impact(3.0)
			world.make_scrub_impact()
			world.scrub_impact(_scrub_t)
			update_code(_scrub_code())
		4:
			_frame_impact(4.0)
			world.play_impact()


func _frame_impact(distance: float) -> void:
	world.camera_rig.position = Vector3(0.0, 0.8, 0.0)
	world.camera_rig.set_view(0.5, -0.25, distance)


func _frame_flash() -> void:
	world.camera_rig.position = Vector3(0.0, 1.5, 0.0)
	world.camera_rig.set_view(0.0, -0.06, 2.2)


func build_panel(parent: VBoxContainer) -> void:
	var replay := Button.new()
	replay.text = "폭발 재생"
	replay.pressed.connect(func() -> void: world.play_impact())
	parent.add_child(replay)
	bind_steps([replay], [0, 4])

	add_slider(parent, "별 갈래 수", 2.0, 16.0, _repeat, _on_repeat_changed, [1])
	add_toggle(parent, "극좌표 각도 보기", _show_polar, _on_polar_toggled, [1])
	add_toggle(parent, "curve_y 변조", _use_offset, _on_offset_toggled, [2])
	var scrub := add_slider(parent, "타임라인 (초)", 0.0, 0.075, _scrub_t, _on_scrub_changed, [3])
	scrub.step = 0.001


func _on_repeat_changed(value: float) -> void:
	_repeat = roundf(value)
	world.set_flash_param("spikes_repeat", _repeat)
	if current_step == 1:
		update_code(_repeat_code())


func _on_polar_toggled(pressed: bool) -> void:
	_show_polar = pressed
	if current_step == 1:
		world.set_flash_param("debug_mode", 1 if pressed else 0)


func _on_offset_toggled(pressed: bool) -> void:
	_use_offset = pressed
	if current_step == 2:
		world.set_flash_param("use_offset", 1.0 if pressed else 0.0)


func _on_scrub_changed(value: float) -> void:
	_scrub_t = value
	world.scrub_impact(value)
	if current_step == 3:
		update_code(_scrub_code())


func _repeat_code() -> String:
	return ("spikes = curve(p_uv.y * %.0f).x\n" % _repeat
			+ "// 원본: p_uv.y * 8.0 ← 슬라이더")


func _scrub_code() -> String:
	var material := world.scrub_flash_material()
	if material == null:
		return ""
	var intensity: float = material.get_shader_parameter("intensity")
	var flash_scale: float = material.get_shader_parameter("scale")
	return ("# t = %.3fs ← 슬라이더\n" % _scrub_t
			+ "intensity = %.2f\n" % intensity
			+ "scale = %.2f" % flash_scale)
