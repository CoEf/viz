// =============================================================================
// 09 - Stylized Toon Water (banded, additive)
// src : https://godotshaders.com/shader/stylized-toon-water/
// type: spatial (3D)   original target: Godot 4.x
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES
//   * Removed a stray double semicolon at the end of vertex() (`;;`).
//   * `render_mode blend_add` means the material is additive: it never goes
//     darker than the background, so on a bright sky it washes out. That is the
//     author's intent - `discard` carves the gaps between the colour bands.
//   * Author's note: feed it low-octave Perlin noise for both wave_texture and
//     noise_texture. The demo binds two FastNoiseLite textures.
// =============================================================================
shader_type spatial;
render_mode cull_disabled, blend_add, unshaded;

uniform float time_speed = 1.0;
// time specifically for the wave noise texture
uniform float surface_speed = 1.0;
uniform float spin = 0.0; // Twisting motion of the water
uniform float brightness = 0.6;
uniform float color_intensity = 0.0;
// Tiling frequency of the noise across the mesh
uniform float horizontal_frequency = 2.0;
uniform float vertical_frequency = 2.0;
// overall size multiplier
uniform float size = 3.0;
// affects total size
uniform float banding_bias = 0.6;

uniform sampler2D wave_texture : repeat_enable;
uniform sampler2D noise_texture : repeat_enable;
// wave height, use for ocean waves
uniform float wave_height = 0.5;
// water surface height variation based on the noise texture
uniform float texture_height = 0.5;
// preset band colors
uniform vec4 color1 : source_color = vec4(0.59, 0.761, 1.0, 1.0);
uniform vec4 color2 : source_color = vec4(0.274, 0.474, 0.98, 1.0);
uniform vec4 color3 : source_color = vec4(0.059, 0.389, 0.85, 1.0);
uniform vec4 color4 : source_color = vec4(0.0, 0.267, 1.0, 1.0);

void vertex() {
	float time = -TIME * time_speed;
	VERTEX += NORMAL * wave_height * texture(wave_texture, vec2(UV.x + time * surface_speed, UV.y + time * surface_speed)).r;
	VERTEX += NORMAL * texture_height * texture(noise_texture, vec2(UV.x * horizontal_frequency + spin * (time / 2.0), (UV.y * vertical_frequency) + time)).r;
}

void fragment() {
	float time = -TIME * time_speed;

	// Dot product of normals combined with the noise texture value
	float normal_facing = dot(NORMAL, VIEW);
	float noise_value = texture(noise_texture, vec2(UV.x * horizontal_frequency + spin * (time / 2.0), (UV.y * vertical_frequency) + time)).r;
	normal_facing += (noise_value - 0.5 + size) * 0.3;

	float band = normal_facing * 3.0 * banding_bias;
	vec4 band_color = vec4(0, 0, 0, 0);
	if (band <= 1.5) {
		discard;
	} else if (band <= 2.0) {
		band_color = mix(color1, color2, -0.01 / (band - 2.01)); // slight gradient between bands
	} else if (band <= 2.5) {
		band_color = mix(color2, color3, -0.01 / (band - 2.51));
	} else if (band <= 2.9) {
		band_color = mix(color3, color4, -0.01 / (band - 2.91));
	} else if (band >= 0.0) {
		band_color = color4;
	}
	// Final color adjustment
	ALBEDO = clamp(brightness * (vec3(1.0, 1.0, 1.0) - (band_color.xyz * -color_intensity)) * band_color.xyz, vec3(0.0, 0.0, 0.0), vec3(brightness, brightness, brightness));
}
