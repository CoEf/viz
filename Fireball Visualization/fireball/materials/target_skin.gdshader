// 이식본: assets/dummy/dummy.gdshader 의 캡슐용 축약판.
// 원본은 albedo/roughness/normal 텍스처를 쓰는 리그 모델용 — 텍스처를 단색
// uniform으로 바꾼 것 외에 피격 발광(mix + emission_blend) 로직은 동일하다.
shader_type spatial;
render_mode cull_back;

uniform vec3 albedo_color : source_color = vec3(0.55, 0.55, 0.58);
uniform vec3 emission_color : source_color = vec3(1.0, 0.45, 0.1);
uniform float emission_strength = 1.0;
uniform float emission_blend : hint_range(0.0, 1.0, 0.1) = 0.0;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void fragment() {
	ALBEDO = mix(albedo_color, emission_color, emission_blend);
	EMISSION = mix(vec3(0.0), emission_color * emission_strength, emission_blend)
			+ albedo_color * step(0.6, fresnel(1.0, NORMAL, VIEW)) * 0.3;
	ROUGHNESS = 0.8;
}
