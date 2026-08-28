extends WaterChapter
## 챕터 6 — 셰이더가 붙는 자리, 그리고 4.7이 깨뜨린 것들.
##
## 앞의 다섯 챕터는 셰이더끼리의 차이였다. 이 챕터는 그 25개를 3.x/4.x에서
## 4.7로 옮기며 실제로 걸린 것들이다. 뒤쪽 세 스텝은 "고치기 전" 사본을
## 왼쪽·오른쪽에 나란히 놓는다 — 셋 다 컴파일은 통과한다.
##
## README의 다섯 번째 함정(법선맵에 source_color)은 스텝으로 넣지 않았다.
## 이 프로젝트의 텍스처는 전부 코드 생성이라 임포트 단계의 sRGB 디코딩이
## 개입하지 않고, 나란히 놓아도 차이가 눈에 띄지 않는다. 보여줄 게 없는
## 스텝은 주장만 남는다.

const BUG_03 := "res://water/shaders/bugs/bug_03_depth_3x.gdshader"
const BUG_07 := "res://water/shaders/bugs/bug_07_repeat.gdshader"
const BUG_POW := "res://water/shaders/bugs/bug_03_pow.gdshader"

const STEPS: Array[Dictionary] = [
	{
		"title": "물이 아닌 자리에 붙이기",
		"body": """18번은 수면 셰이더가 [b]아니다.[/b]
blend_mul 오버레이라 이미 칠해진 것을 어둡게만 만든다.
경계는 물이 아니라 [b]메시 자기 원점 기준의 높이[/b]로 정해진다.
그래서 기둥에는 물가 선이 생기고, 큰 바닥판은 통째로 어두워진다.""",
		"chips": [
			{"icon": "shader", "text": "render_mode blend_mul"},
			{"icon": "node3d", "text": "MeshInstance3D.material_overlay"},
		],
		"code": """for node in scenery:
    node.material_overlay = mat""",
		"try": "높이 슬라이더 — 기둥의 어두운 경계선이 오르내린다",
	},
	{
		"title": "canvas_item을 3D 메시에서 떼어내기",
		"body": """25개 중 넷은 [b]shader_type이 canvas_item[/b]이다.
MeshInstance3D에 물리면 아예 돌지 않는다 — 자리가 다르다.
전체 화면 ColorRect에 올려야 한다.
19번은 코사인 16개를 겹치고 유한차분으로 법선까지 만든다.""",
		"chips": [
			{"icon": "shader", "text": "shader_type canvas_item"},
			{"icon": "node3d", "text": "CanvasLayer → ColorRect"},
		],
		"code": """rect.set_anchors_preset(PRESET_FULL_RECT)
rect.material = mat""",
		"try": "3D가 아니다 — 카메라를 돌려도 그대로다",
	},
	{
		"title": "화면 전체를 후처리로 흔들기",
		"body": """24번도 canvas_item인데, 자기 그림을 그리지 않는다.
[b]이미 그려진 화면을 읽어서[/b] UV만 사인파로 민다.
그래서 아무 3D 셰이더 위에나 겹칠 수 있다 — 지금 아래는 3번이다.""",
		"chips": [
			{"icon": "setting", "text": "hint_screen_texture"},
			{"icon": "node3d", "text": "CanvasLayer.layer = 1"},
		],
		"code": """uv.x += sin(SCREEN_UV.y*10.0 + TIME)*0.030;
uv.y += sin(SCREEN_UV.x*10.0 + TIME)*0.030;
COLOR = texture(screen_texture, uv);""",
		"try": "진동 폭 슬라이더 — 기둥과 지평선까지 같이 휜다",
	},
	{
		"title": "컴파일러가 막아주는 것 확인하기",
		"body": """4.7이 [b]거부하는[/b] 것들은 사실 안전하다. 바로 멈추니까.
hint_color·hint_black·WORLD_MATRIX·NORMALMAP은 이름만 바뀌었고,
TRANSMISSION은 [b]이름이 바뀐 게 아니라 삭제[/b]됐다 — 22번이 그 경우다.
`1f`는 에러지만 `1.0f`는 통과한다는 것도 여기서 갈렸다.""",
		"chips": [{"icon": "shader", "text": "22_fbm_toon_water fragment()"}],
		"code": """// 3.x: TRANSMISSION = vec3(0.2,0.7,0.3);
BACKLIGHT = vec3(0.2, 0.7, 0.3);""",
		"try": "여기까지는 컴파일 에러 목록 — 다음부터가 진짜 문제다",
	},
	{
		"title": "역Z 깊이 규약 되돌려 보기",
		"body": """오른쪽은 3번의 [b]고치기 전[/b] 사본이다. 컴파일은 통과한다.
3.x는 깊이를 NDC [-1,1]로, 4.x는 역Z [0,1]로 저장한다.
같은 나눗셈 공식에 다른 규약을 먹이면 쓰레기값이 나온다.
클립공간 z도 상수 0.05로 무너져 굴절이 20배로 튄다.""",
		"chips": [
			{"icon": "shader", "text": "bug_03_depth_3x.gdshader"},
			{"icon": "setting", "text": "INV_PROJECTION_MATRIX"},
		],
		"code": """// 3.x
depth = PROJECTION_MATRIX[3][2]
      / (raw + PROJECTION_MATRIX[2][2]);""",
		"try": "오른쪽은 포말이 수면 전체에 깔리고 굴절이 튄다",
	},
	{
		"title": "샘플러 기본 wrap 확인하기",
		"body": """이 셋에서 [b]가장 찾기 어려웠던[/b] 것이다. 한 단어짜리 차이다.
4.x는 모든 uniform sampler2D가 기본 repeat_enable이다.
256×1 램프에서 u=0 조회가 감싸진 texel 255와 보간되고,
7번은 면적 대부분이 u=0이라 [b]명암이 통째로 뒤집힌다.[/b]""",
		"chips": [
			{"icon": "texture", "text": "GradientTexture1D"},
			{"icon": "setting", "text": "repeat_disable"},
		],
		"code": """uniform sampler2D color_gradient
        : source_color, repeat_disable;""",
		"try": "오른쪽은 물 바깥이 허옇게 뜬다 — 램프의 반대쪽 끝이다",
	},
	{
		"title": "pow()의 밑이 음수가 되게 두기",
		"body": """3번의 포말 항은 [b]pow(1.0 - 수심차 + noise, 8.0)[/b]이다.
물이 1 유닛보다 깊어지면 밑이 음수가 되고,
GLSL에서 음수 밑의 pow는 [b]정의되지 않은 동작[/b]이다.
이 하드웨어에서는 거대한 양수가 나와 수면이 하얘진다.""",
		"chips": [{"icon": "shader", "text": "bug_03_pow.gdshader"}],
		"code": """// 원본
pow(1.0 - d + noise, 8.0)
// 4.7
pow(max(1.0 - d + noise, 0.0), 8.0)""",
		"try": "오른쪽은 얕은 물가만 빼고 전부 하얗다",
	},
]

