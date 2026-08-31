extends HalloweenChapter
## 챕터 5 — 타임라인(지휘자). 42개 트랙이 5초 동안 무엇을 언제 하는지.
## 모든 시스템을 만난 뒤에야 이 챕터가 의미를 가진다.

const STEPS: Array[Dictionary] = [
	{
		"title": "지휘 스크립트는 두 줄뿐",
		"body": """파티클 켜기도, uniform 몰기도, 노드 scale도
전부 [b]애니메이션 트랙 42개[/b]가 한다.
스크립트는 재생하고, 끝나면 자신을 지울 뿐.""",
		"chips": [
			{"icon": "script", "text": "explosion.gd"},
			{"icon": "node3d", "text": "AnimationPlayer"},
		],
		"code": """animation_player.play("default")
# animation_finished → queue_free()""",
		"try": "폭발 재생 → 이 모든 게 트랙이다",
	},
	{
		"title": "5초를 손으로 훑기",
		"body": """0~0.6초 섬광과 균열(짧고 밝다),
0~3초 링 5장(서로 다른 속도),
0.1~4.5초 버섯구름(혼자 긴 호흡).""",
		"chips": [{"icon": "resource", "text": "Animation \"default\" 5.0s"}],
		"try": "0.4초 근처 → 균열이 세 배로 타는 절정",
	},
	{
		"title": "복제 링은 0.5초 늦게",
		"body": """ExplosionRing2는 같은 셰이더, 같은 2.5초 모션에
[b]트랙 시작만 0.5초 뒤[/b]로 민 복제다.
노드 하나 복제로 압력파 밀도가 배가 된다.""",
		"chips": [{"icon": "node3d", "text": "ExplosionRing2"}],
		"code": """Ring : scale 0→2.2  (0.0 ~ 2.5s)
Ring2: scale 0.4→2.6 (0.5 ~ 3.0s)""",
		"try": "0.5~1.5초 훑기 → 두 링이 시차로 따라온다",
	},
	{
		"title": "끝은 가장 느린 요소가 정한다",
		"body": """가장 느린 버섯구름이 4.5초에 끝난다.
애니메이션 길이 5.0초 = 4.5 + 여유 0.5.
바깥은 [b]tree_exited[/b]로 다음 사이클을 잇는다.""",
		"chips": [{"icon": "signal", "text": "animation_finished"}],
		"code": """explosion.tree_exited.connect(
    jack_o_lantern.idle) # 다음 사이클""",
		"try": "4.5초 이후로 → 화면에 남는 건 잔불뿐",
	},
	{
		"title": "카메라 셰이크 얹기",
		"body": """위치·회전이 아니라 [b]h_offset / v_offset[/b]을 흔든다 —
프러스텀 오프셋이라 오빗 카메라와 충돌하지 않는다.
i%2로 부호를 뒤집고 두 축의 횟수를 다르게(4~6).""",
		"chips": [{"icon": "script", "text": "turner/camera.gd shake()"}],
		"code": """shake_value("h_offset", randi_range(4,6))
v = vector if bool(i % 2) else -vector""",
		"try": "흔들며 재생 → 명중감이 확 달라진다",
	},
]

var _scrub_t := 0.4


func _ready() -> void:
	world.camera_rig.position = Vector3(0.0, 2.0, 0.0)
	world.camera_rig.set_view(0.5, -0.25, 11.0)
	world.play_explosion.call_deferred()


func get_chapter_title() -> String:
	return "타임라인 — 42개 트랙의 지휘"


func get_steps() -> Array[Dictionary]:
	return STEPS


func _ensure_scrub_lab() -> void:
	world.clear_explosions()
	world.make_lab()
	world.lab_show_all()
	world.lab_scrub_start()
	world.lab_seek(_scrub_t)
	update_code(_scrub_code())


func apply_step(index: int) -> void:
	match index:
		0:
			world.clear_lab()
			world.play_explosion()
		1, 2, 3:
			_ensure_scrub_lab()
		4:
			world.clear_lab()
			world.play_explosion()
			world.shake_camera()


func build_panel(parent: VBoxContainer) -> void:
	var replay := Button.new()
	replay.text = "폭발 재생"
	replay.pressed.connect(func() -> void: world.play_explosion())
	parent.add_child(replay)
	bind_steps([replay], [0])

	var scrub := add_slider(parent, "타임라인 (초)", 0.0, 5.0, _scrub_t, _on_scrub_changed, [1, 2, 3])
	scrub.step = 0.01

	var shake := Button.new()
	shake.text = "흔들며 재생"
	shake.pressed.connect(func() -> void:
		world.play_explosion()
		world.shake_camera())
	parent.add_child(shake)
	bind_steps([shake], [4])


func _on_scrub_changed(value: float) -> void:
	_scrub_t = value
	if current_step >= 1 and current_step <= 3:
		world.lab_seek(value)
		update_code(_scrub_code())


func _scrub_code() -> String:
	return "# t = %.2fs ← 슬라이더\n# %s" % [_scrub_t, _phase_for(_scrub_t)]


func _phase_for(t: float) -> String:
	if t < 0.4:
		return "섬광 최대, 균열이 확 번진다"
	if t < 0.6:
		return "섬광 소멸, ExplosionRing2 출발"
	if t < 1.0:
		return "링 팽창, 버섯구름 성장"
	if t < 1.5:
		return "FireRing·WindHalo·WindRing 소멸"
	if t < 2.5:
		return "링 식음, 균열 알파 빠지기 시작"
	if t < 3.0:
		return "ExplosionRing2 소멸"
	if t < 3.5:
		return "구름 홀로 — 얼굴이 사라지는 중"
	if t < 4.5:
		return "구름이 흩어진다"
	return "잔불만 남음 (여유 0.5초)"
