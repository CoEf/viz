shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded, shadows_disabled;

// Soft round snowflake billboard for GPUParticles3D draw passes.
// No texture needed: the radial falloff is computed from the quad UV.

uniform float brightness : hint_range(0.2, 3.0) = 1.15;

void vertex() {
	// Billboard facing the camera while preserving the particle's scale.
	mat4 basis = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	mat4 scale = mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * basis * scale;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float dist = length(UV - vec2(0.5)) * 2.0;
	float mask = smoothstep(1.0, 0.25, dist);
	ALBEDO = COLOR.rgb * brightness;
	ALPHA = mask * COLOR.a;
}
