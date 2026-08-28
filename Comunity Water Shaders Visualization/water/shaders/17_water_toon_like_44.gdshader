// =============================================================================
// 17 - Water Shader (toon-like) for Godot 4.4
// src : https://godotshaders.com/shader/water-shader-toon-like-godot-4-4/
// type: spatial (3D)   original target: Godot 4.4+
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES
//   * Compiles unchanged on 4.7 - nothing rewritten.
//   * The `0.65f` / `0.1f` / `1.0f` / `0.5f` / `0.6f` literals here are all
//     legal: 4.7 accepts an `f` suffix as long as the number has a decimal
//     point. Only forms like `100f` (no point) are rejected. See shader 14,
//     where that distinction actually mattered.
//   * `clamp(rand + 0.2, 0, 1)` also passes: int literals promote inside
//     expressions, just not as uniform initialisers.
//   * `render_mode world_vertex_coords` means VERTEX.xz in vertex() is already
//     world space, which is what the noise lookup assumes - keep it.
//   * Needs a transparent material (it writes ALPHA) and two normal-map style
//     noise textures.
// =============================================================================
shader_type spatial;
render_mode world_vertex_coords;
uniform sampler2D norRand1 : repeat_enable;
uniform sampler2D norRand2 : repeat_enable;
uniform vec2 dir = vec2(-0.2, 1.);
uniform float alpha : hint_range(0.1, 1.0) = 0.65f;
uniform float distScaler : hint_range(0.01, 1.0) = 0.1f;
uniform vec4 baseCol : source_color = vec4(0.15, 0.45, 0.65, 1.0);
uniform vec3 deepCol : source_color = vec3(0.01, 0.1, 0.25);
uniform float deepColOffset = 0.0;
uniform float noiseScaler = 0.001;
uniform float waveSpeedScaler = 1.0;
uniform float vertexSpeedScaler = 1.0;
uniform vec4 fresnelColor : source_color = vec4(0.6, 0.85, 1.0, 1.0);
uniform vec4 edgeColor : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float edgeThreshold = 0.1f;
uniform sampler2D depthTex : hint_depth_texture;
uniform sampler2D edgeNoise : repeat_enable;
uniform float windRippleDegScaler = 1.0f;
varying vec2 worldXZ;

float fresnel_schlick(vec3 view_dir, vec3 normal) {
	float F0 = 0.02;
	float cos_theta = clamp(dot(normalize(view_dir), normalize(normal)), 0.0, 1.0);
	return F0 + (1.0 - F0) * pow(1.0 - cos_theta, 5.0);
}

void vertex() {
	worldXZ = VERTEX.xz;
	VERTEX.y += windRippleDegScaler * 0.5f * (texture(norRand1, (dir * vertexSpeedScaler * TIME + VERTEX.xz) * 0.01).r - 0.5f);
}

void fragment() {
	vec2 offSet = dir * TIME * waveSpeedScaler;
	NORMAL_MAP = mix(texture(norRand1, (worldXZ + offSet) * noiseScaler),
	texture(norRand2, (worldXZ + offSet) * noiseScaler), 0.5).rgb;

	ALBEDO = baseCol.rgb;
	ALBEDO = mix(ALBEDO, fresnelColor.rgb, fresnel_schlick(VIEW, NORMAL));

	float depth = texture(depthTex, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	float nodeY = NODE_POSITION_WORLD.y;
	float dis = (nodeY - world_position.y) * distScaler;
	float mixEdge = step(dis, edgeThreshold);
	float rand = texture(edgeNoise, (-dir * TIME + worldXZ) * 0.02).x;
	float mixAmount = clamp(rand + 0.2, 0, 1);
	ALBEDO = mix(ALBEDO, edgeColor.rgb, mixAmount * mixEdge);

	float mixDeepAmount = clamp(dis * (deepColOffset + 1.) * 0.6f, 0., 1.);
	mixDeepAmount = pow(mixDeepAmount, 0.85);
	ALBEDO = mix(ALBEDO, deepCol, mixDeepAmount);

	ROUGHNESS = 0.02;
	ALPHA = alpha;
}
