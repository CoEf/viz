// 이식본: explosion.tscn 안의 인라인 섬광 셰이더 (Y축 고정 빌보드).
// 원본과의 차이: 인라인 → 파일로 추출, debug_mode 추가. 기본값이 곧 원본 동작.
shader_type spatial;

uniform vec3 base_color : source_color;
uniform sampler2D flash_sampler : filter_linear_mipmap, repeat_disable;

uniform float alpha = 1.0;
uniform float intensity = 1.0;
uniform float progress : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float offset = 0.0;

// --- 시각화용 ---
uniform int debug_mode = 0; // 1=아틀라스 .r(무늬 위상) 2=.g(형태 마스크)

void vertex() {
	// NOTE: Shader automatically converted from Godot Engine 4.1.1.stable's StandardMaterial3D.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 flash_data = texture(flash_sampler, UV).rg;
	float inv_progress = 1.0 - progress;
	float dist = (sin(flash_data.r * progress * 10.0 + offset) + 1.0) * 0.5;
	ALPHA *= smoothstep(max(0.0, inv_progress - 0.1), min(1.0, inv_progress + 0.1), dist * flash_data.g) * alpha;
	ALBEDO = base_color;
	EMISSION = base_color * intensity;

	if (debug_mode == 1) {
		ALBEDO = vec3(flash_data.r);
		EMISSION = vec3(flash_data.r);
		ALPHA = 1.0;
	} else if (debug_mode == 2) {
		ALBEDO = vec3(flash_data.g);
		EMISSION = vec3(flash_data.g);
		ALPHA = 1.0;
	}
}
