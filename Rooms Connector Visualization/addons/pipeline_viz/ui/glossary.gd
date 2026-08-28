class_name Glossary
extends RefCounted
## 코드 칸에 뜨는 단어 중 "엔진·언어가 준 것"만 모아 둔 사전. 마우스를 올리면
## CodeFormat이 이 설명을 툴팁으로 띄운다.
##
## 넣는 기준은 하나다 — 이 프로젝트가 만들지 않은 이름만 넣는다. GLSL 내장
## 함수나 셰이더 내장 변수는 넣고, snow_amount·foam_edge_distance처럼 이
## 프로젝트가 정한 uniform은 넣지 않는다(그건 스텝 본문이 설명할 몫이다).
## 설명이 서너 줄을 넘어가면 그것도 스텝 본문으로 갈 내용이다.
##
## GLSL 함수 21 + 셰이더 내장 변수 26 + Godot API 29 + 프로퍼티 27 + 키워드 18.
##
## 항목마다 kind가 붙는다 — 그 단어가 문법적으로 무엇인지(function·type·keyword·
## property)이고, 화면 색은 여기서 나온다. 사전에 있다는 사실 자체는 색으로
## 드러내지 않는다: 이제 코드에 뜨는 엔진 이름이 거의 다 사전에 있어서,
## 그걸 색으로 표시하면 아무것도 구별해 주지 못한다.
## 더 넣을 게 생기면 같은 형식으로 이어 붙이면 된다 — CodeFormat은 안 건드려도 된다.
##
## 코드 칸에 뜨는 대문자 이름이라고 다 여기 넣지는 않았다. M_2PI·M_6PI는
## 이식해 온 원본 셰이더가 스스로 정의한 상수이고, REFRACTION은 Water Shader
## 프로젝트가 만든 #define 스위치다 — 엔진이 준 이름이 아니라서 뺐다.

