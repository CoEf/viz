shader_type texture_blit;
render_mode blend_mix;

// Triangle-aware dirt erase.
//
// Blitted once per affected triangle into that triangle's UV bounding rect.
// For each canvas pixel inside the triangle we reconstruct its 3D position
// (via barycentric interpolation) and erase based on its distance to the
// brush capsule (segment brush_a -> brush_b). Pixels outside the triangle
// are left untouched, so adjacent UV islands across a seam never bleed.

// Current triangle, UV (0-1) and local 3D vertices.
uniform vec2 tri_uv0;
uniform vec2 tri_uv1;
uniform vec2 tri_uv2;
uniform vec3 tri_pos0;
uniform vec3 tri_pos1;
uniform vec3 tri_pos2;

// Brush capsule in model-local space (a == b for a single stamp).
uniform vec3 brush_a;
uniform vec3 brush_b;
uniform float brush_radius = 0.05;

uniform float pressure : hint_range(0.0, 1.0) = 1.0;
uniform vec2 texture_size = vec2(1024.0, 1024.0);

// Conservative dilation so neighbouring triangles overlap by ~1px at shared
// edges instead of leaving an un-erased rasterisation seam.
const float EDGE_EPS = 0.01;

// Barycentric coords of uv inside the triangle. Returns false for a
// degenerate (zero-area) UV triangle.
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

// Shortest distance from point p to segment [a, b].
float dist_to_segment(vec3 p, vec3 a, vec3 b) {
	vec3 ab = b - a;
	float len_sq = dot(ab, ab);
	float t = len_sq > 1e-12 ? clamp(dot(p - a, ab) / len_sq, 0.0, 1.0) : 0.0;
	return distance(p, a + ab * t);
}

void blit() {
	// FRAGCOORD spans the full canvas; UV would only cover the blit rect.
	vec2 uv = FRAGCOORD.xy / texture_size;

	vec3 bary;
	bool valid = barycentric(uv, bary);
	bool inside = valid
		&& bary.x >= -EDGE_EPS
		&& bary.y >= -EDGE_EPS
		&& bary.z >= -EDGE_EPS;

	float erase_strength = 0.0;
	if (inside) {
		// Reconstruct the local-space surface point this texel maps to.
		vec3 local_pos = tri_pos0 * bary.x + tri_pos1 * bary.y + tri_pos2 * bary.z;
		float dist = dist_to_segment(local_pos, brush_a, brush_b);
		float falloff = 1.0 - smoothstep(brush_radius * 0.3, brush_radius, dist);
		erase_strength = falloff * pressure;
	}

	// blend_mix: result = 0 * a + dirt * (1 - a) -> dirt reduced toward clean.
	// alpha 0 (outside triangle) leaves the mask pixel completely unchanged.
	COLOR0 = vec4(0.0, 0.0, 0.0, erase_strength);
}
