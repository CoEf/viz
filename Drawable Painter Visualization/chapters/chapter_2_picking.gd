extends PainterChapter
## 챕터 2 — 표면 피킹. 화면 픽셀 → 광선 → 삼각형 → UV 로 가는 길을 그린다.
##
## 광선을 실제 시점 카메라에서 쏘면 화살표가 시선과 겹쳐 점으로 붕괴한다.
## 그래서 고정된 프로브 카메라가 광선을 쏘고, 관람 카메라는 옆에서 본다.

const STEPS: Array[Dictionary] = [
	{
		"title": "메시를 레이캐스트 사본으로 굽기",
		"body": """물리 엔진 없이 TriangleMesh 하나로 잰다.
정점·UV 배열을 셋업 때 한 번 복사해 두면
[b]모든 클릭이 이 사본과의 교차 검사[/b]다.""",
		"chips": [
			{"icon": "script", "text": "surface_picker_component.gd"},
			{"icon": "resource", "text": "TriangleMesh"},
		],
		"code": "_hit_mesh.create_from_faces(_faces)",
	},
	{
		"title": "화면 점에서 광선 쏘기",
		"body": """카메라가 화면 픽셀을 광선으로 바꾼다.
주황 화살표가 그 광선,
구슬이 인형 표면과 만난 점이다.""",
		"chips": [
			{"icon": "node3d", "text": "Camera3D"},
			{"icon": "script", "text": "project_ray_origin·normal"},
		],
		"code": """var o := cam.project_ray_origin(pos)
var n := cam.project_ray_normal(pos)""",
		"try": "화면 X 슬라이더 → 광선과 맞은 점이 따라간다",
	},
	{
		"title": "맞은 삼각형에서 UV 뽑기",
		"body": """교차점이 세 꼭짓점과 이루는 넓이 비율로
[b]꼭짓점 UV 세 개를 섞는다[/b](무게중심 보간).
구슬 크기가 각 꼭짓점의 가중치다.""",
		"chips": [
			{"icon": "script", "text": "intersect_ray"},
			{"icon": "script", "text": "무게중심 보간"},
		],
		"code": """return _uvs[i] * a1
     + _uvs[i + 1] * a2
     + _uvs[i + 2] * a3""",
		"try": "슬라이더로 밀며 오른쪽 십자 보기 — 삼각형이 바뀌면 UV가 점프한다",
	},
	{
		"title": "Pose로 커서 세우기",
		"body": """지우개·미리보기 커서는 UV가 아니라
[b]위치+법선(Pose)[/b]을 받는다.
원반이 곡면에 딱 붙는 이유다.""",
		"chips": [
			{"icon": "script", "text": "get_pose"},
			{"icon": "script", "text": "Pose.align_up"},
		],
		"code": """basis.y = up_direction
basis.x = -basis.z.cross(up_direction)
return basis.orthonormalized()""",
		"try": "슬라이더로 옮기면 원반이 곡면을 따라 기운다",
	},
]

var _diagram: Node3D
var _probe: Camera3D
var _screen_x := 0.5
var _uv_view: TextureRect
var _marker_h: ColorRect
var _marker_v: ColorRect


func _ready() -> void:
	_diagram = Node3D.new()
	add_child(_diagram)
	# 광선을 쏘는 고정 프로브 — 기본 정면 시점과 같은 자리.
	_probe = Camera3D.new()
	_probe.near = 0.005
	world.add_child(_probe)
	_probe.look_at_from_position(
			Vector3(0.0, 0.07, -0.34), Vector3(0.0, 0.02, 0.0), Vector3.UP)


func get_chapter_title() -> String:
	return "클릭을 UV로 바꾸기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_interactive(false)
	world.use_paint_canvas()
	# 얇은 화살표·리본이 블룸에 뭉개지지 않도록 도해 스텝에서는 글로우를 끈다.
	world.environment().glow_enabled = index == 0
	if index >= 2:
		# UV 십자를 읽을 수 있게 캔버스 전체에 인형 무늬를 깔아 둔다.
		world.canvas.paint_at(Vector2(0.5, 0.5), 6000.0, world.brushes()[1])
	if index == 0:
		world.set_view(PI, -0.18, 0.32)
	else:
		# 광선이 보이도록 옆에서 본다.
		world.set_view(PI * 0.62, -0.22, 0.3 if index >= 2 else 0.5)
	_rebuild_diagram(index)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "화면 X (프로브 카메라)", 0.3, 0.7, _screen_x,
			_on_screen_x_changed, [1, 2, 3])
	_uv_view = add_texture_view(parent, "캔버스와 보간된 UV", world.get_albedo_texture(),
			[2, 3], 220.0)
	_marker_h = ColorRect.new()
	_marker_h.color = Color(1.0, 0.4, 0.1)
	_marker_h.size = Vector2(220.0, 2.0)
	_uv_view.add_child(_marker_h)
	_marker_v = ColorRect.new()
	_marker_v.color = Color(1.0, 0.4, 0.1)
	_marker_v.size = Vector2(2.0, 220.0)
	_uv_view.add_child(_marker_v)


