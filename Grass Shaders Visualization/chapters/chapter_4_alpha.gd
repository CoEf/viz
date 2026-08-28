extends GrassChapter
## 챕터 4 — 알파 축. 이 프로젝트에서 제일 오래 헤맨 문제가 여기 있다.

const STEPS: Array[Dictionary] = [
	{
		"title": "알파 시저로 잎 모양 오리기",
		"body": """카드는 사각형이다. 잎 모양은 [b]텍스처로 오린다.[/b]
마스크가 임계값보다 낮은 픽셀을 통째로 버린다.
열 개 중 대부분이 이 방식이다.""",
		"chips": [{"icon": "shader", "text": "ALPHA_SCISSOR_THRESHOLD"}],
		"code": """ALPHA = texture(mask, UV).r;
ALPHA_SCISSOR_THRESHOLD = 0.8;""",
		"try": "가까이서는 멀쩡하다 — 다음 스텝에서 멀어져 본다",
	},
	{
		"title": "멀어지면 잔디가 통째로 사라진다",
		"body": """잎 실루엣은 텍스처 폭의 [b]6~15%[/b]밖에 안 된다.
멀어져 상위 밉을 쓰면 알파가 그 비율로 평균화돼
0.06~0.15가 되고, 임계값 0.8 아래라 [b]전부 discard[/b]된다.""",
		"chips": [{"icon": "texture", "text": "mipmaps/generate"}],
		"try": "아래 토글로 밉맵을 껐다 켜며 비교 — 이 스텝에서만 켤 수 있다",
	},
	{
		"title": "디더로 바꿔 함정을 피하기",
		"body": """3번만 이 함정에 안 걸린다.
마스크를 임계값과 비교하는 대신 [b]디더 stipple[/b]로 바꾼다.
밉으로 흐려지면 stipple이 성겨질 뿐, 필드가 사라지지 않는다.""",
		"chips": [
			{"icon": "shader", "text": "dither.gdshaderinc"},
			{"icon": "shader", "text": "grass_billboard.gdshader"},
		],
		"try": "아래 토글로 3번의 알파 방식을 바꿔 보기",
	},
]

var _toggle_on := true
var _mipmaps_on := true


func get_chapter_title() -> String:
	return "알파 — 잎 모양을 어떻게 오리는가"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	match index:
		0:
			world.set_mipmaps(false)
			world.show_patches([2])
			world.camera_rig.set_view(0.0, -0.28, 9.0)
		1:
			world.show_patches([2, 7])
			# 함정은 거리에서만 드러난다. 멀리 빼고, 밉맵 켠 사본으로 갈아 끼운다.
			world.set_mipmaps(_mipmaps_on)
			world.camera_rig.set_view(0.0, -0.20, 52.0)
			update_code(_mip_code())
		_:
			world.set_mipmaps(false)
			world.show_patches([2, 3])
			world.set_toggle(3, _toggle_on)
			world.camera_rig.set_view(0.0, -0.24, 30.0)
			update_code(_toggle_code(3))
	world.camera_rig.position = Vector3(0.0, 1.4, 0.0)


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, "잎 마스크 밉맵", true, _on_mipmaps_toggled, [1])
	add_toggle(parent, "3번 알파 모드", true, _on_toggled, [2])


func _on_mipmaps_toggled(on: bool) -> void:
	_mipmaps_on = on
	if current_step == 1:
		world.set_mipmaps(on)
		update_code(_mip_code())


func _mip_code() -> String:
	return ("mipmaps/generate=%s   // ← 토글\n" % str(_mipmaps_on).to_lower()
			+ "ALPHA_SCISSOR_THRESHOLD = 0.8;")


func _on_toggled(on: bool) -> void:
	_toggle_on = on
	if current_step == 2:
		world.set_toggle(3, on)
		update_code(_toggle_code(3))


func _toggle_code(number: int) -> String:
	var entry: Dictionary = world.entry_of(number)
	return ("%s = %s\n" % [entry["toggle"]["uniform"], str(entry["toggle"]["values"][0 if _toggle_on else 1])]
			+ "// %s" % world.toggle_label(number, _toggle_on))
