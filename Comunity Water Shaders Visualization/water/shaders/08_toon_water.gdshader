// =============================================================================
// 08 - Toon Water (depth-faded scrolling texture)
// src : https://godotshaders.com/shader/toon-water/
// type: spatial (3D)   original target: Godot 4.x
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES
//   * Compiles unchanged on 4.7 - including the slightly odd
//     `: source_color, hint_depth_texture` hint pair, which 4.7 still accepts.
//   * `vec3(1,1,1)` int literals are fine inside expressions in 4.7; only
//     uniform *initialisers* need explicit floats. Left as published.
//   * Author's note: their water texture was 2:1, hence the "* 2.0" hint on the
//     Y sample. The demo uses a square noise texture, so it stays at 1:1.
// =============================================================================
shader_type spatial;

render_mode unshaded;

uniform float slide_speed = 0.3;
uniform float wobble_speed = 1.0;
uniform float wobble_intensity = 0.4;
uniform float texture_scale = 0.2;
uniform sampler2D water : repeat_enable;

// https://godotshaders.com/shader/shield-shader-with-intersection-highlight/
uniform sampler2D depth_texture : source_color, hint_depth_texture;

varying vec2 sample_choord;

void vertex() {
	VERTEX.y += sin(TIME * wobble_speed + (VERTEX.x + VERTEX.z) * 0.3) * 0.2;
	sample_choord = VERTEX.xz;
}

void fragment() {
	vec3 color1 = vec3(1, 1, 1);
	vec3 color2 = texture(
		water,
		vec2(
			(sample_choord.x + sin(TIME * wobble_speed) * wobble_intensity + TIME * slide_speed) * texture_scale,
			// AWOOGA the author's texture was 2:1 AR, so put "* 2.0" here if you use it
			(sample_choord.y + cos(TIME * wobble_speed * 0.5) * wobble_intensity) * texture_scale
		)
	).rgb;

	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;

	float object_depth = FRAGCOORD.z;
	vec3 object_ndc = vec3(SCREEN_UV * 2.0 - 1.0, object_depth);
	vec4 object_view = INV_PROJECTION_MATRIX * vec4(object_ndc, 1.0);
	object_view.xyz /= object_view.w;
	float linear_object_depth = -object_view.z;

	ALBEDO = mix(color1, color2, smoothstep(0.0, 4.0, linear_depth - linear_object_depth));
}
