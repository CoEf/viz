shader_type texture_blit;
render_mode blend_mix;

// Bound to sources[0] in blit_rect_multi — the initial dirt pattern texture.
uniform sampler2D initial_dirt : hint_blit_source0;
uniform vec2 texture_size = vec2(1024.0, 1024.0);

void blit() {
	// FRAGCOORD maps across the full canvas; UV would only cover the blit rect.
	vec2 uv = FRAGCOORD.xy / texture_size;
	float dirt = texture(initial_dirt, uv).r;
	// alpha = 1.0 → blend_mix fully overwrites the DrawableTexture2D content.
	COLOR0 = vec4(dirt, dirt, dirt, 1.0);
}
