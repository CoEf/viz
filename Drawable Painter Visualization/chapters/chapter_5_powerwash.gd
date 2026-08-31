extends PainterChapter
## 챕터 5 — 파워워시 응용. 같은 DrawableTexture2D를 색이 아니라
## "얼마나 더러운가" 데이터 마스크로 쓰는 두 번째 소비자.

const STEPS: Array[Dictionary] = [
	{
		"title": "때 마스크 한 장 덮기",
		"body": """이번 캔버스는 색이 아니라 [b]데이터[/b]다.
R=1이면 때, R=0이면 원래 표면 —
표면 셰이더가 mix 비율로 읽는다.""",
		"chips": [
			{"icon": "shader", "text": "dirt_surface.gdshader"},
			{"icon": "resource", "text": "dirt_mask (DrawableTexture2D)"},
		],
		"code": """float dirt = texture(dirt_mask, uv).r;
ALBEDO = mix(clean, dirt_color, dirt);""",
		"try": "오른쪽 마스크의 밝은 곳이 3D의 때 낀 곳이다",
	},
	{
		"title": "3D 캡슐 거리로 지우기",
		"body": """지우개는 UV 보간이 아니라 [b]모델 공간 캡슐[/b]이다.
닿은 삼각형만 골라 그 UV 영역에 블릿하니
UV 섬 경계(심)를 넘어도 자국이 이어진다.""",
		"chips": [
			{"icon": "script", "text": "get_triangles_in_capsule"},
			{"icon": "shader", "text": "erase_dirt_3d.gdshader"},
		],
		"code": """float d = dist_to_segment(pos, a, b);
float fall = 1.0
  - smoothstep(r * 0.3, r, d);""",
		"try": "직접 문질러 씻기 · 압력 슬라이더로 세기 조절",
	},
	{
		"title": "덮인 픽셀만 세어 진행률 내기",
		"body": """1초마다 마스크를 CPU로 내려 32×32로 줄여 센다.
[b]빈 UV 공간은 커버리지 마스크로 제외[/b] —
안 빼면 100%가 영영 안 나온다.""",
		"chips": [
			{"icon": "script", "text": "progress_component.gd"},
			{"icon": "signal", "text": "progress_updated"},
		],
		"code": """img.resize(32, 32, INTERPOLATE_BILINEAR)
avg = dirty / maxf(covered, 1.0)""",
		"try": "씻을수록 아래 CLEAN %가 오른다 (1초마다 갱신)",
	},
]

var _pressure := 0.7
var _progress_label: Label
var _progress_connected := false
var _mask_view: TextureRect


func _ready() -> void:
	world.set_view(PI, -0.18, 0.34)


func get_chapter_title() -> String:
	return "파워워시 응용"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_interactive(index >= 1)
	world.nozzle().pressure = _pressure
	world.use_dirt_surface(index == 2)
	# setup()이 매번 새 dirt_mask를 만들므로 패널 뷰도 새 인스턴스로 갈아 끼운다.
	if _mask_view != null:
		_mask_view.texture = world.dirt_canvas.get_dirt_mask()
	if index >= 1:
		for _pass in 2:
			world.spray_screen_path(
					world.arc_path(Vector2(0.36, 0.5), Vector2(0.64, 0.48), 16, 0.08), 150.0)
	if index == 2 and not _progress_connected:
		world.progress.progress_updated.connect(_on_progress_updated)
		_progress_connected = true
	if _progress_label != null:
		_progress_label.text = "CLEAN: 집계 중…"
	if index == 1:
		update_code(_pressure_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "노즐 압력", 0.1, 1.0, _pressure, _on_pressure_changed, [1, 2])
	_progress_label = Label.new()
	_progress_label.text = "CLEAN: 집계 중…"
	_progress_label.add_theme_font_size_override("font_size", 19)
	parent.add_child(_progress_label)
	bind_steps([_progress_label], [2])
	_mask_view = add_texture_view(
			parent, "dirt_mask (라이브 · R채널)", _dirt_mask_texture(), [], 190.0)


func _dirt_mask_texture() -> Texture2D:
	# build_panel은 apply_step(0)보다 먼저 불린다 — 마스크가 아직 없으면
	# 지연 생성해서라도 같은 인스턴스를 물린다(use_dirt_surface가 재사용).
	if world.dirt_canvas == null:
		world.use_dirt_surface(false)
	return world.dirt_canvas.get_dirt_mask()


func _on_pressure_changed(value: float) -> void:
	_pressure = value
	world.nozzle().pressure = value
	if current_step == 1:
		apply_step(1)


func _on_progress_updated(pct: float) -> void:
	if _progress_label != null:
		_progress_label.text = "CLEAN: %.1f%%" % pct


func _pressure_code() -> String:
	return ("pressure = %.2f   # ← 슬라이더\nfloat fall = 1.0\n  - smoothstep(r * 0.3, r, d);"
			% _pressure)
