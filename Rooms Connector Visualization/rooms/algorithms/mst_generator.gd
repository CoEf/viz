class_name MSTGenerator
extends RefCounted
## MST (Minimum Spanning Tree) 생성기
## Prim's Algorithm을 사용하여 최소 신장 트리를 생성한다.
## AStar2D를 내부 그래프 구조로 활용하여 이후 경로 탐색에도 사용 가능.

## 내부 AStar2D 그래프
var _astar: AStar2D
## RoomData.id -> AStar point ID 매핑
var _room_to_point_id: Dictionary
## AStar point ID -> RoomData 매핑
var _point_id_to_room: Dictionary
## MST를 구성하는 간선 목록
var _mst_edges: Array[EdgeData]


func _init() -> void:
	_astar = AStar2D.new()
	_room_to_point_id = {}
	_point_id_to_room = {}
	_mst_edges = []


## MST 생성
## rooms: 연결할 방 목록
## available_edges: Delaunay에서 생성된 간선 목록 (이 간선들만 사용)
## 반환: MST를 구성하는 EdgeData 배열
func generate_mst(rooms: Array[RoomData], available_edges: Array[EdgeData]) -> Array[EdgeData]:
	# 초기화
	_astar = AStar2D.new()
	_room_to_point_id = {}
	_point_id_to_room = {}
	_mst_edges = []

	if rooms.is_empty():
		return []

	if rooms.size() == 1:
		_add_room_to_astar(rooms[0])
		return []

	# 인접 리스트 구축
	var adjacency: Dictionary = _build_adjacency(available_edges)

	# MST에 포함된 방 추적
	var in_mst: Dictionary = {}  # room.id -> bool
	var remaining: Array[RoomData] = rooms.duplicate()

	# 첫 번째 방으로 시작
	var first_room: RoomData = remaining.pop_front()
	_add_room_to_astar(first_room)
	in_mst[first_room.id] = true

	# Prim's Algorithm 메인 루프
	while not remaining.is_empty():
		var min_dist: float = INF
		var min_edge: EdgeData = null
		var next_room: RoomData = null
		var connecting_room_id: int = -1

		# MST에 있는 모든 방에서 MST에 없는 가장 가까운 방 찾기
		for room_id in in_mst.keys():
			if not adjacency.has(room_id):
				continue

			var neighbors: Array = adjacency[room_id]
			for edge_info in neighbors:
				var neighbor_id: int = edge_info["neighbor_id"]
				var edge: EdgeData = edge_info["edge"]

				# 이미 MST에 있는 방은 스킵
				if in_mst.has(neighbor_id):
					continue

				if edge.distance < min_dist:
					min_dist = edge.distance
					min_edge = edge
					connecting_room_id = room_id
					# remaining에서 해당 방 찾기
					for r in remaining:
						if r.id == neighbor_id:
							next_room = r
							break

		# 연결할 방을 찾지 못함 (그래프가 분리됨)
		if next_room == null:
			push_warning("MSTGenerator: Graph is disconnected. Some rooms cannot be reached.")
			break

		# 방과 간선을 MST에 추가
		_add_room_to_astar(next_room)
		min_edge.is_mst = true
		min_edge.is_selected = true
		_mst_edges.append(min_edge)

		# AStar에서 연결
		var id_a = _room_to_point_id[min_edge.room_a.id]
		var id_b = _room_to_point_id[min_edge.room_b.id]
		_astar.connect_points(id_a, id_b)

		in_mst[next_room.id] = true
		remaining.erase(next_room)

	return _mst_edges


## 간선 목록으로부터 인접 리스트 구축
func _build_adjacency(edges: Array[EdgeData]) -> Dictionary:
	var adj: Dictionary = {}

	for edge in edges:
		var id_a := edge.room_a.id
		var id_b := edge.room_b.id

		if not adj.has(id_a):
			adj[id_a] = []
		if not adj.has(id_b):
			adj[id_b] = []

		adj[id_a].append({"neighbor_id": id_b, "edge": edge})
		adj[id_b].append({"neighbor_id": id_a, "edge": edge})

	return adj


## AStar에 방 추가
func _add_room_to_astar(room: RoomData) -> void:
	var point_id := _astar.get_available_point_id()
	_astar.add_point(point_id, room.center)
	_room_to_point_id[room.id] = point_id
	_point_id_to_room[point_id] = room


## 생성된 AStar2D 그래프 반환 (경로 탐색 등에 활용 가능)
func get_astar() -> AStar2D:
	return _astar


## MST 간선 목록 반환
func get_mst_edges() -> Array[EdgeData]:
	return _mst_edges


## 특정 방의 AStar point ID 반환
func get_point_id(room: RoomData) -> int:
	if _room_to_point_id.has(room.id):
		return _room_to_point_id[room.id]
	return -1


## 특정 AStar point ID의 방 반환
func get_room(point_id: int) -> RoomData:
	if _point_id_to_room.has(point_id):
		return _point_id_to_room[point_id]
	return null


## 두 방 사이의 경로 찾기 (AStar 사용)
func find_path(from_room: RoomData, to_room: RoomData) -> PackedVector2Array:
	var from_id := get_point_id(from_room)
	var to_id := get_point_id(to_room)

	if from_id == -1 or to_id == -1:
		return PackedVector2Array()

	return _astar.get_point_path(from_id, to_id)
