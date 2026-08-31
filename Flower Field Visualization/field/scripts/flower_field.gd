@tool
extends Node3D
## 이식본: effects/flower_field/flower_field.gd
## 원본과의 차이: 배치 상수들(지터 0.5, 컷 0.5, 분류 0.96)을 export로 뽑아
## 슬라이더가 재생성하며 비교할 수 있게 했다. 기본값이 원본 동작.

@export var jitter := 0.5
@export var cut_radius := 0.5
@export var flower_ratio := 0.96
@export var use_noise_scale := true

@export var noise : Noise

var multi_meshs : Array[MultiMeshInstance3D]
var transforms : Array
var base_scales : Array[float] = []

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_accept"):
		generate()

func _ready():
	generate()

func generate():
	multi_meshs.assign(find_children("", "MultiMeshInstance3D"))
	transforms.resize(multi_meshs.size())
	base_scales.resize(multi_meshs.size())
	
	for i in multi_meshs.size():
		var multimesh = multi_meshs[i]
		transforms[i] = []
		base_scales[i] = multimesh.get_meta("base_scale", 1.0)
	
	var size = 10.0
	var res = int(size * 3.0)
	var total = res * res
	
	for i in total:
		var v = Vector2.from_angle(randf() * TAU) / float(res) * randf() * jitter
		v.x += (i % res) / float(res)
		v.y += floor(i / float(res)) / float(res)
		v.x -= 0.5
		v.y -= 0.5
		var dist = 1.0 - v.length()
		if dist < cut_radius: continue
		v *= size
		var n = get_noise_value(v.x * 40.0, v.y * 40.0) if use_noise_scale else randf() * 2.0 - 1.0
		var scale_factor = remap(n, -1.0, 1.0, 0.5, 1.5) * 0.5
		
		var idx : int = int(randf() < flower_ratio)
		
		var t : Transform3D = Transform3D.IDENTITY
		t = t.translated(Vector3(v.x, 0.0, v.y))
		# t = t.rotated_local(Vector3.UP, randf() * TAU)
		t = t.scaled_local(Vector3.ONE * base_scales[idx] * scale_factor * dist * 2.0)
		
		transforms[idx].append(t)
	
	
	for idx in multi_meshs.size():
		var t = transforms[idx]
		var multimesh = multi_meshs[idx].multimesh
		multimesh.instance_count = t.size()

		for t_idx in t.size():
			multimesh.set_instance_transform(t_idx, t[t_idx])
			multimesh.set_instance_color(t_idx, Color(randf(), 0.0, 0.0))

func get_noise_value(x = 0.0, y = 0.0):
	return noise.get_noise_2d(x, y)
