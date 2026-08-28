shader_type spatial;

// Snowfield ground with compression trails driven by a DrawableTexture2D
// heightmap (Godot 4.7): deform_map 1.0 = untouched snow, 0.0 = fully
// pressed. The map covers `region_size` metres centred on the world origin.
// 학습용 디버그 유니폼: 챕터들이 중간 계산값을 눈으로 볼 수 있게 한다.

global uniform float snow_amount;
global uniform float sparkle_strength;
global uniform float sparkle_density;

uniform sampler2D deform_map : hint_default_white, filter_linear, repeat_disable;
uniform vec2 region_size = vec2(40.0, 40.0);
uniform float trail_depth = 0.3;
uniform vec3 snow_color : source_color = vec3(0.93, 0.95, 0.99);
uniform vec3 dirt_color : source_color = vec3(0.32, 0.27, 0.21);
uniform float snow_roughness : hint_range(0.0, 1.0) = 0.5;

// 0 = 최종, 1 = 높이맵, 2 = 재계산한 법선, 3 = 반짝임 셀
uniform int debug_mode : hint_range(0, 3) = 0;
uniform float debug_displacement : hint_range(0.0, 1.0) = 1.0;
uniform float debug_press_shading : hint_range(0.0, 1.0) = 1.0;

varying vec3 world_pos;

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

vec2 deform_uv(vec3 pos) {
	return pos.xz / region_size + vec2(0.5);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float press = 1.0 - textureLod(deform_map, deform_uv(world_pos), 0.0).r;
	VERTEX.y -= press * trail_depth * debug_displacement;
}

void fragment() {
	vec2 uv = deform_uv(world_pos);
	// Rebuild the normal from the heightmap so trails catch light even
	// where the vertex grid is coarser than the map.
	vec2 texel = 1.0 / vec2(textureSize(deform_map, 0));
	float hl = texture(deform_map, uv - vec2(texel.x, 0.0)).r;
	float hr = texture(deform_map, uv + vec2(texel.x, 0.0)).r;
	float hd = texture(deform_map, uv - vec2(0.0, texel.y)).r;
	float hu = texture(deform_map, uv + vec2(0.0, texel.y)).r;
	vec2 world_texel = region_size * texel;
	float slope_depth = trail_depth * debug_displacement;
	vec3 n_world = normalize(vec3(
			(hl - hr) * slope_depth / (2.0 * world_texel.x),
			1.0,
			(hd - hu) * slope_depth / (2.0 * world_texel.y)));
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);

	float press = clamp(1.0 - texture(deform_map, uv).r, 0.0, 1.0) * debug_press_shading;
	float ground_snow = clamp(snow_amount * 3.0, 0.0, 1.0);
	float tone = 0.94 + 0.06 * value_noise(world_pos.xz * 0.6);
	vec3 albedo = mix(dirt_color, snow_color * tone, ground_snow);
	albedo *= mix(1.0, 0.8, press);
	ALBEDO = albedo;
	ROUGHNESS = mix(mix(0.9, snow_roughness, ground_snow), 0.32, press);

	if (debug_mode == 1) {
		ALBEDO = vec3(0.0);
		EMISSION = vec3(texture(deform_map, uv).r);
	} else if (debug_mode == 2) {
		ALBEDO = vec3(0.0);
		EMISSION = n_world * 0.5 + 0.5;
	} else if (debug_mode == 3) {
		ALBEDO = vec3(0.0);
		EMISSION = hash33(floor(world_pos * sparkle_density));
	}
}

void light() {
	DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI;
	float snow_vis = clamp(snow_amount * 3.0, 0.0, 1.0);
	if (snow_vis > 0.01 && debug_mode == 0) {
		vec3 cell = hash33(floor(world_pos * sparkle_density));
		vec3 rand_dir = normalize(mat3(VIEW_MATRIX) * normalize(cell * 2.0 - 1.0));
		vec3 glint_normal = normalize(mix(NORMAL, rand_dir, 0.65));
		vec3 half_vec = normalize(VIEW + LIGHT);
		float glint = smoothstep(0.982, 1.0, clamp(dot(glint_normal, half_vec), 0.0, 1.0));
		float gate = step(0.5, cell.x);
		SPECULAR_LIGHT += glint * gate * snow_vis * sparkle_strength * 4.0 * ATTENUATION * LIGHT_COLOR;
	}
}