func _on_screen_x_changed(value: float) -> void:
	_screen_x = value
	_rebuild_diagram(current_step)


func _rebuild_diagram(index: int) -> void:
	for child in _diagram.get_children():
		child.free()
	if index == 0:
		return

	var hit = world.picker.get_hit_info(_probe, world.screen_px(Vector2(_screen_x, 0.47)))
	if hit == null:
		return
	var hit_pos: Vector3 = hit.world_pos
	var origin: Vector3 = _probe.global_position

	# 프로브 카메라 몸통.
	var camera_box := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.025, 0.018, 0.03)
	camera_box.mesh = box
	camera_box.material_override = DiagramKit.flat_material(Color(0.25, 0.28, 0.34))
	camera_box.position = origin
	_diagram.add_child(camera_box)

	# 광선 화살표.
	var direction := hit_pos - origin
	var ray := DiagramKit.arrow(
			DiagramKit.flat_material(Color(1.0, 0.55, 0.1)),
			direction.length() - 0.01, 0.0018)
	_diagram.add_child(ray)
	ray.global_position = origin
	DiagramKit.aim(ray, direction)

	# 교차점 구슬.
	var hit_ball := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.0045
	ball.height = 0.009
	hit_ball.mesh = ball
	hit_ball.material_override = DiagramKit.flat_material(Color(1.0, 0.85, 0.2))
	hit_ball.position = hit_pos
	_diagram.add_child(hit_ball)

	if index >= 2:
		_add_triangle(hit)
	if index >= 3:
		_add_pose_disc()
	_update_uv_marker(hit.uv)


## 맞은 삼각형 테두리 리본 + 무게중심 가중치 구슬(클수록 가중치 큼).
func _add_triangle(hit: Dictionary) -> void:
	var to_world := world.mesh.global_transform
	var corners: Array = hit.local_positions
	var weights: Vector3 = hit.weights
	var path := PackedVector3Array()
	for corner: Vector3 in corners:
		path.append(to_world * corner)
	path.append(to_world * (corners[0] as Vector3))
	var surface := DiagramKit.ribbon_surface()
	_diagram.add_child(surface)
	var paths: Array[PackedVector3Array] = [path]
	DiagramKit.rebuild_ribbons(surface, paths, 0.0011, Color(0.3, 0.9, 1.0), false)

	var colors: Array[Color] = [
		Color(1.0, 0.35, 0.35), Color(0.4, 1.0, 0.45), Color(0.45, 0.6, 1.0)]
	for i in 3:
		var vertex_ball := MeshInstance3D.new()
		var ball := SphereMesh.new()
		var weight: float = weights[i]
		ball.radius = 0.0016 + weight * 0.005
		ball.height = ball.radius * 2.0
		vertex_ball.mesh = ball
		vertex_ball.material_override = DiagramKit.flat_material(colors[i])
		vertex_ball.position = to_world * (corners[i] as Vector3)
		_diagram.add_child(vertex_ball)


## get_pose()가 준 위치+법선에 원반을 붙인다 — 원본 커서와 같은 경로.
func _add_pose_disc() -> void:
	var pose = world.picker.get_pose(_probe, world.screen_px(Vector2(_screen_x, 0.47)))
	if pose == null:
		return
	var disc := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.018
	cylinder.bottom_radius = 0.018
	cylinder.height = 0.001
	disc.mesh = cylinder
	disc.material_override = DiagramKit.flat_material(Color(1.0, 0.55, 0.1, 0.85))
	_diagram.add_child(disc)
	pose.apply(disc)
	var normal_arrow := DiagramKit.arrow(
			DiagramKit.flat_material(Color(0.3, 0.9, 1.0)), 0.04, 0.0013)
	_diagram.add_child(normal_arrow)
	normal_arrow.global_transform = disc.global_transform


func _update_uv_marker(uv: Vector2) -> void:
	if _marker_h == null:
		return
	var side: float = _uv_view.custom_minimum_size.x
	_marker_h.position = Vector2(0.0, clampf(uv.y * side, 0.0, side - 2.0))
	_marker_v.position = Vector2(clampf(uv.x * side, 0.0, side - 2.0), 0.0)
