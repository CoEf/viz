extends GrassChapter
## 챕터 5 — 셰이더가 아니라 이식 이야기. 10개를 4.7로 옮기며 반복해 걸린 것들.

const STEPS: Array[Dictionary] = [
	{
		"title": "이름 바뀐 내장 변수 고치기",
		"body": """3.x 셰이더를 4.x로 옮길 때 가장 먼저 걸린다.
컴파일 에러라 최소한 [b]바로 알아채기는 한다.[/b]""",
		"chips": [{"icon": "setting", "text": "PORT 주석"}],
		"code": """WORLD_MATRIX  -> MODEL_MATRIX
CAMERA_MATRIX -> INV_VIEW_MATRIX
hint_color    -> source_color""",
		"try": "10개 중 3개는 이것 때문에 전면 재작성됐다",
	},
	{
		"title": "4.7에서 새로 깨진 것 찾기",
		"body": """`DEPTH_TEXTURE` 내장 변수가 [b]4.7에서 제거[/b]됐다.
4.1~4.6용 셰이더를 가져와도 이건 새로 만난다.
1번이 여기 걸렸다.""",
		"chips": [{"icon": "shader", "text": "grass_ssd.gdshader"}],
		"code": """uniform sampler2D DEPTH_TEXTURE
    : hint_depth_texture, filter_linear_mipmap;""",
		"try": "이제 직접 선언해야 한다",
	},
	{
		"title": "암시 형변환이 사라진 것 알기",
		"body": """Godot 4는 int를 float로 [b]자동 변환하지 않는다.[/b]
3.x에서 멀쩡하던 줄이 전부 컴파일 에러가 된다.""",
		"chips": [{"icon": "setting", "text": "GLSL 타입 엄격성"}],
		"code": """clamp(x, 0, 1)  -> clamp(x, 0.0, 1.0)
pow(x, 2)       -> pow(x, 2.0)
1.0f            -> 1.0""",
		"try": "`f` 접미사도 없다",
	},
	{
		"title": "코드가 아니라 임포트 설정 의심하기",
		"body": """[b]이건 코드만 봐서는 못 찾는다.[/b]
커브 텍스처가 기본 repeat이라 4번은 반경 밖 잔디가
캐릭터에 반응했다. `repeat_disable`을 안 걸어서다.

데이터 텍스처는 압축을 끄지 않으면 3D에서 처음 쓰는 순간
재임포트되어 정밀도가 날아간다.""",
		"chips": [{"icon": "texture", "text": ".import 설정"}],
		"code": """detect_3d/compress_to=0
compress/mode=0""",
		"try": "챕터 4의 밉맵 함정도 같은 부류다",
	},
]


func get_chapter_title() -> String:
	return "이식 — 4.7에서 걸린 것들"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.show_patches([1] if index == 1 else [4] if index == 3 else [1, 4, 5])
	world.camera_rig.position = Vector3(0.0, 1.4, 0.0)
	world.camera_rig.set_view(0.0, -0.28, 13.0 if index in [1, 3] else 26.0)
