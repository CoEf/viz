// 이식본: effects/fireball/materials/fireball_impact_trail.gdshader
// 원본과의 차이: debug_mode 추가.
shader_type spatial;
render_mode particle_trails, cull_disabled;

// --- 시각화용 ---
uniform int debug_mode = 0; // 1=sin×sin 봉우리 원값

varying vec4 custom;

void vertex() {
	custom = INSTANCE_CUSTOM;
}

void fragment() {
	float edge = sin(UV.x * PI) * sin(UV.y * PI);
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * 1.6 * COLOR.a;
	ALPHA = step(0.2, edge) * (1.0 - UV.y) * COLOR.a;

	if (debug_mode == 1) {
		ALBEDO = vec3(edge);
		EMISSION = vec3(edge);
		ALPHA = 1.0;
	}
}
