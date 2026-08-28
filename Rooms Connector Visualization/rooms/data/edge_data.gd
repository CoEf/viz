class_name EdgeData
extends RefCounted
## 간선 데이터 구조
## 두 방 사이의 연결을 나타낸다.

## 시작 방
var room_a: RoomData
## 끝 방
var room_b: RoomData
## 두 방 중심 사이의 거리 (캐시됨)
var distance: float
## MST에 포함된 간선인지 여부
var is_mst: bool = false
## 최종 그래프에서 선택된 간선인지 여부
var is_selected: bool = false


func _init(p_room_a: RoomData, p_room_b: RoomData) -> void:
	room_a = p_room_a
	room_b = p_room_b
	distance = room_a.center.distance_to(room_b.center)


## 다른 EdgeData와 동일한지 확인 (무방향 간선이므로 (A,B) == (B,A))
func equals(other: EdgeData) -> bool:
	return (room_a.id == other.room_a.id and room_b.id == other.room_b.id) or \
		   (room_a.id == other.room_b.id and room_b.id == other.room_a.id)


## 간선의 중심점 반환
func get_center() -> Vector2:
	return (room_a.center + room_b.center) / 2.0


## 방향에 상관없이 일관된 키 생성 (Dictionary 키로 사용)
func get_rooms_key() -> String:
	var min_id := mini(room_a.id, room_b.id)
	var max_id := maxi(room_a.id, room_b.id)
	return "%d_%d" % [min_id, max_id]


## 주어진 방이 이 간선에 연결되어 있는지 확인
func contains_room(room: RoomData) -> bool:
	return room.id == room_a.id or room.id == room_b.id


## 주어진 방의 반대편 방 반환
func get_other_room(room: RoomData) -> RoomData:
	if room.id == room_a.id:
		return room_b
	elif room.id == room_b.id:
		return room_a
	return null


func _to_string() -> String:
	var mst_str := " [MST]" if is_mst else ""
	var sel_str := " [SEL]" if is_selected else ""
	return "EdgeData(%d <-> %d, dist=%.1f%s%s)" % [room_a.id, room_b.id, distance, mst_str, sel_str]
