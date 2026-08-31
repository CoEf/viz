class_name SimpleProjectile
extends Node3D
## 이식본: effects/fireball/scripts/simple_projectile.gd
## 원본과의 차이: turn_rate(원본 상수 4.0)와 hard_kill(조립 챕터의 out() 비교용) export 추가.

@export var spawn_scene : PackedScene
@export var impact_scene : PackedScene

@export var turn_rate := 4.0    # 원본: speed * 4.0 * delta
@export var hard_kill := false  # true: out() 대신 통째로 숨김 — 꼬리 잘림 비교용

@onready var hit_zone_3d = %HitZone3D
@onready var fireball = %Fireball

var target_node : Node3D
var velocity : Vector3
var speed = 1.0

func launch(start_position : Vector3, start_velocity : Vector3, target : Node3D):
	global_position = start_position
	velocity = start_velocity
	target_node = target

	_look_at_velocity()

	var spawn = spawn_scene.instantiate()
	add_sibling(spawn)
	spawn.transform = transform

func _ready():
	hit_zone_3d.connect("hit", func(hit_pos, hit_normal):
		if hard_kill:
			fireball.hide()
			get_tree().create_timer(4.0).timeout.connect(queue_free)
		else:
			fireball.out()
		set_physics_process(false)
		var impact = impact_scene.instantiate()
		add_sibling(impact)
		impact.global_position = hit_pos
		impact.look_at(impact.transform.origin + hit_normal, Vector3.UP)
		)
	fireball.connect("is_out", queue_free)

func _physics_process(delta):
	if target_node == null: return
	var direction = (target_node.global_position - global_position).normalized()
	velocity = velocity.move_toward(direction * speed, speed * turn_rate * delta)
	position += velocity
	_look_at_velocity()

func _look_at_velocity():
	var look_at_target = transform.origin + velocity
	if transform.origin != look_at_target:
		look_at(look_at_target, Vector3.UP, true)
