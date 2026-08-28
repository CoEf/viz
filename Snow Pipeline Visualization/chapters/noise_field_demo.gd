class_name NoiseFieldDemo
extends Node3D
## 챕터 2의 난류 해부용 시각화.
##
## XY 평면에 노이즈 필드를 화살표로 그리고(= 그 지점에서 눈송이를 미는 방향과
## 세기), 같은 필드로 눈송이를 적분해 궤적 리본을 그린다. 필드를 시간에 따라
## 흐르게 하지 않는 이유는, 화살표와 궤적이 정확히 대응해야 "노이즈가 경로를
## 흔든다"가 눈으로 읽히기 때문이다.

const GRID_X := 11
const GRID_Y := 8
const SPACING := 1.2
const ORIGIN := Vector2(-6.0, 1.2)
const ARROW_LEN := 0.72
const REFERENCE_STRENGTH := 0.6

const FLAKE_COUNT := 11
const FALL_SPEED := 0.85
const DEFLECT := 1.5
const TOP_Y := 10.0
const BOTTOM_Y := 0.6
const TRAIL_SAMPLE := 0.05
const TRAIL_POINTS := 90
const TRAIL_WIDTH := 0.05

const ARROW_COLOR := Color(0.38, 0.76, 1.0)
const TRAIL_COLOR := Color(1.0, 0.96, 0.78)

var _ready_done := false
var _strength := REFERENCE_STRENGTH
var _show_flakes := false
var _noise := FastNoiseLite.new()
var _flow_scale := 1.0
var _sample_timer := 0.0
var _flakes: Array[Vector3] = []
var _paths: Array[PackedVector3Array] = []
var _arrows: MultiMeshInstance3D
var _heads: MultiMeshInstance3D
var _trails: MeshInstance3D


func _ready() -> void:
	_noise.seed = 20260825
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 0.13
	_calibrate_flow()
	_build_backdrop()
	_build_arrows()
	_build_trails()
	_ready_done = true
	_update_arrows()
	restart()


func _process(delta: float) -> void:
	if not visible or not _show_flakes:
		return
	_advance(minf(delta, 0.05))
	_update_heads()
	_rebuild_trails()


## 화살표 길이는 세기에 비례한다 — 세기 0이면 화살표도 궤적의 휨도 사라진다.
func set_strength(value: float) -> void:
	_strength = value
	if not _ready_done:
		return
	_update_arrows()
	restart()
	_rebuild_trails()


func set_show_flakes(enabled: bool) -> void:
	_show_flakes = enabled
	if not _ready_done:
		return
	_heads.visible = enabled
	if enabled:
		restart()
		_update_heads()
		_rebuild_trails()
	else:
		DiagramKit.rebuild_ribbons(_trails, [], TRAIL_WIDTH, TRAIL_COLOR)


func restart() -> void:
	_flakes.clear()
	_paths.clear()
	var span := TOP_Y - BOTTOM_Y
	for i in FLAKE_COUNT:
		# 시작 높이를 층층이 어긋나게 둬야 궤적이 한꺼번에 리셋되지 않는다.
		var start := Vector3(
				lerpf(-5.2, 5.2, float(i) / float(FLAKE_COUNT - 1)),
				TOP_Y - span * float(i) / float(FLAKE_COUNT),
				0.0)
		_flakes.append(start)
		_paths.append(PackedVector3Array([start]))
	for _step in 100:
		_advance(0.05)


func _calibrate_flow() -> void:
	var peak := 0.0
	for gy in GRID_Y:
		for gx in GRID_X:
			peak = maxf(peak, _raw_flow(_grid_point(gx, gy)).length())
	_flow_scale = 1.0 / maxf(peak, 0.0001)


func _grid_point(gx: int, gy: int) -> Vector2:
	return ORIGIN + Vector2(gx, gy) * SPACING


## 스칼라 노이즈의 컬(curl) — 소용돌이가 도는 흐름 필드가 된다.
func _raw_flow(p: Vector2) -> Vector2:
	const E := 0.35
	var dx := (_noise.get_noise_2d(p.x + E, p.y) - _noise.get_noise_2d(p.x - E, p.y)) / (2.0 * E)
	var dy := (_noise.get_noise_2d(p.x, p.y + E) - _noise.get_noise_2d(p.x, p.y - E)) / (2.0 * E)
	return Vector2(dy, -dx)


func _flow(p: Vector2) -> Vector2:
	return _raw_flow(p) * _flow_scale


func _advance(delta: float) -> void:
	var push := _strength * DEFLECT
	for i in _flakes.size():
		var pos: Vector3 = _flakes[i]
		var flow := _flow(Vector2(pos.x, pos.y)) * push
		pos += Vector3(flow.x, flow.y - FALL_SPEED, 0.0) * delta
		if pos.y < BOTTOM_Y or absf(pos.x) > 6.4:
			pos = Vector3(randf_range(-5.2, 5.2), TOP_Y, 0.0)
			_paths[i] = PackedVector3Array()
		_flakes[i] = pos
	_sample_timer += delta
	if _sample_timer < TRAIL_SAMPLE:
		return
	_sample_timer = 0.0
	for i in _flakes.size():
		var path: PackedVector3Array = _paths[i]
		path.append(_flakes[i])
		if path.size() > TRAIL_POINTS:
			path.remove_at(0)
		_paths[i] = path


func _build_backdrop() -> void:
	var backdrop := DiagramKit.backdrop(
			Vector2(GRID_X * SPACING + 2.0, GRID_Y * SPACING + 1.4))
	backdrop.position = Vector3(
			ORIGIN.x + (GRID_X - 1) * SPACING * 0.5,
			ORIGIN.y + (GRID_Y - 1) * SPACING * 0.5 + 0.6,
			-1.5)
	add_child(backdrop)


func _build_arrows() -> void:
	_arrows = DiagramKit.vector_field(GRID_X * GRID_Y, ARROW_COLOR)
	add_child(_arrows)


func _update_arrows() -> void:
	var factor := clampf(_strength / REFERENCE_STRENGTH, 0.0, 1.8)
	for gy in GRID_Y:
		for gx in GRID_X:
			var point := _grid_point(gx, gy)
			var flow := _flow(point)
			# 화살표 길이 = 미는 세기. 세기 0이면 화살표도 사라진다.
			DiagramKit.set_field_arrow(
					_arrows, gy * GRID_X + gx, point, flow * ARROW_LEN * factor,
					Color(ARROW_COLOR.r, ARROW_COLOR.g, ARROW_COLOR.b,
							0.55 + 0.45 * flow.length()))


func _build_trails() -> void:
	_trails = DiagramKit.ribbon_surface()
	add_child(_trails)

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var head := SphereMesh.new()
	head.radius = 0.09
	head.height = 0.18
	head.radial_segments = 8
	head.rings = 4
	multimesh.mesh = head
	multimesh.instance_count = FLAKE_COUNT
	_heads = MultiMeshInstance3D.new()
	_heads.multimesh = multimesh
	_heads.material_override = DiagramKit.flat_material(Color.WHITE)
	_heads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_heads.visible = false
	add_child(_heads)


func _update_heads() -> void:
	for i in _flakes.size():
		_heads.multimesh.set_instance_transform(
				i, Transform3D(Basis.IDENTITY, _flakes[i]))


func _rebuild_trails() -> void:
	DiagramKit.rebuild_ribbons(_trails, _paths, TRAIL_WIDTH, TRAIL_COLOR)
