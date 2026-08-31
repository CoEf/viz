shader_type texture_blit;
render_mode blend_mix;

// Rasterises one triangle into the UV coverage mask.
// Inside pixels → R=1 alpha=1 (overwrite).
// Outside pixels → alpha=0 (blend_mix leaves existing value untouched).
// Blitted once per triangle during setup; result is a binary mask where
// R=1 means "a triangle covers this texel" and R=0 means empty UV space.

uniform vec2 tri_uv0;
uniform vec2 tri_uv1;
uniform vec2 tri_uv2;
uniform vec2 texture_size = vec2(1024.0, 1024.0);

// Same dilation as erase_dirt_3d so coverage and erase footprints match.
const float EDGE_EPS = 0.01;

bool barycentric(vec2 uv, out vec3 bary) {
	vec2 d = uv - tri_uv0;
	vec2 e1 = tri_uv1 - tri_uv0;
	vec2 e2 = tri_uv2 - tri_uv0;
	float denom = e1.x * e2.y - e1.y * e2.x;
	if (abs(denom) < 1e-12) {
		bary = vec3(0.0);
		return false;
	}
	float inv = 1.0 / denom;
	float v = (d.x * e2.y - d.y * e2.x) * inv;
	float w = (e1.x * d.y - e1.y * d.x) * inv;
	bary = vec3(1.0 - v - w, v, w);
	return true;
}

void blit() {
	vec2 uv = FRAGCOORD.xy / texture_size;

	vec3 bary;
	bool valid = barycentric(uv, bary);
	bool inside = valid
		&& bary.x >= -EDGE_EPS
		&& bary.y >= -EDGE_EPS
		&& bary.z >= -EDGE_EPS;

	// alpha=1 inside → overwrites to white; alpha=0 outside → no change.
	float a = inside ? 1.0 : 0.0;
	COLOR0 = vec4(1.0, 1.0, 1.0, a);
}
