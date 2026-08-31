class_name ShakeCamera
extends Camera3D
## 이식본: turner/camera.gd 의 셰이크 부분. 원본은 진폭·지속 커브를 리소스로
## 받지만, 여기서는 같은 모양의 감쇠 커브를 코드에서 만든다. 핵심 로직
## (h_offset/v_offset 트윈, i%2 부호 반전, 커브 샘플)은 원본 그대로.

var shake_amount : Curve
var shake_duration : Curve


func _ready() -> void:
	shake_amount = Curve.new()
	shake_amount.add_point(Vector2(0.0, 1.0))
	shake_amount.add_point(Vector2(1.0, 0.1))
	shake_duration = Curve.new()
	shake_duration.add_point(Vector2(0.0, 0.4))
	shake_duration.add_point(Vector2(1.0, 1.0))


func shake():
	shake_value("h_offset", randi_range(4, 6))
	shake_value("v_offset", randi_range(4, 6))


func shake_value(property_name : String, shake_count : int, vector : float = 1.0):
	var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	for i in shake_count:
		var progress : float = i / float(shake_count - 1)
		var inv = i % 2
		var v = vector if bool(inv) else -vector
		t.tween_property(self, property_name,
			v * shake_amount.sample(progress),
			shake_duration.sample(progress) * 0.2)
	# 이식본 추가: 흔들림이 끝나면 오프셋을 0으로 되돌린다.
	t.tween_property(self, property_name, 0.0, 0.1)
