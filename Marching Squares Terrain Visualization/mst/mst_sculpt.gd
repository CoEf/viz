class_name MstSculpt
## 브러시 네 종류가 높이맵에 쓰는 값. 원본 `marching_squares_terrain_plugin.gd`의
## `draw_pattern()` 한 함수 안에 `elif mode == ...` 로 나뉘어 있는 식들을 그대로 옮겼다.
##
## 네 도구는 전부 같은 자리(`chunk.draw_height`)에 쓴다. 다른 것은 쓸 값을 정하는
## 한 줄뿐이다 — 그게 1장의 요점이다.

const FALLOFF: Curve = preload("res://assets/noise/curve_falloff.tres")


## 브러시가 닿는 꼭짓점과 그 폴오프 세기를 {Vector2i: float} 로 돌려준다.
## 원본은 청크 여러 개에 걸치는 경우를 다루지만 여기는 청크가 하나뿐이다.
static func gather(chunk: MarchingSquaresTerrainChunk, center: Vector2,
		brush_size: float, brush_index: int, use_falloff: bool) -> Dictionary:
	var out: Dictionary = {}
	var cs := chunk.cell_size
	var max_distance := BrushPatternCalculator.calculate_max_distance(brush_size, brush_index)
	var dim := chunk.dimensions
	for z in range(dim.z):
		for x in range(dim.x):
			var world_pos := Vector2(x * cs.x, z * cs.y)
			var sample := BrushPatternCalculator.calculate_falloff_sample(
					world_pos, center, brush_size, brush_index, max_distance,
					use_falloff, FALLOFF)
			if sample < 0.0:
				continue
			out[Vector2i(x, z)] = clampf(sample, 0.001, 0.999)
	return out


## 브러시 도구 — 닿은 높이에 차이를 더한다.
static func brush(chunk: MarchingSquaresTerrainChunk, pattern: Dictionary,
		height_diff: float) -> void:
	for cc: Vector2i in pattern:
		var sample: float = pattern[cc]
		var restore := chunk.get_height(cc)
		chunk.draw_height(cc.x, cc.y, lerpf(restore, restore + height_diff, sample))


## 레벨 도구 — 정해 둔 한 높이로 끌어당긴다.
static func level(chunk: MarchingSquaresTerrainChunk, pattern: Dictionary,
		height: float) -> void:
	for cc: Vector2i in pattern:
		var sample: float = pattern[cc]
		var restore := chunk.get_height(cc)
		chunk.draw_height(cc.x, cc.y, lerpf(restore, height, sample))


## 스무드 도구 — 닿은 꼭짓점 전체의 평균으로 끌어당긴다.
static func smooth(chunk: MarchingSquaresTerrainChunk, pattern: Dictionary,
		strength: float) -> void:
	if pattern.is_empty():
		return
	var avg_height := 0.0
	for cc: Vector2i in pattern:
		avg_height += chunk.get_height(cc)
	avg_height /= pattern.size()
	for cc: Vector2i in pattern:
		var sample: float = pattern[cc]
		var restore := chunk.get_height(cc)
		chunk.draw_height(cc.x, cc.y, lerpf(restore, avg_height, sample * strength))


## 브리지 도구 — 두 점을 잇는 선 위에서의 진행도를 ease()로 굽혀 높이를 정한다.
static func bridge(chunk: MarchingSquaresTerrainChunk, pattern: Dictionary,
		start: Vector3, end: Vector3, ease_value: float) -> void:
	var cs := chunk.cell_size
	var b_start := Vector2(start.x, start.z)
	var b_end := Vector2(end.x, end.z)
	var bridge_length := (b_end - b_start).length()
	if bridge_length < 0.5:
		return
	var bridge_dir := (b_end - b_start) / bridge_length
	for cc: Vector2i in pattern:
		var world_cell := Vector2(cc.x * cs.x, cc.y * cs.y)
		var linear_offset := (world_cell - b_start).dot(bridge_dir)
		var progress := clampf(linear_offset / bridge_length, 0.0, 1.0)
		if ease_value != -1.0:
			progress = ease(progress, ease_value)
		chunk.draw_height(cc.x, cc.y, lerpf(start.y, end.y, progress))


## 브리지는 시작점과 끝점을 잇는 띠에만 닿는다.
static func gather_line(chunk: MarchingSquaresTerrainChunk, start: Vector2,
		end: Vector2, width: float) -> Dictionary:
	var out: Dictionary = {}
	var cs := chunk.cell_size
	var length := (end - start).length()
	if length < 0.001:
		return out
	var dir := (end - start) / length
	var dim := chunk.dimensions
	for z in range(dim.z):
		for x in range(dim.x):
			var p := Vector2(x * cs.x, z * cs.y) - start
			var along := p.dot(dir)
			if along < 0.0 or along > length:
				continue
			var across: float = absf(p.cross(dir))
			if across > width * 0.5:
				continue
			out[Vector2i(x, z)] = 0.999
	return out
