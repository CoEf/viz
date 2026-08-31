extends FireballChapter
## 챕터 2 — 코어. 4줄짜리 프레넬+step 셰이더를 값 그대로 열어 본다.
## 이 저장소 전체에서 반복되는 "잘라서 형태, 안 자른 값으로 강도" 패턴의 원형.

const STEPS: Array[Dictionary] = [
	{
		"title": "프레넬 원값 보기",
		"body": """프레넬은 [b]시선과 법선이 벌어진 정도[/b]다.
정면은 0(검정), 가장자리로 갈수록 1(흰색).
어느 각도에서 봐도 가장자리가 밝다.""",
		"chips": [
			{"icon": "shader", "text": "fireball_core.gdshader"},
			{"icon": "shader", "text": "fresnel.gdshaderinc"},
		],
		"code": "float f = fresnel(1.0, NORMAL, VIEW);",
		"try": "드래그로 회전 → 밝은 테두리가 시선을 따라온다",
	},
	{
		"title": "step으로 딱 잘라 이분화하기",
		"body": """부드러운 그라데이션을 [b]문턱값 하나로[/b] 0/1로 자른다.
하드 엣지 스타일라이즈드 룩의 최소 비용 공식.""",
		"chips": [{"icon": "shader", "text": "step()"}],
		"try": "문턱값을 내리면 → 흰 테가 두꺼워진다",
	},
	{
		"title": "자른 값으로 색, 원값으로 강도",
		"body": """마스크로는 색을 [b]교체[/b]하고(mix),
원값 f로는 발광을 [b]연속으로[/b] 키운다.
같은 프레넬을 두 번 다르게 쓰는 게 핵심.""",
		"chips": [{"icon": "shader", "text": "fireball_core fragment()"}],
		"code": """ALBEDO = mix(albedo, emission, mask);
EMISSION = ALBEDO * 2.0 * f;""",
		"try": "문턱값 슬라이더 → 주황 테두리 폭이 변한다",
	},
	{
		"title": "껍질 틈으로 비치게 하기",
		"body": """껍질이 노이즈로 뜯긴 틈으로
[b]어두운 코어와 그 가장자리의 밝은 림[/b]이 비친다.
이 레이어링이 파이어볼 부피감의 정체다.""",
		"chips": [
			{"icon": "node3d", "text": "FireballShellMesh"},
			{"icon": "node3d", "text": "Core"},
		],
		"try": "드래그로 돌려 뜯긴 틈새로 코어 찾기",
	},
]

var _threshold := 0.4


func _ready() -> void:
	world.set_autofire(false)
	world.set_target_visible(false)
	world.set_stationary_visible(true)
	world.set_stationary_inertia(false)
	world.set_shell_visible(false)
	world.set_core_visible(true)
	world.set_trail_emitting(false)
	world.set_smoke_emitting(false)
	world.camera_rig.position = Vector3(0.0, 1.5, 0.0)


func get_chapter_title() -> String:
	return "코어 — 프레넬 + step 네 줄"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_core_params()
	world.set_core_param("rim_threshold", _threshold)
	match index:
		0:
			world.set_shell_visible(false)
			world.set_core_param("debug_mode", 1)
			world.camera_rig.set_view(0.65, -0.18, 0.9)
		1:
			world.set_shell_visible(false)
			world.set_core_param("debug_mode", 2)
			world.camera_rig.set_view(0.65, -0.18, 0.9)
			update_code(_threshold_code())
		2:
			world.set_shell_visible(false)
			world.camera_rig.set_view(0.65, -0.18, 0.9)
		3:
			world.reset_shell_params()
			world.set_shell_visible(true)
			world.camera_rig.set_view(0.65, -0.18, 2.6)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "림 문턱값", 0.05, 0.95, _threshold, _on_threshold_changed, [1, 2])


func _on_threshold_changed(value: float) -> void:
	_threshold = value
	world.set_core_param("rim_threshold", value)
	if current_step == 1:
		update_code(_threshold_code())


func _threshold_code() -> String:
	return "float mask = step(%.2f, f); ← 슬라이더" % _threshold