const TERMS := {
	"texture": {
		"kind": "function",
		"sig": "texture(샘플러, uv) -> vec4",
		"desc": "이미지에서 uv 자리의 색을 읽는다.\nuv는 0~1로 정규화된 좌표라 이미지의\n실제 픽셀 수와 상관없이 같은 자리를 가리킨다.",
	},
	"mix": {
		"kind": "function",
		"sig": "mix(a, b, t) -> a와 같은 타입",
		"desc": "a와 b를 t 비율로 섞는다.\nt가 0이면 a, 1이면 b, 0.5면 정확히 중간.\n두 값 사이를 직선으로 잇는 보간.",
	},
	"smoothstep": {
		"kind": "function",
		"sig": "smoothstep(edge0, edge1, x) -> float",
		"desc": "x가 edge0 이하면 0, edge1 이상이면 1,\n그 사이는 S자 곡선으로 부드럽게 넘어간다.\nstep과 달리 경계가 각지지 않는다.",
	},
	"step": {
		"kind": "function",
		"sig": "step(edge, x) -> float",
		"desc": "x가 edge보다 작으면 0, 아니면 1.\n칼같이 둘 중 하나다.\n경계를 부드럽게 하려면 smoothstep.",
	},
	"clamp": {
		"kind": "function",
		"sig": "clamp(x, 최소, 최대) -> x와 같은 타입",
		"desc": "x를 최소와 최대 사이에 가둔다.\n계산 결과가 범위를 넘어 색이 터지거나\n뒤집히는 걸 막는 안전장치.",
	},
	"normalize": {
		"kind": "function",
		"sig": "normalize(v) -> v와 같은 타입",
		"desc": "벡터의 방향은 그대로 두고 길이만 1로 만든다.\n크기는 필요 없고 방향만 쓸 때 —\n법선, 시선, 빛 방향이 전부 이 상태로 다닌다.",
	},
	"dot": {
		"kind": "function",
		"sig": "dot(a, b) -> float",
		"desc": "두 벡터의 내적. 둘 다 길이가 1이면\n결과가 곧 사이각의 코사인이다.\n1이면 같은 방향, 0이면 직각, -1이면 반대.",
	},
	"cross": {
		"kind": "function",
		"sig": "cross(a, b) -> vec3",
		"desc": "두 벡터 모두에 수직인 벡터를 만든다.\n면 위의 접선 두 개를 알 때\n그 면의 법선을 구하는 방법.",
	},
	"length": {
		"kind": "function",
		"sig": "length(v) -> float",
		"desc": "벡터의 길이. 원점에서 그 점까지의 거리다.\n중심에서 얼마나 떨어졌는지 재서\n원이나 방사형 그라데이션을 만들 때 쓴다.",
	},
	"pow": {
		"kind": "function",
		"sig": "pow(x, y) -> float",
		"desc": "x의 y제곱.\ny가 1보다 크면 작은 값이 더 빨리 작아져서\n대비가 세지고 감쇠가 급해진다.",
	},
	"exp": {
		"kind": "function",
		"sig": "exp(x) -> float",
		"desc": "e의 x제곱.\nx가 음수로 갈수록 0을 향해 빠르게 사그라든다.\n빛이 물에 흡수돼 사라지는 곡선이 이 모양.",
	},
	"sqrt": {
		"kind": "function",
		"sig": "sqrt(x) -> float",
		"desc": "제곱근. 제곱해서 x가 되는 값.\n거리 계산에 딸려 나오는 일이 많다.",
	},
	"abs": {
		"kind": "function",
		"sig": "abs(x) -> x와 같은 타입",
		"desc": "부호를 떼고 크기만 남긴다. -0.3이 0.3이 된다.\n어느 쪽으로 어긋났는지는 관심 없고\n얼마나 어긋났는지만 볼 때.",
	},
	"max": {
		"kind": "function",
		"sig": "max(a, b) -> a와 같은 타입",
		"desc": "둘 중 큰 쪽.\n바닥을 깔 때도 쓴다 —\nmax(x, 0.0)이면 음수가 0에서 걸린다.",
	},
	"min": {
		"kind": "function",
		"sig": "min(a, b) -> a와 같은 타입",
		"desc": "둘 중 작은 쪽.\n천장을 씌울 때 쓴다 —\nmin(x, 1.0)이면 1을 못 넘는다.",
	},
	"mod": {
		"kind": "function",
		"sig": "mod(x, y) -> float",
		"desc": "x를 y로 나눈 나머지.\n값을 0~y 사이로 계속 되감아서\n반복되는 무늬나 격자를 만든다.",
	},
	"sin": {
		"kind": "function",
		"sig": "sin(x) -> float",
		"desc": "x(라디안)의 사인. -1과 1 사이를 오간다.\n6.28(2파이)마다 한 바퀴 —\n파도처럼 반복하는 움직임의 기본 재료.",
	},
	"cos": {
		"kind": "function",
		"sig": "cos(x) -> float",
		"desc": "x(라디안)의 코사인. sin과 같은 파형인데\n1/4바퀴 앞서 있다.\nsin과 짝지으면 원을 그리는 움직임이 된다.",
	},
	"acos": {
		"kind": "function",
		"sig": "acos(x) -> float",
		"desc": "코사인의 역함수.\ndot으로 얻은 -1~1 값을 다시 각도(라디안)로\n되돌릴 때 쓴다.",
	},

	# --- 셰이더 내장 변수 ------------------------------------------
	"UV": {
		"kind": "type",
		"sig": "UV — vec2",
		"desc": "지금 그리는 지점이 텍스처의 어디인지 가리키는 0~1 좌표.\n메시가 크든 작든 값은 늘 0~1이라\n텍스처 해상도와 무관하게 같은 자리를 뜻한다.",
	},
	"SCREEN_UV": {
		"kind": "type",
		"sig": "SCREEN_UV — vec2 (fragment 전용)",
		"desc": "지금 픽셀이 화면의 어디인지를 0~1로.\nUV가 메시 기준이라면 이건 화면 기준이다.\n뒤에 이미 그려진 화면을 훔쳐 읽을 때 쓴다.",
	},
	"VERTEX": {
		"kind": "type",
		"sig": "VERTEX — vec3 (읽고 쓰기)",
		"desc": "정점의 위치. 기본은 모델 좌표계다.\nvertex()에서 이 값을 바꾸면 메시가 실제로 휜다 —\n파도와 바람이 전부 여기서 나온다.",
	},
	"NORMAL": {
		"kind": "type",
		"sig": "NORMAL — vec3",
		"desc": "면이 바라보는 방향(길이 1인 벡터).\n빛 계산이 전부 이 값에 걸려 있어서,\n모양은 그대로 두고 음영만 바꾸고 싶을 때 건드린다.",
	},
	"ALBEDO": {
		"kind": "type",
		"sig": "ALBEDO — vec3 (fragment 출력)",
		"desc": "빛을 계산하기 전 이 픽셀의 바탕색.\n여기 넣은 색에 조명이 곱해져 최종 색이 된다.",
	},
	"ALPHA": {
		"kind": "type",
		"sig": "ALPHA — float (fragment 출력)",
		"desc": "불투명도. 1이면 불투명, 0이면 안 보인다.\n이 값을 쓰는 순간 셰이더가 투명 취급으로 넘어가\n그리는 순서가 중요해진다.",
	},
	"ROUGHNESS": {
		"kind": "type",
		"sig": "ROUGHNESS — float (fragment 출력)",
		"desc": "표면의 거칠기.\n0이면 거울처럼 매끈해 반사가 또렷하고,\n1이면 무광이라 빛이 넓게 퍼진다.",
	},
	"COLOR": {
		"kind": "type",
		"sig": "COLOR — vec4",
		"desc": "셰이더 종류에 따라 뜻이 다르다.\ncanvas_item에서는 내보낼 최종 색이고,\nspatial·파티클에서는 정점이 들고 온 색이다.",
	},
	"TIME": {
		"kind": "type",
		"sig": "TIME — float",
		"desc": "셰이더가 시작한 뒤 흐른 초.\n계속 커지기만 하는 유일한 값이라,\n셰이더 안의 모든 움직임은 결국 여기서 나온다.",
	},
	"VIEW": {
		"kind": "type",
		"sig": "VIEW — vec3",
		"desc": "표면에서 카메라 쪽을 향하는 길이 1 벡터.\nLIGHT과 더해 반쯤 되는 방향을 만들면\n어디가 번쩍일지 정할 수 있다.",
	},
	"LIGHT": {
		"kind": "type",
		"sig": "LIGHT — vec3 (light 함수 전용)",
		"desc": "표면에서 광원 쪽을 향하는 방향.\nlight() 안에서만 쓸 수 있고,\n광원 하나마다 이 함수가 다시 불린다.",
	},
	"LIGHT_COLOR": {
		"kind": "type",
		"sig": "LIGHT_COLOR — vec3 (light 함수 전용)",
		"desc": "지금 계산 중인 광원의 색과 세기.\n곱해 주면 그 빛의 성격이 결과에 묻어난다.",
	},
	"SPECULAR_LIGHT": {
		"kind": "type",
		"sig": "SPECULAR_LIGHT — vec3 (light 함수 출력)",
		"desc": "반사 하이라이트를 더해 넣는 자리.\n1.0을 넘겨 쓰면 화면에 담기지 못한 밝기가\n글로우로 번져 별처럼 보인다.",
	},
	"BACKLIGHT": {
		"kind": "type",
		"sig": "BACKLIGHT — vec3 (fragment 출력)",
		"desc": "빛이 얇은 물체를 뚫고 뒤로 비쳐 나오는 정도.\n역광에서 잎사귀가 붉게 비치는 그 효과.\nGodot 3의 TRANSMISSION이 이 이름으로 바뀌었다.",
	},
	"NORMAL_MAP": {
		"kind": "type",
		"sig": "NORMAL_MAP — vec3 (fragment 출력)",
		"desc": "법선맵 텍스처를 그대로 넘겨 주는 자리.\nNORMAL에 직접 쓰는 것과 달리\n접선 공간을 푸는 일을 엔진이 대신해 준다.",
	},
	"ALPHA_SCISSOR_THRESHOLD": {
		"kind": "type",
		"sig": "ALPHA_SCISSOR_THRESHOLD — float",
		"desc": "ALPHA가 이 값보다 작은 픽셀을 통째로 버린다.\n정렬 없이 구멍을 뚫는 싼 방법이지만,\n밉맵과 만나면 멀리서 형체가 사라지는 함정이 있다.",
	},
	"DEPTH_TEXTURE": {
		"kind": "type",
		"sig": "DEPTH_TEXTURE — sampler2D",
		"desc": "화면의 깊이 버퍼. 각 픽셀이 카메라에서 얼마나 먼지.\n4.7에서 내장 변수가 사라져,\n이제 hint_depth_texture로 직접 선언해야 한다.",
	},
	"MODEL_MATRIX": {
		"kind": "type",
		"sig": "MODEL_MATRIX — mat4",
		"desc": "모델(로컬) 좌표를 월드 좌표로 옮기는 행렬.\n노드의 위치·회전·크기가 이 안에 들어 있다.\nGodot 3의 WORLD_MATRIX.",
	},
	"MODEL_NORMAL_MATRIX": {
		"kind": "type",
		"sig": "MODEL_NORMAL_MATRIX — mat3",
		"desc": "법선을 월드 방향으로 옮기는 행렬.\n위치용 MODEL_MATRIX와 따로 있는 까닭은,\n한 축만 늘린 물체에서 법선이 어긋나기 때문이다.",
	},
	"INV_VIEW_MATRIX": {
		"kind": "type",
		"sig": "INV_VIEW_MATRIX — mat4",
		"desc": "뷰 좌표를 월드 좌표로 되돌리는 행렬.\n카메라의 월드 위치와 방향이 여기 담겨 있다.\nGodot 3의 CAMERA_MATRIX.",
	},
	"PROJECTION_MATRIX": {
		"kind": "type",
		"sig": "PROJECTION_MATRIX — mat4",
		"desc": "뷰 좌표를 화면에 눌러 담는 행렬.\n멀수록 작아 보이는 원근이 여기서 생긴다.",
	},
	"INV_PROJECTION_MATRIX": {
		"kind": "type",
		"sig": "INV_PROJECTION_MATRIX — mat4",
		"desc": "PROJECTION_MATRIX를 되돌리는 행렬.\n깊이 버퍼에서 읽은 화면 좌표를\n다시 3D 위치로 펴낼 때 쓴다.",
	},
	"NODE_POSITION_WORLD": {
		"kind": "type",
		"sig": "NODE_POSITION_WORLD — vec3",
		"desc": "이 노드의 월드 위치.\n주의 — MultiMesh에서는 인스턴스마다가 아니라\n노드 하나의 값이라, 이걸로 위상을 흩으면 전부 같이 움직인다.",
	},
	"WORLD_MATRIX": {
		"kind": "type",
		"sig": "WORLD_MATRIX — Godot 3.x 이름",
		"desc": "4에서는 MODEL_MATRIX다.\n3.x 셰이더를 그대로 가져오면\n이 줄에서 컴파일이 멈춘다.",
	},
	"CAMERA_MATRIX": {
		"kind": "type",
		"sig": "CAMERA_MATRIX — Godot 3.x 이름",
		"desc": "4에서는 INV_VIEW_MATRIX다.\n이름만 바뀐 게 아니라 짝인 INV_CAMERA_MATRIX도\nVIEW_MATRIX로 함께 옮겨졌다.",
	},
	"TRANSMISSION": {
		"kind": "type",
		"sig": "TRANSMISSION — Godot 3.x 이름",
		"desc": "4에서는 BACKLIGHT다.\n빛이 얇은 물체를 뚫고 나오는 그 값 그대로,\n이름만 바뀌었다.",
	},

	# --- Godot API ------------------------------------------------
	"RenderingServer": {
		"kind": "type",
		"sig": "RenderingServer — 싱글턴",
		"desc": "노드를 거치지 않고 렌더러에 직접 말을 거는 창구.\n씬 트리 밖에서도 쓸 수 있어\n전역 설정을 만질 때 자주 등장한다.",
	},
	"global_shader_parameter_set": {
		"kind": "function",
		"sig": "RenderingServer.global_shader_parameter_set(이름, 값)",
		"desc": "모든 셰이더가 함께 읽는 전역 값을 바꾼다.\n머티리얼마다 따로 넣어 줄 필요가 없다.\n셰이더 쪽에 global uniform으로 선언해 둬야 한다.",
	},
	"set_shader_parameter": {
		"kind": "function",
		"sig": "ShaderMaterial.set_shader_parameter(이름, 값)",
		"desc": "이 머티리얼 하나의 uniform 값을 바꾼다.\n같은 셰이더를 쓰더라도 머티리얼이 다르면\n값은 서로 따로 논다.",
	},
	"set_instance_shader_parameter": {
		"kind": "function",
		"sig": "GeometryInstance3D.set_instance_shader_parameter(이름, 값)",
		"desc": "머티리얼은 공유한 채 인스턴스마다 다른 값을 준다.\n셰이더 쪽에 instance uniform으로 선언해야 하고,\n쓸 수 있는 개수에 제한이 있다.",
	},
	"Geometry2D": {
		"kind": "type",
		"sig": "Geometry2D — 싱글턴",
		"desc": "2D 기하 계산 모음.\n삼각분할·다각형 교집합·볼록 껍질 같은 것을\n노드 없이 바로 부른다.",
	},
	"triangulate_delaunay": {
		"kind": "function",
		"sig": "Geometry2D.triangulate_delaunay(점들) -> PackedInt32Array",
		"desc": "점들을 삼각형으로 잇되\n가늘고 긴 삼각형이 최대한 안 생기게 나눈다.\n결과는 점 번호가 셋씩 묶인 배열이다.",
	},
	"PackedVector2Array": {
		"kind": "type",
		"sig": "PackedVector2Array — 타입",
		"desc": "Vector2를 촘촘하게 담는 배열.\n일반 Array와 달리 타입이 고정돼 메모리를 아끼고,\n엔진 함수에 그대로 넘길 수 있다.",
	},
	"Vector2": {
		"kind": "type",
		"sig": "Vector2 — 타입",
		"desc": "x, y 두 값을 묶은 2차원 벡터.\n위치·크기·방향 어디에나 쓴다.",
	},
	"Vector3": {
		"kind": "type",
		"sig": "Vector3 — 타입",
		"desc": "x, y, z 세 값을 묶은 3차원 벡터.\n3D 위치와 방향의 기본 단위.",
	},
	"Rect2": {
		"kind": "type",
		"sig": "Rect2 — 타입",
		"desc": "위치와 크기로 정의되는 사각형 영역.\n겹침을 검사하거나 경계 상자를 잡을 때 쓴다.",
	},
	"String": {
		"kind": "type",
		"sig": "String — 타입",
		"desc": "Godot의 문자열.\n짝으로 StringName이 있는데 앞에 &를 붙인 게 그것이다.\n같은 이름을 자꾸 비교할 때 훨씬 싸다.",
	},
	"sort_custom": {
		"kind": "function",
		"sig": "Array.sort_custom(비교 함수)",
		"desc": "내가 정한 기준으로 배열을 정렬한다.\n넘긴 함수가 a를 b보다 앞에 두고 싶으면\ntrue를 돌려주면 된다.",
	},
	"connect": {
		"kind": "function",
		"sig": "Signal.connect(콜백)",
		"desc": "시그널이 울릴 때 부를 함수를 등록한다.\n보내는 쪽은 받는 쪽이 누군지 모른 채 알림만 쏜다 —\n이게 느슨한 연결의 실체다.",
	},
	"lerpf": {
		"kind": "function",
		"sig": "lerpf(from, to, weight) -> float",
		"desc": "두 실수 사이를 weight 비율로 섞는다.\n셰이더의 mix와 같은 계산의 GDScript판.",
	},
	"clampf": {
		"kind": "function",
		"sig": "clampf(값, 최소, 최대) -> float",
		"desc": "실수를 범위 안에 가둔다.\n셰이더의 clamp와 같은 일을 하고,\nfloat 전용이라 조금 더 빠르다.",
	},
	"rad_to_deg": {
		"kind": "function",
		"sig": "rad_to_deg(라디안) -> float",
		"desc": "라디안을 도로 바꾼다.\n삼각함수는 라디안으로 답하는데 사람은 도로 읽으니,\n마지막에 한 번 씌운다.",
	},
	"set_anchors_preset": {
		"kind": "function",
		"sig": "Control.set_anchors_preset(프리셋)",
		"desc": "컨트롤이 부모 안에서 어디에 붙을지 한 번에 정한다.\n앵커 네 개를 따로 만지는 대신 쓰는 지름길.",
	},
	"PRESET_FULL_RECT": {
		"kind": "type",
		"sig": "Control.PRESET_FULL_RECT",
		"desc": "부모를 가득 채우는 앵커 프리셋.\n부모가 커지면 따라서 같이 커진다.",
	},
	"PROJECTION_ORTHOGONAL": {
		"kind": "type",
		"sig": "Camera3D.PROJECTION_ORTHOGONAL",
		"desc": "원근을 없앤 투영 방식.\n멀리 있는 것도 작아지지 않아,\n위에서 내려본 마스크처럼 크기를 왜곡 없이 재야 할 때 쓴다.",
	},
	"DirectionalLight3D": {
		"kind": "type",
		"sig": "DirectionalLight3D — 노드",
		"desc": "해처럼 무한히 먼 곳에서 오는 빛.\n위치는 무시되고 방향만 쓴다.\n씬 전체에 같은 각도로 그림자가 드리운다.",
	},
	"PlaneMesh": {
		"kind": "type",
		"sig": "PlaneMesh — 리소스",
		"desc": "평평한 사각 판 메시.\nsubdivide로 잘게 쪼개 두면\n정점 셰이더가 이걸 휘게 만들 수 있다.",
	},
	"ProceduralSkyMaterial": {
		"kind": "type",
		"sig": "ProceduralSkyMaterial — 리소스",
		"desc": "텍스처 없이 하늘을 그리는 머티리얼.\n위·중간·아래 색과 해 모양을 값으로 정한다.",
	},
	"BG_SKY": {
		"kind": "type",
		"sig": "Environment.BG_SKY",
		"desc": "빈 곳을 하늘로 채우는 배경 모드.\n그 하늘이 주변광의 출처도 된다.",
	},
	"AMBIENT_SOURCE_SKY": {
		"kind": "type",
		"sig": "Environment.AMBIENT_SOURCE_SKY",
		"desc": "주변광을 하늘에서 가져오는 설정.\n해가 닿지 않는 그늘도 하늘빛을 머금는다.",
	},
	"TONE_MAPPER_ACES": {
		"kind": "type",
		"sig": "Environment.TONE_MAPPER_ACES",
		"desc": "1.0을 넘는 밝기를 화면에 담기게 눌러 주는 방식.\n밝은 곳이 흰색으로 뭉개지지 않고 색을 남긴다.",
	},

	# --- 노드·리소스 프로퍼티 ---------------------------------------------
	"global_position": {
		"kind": "property",
		"sig": "Node3D.global_position / Node2D.global_position — Vector3·Vector2",
		"desc": "부모를 거치지 않은 월드 기준 위치.\nposition은 부모 기준이라, 부모가 움직이면\n같은 position이라도 월드 위치는 달라진다.",
	},
	"rotation_degrees": {
		"kind": "property",
		"sig": "Node3D.rotation_degrees — Vector3",
		"desc": "회전을 도 단위로 읽고 쓴다.\n엔진 내부는 라디안(rotation)이라 이건 사람이 보기 편하게\n감싸 둔 것이다.",
	},
	"size": {
		"kind": "property",
		"sig": "size — 크기",
		"desc": "어느 클래스냐에 따라 단위가 다르다.\nPlaneMesh·QuadMesh면 미터,\nWindow·SubViewport면 픽셀이다.",
	},
	"subdivide_width": {
		"kind": "property",
		"sig": "PlaneMesh.subdivide_width — int",
		"desc": "가로로 몇 번 더 쪼갤지.\n정점이 많아야 정점 셰이더가 판을 매끄럽게 휠 수 있다 —\n0이면 모서리 네 점뿐이라 파도가 안 생긴다.",
	},
	"subdivide_depth": {
		"kind": "property",
		"sig": "PlaneMesh.subdivide_depth — int",
		"desc": "세로로 몇 번 더 쪼갤지.\nsubdivide_width의 짝. 둘 다 올려야 판이 고르게 촘촘해진다.",
	},
	"shadow_enabled": {
		"kind": "property",
		"sig": "Light3D.shadow_enabled — bool",
		"desc": "이 빛이 그림자를 드리울지.\n끄면 밝기는 그대로인데 그림자만 사라져,\n물체가 바닥에서 떠 보인다.",
	},
	"light_energy": {
		"kind": "property",
		"sig": "Light3D.light_energy — float",
		"desc": "빛의 세기 배율.\n1.0이 기준이고, 낮과 밤을 오갈 때\n색과 함께 이 값을 같이 바꾼다.",
	},
	"background_mode": {
		"kind": "property",
		"sig": "Environment.background_mode",
		"desc": "아무것도 안 그려진 자리를 무엇으로 채울지.\n단색·하늘·캔버스 중에 고른다.",
	},
	"ambient_light_source": {
		"kind": "property",
		"sig": "Environment.ambient_light_source",
		"desc": "주변광을 어디서 가져올지.\n해가 닿지 않는 그늘의 밝기를 정하는 값이라,\n이걸 끄면 그늘이 새까매진다.",
	},
	"glow_enabled": {
		"kind": "property",
		"sig": "Environment.glow_enabled — bool",
		"desc": "1.0보다 밝은 부분을 주변으로 번지게 할지.\n반짝임이나 별빛 효과는 전부 이 스위치에 얹혀 있다.",
	},
	"tonemap_mode": {
		"kind": "property",
		"sig": "Environment.tonemap_mode",
		"desc": "화면에 담기지 않는 밝기를 어떤 곡선으로 눌러 담을지.\n고르는 방식에 따라 밝은 부분의 색이 달라진다.",
	},
	"fog_enabled": {
		"kind": "property",
		"sig": "Environment.fog_enabled — bool",
		"desc": "거리에 따라 안개색을 섞을지.\n끄면 먼 것과 가까운 것이 똑같이 또렷해져\n깊이감이 사라진다.",
	},
	"fog_density": {
		"kind": "property",
		"sig": "Environment.fog_density — float",
		"desc": "안개가 얼마나 빨리 짙어지는지.\n값이 클수록 가까운 거리에서도 안개색에 묻힌다.",
	},
	"projection": {
		"kind": "property",
		"sig": "Camera3D.projection",
		"desc": "원근으로 볼지 직교로 볼지.\n직교로 두면 거리가 크기에 영향을 주지 않아\n위에서 내려본 마스크를 왜곡 없이 뽑을 수 있다.",
	},
	"cull_mask": {
		"kind": "property",
		"sig": "Camera3D.cull_mask — int",
		"desc": "이 카메라가 볼 레이어를 비트로 고른다.\n특정 물체만 따로 찍어 텍스처로 쓸 때,\n나머지를 안 보이게 걸러 내는 방법.",
	},
	"multimesh": {
		"kind": "property",
		"sig": "MultiMeshInstance3D.multimesh — MultiMesh",
		"desc": "같은 메시를 수천 개 그리는 리소스.\n노드를 개수만큼 만들지 않고 한 번에 넘겨서\n드로우 콜을 하나로 줄인다.",
	},
	"instance_count": {
		"kind": "property",
		"sig": "MultiMesh.instance_count — int",
		"desc": "그릴 인스턴스 개수.\n늘려도 드로우 콜은 그대로라 싸지만,\n인스턴스마다 다른 값을 주려면 따로 손이 든다.",
	},
	"amount": {
		"kind": "property",
		"sig": "GPUParticles3D.amount — int",
		"desc": "동시에 살아 있는 파티클 개수.\n바꾸면 시뮬레이션이 처음부터 다시 돌아,\n떨어지던 것들이 한 번 사라진다.",
	},
	"amount_ratio": {
		"kind": "property",
		"sig": "GPUParticles3D.amount_ratio — float",
		"desc": "amount 중 실제로 몇 할을 쓸지(0~1).\namount와 달리 시뮬레이션을 다시 시작하지 않아\n중간에 양을 줄였다 늘리기 좋다.",
	},
	"lifetime": {
		"kind": "property",
		"sig": "GPUParticles3D.lifetime — float",
		"desc": "파티클 하나가 태어나서 사라지기까지의 초.\n길수록 화면에 오래 남아 더 촘촘해 보인다.",
	},
	"preprocess": {
		"kind": "property",
		"sig": "GPUParticles3D.preprocess — float",
		"desc": "켜지는 순간 이미 이만큼 초를 돌린 상태로 시작한다.\n없으면 첫 프레임에 눈이 하늘에만 몰려 있다가\n서서히 내려오는 게 보인다.",
	},
	"scale_max": {
		"kind": "property",
		"sig": "ParticleProcessMaterial.scale_max — float",
		"desc": "파티클 크기의 위쪽 한계.\nscale_min과의 사이에서 무작위로 정해져\n알갱이마다 크기가 달라진다.",
	},
	"turbulence_enabled": {
		"kind": "property",
		"sig": "ParticleProcessMaterial.turbulence_enabled — bool",
		"desc": "난류를 켤지.\n공간에 깔린 흐름 필드가 파티클을 옆으로 밀어\n곧게 떨어지지 않게 만든다.",
	},
	"turbulence_noise_scale": {
		"kind": "property",
		"sig": "ParticleProcessMaterial.turbulence_noise_scale — float",
		"desc": "흐름 필드 무늬의 크기.\n작을수록 무늬가 커져 넓게 휩쓸리고,\n클수록 잘게 흩어진다.",
	},
	"turbulence_noise_strength": {
		"kind": "property",
		"sig": "ParticleProcessMaterial.turbulence_noise_strength — float",
		"desc": "그 필드가 미는 힘.\n0이면 난류가 있어도 아무 일도 안 일어나\n낙하 경로가 직선이 된다.",
	},
	"turbulence_influence_max": {
		"kind": "property",
		"sig": "ParticleProcessMaterial.turbulence_influence_max — float",
		"desc": "난류가 파티클을 최대 얼마나 끌고 갈 수 있는지.\n세기를 아무리 올려도 이 값이 천장 노릇을 한다.",
	},
	"value_changed": {
		"kind": "property",
		"sig": "Range.value_changed(value) — 시그널",
		"desc": "슬라이더나 스핀박스의 값이 바뀔 때 울린다.\nRange를 물려받은 컨트롤이 다 갖고 있다.",
	},

	# --- 나머지 -----------------------------------------------------
	"Color": {
		"kind": "type",
		"sig": "Color — 타입",
		"desc": "빨강·초록·파랑·알파 네 값(0~1)으로 된 색.\n0~255가 아니라 0~1이라,\n1.0을 넘겨 쓰면 글로우가 번지는 밝기가 된다.",
	},
	"Rect2i": {
		"kind": "type",
		"sig": "Rect2i — 타입",
		"desc": "정수 좌표로 된 사각형 영역.\nRect2와 달리 소수점이 없어\n픽셀 단위로 딱 떨어져야 하는 곳에 쓴다.",
	},
	"emit": {
		"kind": "function",
		"sig": "Signal.emit(인자들) — 메서드",
		"desc": "시그널을 울린다.\nconnect로 등록해 둔 함수들이 이때 불리고,\n등록한 쪽이 없으면 조용히 아무 일도 안 일어난다.",
	},
	"blit_rect": {
		"kind": "function",
		"sig": "blit_rect(원본, 잘라낼 영역, 붙일 위치)",
		"desc": "이미지 일부를 다른 이미지에 찍어 넣는다.\nDrawableTexture2D에 쓰면 GPU에 올라간 텍스처를\n매 프레임 고쳐 그릴 수 있다.",
	},
	"floor": {
		"kind": "function",
		"sig": "floor(x) -> x와 같은 타입",
		"desc": "소수점을 버려 아래 정수로 내린다.\n2.9는 2, -0.1은 -1이 된다.\n연속된 좌표를 칸으로 묶어 격자를 만들 때 쓴다.",
	},
	"textureLod": {
		"kind": "function",
		"sig": "textureLod(샘플러, uv, lod) -> vec4",
		"desc": "밉맵 단계를 직접 골라 읽는 texture.\n0이면 원본 해상도다.\nvertex()처럼 엔진이 단계를 못 정하는 곳에서 필요하다.",
	},

	# --- 셰이더 키워드·힌트 --------------------------------------
	"uniform": {
		"kind": "keyword",
		"sig": "uniform 타입 이름;",
		"desc": "셰이더 밖에서 넣어 주는 값.\n한 번 그리는 동안 모든 정점과 픽셀이 같은 값을 본다.\n머티리얼 패널에 뜨는 손잡이가 전부 이걸로 만들어진다.",
	},
	"varying": {
		"kind": "keyword",
		"sig": "varying 타입 이름;",
		"desc": "vertex()에서 계산해 fragment()로 넘기는 값.\n정점 사이는 자동으로 보간돼서, 픽셀은 자기를 둘러싼\n정점들의 중간값을 받는다.",
	},
	"shader_type": {
		"kind": "keyword",
		"sig": "shader_type 종류;",
		"desc": "이 셰이더가 무엇에 얹힐지 맨 첫 줄에 선언한다.\nspatial(3D)·canvas_item(2D)·particles·sky·fog 중 하나.\n종류마다 쓸 수 있는 내장 변수와 함수가 다르다.",
	},
	"sampler2D": {
		"kind": "type",
		"sig": "sampler2D — 셰이더 타입",
		"desc": "텍스처를 읽기 위한 손잡이.\nuniform으로 선언해 두고 texture()로 값을 꺼낸다.\n텍스처 자체가 아니라 어느 텍스처인지 가리키는 표다.",
	},
	"hint_depth_texture": {
		"kind": "keyword",
		"sig": "uniform sampler2D 이름 : hint_depth_texture",
		"desc": "이 sampler에 화면 깊이 버퍼를 물려 달라는 표시.\n4.7에서 DEPTH_TEXTURE 내장 변수가 없어져,\n이제 이렇게 직접 받아 써야 한다.",
	},
	"hint_screen_texture": {
		"kind": "keyword",
		"sig": "uniform sampler2D 이름 : hint_screen_texture",
		"desc": "이 sampler에 지금까지 그려진 화면을 물려 달라는 표시.\n굴절처럼 뒤 화면을 훔쳐 읽을 때 쓴다.\n읽는 순간까지 그려진 것만 들어 있다.",
	},
	"source_color": {
		"kind": "keyword",
		"sig": "uniform vec4 이름 : source_color",
		"desc": "이 uniform이 색이라고 알려 준다. 에디터가 색 선택기를 띄우고,\nsRGB로 고른 색을 셰이더가 쓰는 선형 공간으로 바꿔 준다.\nGodot 3의 hint_color.",
	},
	"hint_color": {
		"kind": "keyword",
		"sig": "hint_color — Godot 3.x 이름",
		"desc": "4에서는 source_color다.\n3.x 셰이더를 그대로 가져오면 이 줄에서 멈춘다.",
	},
	"filter_linear_mipmap": {
		"kind": "keyword",
		"sig": "uniform sampler2D 이름 : filter_linear_mipmap",
		"desc": "이웃 픽셀을 섞어 읽고(linear),\n거리에 따라 미리 줄여 둔 축소본을 쓴다(mipmap).\n멀리서 지글거리는 걸 막아 준다.",
	},
	"repeat_disable": {
		"kind": "keyword",
		"sig": "uniform sampler2D 이름 : repeat_disable",
		"desc": "UV가 0~1을 벗어나도 무늬를 되풀이하지 않는다.\n기본값이 반복이라, 화면을 한 번만 덮어야 하는\n텍스처에는 이걸 꺼 줘야 가장자리가 안 샌다.",
	},
	"define": {
		"kind": "keyword",
		"sig": "#define 이름",
		"desc": "컴파일 전에 이름 하나를 정해 둔다.\n런타임에 값을 비교하는 게 아니라,\n컴파일할 때 코드가 통째로 들어가거나 빠진다.",
	},
	"ifdef": {
		"kind": "keyword",
		"sig": "#ifdef 이름",
		"desc": "그 이름이 정의돼 있을 때만 아래를 컴파일한다.\n런타임 if와 달리 안 쓰는 쪽은 아예 안 만들어져서\n분기를 고르는 비용 자체가 없다.",
	},
	"endif": {
		"kind": "keyword",
		"sig": "#endif",
		"desc": "#ifdef나 #if로 연 구간을 닫는다.",
	},
	"include": {
		"kind": "keyword",
		"sig": "#include 경로",
		"desc": "다른 파일 내용을 이 자리에 그대로 붙여 넣는다.\nGodot에서는 .gdshaderinc 파일을 이렇게 만들어\n여러 셰이더가 본문 하나를 나눠 쓴다.",
	},
	"canvas_item": {
		"kind": "keyword",
		"sig": "shader_type canvas_item;",
		"desc": "2D용 셰이더 종류.\n3D 메시가 아니라 화면에 붙은 사각형에 얹히고,\n정점이 3차원이 아니라 2차원이다.",
	},
	"particles": {
		"kind": "keyword",
		"sig": "shader_type particles;",
		"desc": "파티클 계산용 셰이더 종류.\n픽셀을 칠하는 게 아니라 알갱이 하나하나의\n위치와 속도를 GPU에서 갱신한다.",
	},
	"vertex": {
		"kind": "function",
		"sig": "void vertex() — 셰이더 함수",
		"desc": "정점마다 한 번 도는 함수.\n여기서 VERTEX를 밀면 메시가 실제로 휜다.\n픽셀보다 훨씬 적게 돌아 그만큼 싸다.",
	},
	"fragment": {
		"kind": "function",
		"sig": "void fragment() — 셰이더 함수",
		"desc": "화면에 찍히는 픽셀마다 도는 함수.\nALBEDO·ROUGHNESS 같은 표면의 성질을 여기서 정한다.\n정점 개수와 무관하게 화면 넓이만큼 돈다.",
	},
}


## 툴팁에 그대로 들어갈 문자열. 사전에 없으면 빈 문자열.
static func hint(token: String) -> String:
	if not TERMS.has(token):
		return ""
	var term: Dictionary = TERMS[token]
	return "%s\n\n%s" % [term["sig"], term["desc"]]


static func has(token: String) -> bool:
	return TERMS.has(token)


## 그 단어가 문법적으로 무엇인지 — function·type·keyword·property.
## CodeFormat이 이걸로 색을 고른다. 티어(GLSL·API·프로퍼티…)와는 다른 축이다:
## Godot API 티어 하나에도 클래스(Vector3)·상수(BG_SKY)·메서드(lerpf)가 섞여 있다.
static func kind_of(token: String) -> String:
	if not TERMS.has(token):
		return ""
	var term: Dictionary = TERMS[token]
	return str(term.get("kind", ""))
