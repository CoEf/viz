// =============================================================================
// 16 - CS 2 Water (flow map + refraction + depth fog)
// src : https://godotshaders.com/shader/cs-2-water/
// type: spatial (3D)   original target: Godot 4.x
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES
//   * Compiles unchanged on 4.7. The author's Russian comments are kept as
//     published, with an English gloss added on the same line.
//   * FIXED, not preserved: the original hints `normal_map` and `flow_map` as
//     `source_color`. That makes Godot sRGB-decode them, and neither holds
//     colour - one is a tangent-space normal, the other is an XY direction. A
//     mid-grey 0.5 decodes to ~0.21, so `normalize(n1 + n2 - 1.0)` came out
//     pointing backwards and the whole surface shaded near-black. Changed to
//     `hint_normal` and an unhinted sampler respectively. `base_texture` really
//     is colour, so it keeps `source_color`.
//   * `water_depth = VERTEX.z - world_pos.z` mixes a view-space z with an
//     unprojected view-space z; both are negative-forward so the subtraction is
//     consistent. Untouched.
//   * Reflections come from the environment / a ReflectionProbe, so the demo
//     scene supplies a sky for this one to bounce.
// =============================================================================
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// === ТЕКСТУРЫ === (textures)
uniform sampler2D normal_map : hint_normal, repeat_enable;    // анимированная normal map (рябь) - animated ripple normal map  [4.7: was source_color]
uniform sampler2D flow_map : repeat_enable;                   // направление течения (R=X, G=Y) - flow direction  [4.7: was source_color]
uniform sampler2D base_texture : source_color, repeat_enable; // мусор, тина, пена (альфа = отражение) - debris/scum/foam, alpha = reflection
uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture;

// === ПАРАМЕТРЫ === (parameters)
uniform vec3 water_color : source_color = vec3(0.1, 0.3, 0.4);
uniform vec3 deep_color : source_color = vec3(0.0, 0.05, 0.1);
uniform float fog_start = 0.5;
uniform float fog_end = 10.0;
uniform float wave_speed = 0.3;
uniform float wave_strength = 0.05;
uniform float flow_strength = 0.5;
uniform float refraction_strength = 0.05;
uniform float reflectivity = 0.6;
uniform float roughness_val = 0.05;

// === ВЕРШИННЫЕ ВОЛНЫ === (vertex waves)
void vertex() {
	vec2 uv_flow = UV + TIME * wave_speed * 0.1;
	float wave = sin(UV.x * 20.0 + TIME * 2.0) * cos(UV.y * 15.0 + TIME * 1.5);
	VERTEX.y += wave * wave_strength;
}

// === ФРАГМЕНТ === (fragment)
void fragment() {
	// --- Flow map (течение как в Source 2) - Source 2 style flow ---
	vec2 flow_dir = texture(flow_map, UV).rg * 2.0 - 1.0;
	vec2 uv1 = UV + flow_dir * flow_strength * TIME * 0.05;
	vec2 uv2 = UV + flow_dir * flow_strength * (TIME * 0.05 + 0.5);

	// --- Анимированная normal map --- (animated normal map)
	vec3 n1 = texture(normal_map, uv1).rgb;
	vec3 n2 = texture(normal_map, uv2).rgb;
	vec3 blended_normal = normalize(n1 + n2 - vec3(1.0));
	NORMAL_MAP = blended_normal;
	NORMAL_MAP_DEPTH = 1.0;

	// --- Преломление (refraction) ---
	vec2 refraction_offset = blended_normal.xy * refraction_strength;
	vec3 refracted = texture(screen_texture, SCREEN_UV + refraction_offset).rgb;

	// --- Глубина (fog под водой) - underwater depth fog ---
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	world_pos.xyz /= world_pos.w;
	float water_depth = VERTEX.z - world_pos.z; // приблизительная глубина - approximate depth
	float fog_factor = clamp((water_depth - fog_start) / (fog_end - fog_start), 0.0, 1.0);

	// --- Цвет воды с туманом --- (water colour with fog)
	vec3 final_color = mix(water_color, deep_color, fog_factor);
	final_color = mix(refracted, final_color, fog_factor * 0.8);

	// --- Base texture (мусор/тина) - debris / scum ---
	vec4 base = texture(base_texture, uv1);
	final_color = mix(final_color, base.rgb, base.a * 0.5);

	// --- Отражение (через ReflectionProbe или env) ---
	// В Godot 4 ReflectionProbe подхватывается автоматически, если roughness низкий.
	// (Godot 4 picks up a ReflectionProbe automatically when roughness is low;
	//  fresnel below strengthens it.)
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float reflect_amount = mix(reflectivity, 1.0, fresnel);

	ALBEDO = final_color;
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;
	ALPHA = 0.85 + reflect_amount * 0.15;
}
