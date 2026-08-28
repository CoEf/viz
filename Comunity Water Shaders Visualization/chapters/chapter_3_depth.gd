extends WaterChapter
## 챕터 3 — 깊이 축. 수심을 아는 열 개와 모르는 아홉 개가 갈리는 지점.
##
## 예시로 17번을 쓴다. 8번도 깊이를 읽지만 불투명(transparent=false)이라 깊이
## 버퍼에 자기 자신이 이미 찍혀 있고, 그래서 바닥까지의 거리가 아니라 거의 0을
## 돌려받는다 — 원본 갤러리의 8번 스크린샷이 온통 흰 것도 그래서다. 수심
## 그라디언트를 보려면 투명하게 그리는 셰이더여야 한다.

const STEPS: Array[Dictionary] = [
	{
		"title": "깊이 버퍼를 월드 좌표로 되돌리기",
		"body": """25개 중 열 개가 [b]hint_depth_texture[/b]를 단다.
읽으면 0~1로 눌린 역Z 값이라 그대로는 못 쓴다.
역투영해서 그 픽셀의 월드 좌표로 되돌린 뒤,
수면 높이에서 빼면 그게 [b]수심[/b]이다.""",
		"chips": [
			{"icon": "shader", "text": "17_water_toon_like_44 fragment()"},
			{"icon": "setting", "text": "hint_depth_texture"},
		],
		"code": """depth = texture(depthTex, SCREEN_UV).x;
ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
world = INV_VIEW_MATRIX
      * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
dis = (nodeY - world.y/world.w) * distScaler;""",
		"try": "얕은 쪽에서 깊은 쪽으로 색이 이어진다 — 이 한 값이다",
	},
	{
		"title": "깊이를 안 읽으면 물가가 없다",
		"body": """왼쪽 11번은 깊이 버퍼를 안 본다.
그래서 바닥이 코앞이든 6m 아래든 [b]똑같은 파랑[/b]이다.
오른쪽 17번은 같은 무대에서 얕은 쪽을 스스로 찾아내고,
기둥과 바위 둘레에 흰 테까지 두른다.""",
		"chips": [
			{"icon": "shader", "text": "11_wind_waker_water"},
			{"icon": "shader", "text": "17_water_toon_like_44"},
		],
		"code": """// 11번 fragment()에는
// DEPTH_TEXTURE도 SCREEN_UV도 없다""",
		"try": "기울어진 바닥이 왼쪽엔 아무 흔적도 안 남긴다",
	},
	{
		"title": "물가 띠의 폭을 정하기",
		"body": """17번은 수심을 [b]임계값 하나로 자른다.[/b]
step() 안쪽이면 흰 테두리 색, 바깥이면 물색.
경계에 노이즈를 곱해서 직선이 아니게 흩어 놓는다.""",
		"chips": [{"icon": "shader", "text": "17_water_toon_like_44 fragment()"}],
		"code": """mixEdge = step(dis, 0.35);
rand = texture(edgeNoise, uv).x;
ALBEDO = mix(ALBEDO, edgeColor.rgb,
             mixAmount * mixEdge);""",
		"try": "물가 폭 슬라이더 — 흰 테가 깊은 쪽으로 번진다",
	},
	{
		"title": "깊이에 지수를 씌워 색을 흡수시키기",
		"body": """17번은 수심을 [b]자르는[/b] 데 쓴다.
3번은 그 값을 exp()에 넣어 [b]깊이만큼 빛을 잃게[/b] 한다.
Beer's law — 물이 두꺼울수록 통과한 빛이 줄어든다.
얕은 색과 깊은 색이 부드럽게 이어지는 이유다.""",
		"chips": [{"icon": "shader", "text": "03_realistic_water fragment()"}],
		"code": """blend = exp((depth+VERTEX.z+off) * -2.00);
blend = clamp(1.0 - blend, 0.0, 1.0);
dye = mix(color_shallow, color_deep, blend);""",
		"try": "흡수 슬라이더 — 오른쪽 물의 바닥이 사라진다",
	},
	{
		"title": "수심이 0에 가까운 띠만 골라 포말 만들기",
		"body": """같은 수심 값을 [b]0 근처에서만[/b] 살리면 교차 포말이 된다.
기둥과 바위가 수면을 뚫은 자리가 정확히 그 띠다.
3번(왼쪽)은 물가 전체에, 13번(오른쪽)은 물체 둘레에 붙는다.""",
		"chips": [{"icon": "shader", "text": "13_toon_style_3d_water calculate_foam()"}],
		"code": """shape = smoothstep(0.0, 0.50, abs(diff));
shape = smoothstep(softness, 0.0, shape);
shape *= smooth_noise(distorted_uv * 10.0);""",
		"try": "포말 폭 슬라이더 — 기둥 둘레의 흰 테가 두꺼워진다",
	},
]

var _edge_threshold := 0.35
var _beers_law := 2.0
var _foam_width := 0.5


func get_chapter_title() -> String:
	return "깊이 — 수심을 어떻게 아는가"


func get_steps() -> Array[Dictionary]:
	return STEPS


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "물가 폭 (edgeThreshold)", 0.0, 1.5, _edge_threshold, _on_edge, [2])
	add_slider(parent, "흡수 (beers_law)", 0.05, 6.0, _beers_law, _on_beers, [3])
	add_slider(parent, "포말 폭 (foam_width)", 0.05, 3.0, _foam_width, _on_foam, [4])


func apply_step(index: int) -> void:
	world.set_dive(false)
	world.set_canvas(null)
	world.set_postfx(null)
	world.set_overlay(null)
	match index:
		0:
			world.show_plots([17])
		1:
			world.show_plots([11, 17])
		2:
			world.show_plots([{"id": 17, "params": {"edgeThreshold": _edge_threshold}}])
		3:
			world.show_plots([17, {"id": 3, "params": {"beers_law": _beers_law}}])
		_:
			world.show_plots([3, {"id": 13, "params": {"foam_width": _foam_width}}])
	world.frame(0.22, -0.46, 1.02)
	_push_code()


func _on_edge(value: float) -> void:
	_edge_threshold = value
	if current_step == 2:
		world.set_param(0, "edgeThreshold", value)
	_push_code()


func _on_beers(value: float) -> void:
	_beers_law = value
	if current_step == 3:
		world.set_param(1, "beers_law", value)
	_push_code()


func _on_foam(value: float) -> void:
	_foam_width = value
	if current_step == 4:
		world.set_param(1, "foam_width", value)
	_push_code()


func _push_code() -> void:
	match current_step:
		2:
			update_code("""mixEdge = step(dis, %.2f);   <- 슬라이더
rand = texture(edgeNoise, uv).x;
ALBEDO = mix(ALBEDO, edgeColor.rgb,
             mixAmount * mixEdge);""" % _edge_threshold)
		3:
			update_code("""blend = exp((depth+VERTEX.z+off) * -%.2f);
                                    ^ 슬라이더
blend = clamp(1.0 - blend, 0.0, 1.0);
dye = mix(color_shallow, color_deep, blend);""" % _beers_law)
		4:
			update_code("""shape = smoothstep(0.0, %.2f, abs(diff));
                        ^ 슬라이더
shape = smoothstep(softness, 0.0, shape);
shape *= smooth_noise(distorted_uv * 10.0);""" % _foam_width)
