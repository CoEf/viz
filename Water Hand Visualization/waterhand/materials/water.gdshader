shader_type spatial;
render_mode cull_back, depth_draw_always;

uniform sampler2D depth_texture_sampler : hint_depth_texture;
uniform sampler2D voronoi_sampler : filter_linear_mipmap, repeat_enable;
uniform sampler2D caustic_sampler : filter_linear_mipmap, repeat_enable;

uniform vec3 base_color : source_color;
uniform vec3 dark_color : source_color;

varying vec3 uv1_triplanar_pos;
uniform float uv1_blend_sharpness;
varying vec3 uv1_power_normal;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

// --- 시각화용 (이식본 추가 — 기본값이 원본 상수) ---
uniform float noise_mix = 0.85;      // 원본: mix(small, big, 0.85)
uniform float wave_amplitude = 0.01; // 원본: 0.01
uniform float edge_small = 0.1;      // 원본: +0.1 (접촉선 폭)
uniform float edge_big = 2.0;        // 원본: +2.0 (침식 폭)
uniform float foam_enabled = 1.0;    // 흰 포말 항 on/off
uniform int debug_mode = 0;          // 1=코스틱 2=접촉선 3=침식항 4=bottom_mask 5=프레넌

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

vec2 polar_coordinates(vec2 uv, vec2 center, float zoom, float repeat)
{
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x) * 1.0/(3.1416 * 2.0);
	return mod(vec2(radius * zoom, angle * repeat), 1.0);
}

void vertex() {
	
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	
	uv1_power_normal=pow(abs(NORMAL),vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
	float wave = sin((uv1_triplanar_pos.y - TIME * 0.8) * PI * 4.0);
	VERTEX += NORMAL * wave * wave_amplitude;
}

vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

void fragment() {
	float depth_texture = textureLod(depth_texture_sampler, SCREEN_UV, 0.0).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0,depth_texture, 1.0);
	world_pos.xyz /= world_pos.w;
	
	float big_noise = triplanar_texture(caustic_sampler, uv1_power_normal, (uv1_triplanar_pos - vec3(TIME, 0.0, 0.0) * 0.2) * 0.8).x;
	float small_noise = triplanar_texture(caustic_sampler, uv1_power_normal, (uv1_triplanar_pos - vec3(TIME, 0.0, 0.0) * 0.1) * 1.2).x;
	
	float voronoi = triplanar_texture(voronoi_sampler, uv1_power_normal, (uv1_triplanar_pos - vec3(TIME, 0.0, 0.0) * 0.2) * 0.8).x;
	
	float noise = mix(small_noise, big_noise, noise_mix);
	
	float small_edge = smoothstep(world_pos.z + edge_small, world_pos.z, VERTEX.z);
	float big_edge = smoothstep(world_pos.z + edge_big, world_pos.z, VERTEX.z);
	float bottom_mask = clamp((1.0 - small_edge) - voronoi * big_edge, 0.0, 1.0);
	
	float f = fresnel(1.0, NORMAL, VIEW);
	ALBEDO = mix(dark_color, base_color, max(0.0, step(0.35, f) + noise)) + step(0.6, f + (1.0 - bottom_mask)) * 0.4 * foam_enabled;
	EMISSION = ALBEDO * f;
	ALPHA = bottom_mask;
	ALPHA_SCISSOR_THRESHOLD = 0.5;

	// 디버그는 마지막에 덮어쓴다
	if (debug_mode == 1) {
		ALBEDO = vec3(noise);
		EMISSION = vec3(noise) * 0.6;
		ALPHA = 1.0;
	} else if (debug_mode == 2) {
		ALBEDO = vec3(0.0);
		EMISSION = mix(vec3(0.06, 0.1, 0.3), vec3(1.0, 0.85, 0.2), small_edge);
		ALPHA = 1.0;
	} else if (debug_mode == 3) {
		ALBEDO = vec3(0.0);
		EMISSION = vec3(voronoi * big_edge);
		ALPHA = 1.0;
	} else if (debug_mode == 4) {
		ALBEDO = vec3(bottom_mask);
		EMISSION = vec3(bottom_mask) * 0.6;
		ALPHA = 1.0;
	} else if (debug_mode == 5) {
		ALBEDO = vec3(0.0);
		EMISSION = vec3(f);
		ALPHA = 1.0;
	}
}
