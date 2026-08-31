extends Node3D
## 이식본: effects/fireball/fireball_impact/fireball_impact.gd
## 원본과의 차이: autoplay export 추가 — 임팩트 챕터가 타임라인을 수동으로
## 스크럽할 수 있게 자동 재생·자멸을 끌 수 있다. true면 원본과 동일.

@export var autoplay := true

@onready var animation_player = %AnimationPlayer
@onready var flash = %Flash

func _ready():
	if not autoplay:
		return
	flash.scale = Vector3.ONE * randfn(1.0, 0.1)
	animation_player.play("default")
	var queue_timer = get_tree().create_timer(4.0)
	queue_timer.connect("timeout", queue_free)