## 기둥은 원점이 y=-3이고 길이가 12다. 이 값에서 어두워지는 경계가 수면과 겹친다.
const WATERLINE_HEIGHT := 1.0

var _height_modifier := WATERLINE_HEIGHT
var _amplitude := 0.03


func get_chapter_title() -> String:
	return "슬롯과 포팅 — 4.7이 깨뜨린 것들"


func get_steps() -> Array[Dictionary]:
	return STEPS


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "높이 (height_modifier)", 0.0, 6.0, _height_modifier, _on_height, [0])
	add_slider(parent, "진동 폭 (amplitude)", 0.0, 0.08, _amplitude, _on_amplitude, [2])


func apply_step(index: int) -> void:
	world.set_dive(false)
	world.set_canvas(null)
	world.set_postfx(null)
	world.set_overlay(null)
	match index:
		0:
			world.show_plots([11])
			world.set_overlay({"id": 18, "params": {"height_modifier": _height_modifier}})
			world.frame(0.25, -0.34, 0.96)
		1:
			world.show_plots([11])
			world.set_canvas(19)
			world.frame(0.25, -0.46, 1.0)
		2:
			world.show_plots([3])
			world.set_postfx({"id": 24, "params": {"amplitude": _amplitude}})
			world.frame(0.25, -0.42, 0.96)
		3:
			world.show_plots([22])
			world.frame(0.25, -0.46, 1.0)
		4:
			world.show_plots([
				{"id": 3, "label": "03 · 4.7 포팅"},
				{"id": 3, "label": "03 · 3.x 공식 그대로", "shader": BUG_03},
			])
			world.frame(0.25, -0.46, 1.04)
		5:
			world.show_plots([
				{"id": 7, "label": "07 · repeat_disable"},
				{"id": 7, "label": "07 · 기본값(repeat)", "shader": BUG_07},
			])
			world.frame(0.0, -0.72, 1.04)
		_:
			world.show_plots([
				{"id": 3, "label": "03 · max() 있음"},
				{"id": 3, "label": "03 · max() 없음", "shader": BUG_POW},
			])
			world.frame(0.25, -0.46, 1.04)
	_push_code()


func _on_height(value: float) -> void:
	_height_modifier = value
	if current_step == 0:
		world.set_overlay({"id": 18, "params": {"height_modifier": value}})
	_push_code()


func _on_amplitude(value: float) -> void:
	_amplitude = value
	if current_step == 2:
		world.set_postfx({"id": 24, "params": {"amplitude": value}})
	_push_code()


func _push_code() -> void:
	if current_step == 0:
		update_code("""ALBEDO = mix(vec3(1.0), vec3(0.1,0.2,0.2),
    clamp(pow(pos.y + %.2f, 0.45), 0., 1.));
                     ^ 슬라이더""" % _height_modifier)
	elif current_step == 2:
		update_code("""uv.x += sin(SCREEN_UV.y*10.0 + TIME)*%.3f;
uv.y += sin(SCREEN_UV.x*10.0 + TIME)*%.3f;
                                     ^ 슬라이더
COLOR = texture(screen_texture, uv);"""
				% [_amplitude, _amplitude])
