class_name GrassField
extends Node3D
## 해부 대상 씬. 원본 갤러리의 핵심 규칙을 그대로 지킨다:
## [b]조명·지면·노출·산포 시드가 전부 공유된다.[/b] 두 패치 사이에 보이는 차이는
## 전부 셰이더 차이다.
##
## 챕터는 show_patches()로 "이번에 비교할 셰이더"만 고르면 된다. 배치·이름표·
## 밀어내는 공 연결은 여기서 처리한다.

const SPACING := 15.0

## 원본은 이 함정을 피하려고 잎 마스크의 밉맵을 끄고 배포한다. 그래서 함정을
## 재현하려면 밉맵을 켠 사본이 따로 있어야 한다 — 임포트 설정이라 런타임에
## 못 바꾼다.
const MIP_VARIANTS: Array[String] = [
	"res://assets/mipmapped/blade_detail_0_mip.png",
	"res://assets/mipmapped/blade_detail_1_mip.png",
	"res://assets/mipmapped/blade_detail_2_mip.png",
	"res://assets/mipmapped/blade_detail_3_mip.png",
]
const FLAT_VARIANTS: Array[String] = [
	"res://assets/generated/blade_detail_0.png",
	"res://assets/generated/blade_detail_1.png",
	"res://assets/generated/blade_detail_2.png",
	"res://assets/generated/blade_detail_3.png",
]
const MIP_FOLIAGE := "res://assets/mipmapped/blade_mask_1_mip.png"
const FLAT_FOLIAGE := "res://assets/generated/blade_mask_1.png"
const NAMEPLATE_HEIGHT := 4.2

var _entries: Array = []
var _demos: Array[Node3D] = []
var _shown: PackedInt32Array = PackedInt32Array()

@onready var camera_rig: OrbitCamera = $CameraRig
@onready var walker: Walker = $Walker
@onready var plots: Node3D = $Plots
@onready var sun: DirectionalLight3D = $Sun
@onready var world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	_entries = ShaderCatalog.ENTRIES


func _process(_delta: float) -> void:
	# 밀어내는 공의 위치를 각 패치에 흘려보낸다. 셰이더마다 받는 방식이 다르지만
	# (uniform / instance uniform / 아예 안 받음) 그 분기는 GrassPlot이 안다.
	for demo: Node3D in _demos:
		for node: Node in demo.find_children("*", "Node3D", true, false):
			if node.has_method("set_player_position"):
				node.call("set_player_position", walker.global_position)


## 비교할 셰이더 번호(1~10)를 골라 나란히 놓는다. 순서가 곧 왼쪽→오른쪽 배치.
func show_patches(numbers: Array) -> void:
	if _shown == PackedInt32Array(numbers):
		return
	_shown = PackedInt32Array(numbers)
	for demo: Node3D in _demos:
		demo.queue_free()
	_demos.clear()
	for i in numbers.size():
		var entry: Dictionary = _entry(numbers[i])
		var packed: PackedScene = load(entry["scene"])
		var demo := packed.instantiate() as Node3D
		demo.position = _origin(i, numbers.size())
		plots.add_child(demo)
		_demos.append(demo)
		_add_nameplate(demo, entry)
	walker.move_home(_origin(0, numbers.size()))


## 그 셰이더의 대표 옵션을 켜고 끈다(원본 갤러리의 V 키). 이게 가장 빠른
## 비교 수단이다 — 그 셰이더가 사주는 게 뭔지는 꺼보면 안다.
func set_toggle(number: int, on: bool) -> void:
	var entry: Dictionary = _entry(number)
	if not entry.has("toggle"):
		return
	var toggle: Dictionary = entry["toggle"]
	var material := load(entry["material"]) as ShaderMaterial
	if material == null:
		return
	var values: Array = toggle["values"]
	material.set_shader_parameter(toggle["uniform"], values[0] if on else values[1])


func toggle_label(number: int, on: bool) -> String:
	var entry: Dictionary = _entry(number)
	if not entry.has("toggle"):
		return ""
	var labels: Array = entry["toggle"]["labels"]
	return str(labels[0] if on else labels[1])


## 2번(variants 배열)과 7번(foliage_texture)의 잎 마스크를 밉맵 켠 사본으로
## 바꾼다. 챕터 4가 알파 시저 + 밉맵 함정을 실제로 재현할 때만 쓴다.
func set_mipmaps(on: bool) -> void:
	var paths: Array[String] = MIP_VARIANTS if on else FLAT_VARIANTS
	var variants: Array[Texture2D] = []
	for path in paths:
		variants.append(load(path) as Texture2D)
	var cartoon := load(_entry(2)["material"]) as ShaderMaterial
	if cartoon != null:
		cartoon.set_shader_parameter("variants", variants)
	var clipmap := load(_entry(7)["material"]) as ShaderMaterial
	if clipmap != null:
		clipmap.set_shader_parameter(
				"foliage_texture", load(MIP_FOLIAGE if on else FLAT_FOLIAGE))


func entry_of(number: int) -> Dictionary:
	return _entry(number)


## 공의 공전 중심과 반경. 여러 패치를 한 번에 훑게 하려면 반경을 키운다 —
## 패치마다 밀림 방식이 다른 걸 보려면 공이 세 패치를 다 지나야 한다.
func set_walker(center: Vector3, radius: float) -> void:
	walker.orbit_radius = radius
	walker.move_home(center)


func _entry(number: int) -> Dictionary:
	return _entries[number - 1] as Dictionary


## 넷까지는 한 줄이 제일 잘 읽힌다. 그 이상은 한 줄로 늘어놓으면 프레임을
## 벗어나므로 원본 갤러리처럼 2행 격자로 접는다.
func _origin(slot: int, total: int) -> Vector3:
	if total <= 4:
		return Vector3((float(slot) - float(total - 1) * 0.5) * SPACING, 0.0, 0.0)
	var columns: int = int(ceil(float(total) / 2.0))
	var column: int = slot % columns
	var row: int = slot / columns
	return Vector3(
			(float(column) - float(columns - 1) * 0.5) * SPACING,
			0.0,
			(float(row) - 0.5) * SPACING)


func _add_nameplate(demo: Node3D, entry: Dictionary) -> void:
	var label := Label3D.new()
	label.text = "%d. %s" % [entry["index"], entry["author"]]
	label.font_size = 96
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(0.94, 0.97, 1.0)
	label.outline_modulate = Color(0.05, 0.07, 0.09, 0.9)
	label.outline_size = 20
	label.position = Vector3(0.0, NAMEPLATE_HEIGHT, 0.0)
	demo.add_child(label)
