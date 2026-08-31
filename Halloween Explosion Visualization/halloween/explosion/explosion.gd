extends Node3D
## 이식본: effects/halloween_explosion/explosion/explosion.gd
## 원본과의 차이: autoplay export 추가 — 챕터가 타임라인을 수동 스크럽하거나
## 노드 하나만 따로 보여줄 수 있게 자동 재생·자멸을 끌 수 있다. true면 원본 동작.
## (원본의 미사용 @onready 셋 — big_amber/small_amber/amber_smoke — 은 그대로 두었다.)

@export var autoplay := true

@onready var animation_player = %AnimationPlayer
@onready var big_amber = %BigAmber
@onready var small_amber = %SmallAmber
@onready var amber_smoke = %AmberSmoke

func _ready():
	if not autoplay:
		return
	animation_player.play("default")
	animation_player.connect("animation_finished",
	func(_anim_name):
		queue_free()
		)
