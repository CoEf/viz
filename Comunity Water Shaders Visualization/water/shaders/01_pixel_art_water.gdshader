// =============================================================================
// 01 - Pixel Art Water   (Taillight Games, MIT)
// src : https://godotshaders.com/shader/pixel-art-water-shader/
// type: spatial (3D)   original target: Godot 4.x
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES
//   * "0.0f / 1.0f / 0.17f" float suffixes are NOT valid in Godot's shading
//     language -> the trailing f was stripped everywhere (light() block).
//   * int literals fed to float params (height_scale = 1, remap(0, .., 1, ..),
//     mod(x, 1)) -> promoted to float literals; 4.x has no implicit int->float.
//   * removed dead varyings (power_normal, object_normal, norm): they were
//     declared but never assigned, which 4.7 rejects.
//   * foam_mask_size had no default value (=> divide by zero). Defaulted to 64.
//   * fragment() referenced NODE_POSITION_WORLD, which is vertex-only in 4.x;
//     it now reads the npw varying that vertex() already fills.
//   * sync_time must be pushed from GDScript each frame (water_sync_time.gd).
// =============================================================================
shader_type spatial;
render_mode cull_disabled, world_vertex_coords, depth_draw_always, ambient_light_disabled, diffuse_burley;

// this must be set every frame in code for it to sync with the WaterManager
uniform float sync_time;

varying vec3 triplanar_pos;
varying vec3 world_normal;

uniform float wave_speed = 0.05;   // the speed of the vertex waves
uniform float caustic_speed = 0.01; // speed that the caustics noise texture is moved

uniform float edge_fade_power = 2.0; // contrast of the opacity fade near objects

uniform float transmittence = 0.04;      // how much light transmits through the water
uniform float h_dist_trans_weight = 3.0; // how much horizontal distance affects depth
uniform vec3 transmit_color : source_color = vec3(0.0, 0.05, 0.1);

uniform float depth_fade : hint_range(0.0, 0.5, 0.01) = 0.3;
uniform float depth_fade_distance : hint_range(0.0, 100.0, 0.1) = 5.0;

uniform vec3 surface_albedo : source_color = vec3(0.25, 0.6, 0.75);
uniform vec4 surface_bottom : source_color = vec4(0.05, 0.2, 0.35, 0.8);

uniform float opacity : hint_range(0.0, 5.0, 0.01) = 0.4;
uniform float opacity_floor = 0.1;
uniform float opacity_ceiling = 0.8;

uniform float roughness : hint_range(0.0, 1.0, 0.01) = 0.4;

uniform float height_scale = 1.0; // 4.7 fix: was `1`
uniform float amplitude1 = 2.0;   // 4.7 fix: was `2`
uniform float amplitude2 = 0.5;

uniform sampler2D vertex_noise_big : repeat_enable;
uniform sampler2D vertex_noise_big2 : repeat_enable;

uniform int v_noise_tile : hint_range(0, 300, 1) = 200;

uniform sampler2D normal_noise : hint_normal, filter_linear_mipmap;
uniform sampler2D normal_noise2 : hint_normal, filter_linear_mipmap;

uniform float normal_noise_size = 5.12;
uniform float normal_noise_speed = 0.05;
uniform float v_normal_scale = 1.0; // 4.7 fix: was `1`
uniform int normal_map_w = 256;

uniform float wobble_power = 0.01;
uniform sampler2D under_wobble_noise;

varying vec3 npw;

uniform vec3 sky_color : source_color = vec3(0.45, 0.65, 0.85);

varying vec4 v_color;

group_uniforms foam;

uniform vec3 foam_color : source_color = vec3(1.0);
uniform sampler2D foam : repeat_enable;
// for proper use, set this to a SubViewport that only draws the foam layer
uniform sampler2D foam_mask : filter_nearest_mipmap;
uniform float foam_mask_size = 64.0;              // 4.7 fix: was undefaulted
uniform vec2 foam_mask_offset = vec2(0.0, 0.0);
uniform float foam_wobble = 0.01;
uniform sampler2D foam_wobble_noise : filter_linear_mipmap;
uniform float foam_wobble_size = 10.0;
varying float foam_power;

group_uniforms v_color;

// to fake transmittence, waves get a different colour as they rise
uniform vec3 high_color : source_color = vec3(0.4, 0.8, 0.9);
uniform vec3 low_color : source_color = vec3(0.02, 0.15, 0.35);

varying vec3 wave_color;

uniform float wave_color_range = 2.0;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;

vec2 round_to_pixel(vec2 i, int width) {
	float denom = 1.0 / float(width);
	float _x = i.x + abs(mod(i.x, denom) - denom);
	float _y = i.y + abs(mod(i.y, denom) - denom);
	return vec2(_x, _y);
}

