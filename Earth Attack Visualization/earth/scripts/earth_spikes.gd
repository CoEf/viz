extends Node3D
## 이식본: effects/earth_attack/earth_spikes.gd
## 원본과의 차이: autoplay export 추가 — 랩 인스턴스가 자동 재생·자멸 없이
## 파티클·파라미터를 직접 조작할 수 있게 한다. true면 원본 동작.

@export var autoplay := true

@export var zone_length : float = 10.0
@onready var rocks_particles = %RocksParticles
@onready var small_rocks = %SmallRocks
@onready var dust_particles = %DustParticles
@onready var hit_zone = %HitZone
@onready var hit_zone_collision = %HitZoneCollision

func _ready():
	if not autoplay:
		return
	var half_length = zone_length / 2.0
	hit_zone.position.x = -half_length
	var t = create_tween()
	t.tween_property(hit_zone, "position:x", half_length, 2.0)
	t.tween_callback(hit_zone_collision.set_deferred.bind("disabled", true))
	
	rocks_particles.emitting = true
	dust_particles.emitting = true
	await get_tree().create_timer(10.0).timeout
	queue_free()
