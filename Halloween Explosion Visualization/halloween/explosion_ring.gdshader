shader_type spatial;
render_mode cull_disabled;

uniform sampler2D noise_sampler : filter_linear_mipmap, repeat_enable;
uniform float alpha : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform sampler2D gradient_sampler : source_color;
uniform float intensity = 1.0;
uniform float offset = 0.0;
uniform float dissolve : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float dissolve_smoothness = 0.0;

// --- 시각화용 (이식본 추가) ---
uniform int debug_mode = 0; // 1=노이즈 2=형태 마스크 3=알파 마스크

// https://gist.github.com/companje/29408948f1e8be54dd5733a74ca49bb9
float map(float value, float min1, float max1, float min2, float max2) {
	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void vertex() {
	VERTEX.y += sin(UV.x * PI * 4.0 + NODE_POSITION_WORLD.y + TIME) * 0.1;
}

void fragment() {
	float noise = texture(noise_sampler, UV * vec2(2.0, 0.6) + vec2(0.0, offset)).x;
	float map_dissolve_progress = map(dissolve, 0.0, 1.0, - dissolve_smoothness, 1.0 + dissolve_smoothness);
	vec3 gradient = texture(gradient_sampler, vec2(noise * (1.0 - dissolve), 0.0)).rgb;
	ALBEDO = gradient;
	EMISSION = gradient * intensity;
	float alpha_mask = clamp(smoothstep(map_dissolve_progress - dissolve_smoothness, map_dissolve_progress + dissolve_smoothness, (noise) - (1.0 - sin(UV.y * PI))), 0.0, 1.0);
	
	ALPHA = alpha * COLOR.a * alpha_mask;

	float shape_mask = 1.0 - sin(UV.y * PI);
	if (debug_mode == 1) {
		ALBEDO = vec3(noise);
		EMISSION = vec3(noise) * 0.7;
		ALPHA = 1.0;
	} else if (debug_mode == 2) {
		ALBEDO = vec3(shape_mask);
		EMISSION = vec3(shape_mask) * 0.7;
		ALPHA = 1.0;
	} else if (debug_mode == 3) {
		ALBEDO = vec3(alpha_mask);
		EMISSION = vec3(alpha_mask) * 0.7;
		ALPHA = 1.0;
	}
}
