shader_type spatial;

uniform sampler2D albedo_texture : source_color;
uniform sampler2D normal_texture : hint_normal;
uniform vec3 fresnel_color : source_color;
// --- 시각화용 (이식본 추가) ---
uniform int debug_mode = 0; // 1=모델 공간 노먀 y 마스크
varying vec3 object_normal;

#include "res://shared/shaders/fresnel.gdshaderinc"

void vertex() {
	object_normal = NORMAL;
}

void fragment() {
	vec3 albedo = texture(albedo_texture, UV).rgb;
	ALBEDO = albedo;
	EMISSION = fresnel_color * step(0.5, fresnel(1.0, NORMAL, VIEW)) * 2.0 * clamp(object_normal.y, 0.0, 1.0);
	NORMAL_MAP = texture(normal_texture, UV).xyz;

	if (debug_mode == 1) {
		ALBEDO = vec3(0.0);
		EMISSION = mix(vec3(0.08, 0.15, 0.6), vec3(1.0, 0.5, 0.1),
				clamp(object_normal.y, 0.0, 1.0));
	}
}