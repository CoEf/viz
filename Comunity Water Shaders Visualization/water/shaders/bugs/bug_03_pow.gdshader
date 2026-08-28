// =============================================================================
// 워크스루 전용 "고치기 전" 사본. 원본 프로젝트에는 이 파일이 없다.
// 03번 — 포말 항의 max(..., 0.0)만 뺀 것. pow()의 밑이 음수가 되면 GLSL에서는
// 정의되지 않은 동작이고, 이 하드웨어에서는 거대한 양수가 나온다.
// =============================================================================
// =============================================================================
// 03 - Realistic Water   (c) 2019 UnionBytes, Achim Menzel (AiYori) - MIT
// src : https://godotshaders.com/shader/realistic-water/
// type: spatial (3D)   original target: Godot 3.1.1 - 3.4
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES  (this one was a full 3.x -> 4.x port)
//   * hint_color            -> source_color
//   * hint_aniso            -> filter_linear_mipmap_anisotropic
//   * hint_black            -> hint_default_black
//   * WORLD_MATRIX          -> MODEL_MATRIX
//   * NORMALMAP / _DEPTH    -> NORMAL_MAP / NORMAL_MAP_DEPTH
//   * SCREEN_TEXTURE and DEPTH_TEXTURE are no longer global builtins; they are
//     now explicit uniforms with hint_screen_texture / hint_depth_texture.
//     screen_texture also needs filter_linear_mipmap because the shader calls
//     textureLod() on it for the blurred-underwater look.
//   * DEPTH CONVENTION. 3.x stored depth as NDC [-1,1] and linearised it with
//     `PROJECTION_MATRIX[3][2] / (d + PROJECTION_MATRIX[2][2])`. 4.x uses a
//     reverse-Z [0,1] buffer, so that formula returns garbage. Replaced with an
//     INV_PROJECTION_MATRIX unprojection that yields the same quantity
//     (positive view-space distance), which keeps every downstream line
//     (`depth + VERTEX.z + depth_offset`) working exactly as written.
//   * The caustic re-projection used `vec4(ref_uv*2-1, depth_raw*2-1, 1)`; in
//     4.x NDC z is already [0,1] so the raw sample is fed in directly.
//   * `vertex_height`. The original stored `(PROJECTION * MODELVIEW * vertex).z`,
//     i.e. clip-space z. On 3.x that is very nearly the view-space distance, and
//     the shader uses it as one - it divides the refraction offset by it and
//     compares the water depth against it for foam. On 4.x, reverse-Z makes
//     PROJECTION[2][2] = 0 and PROJECTION[3][2] = near, so clip.z collapses to a
//     constant ~0.05: refraction blew up about 20x and the foam test fired
//     everywhere. It now stores the view-space distance directly, which is the
//     quantity the rest of the shader was written against.
//   * FOAM / pow of a negative base. The foam term is
//         pow(1.0 - depth_difference + foam_noise, 8.0)
//     which only behaves while the water is under ~1 unit deep - exactly the
//     shoreline case the author's demo had. Once the pool gets deeper the base
//     goes negative, and pow() with a negative base is undefined in GLSL: on
//     this hardware it returns a huge positive number and the whole surface
//     clamps to white foam. Wrapped the base in max(..., 0.0), which is what the
//     expression means anyway (no foam away from the shore) and makes the result
//     depth-independent instead of hardware-dependent.
//   * `uniform mat4 projector` is unused by the shader body (it was driven from
//     GDScript in the original demo) - kept so the material still exposes it.
// =============================================================================
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx, blend_mix;

// Wave settings:
uniform float wave_speed = 0.5;                    // Speed scale for the waves
uniform vec4 wave_a = vec4(1.0, 1.0, 0.35, 3.0);   // xy = Direction, z = Steepness, w = Length
uniform vec4 wave_b = vec4(1.0, 0.6, 0.30, 1.55);  // xy = Direction, z = Steepness, w = Length
uniform vec4 wave_c = vec4(1.0, 1.3, 0.25, 0.9);   // xy = Direction, z = Steepness, w = Length