float remap(float in_low, float in_high, float out_low, float out_high, float value) {
	return out_low + (value - in_low) * (out_high - out_low) / (in_high - in_low);
}

// global uv
vec2 g_uv(vec2 uv, float speed, bool flipped) {
	vec2 _xy;
	_xy.x = uv.x;
	_xy.y = uv.y;
	float t_s = TIME * speed;
	if (!flipped) {
		_xy.x += t_s;
		_xy.y += t_s;
	} else {
		_xy.x -= t_s;
		_xy.y -= 0.0;
	}
	return _xy;
}

vec2 g_v(vec2 v, vec3 n, bool flipped) {
	float f_v_n_t = float(v_noise_tile);
	v.x = mod(v.x, f_v_n_t);
	v.y = mod(v.y, f_v_n_t);
	// 4.7 fix: int literals -> float literals
	vec2 _mapped = vec2(remap(0.0, f_v_n_t, 0.0, 1.0, v.x), remap(0.0, f_v_n_t, 0.0, 1.0, v.y));
	_mapped += n.xz;
	if (flipped) {
		_mapped.y -= (sync_time) * wave_speed;
	} else {
		_mapped.x += (sync_time) * wave_speed;
	}
	_mapped.x = mod(_mapped.x, 1.0); // 4.7 fix: was mod(_mapped.x, 1)
	return _mapped;
}

float wave(vec2 y, vec3 n) {
	vec2 _y1 = g_v(y, n, false);
	vec2 _y2 = g_v(y + vec2(0.3, 0.476), n, true);
	float s = 0.0;
	s += texture(vertex_noise_big, mod(_y1, float(v_noise_tile))).r * amplitude1;
	s += texture(vertex_noise_big2, mod(_y2, float(v_noise_tile))).r * amplitude2;
	s -= height_scale / 2.0;
	return s;
}

varying mat4 camera_mix;

void vertex() {
	npw = NODE_POSITION_WORLD;

	vec2 adj_v_pos = VERTEX.xz;

	float _height = wave(adj_v_pos, NODE_POSITION_WORLD) * height_scale;
	VERTEX.y += _height;

	float wave_color_mix = remap(-wave_color_range, wave_color_range, 0.0, 1.0, _height);
	wave_color_mix = clamp(wave_color_mix, 0.0, 1.0);
	wave_color = mix(low_color, high_color, wave_color_mix);

	vec2 e = vec2(0.1, 0.0);
	float v_scale = height_scale * v_normal_scale;

	vec3 normal = normalize(vec3(
		wave(adj_v_pos - e, NODE_POSITION_WORLD) * v_scale - wave(adj_v_pos + e, NODE_POSITION_WORLD) * v_scale,
		1.0 * e.x,
		wave(adj_v_pos - e.yx, NODE_POSITION_WORLD) * v_scale - wave(adj_v_pos + e.yx, NODE_POSITION_WORLD) * v_scale));

	NORMAL = normal;
	triplanar_pos = VERTEX.xyz * vec3(1.0, 0.0, 1.0);
	v_color = COLOR.rgba;
	camera_mix = INV_VIEW_MATRIX;
}

