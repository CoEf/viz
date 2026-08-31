extends Node3D
## 이식본: effects/fireball/fireball_spawn/fireball_spawn.gd (무수정)

@onready var fire_amber = %FireAmber

func _ready():
	fire_amber.emitting = true
	var queue_timer = get_tree().create_timer(1.0)
	queue_timer.connect("timeout", queue_free)
