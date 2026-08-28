class_name DelaunayTriangulator
extends RefCounted
## Delaunay Triangulation 알고리즘
## Godot의 내장 Geometry2D.triangulate_delaunay()를 사용하여
## 방 중심점들로부터 삼각형과 유니크 간선을 생성한다.

## 입력된 방 목록
var _rooms: Array[RoomData]
## 생성된 삼각형 목록
var _triangles: Array[TriangleData]
## 유니크 간선 딕셔너리 (Key: edge_key, Value: EdgeData)
var _edges: Dictionary


func _init() -> void:
	_rooms = []
	_triangles = []
	_edges = {}


## 방 목록으로부터 Delaunay Triangulation 수행
## 반환: 유니크 EdgeData 배열
func triangulate(rooms: Array[RoomData]) -> Array[EdgeData]:
	_rooms = rooms
	_triangles = []
	_edges = {}

	# 2개 미만의 방은 삼각형을 만들 수 없음
	if rooms.size() < 2:
		return []

	# 2개의 방일 경우 직접 연결
	if rooms.size() == 2:
		var edge := EdgeData.new(rooms[0], rooms[1])
		_edges[edge.get_rooms_key()] = edge
		return [edge]

	# 방 중심점들로 PackedVector2Array 생성
	var points := PackedVector2Array()
	for room in rooms:
		points.append(room.center)

	# Godot 내장 Delaunay Triangulation 호출
	var indices: PackedInt32Array = Geometry2D.triangulate_delaunay(points)

	# 결과가 없으면 (동일선상의 점들 등) 빈 배열 반환
	if indices.is_empty():
		push_warning("DelaunayTriangulator: triangulate_delaunay returned empty. Points may be collinear.")
		return _fallback_connect_sequential(rooms)

	# 인덱스는 3개씩 그룹화됨 (각 삼각형의 세 꼭짓점)
	for i in range(0, indices.size(), 3):
		var idx_a: int = indices[i]
		var idx_b: int = indices[i + 1]
		var idx_c: int = indices[i + 2]

		# 삼각형 생성
		var triangle := TriangleData.new(rooms[idx_a], rooms[idx_b], rooms[idx_c])
		_triangles.append(triangle)

		# 유니크 간선 추가
		for edge in triangle.edges:
			var key := edge.get_rooms_key()
			if not _edges.has(key):
				_edges[key] = edge

	return get_edges()


## 폴백: Delaunay가 실패할 경우 순차적으로 연결
func _fallback_connect_sequential(rooms: Array[RoomData]) -> Array[EdgeData]:
	_edges = {}
	for i in range(rooms.size() - 1):
		var edge := EdgeData.new(rooms[i], rooms[i + 1])
		_edges[edge.get_rooms_key()] = edge
	return get_edges()


## 생성된 삼각형 목록 반환
func get_triangles() -> Array[TriangleData]:
	return _triangles


## 생성된 유니크 간선 목록 반환
func get_edges() -> Array[EdgeData]:
	var result: Array[EdgeData] = []
	for edge in _edges.values():
		result.append(edge)
	return result


## 간선 개수 반환
func get_edge_count() -> int:
	return _edges.size()


## 삼각형 개수 반환
func get_triangle_count() -> int:
	return _triangles.size()
