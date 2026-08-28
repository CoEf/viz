class_name EdgeSelector
extends RefCounted
## 간선 선택기
## MST 간선 + 일정 비율의 비-MST 간선을 선택하여 루프를 추가한다.
## 루프가 있으면 던전에서 순환 경로가 생겨 더 다양한 탐험이 가능해진다.

## 비-MST 간선 중 추가할 비율 (0.0 ~ 1.0)
var loop_percentage: float = 0.15


func _init(p_loop_percentage: float = 0.15) -> void:
	loop_percentage = clampf(p_loop_percentage, 0.0, 1.0)


## 최종 간선 선택
## all_edges: Delaunay에서 생성된 모든 간선
## mst_edges: MST에 포함된 간선들
## 반환: MST 간선 + 선택된 루프 간선
func select_edges(
	all_edges: Array[EdgeData],
	mst_edges: Array[EdgeData]
) -> Array[EdgeData]:
	var selected: Array[EdgeData] = []
	var non_mst: Array[EdgeData] = []

	# MST 간선 키 수집 (빠른 조회용)
	var mst_keys: Dictionary = {}
	for edge in mst_edges:
		edge.is_mst = true
		edge.is_selected = true
		mst_keys[edge.get_rooms_key()] = true
		selected.append(edge)

	# 비-MST 간선 수집
	for edge in all_edges:
		if not mst_keys.has(edge.get_rooms_key()):
			non_mst.append(edge)

	# 비-MST 간선을 거리순으로 정렬 (짧은 간선 우선 - 더 자연스러운 루프)
	non_mst.sort_custom(func(a: EdgeData, b: EdgeData) -> bool:
		return a.distance < b.distance
	)

	# 비율에 따라 간선 추가
	var num_to_add: int = int(ceil(non_mst.size() * loop_percentage))

	for i in range(mini(num_to_add, non_mst.size())):
		non_mst[i].is_selected = true
		selected.append(non_mst[i])

	return selected


## 랜덤하게 간선 선택 (대안 방식)
func select_edges_random(
	all_edges: Array[EdgeData],
	mst_edges: Array[EdgeData],
	rng: RandomNumberGenerator = null
) -> Array[EdgeData]:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var selected: Array[EdgeData] = []
	var non_mst: Array[EdgeData] = []

	var mst_keys: Dictionary = {}
	for edge in mst_edges:
		edge.is_mst = true
		edge.is_selected = true
		mst_keys[edge.get_rooms_key()] = true
		selected.append(edge)

	for edge in all_edges:
		if not mst_keys.has(edge.get_rooms_key()):
			non_mst.append(edge)

	# 셔플 후 비율만큼 선택
	non_mst.shuffle()
	var num_to_add: int = int(ceil(non_mst.size() * loop_percentage))

	for i in range(mini(num_to_add, non_mst.size())):
		non_mst[i].is_selected = true
		selected.append(non_mst[i])

	return selected


## 지정한 개수만큼 루프 간선 추가
func select_edges_count(
	all_edges: Array[EdgeData],
	mst_edges: Array[EdgeData],
	num_loops: int
) -> Array[EdgeData]:
	var selected: Array[EdgeData] = []
	var non_mst: Array[EdgeData] = []

	var mst_keys: Dictionary = {}
	for edge in mst_edges:
		edge.is_mst = true
		edge.is_selected = true
		mst_keys[edge.get_rooms_key()] = true
		selected.append(edge)

	for edge in all_edges:
		if not mst_keys.has(edge.get_rooms_key()):
			non_mst.append(edge)

	# 거리순 정렬
	non_mst.sort_custom(func(a: EdgeData, b: EdgeData) -> bool:
		return a.distance < b.distance
	)

	# 지정 개수만큼 추가
	for i in range(mini(num_loops, non_mst.size())):
		non_mst[i].is_selected = true
		selected.append(non_mst[i])

	return selected


## 선택된 간선 통계 반환
func get_selection_stats(selected: Array[EdgeData]) -> Dictionary:
	var mst_count := 0
	var loop_count := 0
	var total_distance := 0.0

	for edge in selected:
		if edge.is_mst:
			mst_count += 1
		else:
			loop_count += 1
		total_distance += edge.distance

	return {
		"mst_edges": mst_count,
		"loop_edges": loop_count,
		"total_edges": selected.size(),
		"total_distance": total_distance,
		"loop_ratio": float(loop_count) / float(maxi(selected.size(), 1))
	}
