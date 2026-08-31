extends FireworksChapter
## 챕터 3 — 폭발. 같은 씬에 색·속도·개수를 주입해 매번 다른 불꽃을 만든다.

const STEPS: Array[Dictionary] = [
	{
		"title": "파라미터를 런타임에 주입하기",
		"body": """setup(색, 속도, 트레일 수) — 같은 씬으로 매번 다른 불꽃.
색은 [b]Gradient 리소스를 랜덤 샘플링[/b],
계층은 lightened(0.2/0.5)로 색조 유지한 채 밝기만.""",
		"chips": [{"icon": "script", "text": "firework_explosion.gd setup()"}],
		"try": "속도·개수를 바꿔 터뜨려 보라",
	},
	{
		"title": "amount는 곱셈으로 유도",
		"body": """파티클 amount는 풀 크기 — 부족하면 살아 있는 것이
재사용되며 끊긴다. [b]트레일 수 × 초당 8발[/b]로
유도하면 개수를 어떻게 바꿔도 풀이 따라온다.""",
		"chips": [{"icon": "script", "text": "sparks.amount"}],
		"code": """sparks.amount =
    trails_count * small_sparks""",
		"try": "64개로 터뜨려도 잔불꽃이 안 끊긴다",
	},
	{
		"title": "색 변화를 커브로",
		"body": """hue_variation 커브 — 갓 터졌을 땐 개체마다 색이
살짝 다르고 사라질 때쯤 [b]한 색으로 수렴[/b]한다.
alpha 커브는 수명 절반까지 완전 불투명을 유지.""",
		"chips": [{"icon": "resource", "text": "hue_variation_curve"}],
		"code": """hue_variation_max = 0.05
alpha_curve: (0.5, 1) → (1, 0)""",
	},
]

var _velocity := 5.0
var _count := 48.0


func _ready() -> void:
	world.set_show_running(false)
	world.camera_rig.position = Vector3(0.0, 0.0, 0.0)
	world.camera_rig.set_view(0.4, -0.1, 12.0)
	world.spawn_custom_explosion.call_deferred(5.0, 48)


func get_chapter_title() -> String:
	return "폭발 — setup()이 만드는 다양성"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.spawn_custom_explosion(_velocity, int(_count))
	if index == 0:
		update_code(_setup_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "속도 (base_velocity)", 3.0, 8.0, _velocity, _on_velocity_changed, [0, 1])
	add_slider(parent, "트레일 수", 18.0, 64.0, _count, _on_count_changed, [0, 1])

	var boom := Button.new()
	boom.text = "폭발"
	boom.pressed.connect(func() -> void: world.spawn_custom_explosion(_velocity, int(_count)))
	parent.add_child(boom)
	bind_steps([boom], [])


func _on_velocity_changed(value: float) -> void:
	_velocity = value
	if current_step == 0:
		update_code(_setup_code())


func _on_count_changed(value: float) -> void:
	_count = roundf(value)
	if current_step == 0:
		update_code(_setup_code())


func _setup_code() -> String:
	return ("setup(colors.sample(randf()),\n"
			+ "    %.1f, %.0f) ← 슬라이더" % [_velocity, _count])