void fragment() {
	// render the top
	ROUGHNESS = roughness;
	vec3 _albedo;
	vec3 deep;

	vec2 wobble_uv = (texture(under_wobble_noise, g_uv(UV, caustic_speed, false) * 10.0).xy * wobble_power);
	wobble_uv -= wobble_power * 0.86;

	vec3 under = texture(screen_texture, SCREEN_UV + wobble_uv).rgb;

	float depth3 = texture(depth_texture, SCREEN_UV + wobble_uv).x;
	vec3 ndc3 = vec3(SCREEN_UV + wobble_uv, depth3) * 2.0 - 1.0;
	vec4 world3 = camera_mix * INV_PROJECTION_MATRIX * vec4(ndc3, 1.0);
	vec3 world_position = world3.xyz / world3.w;

	float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;

	float _dist = distance(world_position.y, vertex_y);
	// the horizontal distance, used to fade as the camera gets farther away
	float _h_dist = distance(triplanar_pos, world_position);
	_dist += _h_dist * h_dist_trans_weight;

	// Changes the colour of geometry behind it as the water gets deeper
	float depth_fade_blend = exp(-_dist / depth_fade_distance);
	depth_fade_blend = clamp(depth_fade_blend, 0.0, 1.0);

	// Makes the water more transparent as it gets more shallow
	float alpha_blend = -_dist * transmittence;
	alpha_blend = clamp(1.0 - exp(alpha_blend), 0.7, 1.0);

	deep = mix(wave_color, surface_albedo, depth_fade_blend);

	vec2 rounded_uv = round_to_pixel((triplanar_pos.xz * (1.0 / normal_noise_size)) * 0.1, normal_map_w);

	vec3 n_map1 = texture(normal_noise, g_uv(rounded_uv, normal_noise_speed, false)).xyz;
	vec3 n_map2 = texture(normal_noise2, g_uv(rounded_uv, normal_noise_speed, true)).xyz;

	NORMAL_MAP = mix(n_map1, n_map2, 0.5);

	if (FRONT_FACING) {
		_albedo = mix(under, deep, alpha_blend);
		float _ALPHA = remap(0.0, opacity, opacity_floor, opacity_ceiling, pow(alpha_blend, edge_fade_power));
		_albedo = mix(under + transmit_color, _albedo, _ALPHA);
	} else {
		NORMAL = -NORMAL;
		NORMAL_MAP = mix(vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), NORMAL_MAP);
		vec3 over = texture(screen_texture, SCREEN_UV + wobble_uv).rgb;
		_albedo = mix(over, surface_bottom.rgb, surface_bottom.a);
	}
	ALBEDO = _albedo;
	ALBEDO = mix(sky_color, ALBEDO, v_color.a);

	vec4 projected_coords = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0));
	world_normal = abs(INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;

	vec2 porj_pos = projected_coords.xz;
	vec2 porj_pos_w = (porj_pos - npw.xz);

	float foam_m = 0.0;
	if (distance(vec2(npw.x, npw.z), porj_pos) < foam_mask_size / 2.0) {
		vec2 r_f_m = (porj_pos_w + vec2(foam_mask_size / 2.0)) / foam_mask_size;
		r_f_m += foam_mask_offset / 100.0;
		foam_m = texture(foam_mask, (r_f_m)).r;
	}

	vec2 wobble_uv2 = (texture(foam_wobble_noise, g_uv(rounded_uv / foam_wobble_size, caustic_speed, false)).xy) * foam_wobble;
	vec3 f_map1 = texture(foam, g_uv(rounded_uv + wobble_uv2, normal_noise_speed, true)).xyz;
	foam_power = foam_m * texture(foam, rounded_uv + wobble_uv2).a;
	ALBEDO = mix(ALBEDO, f_map1, foam_power);
}

group_uniforms lighting;

// An optional mode where the lighting ignores the view angle.
// Inaccurate to real life but looks kinda cool.
uniform bool enable_fake_lighting = false;

// 4.7 fix: every `0.0f`-style literal in this block lost its `f` suffix
uniform float shine_strength : hint_range(0.0, 1.0) = 0.17;
uniform float shine_shininess : hint_range(0.0, 32.0) = 18.0;

uniform float shadow : hint_range(0.0, 1.0) = 0.72;
uniform float shadow_width : hint_range(0.001, 0.5) = 0.18;
uniform vec4 shadow_color : source_color = vec4(0.705, 0.705, 0.705, 1.0);

uniform float _specular_smoothness : hint_range(0.0, 0.5) = 0.199;
uniform float _specular_strength : hint_range(0.0, 9.25) = 0.075;
uniform float _glossiness : hint_range(0.0, 0.5) = 0.067;

// light code from https://godotshaders.com/shader/toon/ and
// https://godotshaders.com/shader/flexible-toon-shader-godot-4/
void light() {
	vec3 H;
	if (enable_fake_lighting) {
		H = normalize(LIGHT);
	} else {
		H = normalize(VIEW + LIGHT);
	}
	float NdotH = dot(NORMAL, H);
	float specular_amount = max(pow(NdotH, shine_shininess * shine_shininess), 0.0) * ATTENUATION;
	SPECULAR_LIGHT += shine_strength * specular_amount * LIGHT_COLOR;

	float NdotL = dot(NORMAL, LIGHT) * ATTENUATION;
	NdotL = smoothstep(shadow - shadow_width, shadow + shadow_width, NdotL);

	// specular
	float specular_intensity = pow(NdotH, 1.0 / _glossiness);
	vec3 specular = vec3(smoothstep(0.5 - _specular_smoothness, 0.5 + _specular_smoothness, specular_intensity));

	vec3 rim = vec3(1.0);

	DIFFUSE_LIGHT += ATTENUATION * mix(ALBEDO * shadow_color.rgb,
		(ALBEDO + (rim + specular) * _specular_strength) * LIGHT_COLOR.rgb * 0.33, NdotL + 0.33);
	DIFFUSE_LIGHT = mix(sky_color, DIFFUSE_LIGHT, v_color.r);
	SPECULAR_LIGHT = mix(vec3(0.0), SPECULAR_LIGHT, v_color.r);
	SPECULAR_LIGHT = mix(SPECULAR_LIGHT, vec3(0.0), foam_power);
	DIFFUSE_LIGHT = mix(DIFFUSE_LIGHT, foam_color, foam_power);
}
