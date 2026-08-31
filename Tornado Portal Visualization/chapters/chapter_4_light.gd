extends TornadoChapter
## 챕터 4 — 빛기둥·헤일로·파티클. unshaded ALBEDO를 1 이상으로 올려
## EMISSION 없이 블룸을 얻고, 어트랙터 강도 하나로 파티클 흐름을 뒤집는다.

const STEPS: Array[Dictionary] = [
	{
		"title": "그라디언트 두 장 분리하기",
		"body": """원뿔의 색은 [b]색상 그라디언트 × 밝기 그라디언트[/b].
나누면 색조를 건드리지 않고 노출만 조정할 수 있다.
unshaded라 ALBEDO가 1을 넘으면 [b]EMISSION 없이 블룸[/b].""",
		"chips": [
			{"icon": "shader", "text": "portal_light.gdshader"},
			{"icon": "texture", "text": "gradient / intensity_gradient"},
		],
		"code": """ALBEDO = color * intensity
    * texture(intensity_grad, UV.y).rgb;""",
		"try": "intensity를 올리면 → 색은 그대로, 블룸만 짙어진다",
	},
	{
		"title": "가로 한 줄짜리 노이즈",
		"body": """헤일로의 노이즈 텍스처는 [b]height = 1[/b] — 1D다.
둘레 방향만 필요하니 세로 해상도가 낭비.
속도 다른 두 샘플을 [b]곱해[/b] 얼룩을 성기게 만든다.""",
		"chips": [
			{"icon": "shader", "text": "halo_light.gdshader"},
			{"icon": "texture", "text": "NoiseTexture2D height=1"},
		],
		"code": """a = tex(noise, UV.x + TIME * 0.05);
b = tex(noise, UV.x + TIME * 0.02);
m = smoothstep(0.2, 0.8, a * b);""",
		"try": "느리게 흐르는 두 겹의 세로 띠를 관찰",
	},
	{
		"title": "어트랙터로 흐름 뒤집기",
		"body": """파티클은 중력 +8/+4로 솟고 turbulence로 나선을 그린다.
2.3초에 어트랙터 strength가 [b]0→40[/b] —
솟던 것들이 한순간에 아래로 빨려 내려간다.""",
		"chips": [
			{"icon": "node3d", "text": "GPUParticlesAttractorSphere3D"},
			{"icon": "resource", "text": "turbulence_enabled"},
		],
		"try": "40까지 올리면 → 상승하던 나선이 꺾여 떨어진다",
	},
]

var _intensity := 3.5
var _strength := 0.0


func _ready() -> void:
	world.stop()
	world.camera_rig.position = Vector3(0.0, 1.0, 0.0)
	world.camera_rig.set_view(0.5, -0.2, 7.0)


func get_chapter_title() -> String:
	return "빛과 파티클 — 기둥·헤일로·나선"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.stop()
	world.spin_target = false
	world.reset_hole_params(1.0)
	world.set_attractor_strength(0.0)
	match index:
		0:
			world.solo(true, false, false, false)
			world.light_material().set_shader_parameter("intensity", _intensity)
			update_code(_intensity_code())
		1:
			world.solo(true, true, false, false)
			world.halo_material().set_shader_parameter("alpha", 1.0)
			world.camera_rig.set_view(0.5, -0.12, 4.5)
		2:
			world.solo(true, false, false, true)
			world.set_attractor_strength(_strength)
			# 시각화용: 나선이 이미 형성된 시점부터 보여준다
			for particles: GPUParticles3D in [world.trails, world.smalls]:
				particles.preprocess = 1.2
				particles.restart()
				particles.emitting = true
	if index != 1:
		world.camera_rig.set_view(0.5, -0.2, 7.0)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "intensity (블룸)", 0.5, 8.0, _intensity, _on_intensity_changed, [0])
	add_slider(parent, "어트랙터 strength", 0.0, 40.0, _strength, _on_strength_changed, [2])


func _on_intensity_changed(value: float) -> void:
	_intensity = value
	world.light_material().set_shader_parameter("intensity", value)
	if current_step == 0:
		update_code(_intensity_code())


func _on_strength_changed(value: float) -> void:
	_strength = value
	world.set_attractor_strength(value)


func _intensity_code() -> String:
	return ("ALBEDO = color * %.1f\n" % _intensity
			+ "    * intensity_grad; // >1 = 블룸 ← 슬라이더")
