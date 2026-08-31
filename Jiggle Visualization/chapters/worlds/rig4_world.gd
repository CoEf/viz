class_name Rig4World
extends JiggleStage
## 챕터 0 · 6 월드 — 실제 Rigify 캐릭터(본 183개) + 씬에 노드로 들어 있는
## 모디파이어들. adachi_rigged4_jiggle.tscn 을 통째로 인스턴스한다.
## 시뮬레이터를 하나도 만들지 않는다 — 씬에 이미 있는 것을 찾아 조작할 뿐이다.

const RIG_SCENE := preload("res://assets/adachi_rigged4/adachi_rigged4_jiggle.tscn")

const GROUP_COLORS := {
	"hair": Color(1.0, 0.87, 0.20, 0.9),
	"dress": Color(0.30, 1.0, 0.60, 0.9),
	"ribbon": Color(1.0, 0.40, 0.90, 0.9),
}

var show_chains := false
var show_colliders := false

var rig: Rig4Scene
## 그룹 이름("hair" · "dress" · "ribbon") → 그 그룹의 사슬 모디파이어들.
var chain_groups: Dictionary[String, Array] = {}

# 리그 실측 치수. 챕터가 카메라를 잡을 때 쓴다.
var focus := Vector3(0.0, 1.0, 0.0)
var char_height := 1.7
var ground_y := 0.0


func _build() -> void:
	stimulus.kind = Stimulus.Kind.WALK

	rig = RIG_SCENE.instantiate() as Rig4Scene
	add_child(rig)
	_group_modifiers()
	_localize_settings()

	# 카메라와 바닥을 리그 치수에서 뽑는다. 모델이 바뀌어도 다시 맞출 필요가 없다.
	var metrics := Rig4Scene.measure(rig.character)
	focus = metrics["focus"]
	char_height = metrics["height"]
	ground_y = metrics["ground_y"]
	set_ground_y(ground_y)
	view_full()


## 전신이 들어오는 기본 화각.
func view_full() -> void:
	set_view(focus, deg_to_rad(26.0), -0.1, char_height * 1.35)


## 치마·허벅지 높이 근접 화각. 충돌체와 치마 사슬을 볼 때 쓴다.
func view_hips() -> void:
	var hip := Vector3(focus.x, ground_y + char_height * 0.42, focus.z)
	set_view(hip, deg_to_rad(18.0), -0.06, char_height * 0.62)


func reset_world() -> void:
	stimulus.reset()
	if rig != null:
		rig.reset_simulation()
		rig.apply_motion(Vector3.ZERO, Vector3.ZERO)


func _frame_update(_delta: float) -> void:
	rig.apply_motion(stimulus.offset, stimulus.euler)


func _draw_debug() -> void:
	if show_colliders:
		for node in rig.collider_nodes:
			var collider := node.to_collider()
			debug.capsule(
				collider.point_a, collider.point_b, collider.radius, Color(0.35, 0.75, 1.0, 0.6)
			)
	if not show_chains:
		return
	for group: String in chain_groups:
		var color: Color = GROUP_COLORS[group]
		for modifier: JiggleChainModifier3D in chain_groups[group]:
			# 꺼진 모디파이어의 reconstructed 는 지난 프레임 것이라 그리지 않는다.
			if modifier.active:
				debug.polyline(modifier.reconstructed, color)


func chain_count() -> int:
	return rig.chain_modifiers.size()


func set_simulating(value: bool) -> void:
	rig.set_simulating(value)


func set_group_active(group: String, value: bool) -> void:
	if group == "breast":
		for modifier: JiggleBoneModifier3D in rig.bone_modifiers:
			modifier.active = value
	else:
		for modifier: JiggleChainModifier3D in chain_groups.get(group, []):
			modifier.active = value
	if not value:
		# 꺼진 모디파이어는 마지막 포즈를 남긴다. rest 로 돌리고 산 것만 다시 흔들게 한다.
		var skeleton := Rig4Scene.find_skeleton(rig)
		if skeleton != null:
			skeleton.reset_bone_poses()
		rig.reset_simulation()


## 씬의 충돌체를 사슬이 무시하게 한다. "치마가 다리를 뚫는" 비교용.
func set_collision(value: bool) -> void:
	for modifier in rig.chain_modifiers:
		modifier.collision_enabled = value


## 그 그룹이 실제로 쓰는 JiggleChainSettings. 슬라이더가 여기 값을 고치면
## changed 신호를 타고 그룹 전체 가닥에 즉시 반영된다 — 리소스로 묶는 이유 그 자체.
func group_settings(group: String) -> JiggleChainSettings:
	for modifier: JiggleChainModifier3D in chain_groups.get(group, []):
		if modifier.settings != null:
			return modifier.settings
	return null


func _group_modifiers() -> void:
	chain_groups = {"hair": [], "dress": [], "ribbon": []}
	for modifier in rig.chain_modifiers:
		var group := _group_of(modifier.name)
		if not group.is_empty():
			chain_groups[group].append(modifier)


func _group_of(node_name: String) -> String:
	if node_name.begins_with("Jiggle_Hair"):
		return "hair"
	if node_name.begins_with("Jiggle_Dress"):
		return "dress"
	if node_name.begins_with("Jiggle_Front_Ribbon") or node_name.begins_with("Jiggle_Back_Ribbon"):
		return "ribbon"
	return ""


## .tres 설정 리소스를 이 씬 인스턴스 전용 복제본으로 바꾼다.
##
## 슬라이더가 리소스 값을 직접 고치는데, 리소스는 로더가 캐시하므로 안 바꿔 두면
## 챕터를 나갔다 와도 고친 값이 그대로 남는다(챕터 A의 슬라이더가 챕터 B를 바꾸는
## resource_local_to_scene 함정과 같은 이야기다). 같은 원본을 쓰던 가닥들은
## 복제 후에도 같은 복제본을 공유한다 — "리소스 하나로 그룹을 묶는" 구조는 유지된다.
func _localize_settings() -> void:
	var duplicates: Dictionary[JiggleChainSettings, JiggleChainSettings] = {}
	for modifier in rig.chain_modifiers:
		var original := modifier.settings
		if original == null:
			continue
		if not duplicates.has(original):
			duplicates[original] = original.duplicate(true)
		modifier.settings = duplicates[original]
