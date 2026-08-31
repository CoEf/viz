// 이식본: effects/fireball/materials/fireball_shell.gdshader
// 원본과의 차이: 시각화용 uniform 추가(원본은 상수). 기본값이 곧 원본 동작이다.
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D voronoi_sampler : filter_linear_mipmap, repeat_enable;
uniform sampler2D gradient_sampler : filter_linear, source_color;

uniform float def_x = 0.0;
uniform float def_z = 0.0;

// --- 시각화용 (원본 상수) ---
uniform float wave_amplitude = 0.1; // 원본: 0.1
uniform float cut_offset = -0.15;   // 원본: -0.15
uniform float cut_enabled = 1.0;    // 1 = 원본 동작
uniform float use_gradient = 1.0;   // 0 = 단색 민낯
uniform float rim_enabled = 1.0;    // 프레넬 림 항 on/off
uniform int debug_mode = 0;         // 1=보로노이 2=UV.y 축

#include "res://shared/shaders/fresnel.gdshaderinc"
#include "res://shared/shaders/rotate_x.gdshaderinc"
#include "res://shared/shaders/rotate_z.gdshaderinc"

void vertex() {
	VERTEX += sin((UV.y - TIME * 4.0) * PI * 3.0) * NORMAL * (1.0 - UV.y) * wave_amplitude;
	float r_x = def_x * UV.y;
	float r_z = def_z * UV.y;
	VERTEX *= rotateX(r_x) * rotateZ(r_z);
}

void fragment() {
	float voronoi = texture(voronoi_sampler, (UV - vec2(0.0, TIME * 3.0)) * vec2(1.0, 0.8) * 0.6).x;
	vec3 gradient = texture(gradient_sampler, vec2(UV.y, 0.0) * (voronoi * 0.4 + 0.6)).rgb;
	gradient = mix(vec3(0.55, 0.24, 0.1), gradient, use_gradient);
	ALBEDO = gradient;
	EMISSION = gradient * 1.45 * use_gradient
			+ step(0.25, fresnel(2.0, NORMAL, VIEW)) * gradient * 2.0 * rim_enabled;
	ALPHA *= mix(1.0, step(cut_offset, voronoi - UV.y), cut_enabled);
	ALPHA_SCISSOR_THRESHOLD = 0.5;

	// 디버그는 마지막에 덮어쓴다 (fragment 안 return 금지)
	if (debug_mode == 1) {
		ALBEDO = vec3(voronoi);
		EMISSION = vec3(voronoi) * 0.6;
	} else if (debug_mode == 2) {
		ALBEDO = vec3(0.0);
		EMISSION = mix(vec3(0.15, 0.5, 1.0), vec3(1.0, 0.32, 0.1), UV.y);
	}
}
