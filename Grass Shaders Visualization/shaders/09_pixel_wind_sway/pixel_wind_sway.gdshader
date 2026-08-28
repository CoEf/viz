/**
 * Pixel Art Wind Sway (MeshInstance3D, Godot 4.0)
 * Original: Darfine - https://godotshaders.com/shader/pixel-art-wind-sway-meshinstance3d-godot-4-0/
 * License: CC0
 * Original engine: Godot 4.0  ->  compiles unchanged on 4.7.
 *
 * The cheapest shader of the ten: two sine waves, no textures beyond the sprite, no noise,
 * no uniforms. The interesting part is NODE_POSITION_WORLD - it is what de-synchronises
 * neighbouring tufts, and it is *per node*, so this shader only varies if each tuft is its
 * own MeshInstance3D. Put it on a MultiMesh and the whole field sways as one block.
 * (Demo 09 in this project uses individual MeshInstance3D nodes for exactly that reason.)
 *
 * Only addition: ALPHA_SCISSOR_THRESHOLD, taken from "schuster" in the comments, so the
 * pixel sprite keeps hard edges instead of blending. Set to 0.0 to get the original back.
 */
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D grass_texture : filter_nearest, source_color;
uniform float alpha_scissor : hint_range(0.0, 1.0) = 0.5;

void vertex(){
	NORMAL = vec3(0.0, 1.0, 0.0);
	VERTEX.x += sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * ( 1.0 - UV.y) * 0.2;
	VERTEX.z += cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * ( 1.0 - UV.y) * 0.15;
}

void fragment(){
	ALBEDO = texture(grass_texture, UV).rgb;
	ALPHA = texture(grass_texture, UV).a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
}
