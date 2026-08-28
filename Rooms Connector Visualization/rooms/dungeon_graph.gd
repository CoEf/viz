class_name DungeonGraph
extends Node3D
## 해부 대상 씬. 방을 흩뿌리고 원본 알고리즘(Delaunay → MST → 간선 선택)을
## 그대로 돌린 뒤, 각 단계를 XY 평면 도해로 그린다.
##
## 알고리즘 파일은 원본에서 손대지 않고 가져왔다. 여기서 하는 일은 입력을
## 만들고, 단계별 결과를 눈에 보이게 그리는 것뿐이다.

const REGION := Vector2(15.0, 9.0)
const ROOM_COUNT := 14
const SEED := 20260826

const COLOR_ROOM := Color(0.62, 0.70, 0.84)
const COLOR_DELAUNAY := Color(0.34, 0.62, 0.95, 0.40)
const COLOR_MST := Color(1.0, 0.76, 0.20)
const COLOR_LOOP := Color(1.0, 0.32, 0.55)

var rooms: Array[RoomData] = []
var delaunay_edges: Array[EdgeData] = []
var mst_edges: Array[EdgeData] = []
var loop_edges: Array[EdgeData] = []

var _triangulator := DelaunayTriangulator.new()
var _mst := MSTGenerator.new()
var _selector := EdgeSelector.new()
var camera_rig: OrbitCamera
var _room_marks: MultiMeshInstance3D
var _layers: Dictionary[StringName, MeshInstance3D] = {}


func _ready() -> void:
	_build_camera()
	add_child(DiagramKit.backdrop(REGION * 2.0 + Vector2(3.0, 3.0)))
	_build_rooms()
	_run_pipeline()
	_build_room_marks()
	# 같은 평면에 겹쳐 그리면 서로를 덮어 버린다. 레이어마다 z를 띄운다.
	for entry: Array in [[&"delaunay", -0.04], [&"mst", 0.0], [&"loop", 0.04]]:
		var surface := DiagramKit.ribbon_surface()
		surface.position = Vector3(0.0, 0.0, entry[1] as float)
		add_child(surface)
		_layers[entry[0] as StringName] = surface
	show_stage(&"none", 0.15)


## 스텝이 부르는 유일한 진입점. 어느 단계까지 보여줄지만 정하면 된다.
func show_stage(stage: StringName, loop_ratio := 0.15) -> void:
	if stage == &"loop":
		_select_loops(loop_ratio)
	_draw(&"delaunay", delaunay_edges if stage in [&"delaunay", &"mst", &"loop"] else [],
			COLOR_DELAUNAY, 0.03)
	_draw(&"mst", mst_edges if stage in [&"mst", &"loop"] else [], COLOR_MST, 0.075)
	_draw(&"loop", loop_edges if stage == &"loop" else [], COLOR_LOOP, 0.075)


func room_count() -> int:
	return rooms.size()


func _build_rooms() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var placed: Array[Vector2] = []
	# 서로 너무 붙으면 삼각분할이 납작한 삼각형을 만들어 도해가 지저분해진다.
	while placed.size() < ROOM_COUNT:
		var point := Vector2(
				rng.randf_range(-REGION.x, REGION.x),
				rng.randf_range(-REGION.y, REGION.y))
		var ok := true
		for other in placed:
			if point.distance_to(other) < 4.0:
				ok = false
				break
		if ok:
			placed.append(point)
	for i in placed.size():
		rooms.append(RoomData.new(i, placed[i], Rect2(placed[i] - Vector2(1.2, 0.8),
				Vector2(2.4, 1.6))))


func _run_pipeline() -> void:
	delaunay_edges = _triangulator.triangulate(rooms)
	mst_edges = _mst.generate_mst(rooms, delaunay_edges)
	_select_loops(0.15)


func _select_loops(ratio: float) -> void:
	_selector.loop_percentage = ratio
	var selected := _selector.select_edges(delaunay_edges, mst_edges)
	loop_edges.clear()
	for edge in selected:
		if not edge.is_mst:
			loop_edges.append(edge)


func _build_room_marks() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.9, 0.62, 0.12)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = rooms.size()
	_room_marks = MultiMeshInstance3D.new()
	_room_marks.multimesh = multimesh
	_room_marks.material_override = DiagramKit.flat_material(COLOR_ROOM)
	_room_marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in rooms.size():
		multimesh.set_instance_transform(i, Transform3D(
				Basis.IDENTITY, Vector3(rooms[i].center.x, rooms[i].center.y, 0.0)))
	add_child(_room_marks)


func _draw(layer: StringName, edges: Array, color: Color, width: float) -> void:
	var paths: Array[PackedVector3Array] = []
	for edge: EdgeData in edges:
		paths.append(PackedVector3Array([
			Vector3(edge.room_a.center.x, edge.room_a.center.y, 0.0),
			Vector3(edge.room_b.center.x, edge.room_b.center.y, 0.0)]))
	# 그래프 간선은 균일한 굵기여야 한다 — 페이드는 궤적용이다.
	DiagramKit.rebuild_ribbons(_layers[layer], paths, width, color, false)


## XY 평면 도해라 정면에서 보는 게 기본이지만, 드래그로 각도를 바꿔 볼 수 있다.
func _build_camera() -> void:
	camera_rig = OrbitCamera.new()
	camera_rig.min_distance = 8.0
	camera_rig.max_distance = 60.0
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera_rig.add_child(camera)
	add_child(camera_rig)
	camera_rig.set_view(0.0, -0.06, 22.0)
