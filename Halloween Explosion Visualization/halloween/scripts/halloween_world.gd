class_name HalloweenWorld
extends Node3D
## Halloween 폭발 이식본의 얇은 API 계층. 완성 폭발은 원본 흐름 그대로
## 낳고-잊고(play_explosion), 해부는 autoplay를 끈 랩 인스턴스(make_lab)에서
## 노드를 솔로로 켜고 uniform을 직접 만진다. 랩 씬의 머티리얼은 전부
## resource_local_to_scene이라 완성 폭발과 랩이 서로 안 샌다.

const EXPLOSION_SCENE := preload("res://halloween/explosion/explosion.tscn")

## 폭발 씬의 시각 노드 전부 — lab_solo가 이 목록을 기준으로 켜고 끈다.
const VISUAL_NODES: Array[String] = [
	"MushroomCloud", "Flash", "ExplosionRing", "ExplosionRing2", "WindRing",
	"FireRing", "WindHalo", "GroundCracks", "SmallAmber", "BigAmber",
	"AmberSmoke", "SmokeParticles",
]

var camera_rig: OrbitCamera
var camera: ShakeCamera

var _lab: Node3D

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var explosion_anchor: Node3D = $ExplosionAnchor
@onready var lab_anchor: Node3D = $LabAnchor


static func reset_globals() -> void:
	pass # 이 프로젝트는 전역 셰이더 파라미터를 쓰지 않는다


func _ready() -> void:
	camera_rig = OrbitCamera.new()
	camera_rig.min_distance = 0.6
	camera = ShakeCamera.new()
	camera.name = "Camera3D"
	camera.current = true
	camera_rig.add_child(camera)
	add_child(camera_rig)
	camera_rig.position = Vector3(0.0, 2.0, 0.0)
	camera_rig.set_view(0.5, -0.25, 11.0)


func environment() -> Environment:
	return world_environment.environment


# --- 완성 폭발 (원본 흐름) ---------------------------------------------------

## 원본 preview의 explode()처럼 낳기만 한다 — 5초 뒤 스스로 사라진다.
func play_explosion() -> void:
	var explosion := EXPLOSION_SCENE.instantiate()
	explosion_anchor.add_child(explosion)


func clear_explosions() -> void:
	for child in explosion_anchor.get_children():
		child.queue_free()


func shake_camera() -> void:
	camera.shake()


# --- 랩 (autoplay를 끈 해부용 인스턴스) --------------------------------------

func make_lab() -> void:
	clear_lab()
	_lab = EXPLOSION_SCENE.instantiate()
	_lab.autoplay = false
	lab_anchor.add_child(_lab)


func clear_lab() -> void:
	if _lab != null and is_instance_valid(_lab):
		_lab.queue_free()
	_lab = null


func lab_node(node_name: String) -> Node3D:
	return _lab.get_node(node_name)


func lab_material(node_name: String) -> ShaderMaterial:
	return (lab_node(node_name) as GeometryInstance3D).material_override


func lab_set_param(node_name: String, param: String, value: Variant) -> void:
	lab_material(node_name).set_shader_parameter(param, value)


## names에 든 노드만 보이게 한다. 원본 씬에서 ExplosionRing 노드들은
## transparency=1.0(에디터 상태)로 저장돼 있어, 켤 때 0으로 되돌린다.
func lab_solo(names: Array) -> void:
	for node_name in VISUAL_NODES:
		var node := lab_node(node_name) as GeometryInstance3D
		var shown := names.has(node_name)
		node.visible = shown
		if shown:
			node.transparency = 0.0


## 전 노드를 원본 상태 그대로 보이게 한다 (transparency는 건드리지 않는다 —
## 완성 폭발과 동일한 화면을 스크럽하기 위한 모드).
func lab_show_all() -> void:
	for node_name in VISUAL_NODES:
		lab_node(node_name).visible = true


func lab_player() -> AnimationPlayer:
	return _lab.get_node("%AnimationPlayer")


## 랩에서 default 애니메이션을 재생한다 (autoplay가 꺼져 있어 스스로 안 사라진다).
func lab_play() -> void:
	lab_player().stop()
	lab_player().play("default")


func lab_stop() -> void:
	lab_player().stop()


## 수동 스크럽 준비 — 재생을 멈춘 채 0초에 세워 둔다.
func lab_scrub_start() -> void:
	var player := lab_player()
	player.play("default")
	player.pause()
	player.seek(0.0, true)


func lab_seek(time: float) -> void:
	lab_player().seek(time, true)


func lab_restart_particles(names: Array) -> void:
	for node_name in names:
		var particles := lab_node(node_name) as GPUParticles3D
		particles.restart()
		particles.emitting = true
