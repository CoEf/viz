shader_type spatial;
render_mode cull_front;

uniform sampler2D splash_mask : filter_linear_mipmap, repeat_enable;
uniform vec3 base_color : source_color;

uniform float progress : hint_range(0.1, 1.0, 0.01) = 0.5;

// --- 시각화용 (이식본 추가 — 원본은 상수 0.3) ---
uniform float uv_bend = 0.3;
uniform float foam_enabled = 1.0;
uniform int debug_mode = 0; // 1=마스크 값

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}


void fragment() {
	vec2 def_uv = vec2(UV.x, clamp(UV.y - abs(sin(UV.x * PI * 1.0)) * uv_bend, 0.05, 1.0) );
	float mask_value = texture(splash_mask, def_uv * vec2(3.0, 1.0)).x;
	ALPHA = smoothstep(progress, progress + 0.02, mask_value) * clamp((1.0 - UV.y) * 1.25, 0.0, 1.0) * (1.0 - fresnel(2.0, NORMAL, VIEW));
	float foam_mask = step(UV.y * mask_value, 0.2) * foam_enabled;
	ALBEDO = base_color + foam_mask;
	EMISSION = base_color * 1.25;

	if (debug_mode == 1) {
		ALBEDO = vec3(mask_value);
		EMISSION = vec3(mask_value) * 0.6;
		ALPHA = 1.0;
	}
}
