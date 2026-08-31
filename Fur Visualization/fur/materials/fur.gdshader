shader_type spatial;
render_mode cull_back, depth_draw_always;
uniform sampler2D noise_deformation_sampler : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D noise_sampler : filter_linear_mipmap, repeat_enable;
uniform sampler2D curve : repeat_disable;

uniform float _glossiness = 0.5;
uniform float _fur_length = 0.15;
uniform float _fur_deformation = 0.0;
uniform float _fur_gravity = 0.0;

// --- 시각화용 (이식본 추가 — 기본값이 원본 상수) ---
uniform float taper = 1.0;             // 0 = 층별 문턱 동일(양파)
uniform float flow_strength = 0.2;     // 원본: flow_map * 0.2
uniform float terminator_boost = 4.0;  // 원본: NdotL * 4.0
uniform float rim_gated = 1.0;         // 0 = 그림자 쪽 실루엣도 빛남
uniform int debug_mode = 0;            // 1=셸 깊이 2=G 마스크 3=strand

uniform sampler2D albedo_sampler : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D fur_flow_map : filter_linear_mipmap, repeat_disable;

varying float object_y;

#include "res://shared/shaders/fresnel.gdshaderinc"

void vertex() {
	object_y = NORMAL.y;
	float noise = 0.5 - texture(noise_deformation_sampler, UV + COLOR.r * 0.15).x;
	VERTEX += NORMAL * texture(curve, vec2(COLOR.r * COLOR.g, 0.0)).z * _fur_length ;
	VERTEX -= noise * COLOR.r * _fur_deformation;
	VERTEX.y -=  COLOR.r * _fur_gravity;
}

void fragment() {
	vec2 flow_map = texture(fur_flow_map, UV).xy * COLOR.r;
	float strand =  texture(noise_sampler, UV * 10.0 - flow_map * flow_strength).x;
	ALBEDO = texture(albedo_sampler, UV).rgb;
	ALBEDO *= strand * 0.6 + 0.4;
	ALPHA = texture(curve, vec2(strand * (1.0 - COLOR.r * taper), 0.0)).y;
	ALPHA_SCISSOR_THRESHOLD = 0.5;

	// 디버그는 마지막에 덮어쓴다 (알파 컷은 유지 — 털 가닥이 보이도록)
	if (debug_mode == 1) {
		ALBEDO = mix(vec3(0.1, 0.25, 0.9), vec3(1.0, 0.45, 0.1), COLOR.r * 2.0);
	} else if (debug_mode == 2) {
		ALBEDO = vec3(COLOR.g);
	} else if (debug_mode == 3) {
		ALBEDO = vec3(strand);
	}
}

void light() {
	float NdotL = clamp(dot(NORMAL, LIGHT) * ATTENUATION * terminator_boost, 0.0, 1.0);
	
	// specular
	vec3 H = normalize(VIEW + LIGHT);
	float NdotH = max(0, dot(NORMAL, H));
	float specular = clamp(pow(NdotH, 1.0 / _glossiness), 0.0, 1.0);
	// rim
	float rimDot = 1.0 - dot(VIEW, NORMAL);
	float rim = clamp(rimDot * mix(1.0, NdotL, rim_gated), 0.0, 1.0);
	
	DIFFUSE_LIGHT += NdotL * (rim + specular);
	
	DIFFUSE_LIGHT += clamp(vec3(1.0) * step(0.5, fresnel(1.5, NORMAL, VIEW)) * object_y, 0.0, 1.0);
}