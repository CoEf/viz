// =============================================================================
// 18 - Make the Water Line Darker v1.0
// src : https://godotshaders.com/shader/make-the-water-line-darker-v1-0/
// type: spatial (3D)   original target: Godot 4.3
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES
//   * Compiles unchanged on 4.7.
//   * THIS IS NOT A WATER SURFACE. It is a `blend_mul` overlay meant for the
//     MeshInstance3D's *material_overlay* slot, so it darkens whatever material
//     is already on the mesh, by world height. In the demo it therefore sits on
//     the submerged rocks/pillars, not on the water plane - that is the only way
//     to see what it does.
//   * `darkening_color` and `source_color_modifier` are declared but the
//     fragment body hard-codes vec3(1,1,1) and vec3(0.1,0.2,0.2) instead. Left
//     exactly as published; swap them in if you want the uniforms live.
//   * Author's note: if it pops in and out, give the mesh a custom AABB so it
//     is not culled early.
// =============================================================================
shader_type spatial;
render_mode blend_mul; // darken whatever texture you already have set up on the mesh

// Made in GODOT 4.3.
// Designed to be used in the "MATERIAL_OVERLAY" property on a mesh instance,
// so you can do your usual texturing underneath it.

uniform float water_sharpness : hint_range(0.0, 1.0) = 0.45;
uniform float height_modifier = 2.0;
uniform vec3 darkening_color : source_color = vec3(0.1, 0.2, 0.2);
uniform vec3 source_color_modifier : source_color = vec3(1., 1., 1.);
uniform float max_metallic : hint_range(0.0, 1.0) = 1.0;
uniform float max_specular : hint_range(0.0, 1.0) = 1.0;

varying vec3 pos;

// Find the Y POSITION in the world (water is usually flat).
void vertex() {
	pos = mat3(MODEL_MATRIX) * -VERTEX;
	pos = pos - NODE_POSITION_WORLD;
}

// use the position to determine the color change, the metallic, and the specular.
void fragment() {
	ALBEDO = mix(vec3(1., 1., 1.), vec3(0.1, 0.2, 0.2), clamp(pow(pos.y + height_modifier, water_sharpness), 0., 1.));
	METALLIC = clamp(pow(pos.y + height_modifier, water_sharpness), 0., 1.);
	SPECULAR = clamp(pow(pos.y + height_modifier, water_sharpness), 0., 1.);
}
