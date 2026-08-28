// =============================================================================
// 06 - Water Cylindrical Waves (two scrolling foam lines)
// src : https://godotshaders.com/shader/water-cylindrical-waves/
// type: spatial (3D)   original target: Godot 4.x
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES
//   * `uniform float scroll_speed = 4;` -> `4.0`. An int literal as the default
//     of a float uniform is rejected by the 4.7 parser (it is fine inside
//     expressions, but not as a uniform initialiser).
//   * Everything else compiles as published.
//   * Author's note: put it on a CylinderMesh (a splash/whirlpool ring), it
//     also works on a plane.
// =============================================================================
shader_type spatial;
render_mode diffuse_toon, specular_toon, cull_disabled, unshaded;

// --- SHARED MOVEMENT MECHANICS ---
uniform float scroll_speed = 4.0; // 4.7 fix: was `4`

// Set to -1.0 to scroll Left, 1.0 to scroll Right, or 0.0 to Stop
uniform float scroll_direction : hint_range(-1.0, 1.0, 2.0) = -1.0;

uniform float wave_multiplier = 1.0;
uniform float wave_amplitude : hint_range(0.01, 0.5) = 0.15;
uniform float foam_2_wave_shift : hint_range(0.0, 6.28) = 1.57;

// --- FOAM LINE 1 VISUALS ---
uniform vec4 foam_color_1 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float foam_1_height : hint_range(0.0, 1.0) = 0.5;
uniform float foam_1_thickness : hint_range(0.01, 0.5) = 0.05;

// --- FOAM LINE 2 VISUALS ---
uniform vec4 foam_color_2 : source_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform float foam_2_height : hint_range(0.0, 1.0) = 0.3;
uniform float foam_2_thickness : hint_range(0.01, 0.5) = 0.03;

void fragment() {
	// --- 1. CORE MATH TIME LOOP WITH DIRECTION INJECTION ---
	float horizontal_scroll = UV.x - (TIME * scroll_speed * 0.1 * scroll_direction);
	float loop_radians = horizontal_scroll * 6.283185307 * wave_multiplier;

	// --- 2. GENERATE FOAM LINE 1 MASK ---
	float sine_wave_1 = sin(loop_radians) * wave_amplitude;
	float center_line_1 = foam_1_height + sine_wave_1;

	float lower_bound_1 = center_line_1 - (foam_1_thickness * 0.5);
	float upper_bound_1 = center_line_1 + (foam_1_thickness * 0.5);
	float mask_foam_1 = step(lower_bound_1, UV.y) * step(UV.y, upper_bound_1);

	// --- 3. GENERATE FOAM LINE 2 MASK ---
	float sine_wave_2 = sin(loop_radians + foam_2_wave_shift) * wave_amplitude;
	float center_line_2 = foam_2_height + sine_wave_2;

	float lower_bound_2 = center_line_2 - (foam_2_thickness * 0.5);
	float upper_bound_2 = center_line_2 + (foam_2_thickness * 0.5);
	float mask_foam_2 = step(lower_bound_2, UV.y) * step(UV.y, upper_bound_2);

	// --- 4. CONDITIONAL COLOR ROUTING ---
	vec3 final_albedo = vec3(0.0);
	float combined_mask = 0.0;

	if (mask_foam_1 > 0.1) {
		final_albedo = foam_color_1.rgb;
		combined_mask = 1.0;
	}

	if (mask_foam_2 > 0.1) {
		final_albedo = foam_color_2.rgb;
		combined_mask = 1.0;
	}

	// --- 5. PINCH MESH BOUNDARIES AND OUTPUT ---
	float side_pinch = sin(UV.y * 3.14159265);
	float final_alpha = combined_mask * side_pinch;

	ALBEDO = final_albedo;
	ALPHA = step(0.1, final_alpha);

	ALPHA_SCISSOR_THRESHOLD = 0.1;
}
