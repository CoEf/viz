extends WaterChapter
## 챕터 2 — 법선 축. 파도를 밀어도 법선을 안 고치면 빛은 아무것도 모른다.

const STEPS: Array[Dictionary] = [
	{
		"title": "정점만 밀고 법선은 그대로 두기",
		"body": """13번 vertex()는 VERTEX.y만 건드린다.
법선은 판을 만들 때의 [b]위쪽 그대로[/b]다.
그래서 파도가 실루엣으로만 보이고,
수면은 각도와 상관없이 균일하게 칠해진다.""",
		"chips": [{"icon": "shader", "text": "13_toon_style_3d_water vertex()"}],
		"code": """void vertex() {
    float wave = calculate_wave_height(...);
    VERTEX.y += wave;   // NORMAL 안 건드림
}""",
		"try": "가장자리 실루엣은 물결치는데 면은 평평하다",
	},
	{
		"title": "높이를 네 번 더 재서 법선 만들기",
		"body": """1번은 파형 함수를 [b]앞뒤·좌우로 한 번씩 더[/b] 부른다.
0.1만큼 떨어진 두 높이의 차가 곧 기울기고,
그 기울기를 뒤집으면 법선이다 — 유한차분.
같은 파도인데 이제 면마다 밝기가 다르다.""",
		"chips": [{"icon": "shader", "text": "01_pixel_art_water vertex()"}],
		"code": """vec2 e = vec2(0.1, 0.0);
NORMAL = normalize(vec3(
    wave(p-e)*v  - wave(p+e)*v,
    1.0 * e.x,
    wave(p-e.yx)*v - wave(p+e.yx)*v));""",
		"try": "마루와 골의 밝기 차이 — 왼쪽엔 없다",
	},
	{
		"title": "파형을 미분해서 접선 얻기",
		"body": """3번은 높이를 다시 재지 않는다.
게르스트너 식은 미분이 손으로 풀리므로,
파도를 더할 때 [b]접선·종법선도 같이[/b] 누적한다.
샘플 네 번을 아낀 대신 파형을 못 바꾼다.""",
		"chips": [{"icon": "shader", "text": "03_realistic_water wave()"}],
		"code": """tangent  += normalize(vec3(1.0 - ..., ...));
binormal += normalize(vec3(..., ...));
NORMAL = normalize(cross(binormal, tangent));""",
		"try": "잔물결의 음영 밀도 — 오른쪽이 훨씬 촘촘하다",
	},
	{
		"title": "법선맵 두 장을 섞어 잔물결 얹기",
		"body": """정점을 더 쪼갤 수는 없으니, 17번은 [b]법선만[/b] 얹는다.
스크롤하는 법선맵 두 장을 반반 섞어 NORMAL_MAP에 넣는다.
기하는 그대로인데 표면만 잘게 일렁인다.""",
		"chips": [
			{"icon": "shader", "text": "17_water_toon_like_44 fragment()"},
			{"icon": "texture", "text": "norRand1 · norRand2"},
		],
		"code": """NORMAL_MAP = mix(
    texture(norRand1, (worldXZ+offSet)*ns),
    texture(norRand2, (worldXZ+offSet)*ns),
    0.5).rgb;""",
		"try": "노이즈 배율 슬라이더 — 잔물결의 크기가 바뀐다",
	},
	{
		"title": "법선맵을 능선 노이즈로 만들기",
		"body": """둘 다 1번이고, 다른 건 [b]법선맵의 프랙탈 종류[/b] 하나다.
왼쪽 FRACTAL_RIDGED는 날카로운 능선을 만들고,
pow(NdotH, 324)짜리 좁은 스펙큘러가 그 능선에서만 터진다.
오른쪽 FBM은 능선이 없어 그 반짝임이 눈에 띄게 줄어든다.""",
		"chips": [
			{"icon": "resource", "text": "FastNoiseLite.FRACTAL_RIDGED"},
			{"icon": "script", "text": "water_textures.gd"},
		],
		"code": """spec = pow(NdotH, 18.0 * 18.0);
SPECULAR_LIGHT += 0.17*spec*LIGHT_COLOR;""",
		"try": "수면에 흩뿌려진 흰 점 — 왼쪽이 훨씬 많고 날카롭다",
	},
]

const RIDGED := {"id": 1, "label": "01 · RIDGED (원본)"}
const FBM := {
	"id": 1, "label": "01 · FBM",
	"textures": {"normal_noise": &"pw_normal_1_fbm", "normal_noise2": &"pw_normal_2_fbm"},
}

var _shininess := 18.0
var _noise_scale := 0.02


func get_chapter_title() -> String:
	return "법선 — 반짝임을 어디서 얻는가"


func get_steps() -> Array[Dictionary]:
	return STEPS


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "잔물결 배율 (noiseScaler)", 0.005, 0.06, _noise_scale, _on_noise_scale, [3])
	add_slider(parent, "광택 (shine_shininess)", 0.0, 32.0, _shininess, _on_shininess, [4])


func apply_step(index: int) -> void:
	world.set_dive(false)
	world.set_canvas(null)
	world.set_postfx(null)
	world.set_overlay(null)
	match index:
		0:
			world.show_plots([13])
		1:
			world.show_plots([13, 1])
		2:
			world.show_plots([1, 3])
		3:
			world.show_plots([3, {"id": 17, "params": {"noiseScaler": _noise_scale}}])
		_:
			world.show_plots([
				_with_shininess(RIDGED),
				_with_shininess(FBM),
			])
	# 반짝임은 해의 반사 경로가 화면 안에 있을 때만 보인다. 태양이 방위 145도에
	# 있으므로 카메라를 그 반대쪽에 둔다. 마지막 스텝은 픽셀 단위 차이를 보는
	# 것이라 바깥쪽 모서리를 잘라내고 더 붙는다.
	if index == 4:
		world.frame(-0.60, -0.40, 0.86)
	else:
		world.frame(-0.60, -0.46, 1.04)
	_push_code()


func _with_shininess(spec: Dictionary) -> Dictionary:
	var copy: Dictionary = spec.duplicate(true)
	copy["params"] = {"shine_shininess": _shininess}
	return copy


func _on_noise_scale(value: float) -> void:
	_noise_scale = value
	if current_step == 3:
		world.set_param(1, "noiseScaler", value)


func _on_shininess(value: float) -> void:
	_shininess = value
	if current_step == 4:
		world.set_param_all("shine_shininess", value)
	_push_code()


func _push_code() -> void:
	if current_step == 4:
		update_code("""spec = pow(NdotH, %.1f * %.1f);   <- 슬라이더
// 지수 %d 짜리 아주 좁은 스펙큘러
SPECULAR_LIGHT += 0.17*spec*LIGHT_COLOR;"""
				% [_shininess, _shininess, int(_shininess * _shininess)])
