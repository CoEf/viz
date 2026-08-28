shader_type spatial;

// Snow accumulation for arbitrary props: blends snow onto upward-facing
// surfaces. Driven by the project-wide `snow_amount` global so every
// material in the scene reacts to the same slider.
// 학습용 디버그 유니폼: 챕터 3이 중간 계산 단계를 색으로 보여줄 때 쓴다.

global uniform float snow_amount;
global uniform float sparkle_strength;
global uniform float sparkle_density;

uniform vec3 base_color : source_color = vec3(0.4, 0.3, 0.2);
uniform float base_roughness : hint_range(0.0, 1.0) = 0.85;
uniform vec3 snow_color : source_color = vec3(0.93, 0.95, 0.99);
uniform float snow_roughness : hint_range(0.0, 1.0) = 0.55;
uniform float edge_noise_scale = 2.5;

// 0 = 최종, 1 = 위를 보는 정도(normal.y), 2 = 노이즈, 3 = 눈 마스크
uniform int debug_mode : hint_range(0, 3) = 0;

varying vec3 world_pos;
varying vec3 world_normal;
varying float snow_mask;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 443.8975);
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}

vec3 hash33(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yzx + 19.19);
	return fract((p.xxy + p.yzz) * p.zyx);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	float up = world_normal.y;
	float noise = value_noise(world_pos.xz * edge_noise_scale)
			+ value_noise(world_pos.xz * edge_noise_scale * 3.7) * 0.5;
	// snow_amount 0 keeps every face bare, 1 covers anything remotely upward.
	float threshold = mix(1.3, 0.1, snow_amount);
	snow_mask = smoothstep(threshold, threshold + 0.3, up + (noise - 0.75) * 0.3);
	ALBEDO = mix(base_color, snow_color, snow_mask);
	ROUGHNESS = mix(base_roughness, snow_roughness, snow_mask);
	// Fresh snow softens the underlying shape.
	vec3 up_view = normalize(mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0));
	NORMAL = normalize(mix(NORMAL, up_view, snow_mask * 0.45));

	if (debug_mode == 1) {
		ALBEDO = vec3(0.0);
		EMISSION = mix(vec3(0.08, 0.12, 0.4), vec3(1.0), clamp(up, 0.0, 1.0));
	} else if (debug_mode == 2) {
		ALBEDO = vec3(0.0);
		EMISSION = vec3(noise / 1.5);
	} else if (debug_mode == 3) {
		ALBEDO = vec3(0.0);
		EMISSION = vec3(snow_mask);
	}
}

void light() {
	DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI;
	if (snow_mask > 0.01 && debug_mode == 0) {
		// View-dependent glint: each world-space cell gets a random micro-facet
		// normal; cells flash as the half vector sweeps past them, and the HDR
		// output (> 1.0) lets the environment glow bloom them into stars.
		vec3 cell = hash33(floor(world_pos * sparkle_density));
		vec3 rand_dir = normalize(mat3(VIEW_MATRIX) * normalize(cell * 2.0 - 1.0));
		vec3 glint_normal = normalize(mix(NORMAL, rand_dir, 0.65));
		vec3 half_vec = normalize(VIEW + LIGHT);
		float glint = smoothstep(0.982, 1.0, clamp(dot(glint_normal, half_vec), 0.0, 1.0));
		float gate = step(0.5, cell.x);
		SPECULAR_LIGHT += glint * gate * snow_mask * sparkle_strength * 4.0 * ATTENUATION * LIGHT_COLOR;
	}
}
