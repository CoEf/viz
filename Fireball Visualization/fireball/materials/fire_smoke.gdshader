// 이식본: fireball.tscn / fireball_impact.tscn 안의 인라인 연기 셰이더 (코드 동일).
// 원본은 씬 내장 Shader 리소스 — 여기서는 파일로 빼서 두 씬이 공유한다.
shader_type spatial;
render_mode unshaded, ambient_light_disabled;

uniform sampler2D voronoi_sampler : filter_linear_mipmap, repeat_enable;

varying float id;
varying vec4 custom;

void vertex() {
	mat4 mat_world = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]) ,normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	mat_world = mat_world * mat4(vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);

	id = float(INSTANCE_ID);
	custom = INSTANCE_CUSTOM;
}

void fragment() {
	float voronoi = texture(voronoi_sampler, UV * 0.3 + id * 0.1 + custom.b).x;
	float dist = distance(UV, vec2(0.5));
	float dist_mask = smoothstep(0.45, 0.0, dist);
	float mask = max(0.0, dist_mask - voronoi);
	ALBEDO = COLOR.rgb;
	ALPHA = custom.y * mask * COLOR.a;
}
