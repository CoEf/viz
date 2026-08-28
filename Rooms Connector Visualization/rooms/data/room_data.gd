class_name RoomData
extends RefCounted
## 원본 RoomData(299줄)의 최소 이식본.
##
## 원본은 문 마커·씬 인스턴스·방 타입까지 들고 있지만, 이 시각화가 다루는
## 삼각분할·MST·간선 선택 알고리즘은 `id`와 `center`만 읽는다. 나머지를
## 끌고 오면 DoorMarker·RoomScene까지 딸려 오므로 여기서 잘랐다.

var id: int
var center: Vector2
var bounds: Rect2


func _init(p_id: int, p_center: Vector2, p_bounds: Rect2 = Rect2()) -> void:
	id = p_id
	center = p_center
	bounds = p_bounds


func get_connection_point() -> Vector2:
	return center


static func from_rect(p_id: int, rect: Rect2) -> RoomData:
	return RoomData.new(p_id, rect.get_center(), rect)


func _to_string() -> String:
	return "Room(%d @ %s)" % [id, center]
