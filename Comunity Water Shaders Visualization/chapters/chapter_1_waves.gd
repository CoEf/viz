extends WaterChapter
## 챕터 1 — 파도 축. 정점을 무엇으로 미는가. 네 가지가 전혀 다른 선택을 한다.

## 3번의 원작자 기본값. 슬라이더는 wave_a의 가파름을 잡고, b·c는 같은 비율로
## 따라가게 한다 — 셋 중 하나만 세우면 파형이 통째로 무너진다.
const STEEP_A := 0.35
const STEEP_B := 0.30
const STEEP_C := 0.25

const STEPS: Array[Dictionary] = [
	{
		"title": "사인과 코사인을 하나씩 겹쳐 밀기",
		"body": """13번의 파도는 [b]두 줄이 전부[/b]다.
x로 사인, z로 코사인을 잰 뒤 평균 내서 VERTEX.y에 더한다.
텍스처도 노이즈도 없다.""",
		"chips": [
			{"icon": "shader", "text": "13_toon_style_3d_water vertex()"},
			{"icon": "node3d", "text": "PlaneMesh subdivide 96"},
		],
		"code": """wave_x = sin(pos.x*wave_frequency + t*speed);
wave_y = cos(pos.y*wave_frequency + t*speed);
VERTEX.y += (wave_x+wave_y) * 0.5 * 0.25;""",
		"try": "진폭 슬라이더 — 코드의 마지막 숫자가 같이 바뀐다",
	},
	{
		"title": "주파수가 다른 파를 하나 더 얹기",
		"body": """오른쪽 11번은 같은 사인을 [b]두 벌[/b] 돌린다.
느린 큰 파(0.15) 위에 1.3배 촘촘한 잔파(0.05)를 얹는다.
왼쪽의 규칙적인 격자무늬가 깨지는 게 그 차이다.""",
		"chips": [{"icon": "shader", "text": "11_wind_waker_water vertex()"}],
		"code": """d1 = mod(uv.x + uv.y, M_2PI);
d2 = mod((uv.x + uv.y + 0.25)*1.3, M_6PI);
dist.y = cos(d1)*0.15 + cos(d2)*0.05;""",
		"try": "수면의 마루가 어디서 만나고 어디서 끊기는지",
	},
	{
		"title": "게르스트너로 마루를 뾰족하게 만들기",
		"body": """사인파는 마루와 골이 대칭이라 언제나 둥글다.
3번은 정점을 위아래뿐 아니라 [b]수평으로도[/b] 당긴다.
마루로 몰린 정점이 능선을 세운다.""",
		"chips": [{"icon": "shader", "text": "03_realistic_water wave()"}],
		"code": """return vec4(d.x * (a * cos(f)),
            a * sin(f) * 0.25,
            d.y * (a * cos(f)), 0.0);""",
		"try": "가파름 슬라이더를 올리면 마루가 뾰족해진다",
	},
	{
		"title": "노이즈 텍스처를 높이로 읽기",
		"body": """1번은 파형을 계산하지 않고 [b]노이즈 두 장을 샘플[/b]한다.
스크롤 방향이 다른 두 장을 더해 높이를 만든다.
식으로 못 만드는 불규칙한 수면이 이렇게 나온다.""",
		"chips": [
			{"icon": "shader", "text": "01_pixel_art_water wave()"},
			{"icon": "texture", "text": "vertex_noise_big ×2"},
		],
		"code": """s += texture(vertex_noise_big,  m1).r * a1;
s += texture(vertex_noise_big2, m2).r * a2;
VERTEX.y += wave(...) * height_scale;""",
		"try": "물결의 반복 주기를 찾아보면 — 안 보인다",
	},
	{
		"title": "판을 잘게 쪼개 두기",
		"body": """같은 13번이다. 오른쪽만 [b]분할이 0[/b] — 정점이 네 개다.
정점 셰이더는 [b]있는 정점만[/b] 밀 수 있어서,
파도가 아니라 판 한 장이 통째로 기울어진다.
원본 갤러리가 수면을 127분할로 까는 이유다.""",
		"chips": [
			{"icon": "resource", "text": "PlaneMesh.subdivide_width"},
			{"icon": "script", "text": "water_plot.gd"},
		],
		"code": """plane.subdivide_width = 96
plane.subdivide_depth = 96""",
		"try": "오른쪽엔 마루도 골도 없다 — 모서리 네 개가 전부다",
	},
]

var _amplitude := 0.25
var _steepness := STEEP_A


func get_chapter_title() -> String:
	return "파도 — 정점을 무엇으로 미는가"


func get_steps() -> Array[Dictionary]:
	return STEPS


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "파도 진폭 (wave_amplitude)", 0.0, 0.8, _amplitude, _on_amplitude, [0])
	add_slider(parent, "파도 가파름 (wave_a.z)", 0.0, 0.9, _steepness, _on_steepness, [2])


func apply_step(index: int) -> void:
	world.set_dive(false)
	world.set_canvas(null)
	world.set_postfx(null)
	world.set_overlay(null)
	match index:
		0:
			world.show_plots([{"id": 13, "params": {"wave_amplitude": _amplitude}}])
		1:
			world.show_plots([13, 11])
		2:
			world.show_plots([13, {"id": 3, "params": _wave_params(_steepness)}])
		3:
			world.show_plots([3, 1])
		_:
			world.show_plots([
				{"id": 13, "label": "13 · 분할 96"},
				{"id": 13, "label": "13 · 분할 0", "subdiv": 0},
			])
	world.frame(0.30, -0.46, 1.04)
	_push_code()


## 3번은 파도 세 벌을 vec4(방향x, 방향z, 가파름, 파장)로 받는다. 파장은
## 원작자 값 그대로 두고 가파름만 같은 비율로 흔든다.
func _wave_params(steepness: float) -> Dictionary:
	var ratio: float = steepness / STEEP_A
	return {
		"wave_a": Vector4(1.0, 1.0, steepness, 3.0),
		"wave_b": Vector4(1.0, 0.6, STEEP_B * ratio, 1.55),
		"wave_c": Vector4(1.0, 1.3, STEEP_C * ratio, 0.9),
	}


func _on_amplitude(value: float) -> void:
	_amplitude = value
	if current_step == 0:
		world.set_param(0, "wave_amplitude", value)
	_push_code()


func _on_steepness(value: float) -> void:
	_steepness = value
	if current_step == 2:
		var params: Dictionary = _wave_params(value)
		for key: String in params:
			world.set_param(1, key, params[key])
	_push_code()


func _push_code() -> void:
	if current_step == 0:
		update_code("""wave_x = sin(pos.x*wave_frequency + t*speed);
wave_y = cos(pos.y*wave_frequency + t*speed);
VERTEX.y += (wave_x+wave_y) * 0.5 * %.2f;
                                     ^ 슬라이더""" % _amplitude)
	elif current_step == 2:
		update_code("""wave_a = vec4(1.0, 1.0, %.2f, 3.0);
                        ^ 가파름 <- 슬라이더
return vec4(d.x * (a * cos(f)),
            a * sin(f) * 0.25,
            d.y * (a * cos(f)), 0.0);""" % _steepness)
