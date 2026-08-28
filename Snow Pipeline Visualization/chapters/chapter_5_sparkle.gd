extends SnowChapter
## 챕터 5 — 반짝임. 셀 분할 디버그 뷰(스텝 2)와, 카메라를 따라 실시간으로
## 움직이는 빛·시선·하프 벡터 3D 화살표 기즈모(스텝 3)로 글린트를 해부한다.

const STEPS: Array[Dictionary] = [
	{
		"title": "시점을 따라 반짝이게 하기",
		"body": """눈 결정 하나하나가 작은 거울이다.
그래서 반짝이는 자리가 고정되지 않고
[b]보는 각도를 따라[/b] 바뀐다.""",
		"chips": [{"icon": "shader", "text": "light() 패스"}],
		"try": "카메라를 천천히 돌리기",
	},
	{
		"title": "공간을 셀로 나눠 결정 만들기",
		"body": """'눈 결정 하나'에 해당하는 단위가 필요하다.
floor(월드좌표 × 밀도) = [b]셀[/b].
셀마다 난수를 뽑되 같은 셀은 늘 같은 값이라
반짝임이 프레임마다 널뛰지 않는다.""",
		"chips": [
			{"icon": "shader", "text": "snow_ground light()"},
			{"icon": "setting", "text": "전역 sparkle_density"},
		],
		"try": "밀도 슬라이더 — 셀 크기가 변한다",
	},
	{
		"title": "하프 벡터로 반짝일 셀 고르기",
		"body": """[color=#d98cff]보라[/color] = [color=#f2d564]빛[/color]과 [color=#73baf5]시선[/color]의 정확히 중간 방향.
회색 조각들 = 셀마다 정해진 거울 방향.
보라 원뿔이 [b]11° 허용 범위[/b]다.
원뿔 안에 들어온 조각만 [b]금색으로 번쩍인다.[/b]""",
		"chips": [{"icon": "shader", "text": "light() 패스"}],
		"code": """vec3 half_vec = normalize(VIEW + LIGHT);
float glint = smoothstep(0.982, 1.0,
    dot(glint_normal, half_vec));  // 11°""",
		"try": "보라 원뿔이 훑고 지나갈 때 조각이 번쩍인다",
	},
	{
		"title": "HDR 값으로 글로우 번지게 하기",
		"body": """통과한 반짝임에 밝기를 4배로 곱한다.
화면이 낼 수 있는 흰색보다 밝은 값([b]HDR[/b])이라
챕터 1에서 켠 글로우가 이걸 별처럼 피워낸다.""",
		"chips": [
			{"icon": "shader", "text": "light() 패스"},
			{"icon": "resource", "text": "Environment glow"},
		],
		"code": """SPECULAR_LIGHT += glint * gate
    * sparkle_strength * 4.0
    * LIGHT_COLOR;  // 1.0 초과 → 별""",
		"try": "글로우 토글 비교 + 밤 모드",
	},
]

## 셰이더의 smoothstep 하한과 같은 값 — 이 각도 안에 들어야 빛이 통과한다.
const GLINT_ANGLE := 11.0
const SHARDS_ON_PATH := 5
const SHARDS_RANDOM := 3
const CONE_LENGTH := 2.15
const SHARD_DIM := Color(0.42, 0.48, 0.6)
## 1.0을 넘겨 두면 글로우가 물어서 실제로 "번쩍"인다 — 스텝 4의 HDR과 같은 원리.
const SHARD_LIT := DiagramKit.HDR_FLASH

var _density := 12.0
var _gizmo_time := 0.0
var _readout_timer := 0.0
var _gizmo_root: Node3D
var _gizmo_eye: MeshInstance3D
var _backdrop: MeshInstance3D
var _arrow_light: Node3D
var _arrow_view: Node3D
var _arrow_half: Node3D
var _cone: Node3D
var _shards: Array[Node3D] = []
var _shard_materials: Array[StandardMaterial3D] = []
var _shard_lit: Array[bool] = []
var _shard_dirs := PackedVector3Array()


func _ready() -> void:
	WinterWorld.set_global_cover(0.9)
	WinterWorld.set_global_sparkle(1.5)
	world.set_fall_ratio(0.3)
	world.set_track_maker_enabled(false)
	world.camera_rig.set_view(0.65, -0.45, 10.0)
	_build_gizmo()


