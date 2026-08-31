// 이식본: effects/fireball/materials/fireball_particles.gdshader
// 원본과의 차이: demo_age/demo_offset(해부용 쿼드가 INSTANCE_CUSTOM을 흉내내는 값)와
// debug_mode 추가. 기본값(-1, 0)이면 원본과 동일하게 동작한다.
shader_type spatial;
render_mode shadows_disabled;

uniform sampler2D voronoi_sampler : filter_linear_mipmap, repeat_enable;
uniform sampler2D gradient_sampler : filter_linear, source_color, repeat_disable;
uniform float uv_scale : hint_range(0.0, 1.0, 0.1) = 0.5;

// --- 시각화용 ---
uniform float demo_age = -1.0;    // >=0 이면 custom.y(수명 진행도) 대체
uniform float demo_offset = -1.0; // >=0 이면 custom.z(무늬 오프셋) 대체
uniform int debug_mode = 0;       // 1=원형 마스크 2=보로노이 3=최종 마스크

varying vec4 custom;

void vertex() {
	mat4 mat_world = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]) ,normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	mat_world = mat_world * mat4(vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	custom = INSTANCE_CUSTOM;
}

void fragment() {
	float age = demo_age >= 0.0 ? demo_age : custom.y;
	float offset = demo_offset >= 0.0 ? demo_offset : custom.z;
	float voronoi = texture(voronoi_sampler, UV * uv_scale + offset).x - 0.5 + age;
	float dist = distance(UV, vec2(0.5));
	float dist_mask = smoothstep(0.45, 0.2, dist);
	float mask = max(0.0, dist_mask - voronoi);
	vec3 gradient = texture(gradient_sampler, vec2(mask, 0.0)).rgb;

	ALBEDO = gradient;
	EMISSION = ALBEDO;
	ALPHA = round(mask);
	ALPHA_SCISSOR_THRESHOLD = 0.5;

	if (debug_mode == 1) {
		ALBEDO = vec3(dist_mask);
		EMISSION = vec3(dist_mask) * 0.7;
		ALPHA = 1.0;
	} else if (debug_mode == 2) {
		float v = clamp(voronoi, 0.0, 1.0);
		ALBEDO = vec3(v);
		EMISSION = vec3(v) * 0.7;
		ALPHA = 1.0;
	} else if (debug_mode == 3) {
		ALBEDO = vec3(mask);
		EMISSION = vec3(mask) * 0.7;
		ALPHA = 1.0;
	}
}
