/**
 * Grass Patch 3D
 * Original: al77ex - https://godotshaders.com/shader/grass-patch-3d-2/
 * License: CC0
 * Original engine: Godot 4.x  ->  compiles unchanged on 4.7.
 *
 * NOTE: despite the name this is a `canvas_item` shader, not a 3D one. It paints a
 * procedural grass *texture* with no geometry and no source texture at all - two octaves
 * of hash-based value noise, world-anchored by uniforms the game feeds it each frame.
 *
 * In this project it is rendered inside a SubViewport and mapped onto a ground quad, so it
 * can sit in the same 3D scene as the other nine and be compared honestly: it is the
 * "grass from above, zero geometry" answer, which is what you actually want for a
 * top-down/2.5D game or for the far LOD ring behind real blades.
 *
 * res://scripts/grass_patch_feed.gd drives camera_world_pos / camera_zoom.
 */
shader_type canvas_item;

// --- Appearance ---
uniform vec4 color_base : source_color = vec4(0.28, 0.55, 0.15, 1.0);
uniform vec4 color_highlight : source_color = vec4(0.45, 0.72, 0.25, 1.0);
uniform float color_variation : hint_range(0.0, 1.0) = 0.35;

// --- Noise / Texture ---
uniform float noise_scale : hint_range(1.0, 80.0) = 25.0;
uniform float detail_scale : hint_range(10.0, 200.0) = 80.0;
uniform float detail_strength : hint_range(0.0, 1.0) = 0.3;

// --- Wind Movement ---
uniform float wind_speed : hint_range(0.0, 2.0) = 0.4;
uniform float wind_strength : hint_range(0.0, 0.02) = 0.005;
uniform vec2 wind_direction = vec2(1.0, 0.3);

// --- Camera (set by background_grass.gd each frame) ---
uniform vec2 camera_world_pos = vec2(0.0, 0.0);
uniform float camera_zoom = 1.0;

// Cheap hash-based noise (no texture needed)
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // smoothstep

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	// Reconstruct world-anchored UV from camera position + zoom
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv_world = camera_world_pos / screen_size + (UV - 0.5) / camera_zoom;

	// Wind offset applied in world space
	vec2 wind = normalize(wind_direction) * TIME * wind_speed;
	vec2 uv_shifted = uv_world + wind * wind_strength;

	// Large-scale color variation
	float n1 = value_noise(uv_shifted * noise_scale);

	// Fine detail layer
	float n2 = value_noise(uv_shifted * detail_scale);

	// Combine: large patches + fine grain
	float blend = n1 * (1.0 - detail_strength) + n2 * detail_strength;
	blend = mix(0.5 - color_variation * 0.5, 0.5 + color_variation * 0.5, blend);

	// Final color
	COLOR = mix(color_base, color_highlight, blend);
}
