shader_type spatial;

uniform sampler2D voronoi_sampler : filter_linear_mipmap, repeat_enable;
uniform sampler2D caustic_sampler : filter_linear_mipmap_anisotropic, repeat_enable;

uniform vec3 base_color : source_color;
uniform vec3 dark_color : source_color;

uniform float opening : hint_range(0.0, 1.0, 0.1) = 0.1;
uniform float offset = 0.0;

// --- 시각화용 (이식본 추가 — 원본은 상수 4.0 / 1) ---
uniform float swirl_size = 4.0;
uniform int swirl_arms = 1;
uniform int debug_mode = 0; // 1=나선값 2=노이즈

vec2 polar_coordinates(vec2 uv, vec2 center, float zoom, float repeat)
{
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x) * 1.0/(3.1416 * 2.0);
	return mod(vec2(radius * zoom, angle * repeat), 1.0);
}

float swirl(vec2 uv, float size, int arms)
{
	float angle = atan(-uv.y + 0.5, uv.x - 0.5) ;
	float len = length(uv - vec2(0.5, 0.5));
	
	return sin(len * size + angle * float(arms));
}


void fragment() {
	float dist = distance(UV, vec2(0.5)) * 2.0;
	float s = swirl(UV, swirl_size, swirl_arms);
	vec2 uv = polar_coordinates(UV, vec2(0.5), 1.0, 1.0);
	float big_noise = texture(caustic_sampler, vec2(uv.x + offset * 0.45, s) * 0.6).x;
	float small_noise = texture(caustic_sampler, vec2(uv.x + offset * 0.25, s) * 0.8).x;
	float voronoi = texture(voronoi_sampler, vec2(uv.x + offset * 0.45, s) * 0.4).x;
	float noise = mix(small_noise, big_noise, 0.85);
	float edge = smoothstep(opening - 0.25, opening, dist);
	float outter_edge = smoothstep(0.0, opening, dist);
	
	ALBEDO = mix(dark_color, base_color, max(0.0, noise));
	EMISSION = ALBEDO; 
	ALPHA = max(0.0, (1.0 - edge) - voronoi * outter_edge) * opening;

	if (debug_mode == 1) {
		ALBEDO = vec3(0.0);
		EMISSION = mix(vec3(0.06, 0.1, 0.35), vec3(0.4, 0.85, 1.0), s * 0.5 + 0.5);
		ALPHA = 1.0 - step(1.0, dist);
	} else if (debug_mode == 2) {
		ALBEDO = vec3(noise);
		EMISSION = vec3(noise) * 0.6;
		ALPHA = 1.0 - step(1.0, dist);
	}
}