// Surface settings:
uniform vec2 sampler_scale = vec2(0.25, 0.25);      // Scale for the sampler
uniform vec2 sampler_direction = vec2(0.05, 0.04);  // Direction and speed for the sampler offset

uniform sampler2D uv_sampler : filter_linear_mipmap_anisotropic, repeat_enable; // 4.7: was hint_aniso
uniform vec2 uv_sampler_scale = vec2(0.25, 0.25);
uniform float uv_sampler_strength = 0.04;

uniform sampler2D normalmap_a_sampler : hint_normal, repeat_enable;
uniform sampler2D normalmap_b_sampler : hint_normal, repeat_enable;

uniform sampler2D foam_sampler : hint_default_black, repeat_enable; // 4.7: was hint_black
uniform float foam_level = 0.5;

// Volume settings:
uniform float refraction = 0.075;

uniform vec4 color_deep : source_color = vec4(0.02, 0.13, 0.25, 1.0);    // 4.7: was hint_color
uniform vec4 color_shallow : source_color = vec4(0.13, 0.55, 0.55, 1.0); // 4.7: was hint_color
uniform float beers_law = 2.0;
uniform float depth_offset = -0.75;

// Projector for the water caustics:
uniform mat4 projector;
uniform sampler2DArray caustic_sampler : hint_default_black; // 4.7: was hint_black

// Vertex -> Fragment:
varying float vertex_height;
varying vec3 vertex_normal;
varying vec3 vertex_binormal;
varying vec3 vertex_tangent;
varying mat4 inv_mvp;

// 4.7: screen/depth taps are uniforms now
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

// Wave function:
vec4 wave(vec4 parameter, vec2 position, float time, inout vec3 tangent, inout vec3 binormal) {
	float wave_steepness = parameter.z;
	float wave_length = parameter.w;

	float k = 2.0 * 3.14159265359 / wave_length;
	float c = sqrt(9.8 / k);
	vec2 d = normalize(parameter.xy);
	float f = k * (dot(d, position) - c * time);
	float a = wave_steepness / k;

	tangent += normalize(vec3(1.0 - d.x * d.x * (wave_steepness * sin(f)), d.x * (wave_steepness * cos(f)), -d.x * d.y * (wave_steepness * sin(f))));
	binormal += normalize(vec3(-d.x * d.y * (wave_steepness * sin(f)), d.y * (wave_steepness * cos(f)), 1.0 - d.y * d.y * (wave_steepness * sin(f))));

	return vec4(d.x * (a * cos(f)), a * sin(f) * 0.25, d.y * (a * cos(f)), 0.0);
}

void vertex() {
	float time = TIME * wave_speed;

	vec4 vertex = vec4(VERTEX, 1.0);
	vec3 vertex_position = (MODEL_MATRIX * vertex).xyz; // 4.7: was WORLD_MATRIX

	vec3 tang = vec3(0.0, 0.0, 0.0);
	vec3 bin = vec3(0.0, 0.0, 0.0);

	vertex += wave(wave_a, vertex_position.xz, time, tang, bin);
	vertex += wave(wave_b, vertex_position.xz, time, tang, bin);
	vertex += wave(wave_c, vertex_position.xz, time, tang, bin);

	vertex_tangent = tang;
	vertex_binormal = bin;

	vertex_position = vertex.xyz;

	// 4.7: was (PROJECTION_MATRIX * MODELVIEW_MATRIX * vertex).z - see header.
	vertex_height = -(MODELVIEW_MATRIX * vertex).z;

	TANGENT = vertex_tangent;
	BINORMAL = vertex_binormal;
	vertex_normal = normalize(cross(vertex_binormal, vertex_tangent));
	NORMAL = vertex_normal;

	UV = vertex.xz * sampler_scale;

	VERTEX = vertex.xyz;

	inv_mvp = inverse(PROJECTION_MATRIX * MODELVIEW_MATRIX);
}

