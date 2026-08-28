extends SnowChapter
## 챕터 1 — 무대(환경) 요소를 하나씩 켠다. 눈은 전부 끈 '눈 오기 전' 상태.

const STEPS: Array[Dictionary] = [
	{
		"title": "환경을 모두 끄고 시작하기",
		"body": """비교 기준을 만든다.
지금 있는 건 바닥·소품·태양(그림자)뿐.""",
		"chips": [
			{"icon": "node3d", "text": "DirectionalLight3D"},
			{"icon": "resource", "text": "PlaneMesh 40×40m"},
		],
		"code": """# Ground: PlaneMesh
subdivide_width = 250    # ← 챕터 4 복선
# Sun: DirectionalLight3D
shadow_enabled = true""",
		"try": "그늘 색을 기억하기 — 다음 스텝과 비교",
	},
	{
		"title": "하늘로 배경과 주변광 만들기",
		"body": """하늘 하나가 [b]배경[/b]이자 [b]주변광[/b]이 된다.
태양이 닿지 않는 그늘도 하늘빛을 머금는다.""",
		"chips": [
			{"icon": "node3d", "text": "WorldEnvironment"},
			{"icon": "resource", "text": "Environment"},
		],
		"code": """# 하늘: ProceduralSkyMaterial
background_mode = BG_SKY
ambient_light_source = AMBIENT_SOURCE_SKY""",
	},
	{
		"title": "안개로 거리감 만들기",
		"body": """멀리 있는 것일수록 안개색에 가깝게 섞인다.
멀어질수록 물러나 보여 [b]깊이[/b]가 생긴다.""",
		"chips": [{"icon": "resource", "text": "Environment"}],
		"try": "안개 슬라이더 조절",
	},
	{
		"title": "글로우로 밝은 빛 번지게 하기",
		"body": """[b]1.0보다 밝은 값은 주변으로 번진다.[/b]
챕터 5의 반짝임이 이 성질을 쓴다.""",
		"chips": [{"icon": "resource", "text": "Environment"}],
		"code": """glow_enabled = true
tonemap_mode = TONE_MAPPER_ACES""",
		"try": "이전 스텝과 밝은 부분 비교",
	},
]

var _environment: Environment


func _ready() -> void:
	_environment = world.environment()
	world.set_snowfall_enabled(false)
	world.set_fall_ratio(0.0)
	world.set_track_maker_enabled(false)
	WinterWorld.set_global_cover(0.0)
	world.camera_rig.set_view(0.9, -0.3, 18.0)


func get_chapter_title() -> String:
	return "무대 만들기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	if index == 0:
		world.world_environment.environment = null
		return
	world.world_environment.environment = _environment
	_environment.fog_enabled = index >= 2
	_environment.glow_enabled = index >= 3
	if index == 2:
		update_code(_fog_code())


func build_panel(parent: VBoxContainer) -> void:
	# 안개는 스텝 2부터 켜진다. 그 전 스텝에서는 슬라이더를 아예 치운다.
	add_slider(parent, "안개 진하기", 0.0, 1.0, 0.3, _on_fog_changed, [2, 3])


func _on_fog_changed(value: float) -> void:
	world.set_fog(value)
	if current_step == 2:
		update_code(_fog_code())


func _fog_code() -> String:
	return "fog_enabled = true\nfog_density = %.4f   # ← 안개 슬라이더" % _environment.fog_density
