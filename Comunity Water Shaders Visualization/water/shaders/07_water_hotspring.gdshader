// =============================================================================
// 07 - Water / Hotspring (exercise): polar caustics + expanding discs
// src : https://godotshaders.com/shader/water-hotspring-exercise/
// type: spatial (3D)   original target: Godot 3.x
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES
//   * hint_black  -> hint_default_black   (caustics_texture, distort_noise)
//   * hint_albedo -> source_color         (color_gradient)
//   * Added repeat_enable on the two noise samplers; the polar sweep walks UVs
//     far outside 0..1 and needs the wrap.
//   * repeat_disable on color_gradient, and this one is a real 3.x -> 4.x trap.
//     In 3.x a sampler's wrap mode came from the texture's own flags, and a
//     GradientTexture was CLAMP. In 4.x every `uniform sampler2D` defaults to
//     repeat_enable instead. The ramp is 256x1, so with repeat + linear
//     filtering a lookup at u=0 blends texel 0 with the wrapped texel 255 - the
//     opposite end of the gradient. Since the shader spends most of its area at
//     grad_uv = 0, the whole pool picked up the ramp's bright end and the effect
//     rendered inverted: pale background with dark veins instead of deep blue
//     water with bright caustics. One keyword, entirely different image.
//   * `highp` still parses in 4.7, so the precision qualifiers are untouched.
//   * `const float TAU = 6.283185307;` had to GO. 4.7 promoted TAU to a
//     built-in shader constant (alongside PI and E), so redeclaring it is a
//     hard "Redefinition of 'TAU'" error. The built-in value is the same
//     constant to more digits, so the polar maths is unchanged.
//   * The disc loop is fixed at 20 iterations; kept as published.
// =============================================================================
shader_type spatial;

uniform sampler2D caustics_texture : hint_default_black, repeat_enable; // 4.7: was hint_black
uniform sampler2D color_gradient : source_color, repeat_disable;        // 4.7: was hint_albedo (+ repeat_disable, see header)
uniform sampler2D distort_noise : hint_default_black, repeat_enable;    // 4.7: was hint_black

uniform float flow_speed = 0.3;
uniform float vignette_size = 0.3;
uniform float vignette_blend = 0.1;
uniform float distort_strength = 0.1;
uniform float disc_speed = 0.5;

// 4.7: `const float TAU` removed - TAU is a built-in constant now.

vec2 polar_coordinates(vec2 uv, vec2 center, float zoom, float repeat) {
	vec2 dir = uv - center;
	highp float radius = length(dir) * 2.0;
	highp float angle = atan(dir.y, dir.x) / TAU;
	return mod(vec2(radius * zoom, angle * repeat), 1.0);
}

void vertex() {
	float dn = texture(distort_noise, UV + TIME * 0.1).r;
	VERTEX.y += dn * 0.1;
}

void fragment() {
	// Polar UVs + Noise for caustics
	vec2 base_uv = UV;
	float dn = texture(distort_noise, UV + TIME * 0.1).r;
	base_uv += dn * distort_strength;
	base_uv -= distort_strength / 2.0;
	highp vec2 polar_uv = polar_coordinates(base_uv, vec2(0.5), 1.0, 1.0);
	polar_uv.x -= TIME * flow_speed;
	float caus = texture(caustics_texture, polar_uv).r;

	// Fade out caustics
	float cd = distance(UV, vec2(0.5));
	float vign = 1.0 - smoothstep(vignette_size, vignette_size + vignette_blend, cd);

	// Color the caustics
	float grad_uv = caus * vign;
	vec3 color = texture(color_gradient, vec2(grad_uv)).rgb;

	// Center discs
	float global_disc = 0.0;
	for (int i = 0; i < 20; i++) {
		float offset = float(i) * 0.2;
		float radius_disc = 0.8;
		float loop = fract((TIME + offset) * disc_speed) * radius_disc;
		float disc = smoothstep(cd, cd + 0.01, loop);
		float fade = abs(loop - radius_disc);
		fade = pow(fade, 5.0);
		disc *= fade;
		disc = clamp(disc, 0.0, 1.0);
		global_disc += disc;
	}
	global_disc *= 0.6;

	ALBEDO = color + global_disc;
}
