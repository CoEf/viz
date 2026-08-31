shader_type spatial;
render_mode cull_disabled, shadows_disabled;
uniform sampler2D gradient_sampler : filter_linear, repeat_disable;
varying vec4 custom;

// --- 시각화용 (이식본 추가 — 원본은 상수 15.0) ---
uniform float flap_speed = 15.0;

void vertex() {
	custom = INSTANCE_CUSTOM;
	float t = TIME * flap_speed + custom.x;
	float x = UV.x - .5;
	float y_displacement = cos(abs(x) - t + 0.04) - cos(t);
	VERTEX.z += y_displacement * 0.5;
}

void fragment(){
	ALBEDO = texture(gradient_sampler, vec2(custom.z, 0.0)).rgb;
	EMISSION = ALBEDO * 1.25;
}