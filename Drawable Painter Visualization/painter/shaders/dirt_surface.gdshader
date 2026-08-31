shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Clean surface (original model textures)
uniform sampler2D clean_albedo : source_color, hint_default_white;
uniform sampler2D clean_normal : hint_normal;
uniform sampler2D clean_roughness : hint_default_white;

// Dirt overlay appearance
uniform vec3 dirt_color : source_color = vec3(0.12, 0.09, 0.05);
uniform float dirt_roughness : hint_range(0.0, 1.0) = 0.95;

// R=1 fully dirty, R=0 fully clean. Set and written by dirt_canvas_component.
uniform sampler2D dirt_mask : hint_default_white;

void fragment() {
	vec2 uv = UV;
	float dirt = texture(dirt_mask, uv).r;

	// Albedo: clean color fades to muddy brown under dirt
	vec3 clean = texture(clean_albedo, uv).rgb;
	ALBEDO = mix(clean, dirt_color, dirt);

	// Normal: dirt flattens surface detail
	vec3 n = texture(clean_normal, uv).rgb;
	NORMAL_MAP = mix(n, vec3(0.5, 0.5, 1.0), dirt * 0.7);
	NORMAL_MAP_DEPTH = 1.0;

	// PBR: dirty = very rough, non-metallic, slightly occluded
	float r = texture(clean_roughness, uv).r;
	ROUGHNESS = mix(r, dirt_roughness, dirt);
	METALLIC = 0.0;
	AO = mix(1.0, 0.72, dirt);
	AO_LIGHT_AFFECT = 1.0;
}
