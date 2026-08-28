extends SnowChapter
## 챕터 6 — 지휘자. 컨트롤을 움직이면 신호 로그에 실제 전달 경로가
## 찍히고, 최신 줄이 강조 플래시된다.

const STEPS: Array[Dictionary] = [
	{
		"title": "연결을 한 곳에 모으기",
		"body": """슬라이더 하나가 여러 시스템을 함께 바꿔야 한다.
그 연결을 전부 [b]SnowController[/b] 한 곳에 모았다.
UI → 지휘자 → 시스템, 한 방향으로만 흐른다.""",
		"chips": [{"icon": "script", "text": "snow_controller.gd"}],
		"code": """fall_slider.value_changed.connect(
    _on_fall_changed)
track_maker.moved.connect(
    snow_deform.stamp)""",
	},
	{
		"title": "시그널로 느슨하게 연결하기",
		"body": """슬라이더는 '값이 바뀌었다'고 외칠 뿐
누가 듣는지 모른다.
지휘자가 그 신호를 받아 알맞은 곳에 전달한다.""",
		"chips": [
			{"icon": "signal", "text": "value_changed"},
			{"icon": "script", "text": "snow_controller.gd"},
		],
		"code": """func _on_fall_changed(value: float) -> void:
	_near_flakes.amount_ratio = value
	_far_haze.amount_ratio = value""",
		"try": "컨트롤을 움직여 아래 신호 로그 보기",
	},
	{
		"title": "프리셋 교체로 낮/밤 전환하기",
		"body": """토글 하나가 값 네 가지를 한꺼번에 바꾼다.
설정을 딕셔너리로 묶어 두고 [b]통째로 갈아끼운다.[/b]
태양·하늘·안개·눈송이 밝기가 함께 움직인다.""",
		"chips": [{"icon": "script", "text": "snow_controller.gd"}],
		"code": """preset = NIGHT_PRESET  # 또는 DAY_PRESET
sun.light_energy = preset["sun_energy"]
flake.set_shader_parameter("brightness", 0.6)""",
		"try": "밤 토글 — 겨울밤 감상",
	},
]

var _log_label: RichTextLabel
var _log_lines: PackedStringArray = []
var _flash_tween: Tween


func _ready() -> void:
	world.set_fall_ratio(0.6)
	world.camera_rig.set_view(0.65, -0.38, 14.0)


func get_chapter_title() -> String:
	return "지휘자: 모두 연결하기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "눈 내림 (강도)", 0.0, 1.0, 0.6, _on_fall_changed)
	add_slider(parent, "눈 쌓임", 0.0, 1.0, 0.7, _on_cover_changed)
	add_slider(parent, "반짝임 세기", 0.0, 3.0, 1.0, _on_sparkle_changed)
	add_slider(parent, "안개", 0.0, 1.0, 0.3, _on_fog_changed)
	add_toggle(parent, "밤 (달빛)", false, _on_night_toggled)
	add_caption(parent, "신호 로그")
	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.fit_content = true
	_log_label.scroll_active = false
	_log_label.custom_minimum_size = Vector2(0.0, 110.0)
	_log_label.add_theme_font_size_override("normal_font_size", 13)
	_log_label.text = "(컨트롤을 움직이면 전달 경로가 여기 표시됩니다)"
	parent.add_child(_log_label)


func _on_fall_changed(value: float) -> void:
	world.set_fall_ratio(value)
	_route("눈 내림 슬라이더 → GPUParticles3D.amount_ratio = %.2f" % value)


func _on_cover_changed(value: float) -> void:
	WinterWorld.set_global_cover(value)
	_route("눈 쌓임 슬라이더 → 전역 snow_amount = %.2f" % value)


func _on_sparkle_changed(value: float) -> void:
	WinterWorld.set_global_sparkle(value)
	_route("반짝임 슬라이더 → 전역 sparkle_strength = %.2f" % value)


func _on_fog_changed(value: float) -> void:
	world.set_fog(value)
	_route("안개 슬라이더 → Environment.fog_density = %.4f" % (value * WinterWorld.FOG_DENSITY_MAX))


func _on_night_toggled(night: bool) -> void:
	world.set_night(night)
	_route("밤 토글 → 태양·하늘·안개·눈송이 프리셋 %s" % ("NIGHT" if night else "DAY"))


func _route(message: String) -> void:
	if _log_lines.size() >= 5:
		_log_lines.remove_at(0)
	_log_lines.append(message)
	var lines := PackedStringArray()
	for i in _log_lines.size():
		if i == _log_lines.size() - 1:
			lines.append("[color=#8ecbff]" + _log_lines[i] + "[/color]")
		else:
			lines.append("[color=#8a8f98]" + _log_lines[i] + "[/color]")
	_log_label.text = "\n".join(lines)
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_log_label.modulate = Color(1.6, 1.6, 1.6)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_log_label, "modulate", Color.WHITE, 0.35)