func _process(delta: float) -> void:
	if _gizmo_root == null or not _gizmo_root.visible:
		return
	# 실제 카메라를 시선으로 쓰면 화살표가 정면 단축돼 점으로 보인다.
	# 대신 파란 '눈알' 구슬이 궤도를 돌며 시선 역할을 해, 옆에서 관찰할 수 있다.
	_gizmo_time += delta
	_gizmo_eye.position = _orbit(_gizmo_time)
	# DirectionalLight3D는 -Z로 빛을 쏘므로 '빛을 향하는' 방향은 +Z 축이다.
	var light_dir: Vector3 = world.sun.global_transform.basis.z.normalized()
	var view_dir := _gizmo_eye.position.normalized()
	var half_dir := (light_dir + view_dir).normalized()
	DiagramKit.aim(_arrow_light, light_dir)
	DiagramKit.aim(_arrow_view, view_dir)
	DiagramKit.aim(_arrow_half, half_dir)
	DiagramKit.aim(_cone, half_dir)
	_place_backdrop()
	_update_shards(half_dir, delta)


func get_chapter_title() -> String:
	return "반짝이는 눈"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_ground_debug(3 if index == 1 else 0)
	_gizmo_root.visible = index == 2
	_backdrop.visible = index == 2
	if index == 2:
		_place_backdrop()
	if index == 1:
		update_code(_cell_code())
	if index == 2:
		# 첫 명중 직전부터 시작해, 들어오자마자 조각이 번쩍이는 걸 볼 수 있게 한다.
		_gizmo_time = 1.4
		world.camera_rig.position = Vector3(0.0, 3.6, 0.0)
		world.camera_rig.set_view(0.9, -0.08, 4.6)
	else:
		world.camera_rig.position = Vector3(0.0, 1.6, 0.0)
		world.camera_rig.set_view(0.65, -0.45, 10.0)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "반짝임 세기", 0.0, 3.0, 1.5, _on_strength_changed)
	add_slider(parent, "반짝임 밀도 (셀 크기)", 2.0, 40.0, 12.0, _on_density_changed)
	add_toggle(parent, "글로우 (빛 번짐)", true, _on_glow_toggled)
	add_toggle(parent, "밤 (달빛)", false, _on_night_toggled)


func _on_strength_changed(value: float) -> void:
	WinterWorld.set_global_sparkle(value)


func _on_density_changed(value: float) -> void:
	_density = value
	WinterWorld.set_global_sparkle_density(value)
	if current_step == 1:
		update_code(_cell_code())


func _on_glow_toggled(enabled: bool) -> void:
	world.environment().glow_enabled = enabled


func _on_night_toggled(night: bool) -> void:
	world.set_night(night)


func _cell_code() -> String:
	return ("cell = hash33(floor(\n"
			+ "    world_pos * sparkle_density));\n"
			+ "// sparkle_density = %.0f ← 밀도 슬라이더" % _density)


func _build_gizmo() -> void:
	_gizmo_root = Node3D.new()
	# 지면 잡동사니에서 떼어 하늘을 배경으로 두면 도해가 훨씬 잘 읽힌다.
	_gizmo_root.position = Vector3(0.0, 2.6, 0.0)
	_gizmo_root.visible = false
	add_child(_gizmo_root)
	var marker := MeshInstance3D.new()
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.11
	marker_mesh.height = 0.22
	marker.mesh = marker_mesh
	var marker_material := StandardMaterial3D.new()
	marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker_material.albedo_color = Color(1.0, 1.0, 1.0)
	marker.material_override = marker_material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_gizmo_root.add_child(marker)
	_build_backdrop()
	_build_cone()
	_build_shards()
	_arrow_light = _add_arrow(Color(0.95, 0.84, 0.39), 2.3, 0.04)
	_arrow_view = _add_arrow(Color(0.45, 0.73, 0.96), 2.3, 0.04)
	_arrow_half = _add_arrow(Color(0.85, 0.55, 1.0), 2.3, 0.04)
	_gizmo_eye = MeshInstance3D.new()
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.16
	eye_mesh.height = 0.32
	_gizmo_eye.mesh = eye_mesh
	var eye_material := StandardMaterial3D.new()
	eye_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye_material.albedo_color = Color(0.45, 0.73, 0.96)
	_gizmo_eye.material_override = eye_material
	_gizmo_eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_gizmo_root.add_child(_gizmo_eye)