void fragment() {
	// Calculation of the UV with the UV motion sampler
	vec2 uv_offset = sampler_direction * TIME;
	vec2 uv_sampler_uv = UV * uv_sampler_scale + uv_offset;
	vec2 uv_sampler_uv_offset = uv_sampler_strength * texture(uv_sampler, uv_sampler_uv).rg * 2.0 - 1.0;
	vec2 uv = UV + uv_sampler_uv_offset;

	// Normalmap:
	vec3 normalmap = texture(normalmap_a_sampler, uv - uv_offset * 2.0).rgb * 0.75; // 75 % sampler A
	normalmap += texture(normalmap_b_sampler, uv + uv_offset).rgb * 0.25;           // 25 % sampler B

	// Refraction UV:
	vec3 ref_normalmap = normalmap * 2.0 - 1.0;
	ref_normalmap = normalize(vertex_tangent * ref_normalmap.x + vertex_binormal * ref_normalmap.y + vertex_normal * ref_normalmap.z);
	vec2 ref_uv = SCREEN_UV + (ref_normalmap.xy * refraction) / vertex_height;

	// Ground depth (4.7: reverse-Z unprojection instead of the 3.x NDC formula)
	float depth_raw = texture(depth_texture, ref_uv).r;
	vec4 depth_view = INV_PROJECTION_MATRIX * vec4(ref_uv * 2.0 - 1.0, depth_raw, 1.0);
	depth_view.xyz /= depth_view.w;
	float depth = -depth_view.z; // positive view-space distance, same units as 3.x gave

	float depth_blend = exp((depth + VERTEX.z + depth_offset) * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_pow = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

	// Ground color:
	vec3 screen_color = textureLod(screen_texture, ref_uv, depth_blend_pow * 2.5).rgb;

	vec3 dye_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_pow);
	vec3 color = mix(screen_color * dye_color, dye_color * 0.25, depth_blend_pow * 0.5);

	// Caustic screen projection (4.7: NDC z is already [0,1], no *2-1)
	vec4 caustic_screenPos = vec4(ref_uv * 2.0 - 1.0, depth_raw, 1.0);
	vec4 caustic_localPos = inv_mvp * caustic_screenPos;
	caustic_localPos = vec4(caustic_localPos.xyz / caustic_localPos.w, caustic_localPos.w);

	vec2 caustic_Uv = caustic_localPos.xz / vec2(1024.0) + 0.5;
	vec4 caustic_color = texture(caustic_sampler, vec3(caustic_Uv * 300.0, mod(TIME * 14.0, 16.0)));

	color *= 1.0 + pow(caustic_color.r, 1.50) * (1.0 - depth_blend) * 6.0;

	// Foam:
	if (depth + VERTEX.z < vertex_height - 0.1) {
		float foam_noise = clamp(pow(texture(foam_sampler, (uv * 4.0) - uv_offset).r, 10.0) * 40.0, 0.0, 0.2);
		// 4.7: max(..., 0.0) added - see the pow-of-negative note in the header.
		// 원본 그대로: 수심차가 1을 넘으면 밑이 음수가 된다.
		float foam_mix = clamp(pow(1.0 - (depth + VERTEX.z) + foam_noise, 8.0) * foam_noise * 0.4, 0.0, 1.0);
		color = mix(color, vec3(1.0), foam_mix);
	}

	// Set all values:
	ALBEDO = color;
	METALLIC = 0.1;
	ROUGHNESS = 0.2;
	SPECULAR = 0.2 + depth_blend_pow * 0.4;
	NORMAL_MAP = normalmap;       // 4.7: was NORMALMAP
	NORMAL_MAP_DEPTH = 1.25;      // 4.7: was NORMALMAP_DEPTH
}
