// 이식본: effects/fireball/materials/fireball_core.gdshader
// 원본과의 차이: rim_threshold(원본 상수 0.4)와 debug_mode 추가.
shader_type spatial;

uniform vec3 albedo : source_color;
uniform vec3 emission : source_color;

// --- 시각화용 ---
uniform float rim_threshold = 0.4; // 원본: step(0.4, f)
uniform int debug_mode = 0;        // 1=프레넬 원값 2=step 마스크

#include "res://shared/shaders/fresnel.gdshaderinc"

void fragment() {
	float f = fresnel(1.0, NORMAL, VIEW);
	float light_mask = step(rim_threshold, f);
	ALBEDO = mix(albedo, emission, light_mask);
	EMISSION = ALBEDO * 2.0 * f;

	if (debug_mode == 1) {
		ALBEDO = vec3(0.0);
		EMISSION = vec3(f);
	} else if (debug_mode == 2) {
		ALBEDO = vec3(0.0);
		EMISSION = vec3(light_mask);
	}
}
