extends HalloweenChapter
## 챕터 4 — 불티와 연기. 잔불 64개의 튕김, 큰 불티 12개의 서브이미터,
## flatness로 바닥에 깔리는 연기 원반.

const STEPS: Array[Dictionary] = [
	{
		"title": "길쭉한 불똥 튕기기",
		"body": """0.1×0.4 세로 쿼드에 [b]피벗을 위 끝으로[/b] 옮기고
sin×sin을 step으로 잘라 양끝이 뾰족한 불똥.
rigid 충돌 + bounce 0.4 — 3초를 튀며 구른다.""",
		"chips": [
			{"icon": "node3d", "text": "SmallAmber ×64"},
			{"icon": "shader", "text": "small_amber.gdshader"},
		],
		"code": """ALPHA = step(0.2, sin(UV.x * PI)
    * sin(UV.y * PI)) * mask * COLOR.a""",
		"try": "재생 → 바닥에서 튕겨 구르는 잔불",
	},
	{
		"title": "큰 불티가 연기를 흘리게 하기",
		"body": """리본 불티 12개가 날아가며 [b]서브이미터[/b]로
AmberSmoke 1024개를 궤적에 흘린다.
흘린 연기는 spread 180·아래 중력으로 그 자리에 가라앉는다.""",
		"chips": [
			{"icon": "node3d", "text": "BigAmber ×12"},
			{"icon": "node3d", "text": "AmberSmoke ×1024"},
		],
		"code": "sub_emitter = NodePath(\"../AmberSmoke\")",
		"try": "재생 → 불티가 지나간 자리에 연기 흔적",
	},
	{
		"title": "연기를 바닥에 깔기",
		"body": """spread 180으로 사방에 뿌리되
[b]flatness 0.9가 방출 방향을 XZ 평면으로 누른다[/b].
4×4 대형 쿼드 128장이 바닥을 덮는 연기 원반.""",
		"chips": [{"icon": "resource", "text": "ParticleProcessMaterial"}],
		"try": "flatness 0으로 → 사방 구형으로 퍼져 버린다",
	},
]

var _flatness := 0.9


func _ready() -> void:
	world.make_lab()
	world.camera_rig.position = Vector3(0.0, 2.0, 0.0)
	world.camera_rig.set_view(0.5, -0.22, 10.0)


func get_chapter_title() -> String:
	return "불티와 연기 — 폭발의 여운"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.lab_stop()
	match index:
		0:
			world.lab_solo(["SmallAmber"])
			world.lab_restart_particles(["SmallAmber"])
		1:
			world.lab_solo(["BigAmber", "AmberSmoke"])
			world.lab_restart_particles(["BigAmber"])
		2:
			world.lab_solo(["SmokeParticles"])
			_set_flatness(_flatness)


func _set_flatness(value: float) -> void:
	var particles := world.lab_node("SmokeParticles") as GPUParticles3D
	(particles.process_material as ParticleProcessMaterial).flatness = value
	# 시각화용: 원반이 이미 형성된 시점부터 보여준다 (수명 4초 중 1.2초 선진행)
	particles.preprocess = 1.2
	particles.restart()
	particles.emitting = true


func build_panel(parent: VBoxContainer) -> void:
	var replay := Button.new()
	replay.text = "재생"
	replay.pressed.connect(_on_replay_pressed)
	parent.add_child(replay)
	bind_steps([replay], [])

	add_slider(parent, "flatness (납작함)", 0.0, 0.9, _flatness, _on_flatness_changed, [2])


func _on_replay_pressed() -> void:
	match current_step:
		0:
			world.lab_restart_particles(["SmallAmber"])
		1:
			world.lab_restart_particles(["BigAmber"])
		2:
			_set_flatness(_flatness)


func _on_flatness_changed(value: float) -> void:
	_flatness = value
	if current_step == 2:
		_set_flatness(value)
		update_code("flatness = %.2f ← 슬라이더\n// 원본 0.9 — XZ 평면으로 납작" % value)
