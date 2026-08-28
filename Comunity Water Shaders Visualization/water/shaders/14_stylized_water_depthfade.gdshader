// =============================================================================
// 14 - Stylized Water with DepthFade
// src : https://godotshaders.com/shader/stylized-water-with-depthfade/
// type: spatial (3D)   original target: Godot 3.x
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES  (another full 3.x -> 4.x port)
//   * hint_color -> source_color (color, deep_water, edge_color)
//   * SCREEN_TEXTURE / DEPTH_TEXTURE builtins -> explicit hinted uniforms
//   * NORMALMAP -> NORMAL_MAP
//   * FLOAT LITERALS. 4.7 accepts `1.0f` but rejects `1f` / `2f` / `4f` / `70f`
//     / `100f` ("Invalid (float) numeric constant") because there is no decimal
//     point. Every one of those was rewritten with an explicit `.0`.
//   * DEPTH CONVENTION. rim() did `2*d - 1` then the near/far reciprocal trick,
//     which assumes a 3.x [-1,1] NDC depth buffer. 4.7 stores reverse-Z in
//     [0,1], so rim() now unprojects through INV_PROJECTION_MATRIX and returns
//     the same thing it used to: a positive view-space distance. It needs the
//     screen UV and the matrix to do that, hence the two extra arguments -
//     4.7 will not let a *global* function touch a fragment-stage builtin
//     ("Unknown identifier in expression: 'INV_PROJECTION_MATRIX'"), it has to
//     be handed in from fragment(). Shader 12 solves it the same way.
//     `near` and `far` are consequently no longer read - they are kept as
//     uniforms only so the material matches the published one.
//   * calc_depth_fade() had the same 3.x formula inside it; ported the same way.
//   * `_distance` defaulted to 0.0, which divides by zero and blanks the fade.
//     Defaulted to 1.0.
//   * `render_mode specular_phong` is GONE in Godot 4 (only specular_schlick_ggx,
//     specular_toon and specular_disabled survive) -> swapped to
//     specular_schlick_ggx, the engine default and the closest match.
//   * Author's note: set Render Priority to -1 on the material if the water
//     occludes things it shouldn't.
// =============================================================================
shader_type spatial;
render_mode specular_schlick_ggx, cull_disabled; // 4.7: was specular_phong (removed in 4.x)

uniform float speed : hint_range(-1, 1) = 0.0;

uniform sampler2D noise1 : repeat_enable;
uniform sampler2D noise2 : repeat_enable;
uniform sampler2D normalmap : hint_normal, repeat_enable;

uniform vec4 color : source_color = vec4(0.1, 0.5, 0.7, 0.8);       // 4.7: was hint_color
uniform vec4 deep_water : source_color = vec4(0.02, 0.12, 0.3, 1.0); // 4.7: was hint_color

// depth-fade vars
uniform float beer_law_factor = 2.0;
uniform float _distance = 1.0; // 4.7: was 0.0 -> divide by zero

// foam vars
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);  // 4.7: was hint_color
uniform float edge_scale = 0.25;
uniform float near = 0.1;
uniform float far = 100.0; // 4.7: was 100f. No longer read - see header note.

// wave vars
uniform vec2 wave_strength = vec2(0.5, 0.25);
uniform vec2 wave_frequ = vec2(12.0, 12.0);
uniform vec2 time_factor = vec2(1.0, 2.0);

// 4.7: these two used to be engine globals
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture;

float waves(vec2 pos, float time) {
	return (wave_strength.y * sin(pos.y * wave_frequ.y + time * time_factor.y)) + (wave_strength.x * sin(pos.x * wave_frequ.x + time * time_factor.x));
}

void vertex() {
	VERTEX.y += waves(VERTEX.xy, TIME);
}

// 4.7: reverse-Z unprojection replaces the 3.x `2*d-1` + near/far reciprocal.
// Returns the same quantity the original did: positive view-space distance.
float rim(float depth, vec2 screen_uv, mat4 inv_projection_matrix) {
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth);
	vec4 view = inv_projection_matrix * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

float calc_depth_fade(float depth, vec2 screen_uv, mat4 inv_projection_matrix,
						vec4 fragcoord, float beer_factor, float __distance, vec3 vertex) {

	// 4.7: linearise through the inverse projection instead of
	// `projection_matrix[3][2] / (ndc + projection_matrix[2][2])`
	float scene_depth = rim(depth, screen_uv, inv_projection_matrix);

	scene_depth = scene_depth + vertex.z; // z is negative

	// application of beers law
	scene_depth = exp(-scene_depth * beer_factor);

	float screen_depth = fragcoord.z;

	float depth_fade = (scene_depth - screen_depth) / __distance;

	depth_fade = clamp(depth_fade, 0.0, 1.0);

	return depth_fade;
}

void fragment() {
	float time = TIME * speed;

	vec3 n1 = texture(noise1, UV + time).rgb;
	vec3 n2 = texture(noise2, UV - time * 0.2).rgb;

	vec2 uv_movement = UV * 4.0;         // 4.7: was 4f
	uv_movement += TIME * speed * 4.0;   // 4.7: was 4f

	float sum = (n1.r + n2.r) - 1.0;     // 4.7: was 1f

	float z_depth = rim(texture(depth_texture, SCREEN_UV).x, SCREEN_UV, INV_PROJECTION_MATRIX);
	float z_pos = rim(FRAGCOORD.z, SCREEN_UV, INV_PROJECTION_MATRIX);
	float diff = z_depth - z_pos;

	// depth-fade
	float z_depth_fade = calc_depth_fade(texture(depth_texture, SCREEN_UV).x, SCREEN_UV, INV_PROJECTION_MATRIX, FRAGCOORD, beer_law_factor, _distance, VERTEX);
	float z_fade = rim(FRAGCOORD.z, SCREEN_UV, INV_PROJECTION_MATRIX);
	float fade_diff = z_depth_fade - z_fade;

	vec4 gradientcolor = mix(color, deep_water, z_depth_fade);

	vec2 displacement = vec2(sum * 0.1);
	diff += displacement.x * 70.0;       // 4.7: was 70f

	vec4 col = mix(edge_color, gradientcolor, step(edge_scale, diff));

	vec4 alpha = texture(screen_texture, SCREEN_UV + displacement);

	float fin = 0.0;
	if (sum > 0.0 && sum < 0.4) fin = 0.1;
	if (sum > 0.4 && sum < 0.8) fin = 0.0;
	if (sum > 0.8) fin = 1.0;            // 4.7: was 1f

	ALBEDO = vec3(fin) + mix(alpha.rgb, col.rgb, gradientcolor.a);

	NORMAL_MAP = texture(normalmap, uv_movement).rgb; // 4.7: was NORMALMAP

	ROUGHNESS = 0.1;
}