func _add_arrow(color: Color, length: float, radius: float) -> Node3D:
	var arrow := DiagramKit.arrow(DiagramKit.flat_material(color), length, radius)
	_gizmo_root.add_child(arrow)
	return arrow


func _orbit(t: float) -> Vector3:
	return Vector3(cos(t * 0.5) * 2.4, 1.5 + sin(t * 0.35) * 0.7, sin(t * 0.5) * 2.4)


func _build_backdrop() -> void:
	# 시점이 도는 기즈모라 billboard 판을 쓴다. 기즈모의 자식이면 부모 회전을
	# 타므로 챕터에 직접 붙이고 위치만 매 프레임 잡아 준다.
	_backdrop = DiagramKit.backdrop(Vector2(6.4, 4.2), true)
	add_child(_backdrop)


func _place_backdrop() -> void:
	DiagramKit.place_behind(
			_backdrop, _gizmo_root, get_viewport().get_camera_3d(), 3.4, 1.05)


## 하프 벡터를 축으로 한 반각 11°의 원뿔 — 이 안에 든 거울 조각만 통과한다.
func _build_cone() -> void:
	_cone = DiagramKit.cone_gizmo(GLINT_ANGLE, CONE_LENGTH, Color(0.85, 0.55, 1.0))
	_gizmo_root.add_child(_cone)


func _build_shards() -> void:
	var light_dir: Vector3 = world.sun.global_transform.basis.z.normalized()
	var directions: Array[Vector3] = []
	# 시선이 도는 동안 하프 벡터가 실제로 지나가는 방향들 — 여기 둔 조각은 반드시 번쩍인다.
	for i in SHARDS_ON_PATH:
		directions.append((light_dir + _orbit(1.7 + float(i) * 3.1).normalized()).normalized())
	# 나머지는 아무 방향. 실제 셰이더처럼 대부분은 끝내 조건을 못 맞춘다.
	var rng := RandomNumberGenerator.new()
	rng.seed = 90125
	for i in SHARDS_RANDOM:
		directions.append(Vector3(
				rng.randf_range(-1.0, 1.0),
				rng.randf_range(0.15, 1.0),
				rng.randf_range(-1.0, 1.0)).normalized())
	for direction in directions:
		var material := DiagramKit.flat_material(SHARD_DIM)
		var shard := DiagramKit.arrow(material, 0.95, 0.024)
		_gizmo_root.add_child(shard)
		DiagramKit.aim(shard, direction)
		_shards.append(shard)
		_shard_materials.append(material)
		_shard_lit.append(false)
		_shard_dirs.append(direction)


func _update_shards(half_dir: Vector3, delta: float) -> void:
	var threshold := cos(deg_to_rad(GLINT_ANGLE))
	var best := -1.0
	for i in _shards.size():
		var alignment := _shard_dirs[i].dot(half_dir)
		best = maxf(best, alignment)
		var lit := alignment >= threshold
		# 상태가 바뀔 때만 손댄다 — scale을 매 프레임 다시 쓰면 회전이 조금씩 뭉개진다.
		if lit == _shard_lit[i]:
			continue
		_shard_lit[i] = lit
		_shard_materials[i].albedo_color = SHARD_LIT if lit else SHARD_DIM
		_shards[i].scale = Vector3.ONE * (1.3 if lit else 1.0)
	_readout_timer += delta
	if _readout_timer < 0.12:
		return
	_readout_timer = 0.0
	if current_step == 2:
		update_code(_glint_code(best, best >= threshold))


func _glint_code(best: float, passing: bool) -> String:
	return ("float glint = smoothstep(0.982, 1.0,\n"
			+ "    dot(glint_normal, half_vec));\n"
			+ "// 가장 가까운 조각 %.1f° → %s" % [
					rad_to_deg(acos(clampf(best, -1.0, 1.0))),
					"통과" if passing else "탈락"])
