class_name TriangleData
extends RefCounted
## 삼각형 데이터 구조
## Delaunay Triangulation에서 생성된 삼각형을 나타낸다.

## 삼각형의 세 꼭짓점 (방)
var room_a: RoomData
var room_b: RoomData
var room_c: RoomData

## 삼각형의 세 변 (간선)
var edges: Array[EdgeData]


func _init(p_a: RoomData, p_b: RoomData, p_c: RoomData) -> void:
	room_a = p_a
	room_b = p_b
	room_c = p_c
	edges = [
		EdgeData.new(room_a, room_b),
		EdgeData.new(room_b, room_c),
		EdgeData.new(room_c, room_a)
	]


## 세 꼭짓점의 좌표 배열 반환
func get_vertices() -> Array[Vector2]:
	return [room_a.center, room_b.center, room_c.center]


## 세 방의 ID 배열 반환
func get_room_ids() -> Array[int]:
	return [room_a.id, room_b.id, room_c.id]


## 삼각형의 무게중심 반환
func get_centroid() -> Vector2:
	return (room_a.center + room_b.center + room_c.center) / 3.0


## 주어진 방이 이 삼각형에 포함되어 있는지 확인
func contains_room(room: RoomData) -> bool:
	return room.id == room_a.id or room.id == room_b.id or room.id == room_c.id


func _to_string() -> String:
	return "TriangleData(%d, %d, %d)" % [room_a.id, room_b.id, room_c.id]
