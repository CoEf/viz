// =============================================================================
// 05 - Water Ripples (procedural rings around a moving object)
// src : https://godotshaders.com/shader/water-ripples/
// type: spatial (3D)   original target: Godot 4.x
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES
//   * Compiles unchanged on 4.7.
//   * Needs a transparent material: it writes ALPHA and expects blending, so
//     the demo material has transparency on. Without it the rings look solid.
//   * `boat_position` must be pushed from GDScript; the demo binds it to the
//     roaming probe sphere so the rings follow it.
// =============================================================================
shader_type spatial;
render_mode diffuse_toon, specular_toon, depth_draw_always;

uniform vec3 water_color : source_color = vec3(0.1, 0.4, 0.8);
uniform vec3 foam_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float water_opacity : hint_range(0.0, 1.0) = 0.7;

// Boat Tracker
uniform vec3 boat_position = vec3(0.0, 0.0, 0.0);

// Wave Math
uniform float wave_frequency = 3.0;
uniform float wave_speed = 5.0;
uniform float max_radius = 10.0;

// --- Randomization Controls ---
uniform float noise_scale = 1.5;                             // Size of the random ripples
uniform float distortion_strength = 0.5;                     // How wobbly the rings become
uniform float breakup_strength : hint_range(0.0, 1.5) = 0.8; // How much the foam tears apart

varying vec3 world_pos;

// --- PROCEDURAL 2D NOISE GENERATOR ---
vec2 random2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(dot(random2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
				   dot(random2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
			   mix(dot(random2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
				   dot(random2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 flat_world_pos = world_pos.xz;
	vec2 flat_boat_pos = boat_position.xz;

	// 1. GENERATE THE NOISE MAP (TIME makes the pattern slowly boil)
	float organic_noise = noise(flat_world_pos * noise_scale + (TIME * 0.2));

	// 2. DISTORT THE DISTANCE so the rings stop being perfect circles
	float dist_to_boat = distance(flat_world_pos, flat_boat_pos);
	float wobbly_dist = dist_to_boat + (organic_noise * distortion_strength);

	// 3. APPLY TO WAVE MATH
	float wave_math = sin((wobbly_dist * wave_frequency) - (TIME * wave_speed));

	// 4. BREAK UP THE RINGS - subtract noise to tear holes in the foam
	float threshold = 0.8 + (organic_noise * breakup_strength);
	float sharp_foam = step(threshold, wave_math);

	// 5. FADE OUT WITH DISTANCE
	float radius_mask = 1.0 - smoothstep(max_radius * 0.5, max_radius, dist_to_boat);
	float final_foam_mask = sharp_foam * radius_mask;

	ALBEDO = mix(water_color, foam_color, final_foam_mask);
	ALPHA = final_foam_mask;
}
