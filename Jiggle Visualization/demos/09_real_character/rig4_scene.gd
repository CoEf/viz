class_name Rig4Scene
extends Node3D

## 이식본 — 원본 Jiggle 프로젝트의 demos/09_real_character/rig4_scene.gd 에서
## 워크스루에 필요 없는 것(무대 · HUD · 키 입력 · 자체 자극)을 덜어낸 것.
## adachi_rigged4_jiggle.tscn 이 루트 스크립트로 쓴다.
##
## 원본과 같은 원칙: [b]이 스크립트는 시뮬레이터를 만들지 않는다.[/b]
## 모디파이어 · 충돌체는 전부 .tscn 안에 실제 노드로 들어 있고, 여기서는 찾아 둘 뿐이다.

## 화면에 띄울 이름. 씬 파일이 값을 넣으므로 지우면 안 된다.
@export var title := ""
## 캐릭터를 담고 있는 노드 이름(glb 인스턴스).
@export var character_path := NodePath("Character")

var character: Node3D = null
var chain_modifiers: Array[JiggleChainModifier3D] = []
var bone_modifiers: Array[JiggleBoneModifier3D] = []
var collider_nodes: Array[JiggleCollider3D] = []


func _ready() -> void:
	character = get_node_or_null(character_path) as Node3D
	_walk(self)


## 캐릭터를 자극 위치로 옮긴다. 흔들림은 이 이동을 파티클이 못 따라가면서 생긴다.
func apply_motion(offset: Vector3, euler: Vector3) -> void:
	if character != null:
		character.transform = Transform3D(Basis.from_euler(euler), offset)


func set_simulating(value: bool) -> void:
	for modifier in chain_modifiers:
		modifier.active = value
	for modifier in bone_modifiers:
		modifier.active = value
	if not value:
		# 모디파이어를 끄면 마지막 포즈가 그대로 남는다. 직접 되돌려 줘야 한다.
		var skeleton := find_skeleton(self)
		if skeleton != null:
			skeleton.reset_bone_poses()


func reset_simulation() -> void:
	for modifier in chain_modifiers:
		modifier.reset_simulation()
	for modifier in bone_modifiers:
		modifier.reset_simulation()


## 씬에 이미 들어 있는 시뮬레이터 노드를 찾아 둔다. 만들지 않는다.
func _walk(node: Node) -> void:
	var chain := node as JiggleChainModifier3D
	if chain != null:
		chain_modifiers.append(chain)
	var bone := node as JiggleBoneModifier3D
	if bone != null:
		bone_modifiers.append(bone)
	var collider := node as JiggleCollider3D
	if collider != null:
		collider_nodes.append(collider)
	for child in node.get_children():
		_walk(child)


## 카메라를 어디에 둘지 리그 치수에서 뽑는다. 원본 build_stage 가 쓰던 것과 같다.
static func measure(target: Node3D) -> Dictionary:
	var skeleton := find_skeleton(target)
	if skeleton == null:
		return {"focus": Vector3(0.0, 1.0, 0.0), "height": 1.7, "ground_y": 0.0}
	var world := skeleton.global_transform
	var head := (world * skeleton.get_bone_global_pose(skeleton.find_bone("Head"))).origin
	var foot := (world * skeleton.get_bone_global_pose(skeleton.find_bone("foot.L"))).origin
	var hip := (world * skeleton.get_bone_global_pose(skeleton.find_bone("spine"))).origin
	# Head 본은 목 밑이라 머리카락 높이가 빠진다. 그만큼 얹어 실제 실루엣에 맞춘다.
	var height := maxf(head.y - foot.y, 0.3) * 1.25
	return {
		"focus": Vector3(hip.x, (head.y + foot.y) * 0.5 + height * 0.10, hip.z),
		"height": height,
		"ground_y": foot.y,
	}


static func find_skeleton(node: Node) -> Skeleton3D:
	var found := node as Skeleton3D
	if found != null:
		return found
	for child in node.get_children():
		var result := find_skeleton(child)
		if result != null:
			return result
	return null
