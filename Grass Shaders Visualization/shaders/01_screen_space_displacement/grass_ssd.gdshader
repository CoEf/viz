/**
 * Grass with Screen-Space Displacement
 * Original: Toadile - https://godotshaders.com/shader/grass-with-screen-space-displacement/
 * License: MIT
 * Original engine: Godot 3.x (3.4 / 3.5)
 * Ported to Godot 4.7 - see NOTES.md for the full change list.
 *
 * Idea: the grass card is 2x wider than it needs to be, and the fragment shader slides
 * the albedo UV sideways/down wherever DEPTH_TEXTURE says a solid object is close to the
 * card. The blade "bends away" purely in texture space, no vertex work, no per-instance
 * data - so any number of objects push the grass for free.
 */
shader_type spatial;
// PORT: Godot 4 only allows one render_mode block, and it must precede every function.
// The original declared `depth_draw_opaque` at the top and `depth_draw_always` again in
// the middle of the file; `always` is the one the displacement needs, so it wins.
render_mode blend_mix, cull_disabled, depth_draw_always;

// general parameters
uniform float y_offset = 0.5;
uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 end_color : source_color = vec4(1.0);
uniform float specular : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float rim : hint_range(0.0, 1.0) = 0.01;
uniform float transmission : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap, repeat_disable;
uniform sampler2D texture_wind_noise : filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);

// wind parameters
uniform float wind_noise_scale = 2.0;
uniform vec2 wind_direction = vec2(0.0, 1.0);
uniform float wind_speed : hint_range(0.0, 10.0) = 1.0;
uniform float wind_strength : hint_range(0.0, 10.0) = 1.0;

// grass properties
uniform float color_variatiion : hint_range(0.0, 2.0) = 0.5;
uniform float height : hint_range(0.0, 10.0) = 1.0;
uniform float height_variation : hint_range(0.0, 2.0) = 0.3;
uniform float flatness : hint_range(0.0, 2.0) = 0.2;

// rendering settings
uniform float fade_out_distance = 30.0;
uniform float fade_out_transition = 20.0;
uniform bool y_billboard = false;
uniform float displace_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float proximity_distance : hint_range(0.0, 2.0) = 1.0;
uniform bool displace = true;
uniform float alpha_scissors : hint_range(0.0, 1.0) = 0.9;
uniform bool use_normal_map_alpha = false;

// PORT: Godot 4.7 removed the implicit DEPTH_TEXTURE built-in; it now has to be declared
// as a uniform with hint_depth_texture. This is what makes the whole shader work - it is
// the buffer the grass reads to find out that something solid is standing next to it.
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

// variables
varying float bend_uv_direction;
varying vec3 instance_offset;
varying float fade;

void vertex() {
	// set up grass
	VERTEX.y *= height;
	VERTEX.y += y_offset * height;
	float inverse_uv_y = 1.0 - UV.y;
	COLOR = base_color * vec4(UV.y) + end_color * vec4(inverse_uv_y);

	// "h" means height
	float h_variation = float(INSTANCE_ID % 3) * height_variation * 0.5;
	float inv_h_stiff = (h_variation + height + 1.0) * 2.0;
	float h_stiff = 1.0 / inv_h_stiff;

	// wind noise animation
	// PORT: WORLD_MATRIX -> MODEL_MATRIX
	vec2 world_xy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz * 0.2 * wind_noise_scale
			+ wind_direction * TIME * wind_speed * 0.51 * h_stiff;
	vec4 noise_tex = texture(texture_wind_noise, world_xy);

	// y billboard adjustment
	// PORT: INV_CAMERA_MATRIX -> VIEW_MATRIX, CAMERA_MATRIX -> INV_VIEW_MATRIX
	if (y_billboard) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
	}

	// animate the grass
	vec4 local_wind_direction;
	if (y_billboard) {
		local_wind_direction = vec4(wind_direction.x, 1.0, wind_direction.y, 0.0) * INV_VIEW_MATRIX;
	} else {
		local_wind_direction = vec4(wind_direction.x, 1.0, wind_direction.y, 0.0) * MODEL_MATRIX;
	}
	float flat_x = sin(MODELVIEW_MATRIX[2].x) * flatness * h_stiff;
	float flat_y = cos(MODELVIEW_MATRIX[2].z) * flatness * h_stiff;
	// PORT: pow() with an int literal exponent is a compile error in Godot 4.
	float bend = pow(inverse_uv_y, 2.0);
	float n = (noise_tex.r - 0.5 * 2.0) * bend * wind_strength;
	VERTEX.x += n * flat_x + sin(TIME * 0.01 * h_stiff + float(INSTANCE_ID)) * n * 0.1 * inv_h_stiff
			+ local_wind_direction.x * wind_strength * bend * height;
	VERTEX.z += n * flat_y + cos(TIME * 0.01 * h_stiff + float(INSTANCE_ID)) * n * 0.1 * inv_h_stiff
			+ local_wind_direction.z * wind_strength * bend * height;
	VERTEX.y += h_variation * inverse_uv_y;
	VERTEX.y -= inverse_uv_y * flatness * 0.15;

	// introduce variation per grass instance
	if (INSTANCE_ID % 2 == 0) {
		bend_uv_direction = 1.0;
	} else {
		bend_uv_direction = -1.0;
	}

	if (INSTANCE_ID % 2 == 0) {
		instance_offset = vec3(color_variatiion * 0.1);
	} else {
		instance_offset = vec3(-color_variatiion * 0.1);
	}

	// fade out grass by shrinking it
	// PORT: the `1.0f` / `0.5f` float suffix does not exist in Godot's shader language.
	float view_distance = length(VERTEX - vec3(MODELVIEW_MATRIX[3].x, MODELVIEW_MATRIX[3].y, MODELVIEW_MATRIX[3].z));
	if (view_distance > fade_out_distance + fade_out_transition) {
		fade = 1.0;
	} else {
		fade = 0.0;
	}
	if (view_distance > fade_out_distance) {
		float offset = (fade_out_distance + fade_out_transition - view_distance) / fade_out_transition;
		VERTEX.y *= offset;
	}
}

void fragment() {
	if (fade >= 0.5) {
		discard;
	}
	vec2 base_uv = UV;
	base_uv.x *= 2.0;
	base_uv.x -= 0.5;
	base_uv *= uv_scale;
	base_uv += uv_offset;
	float prox = 1.0;

	// comment out this if-block if not wanting to use displacement and wanting SSAO
	if (displace) {
		float depth_tex = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
		vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_tex * 2.0 - 1.0, 1.0);
		world_pos.xyz /= world_pos.w;
		prox = clamp(1.0 - smoothstep(world_pos.z + proximity_distance, world_pos.z, VERTEX.z)
				+ UV.y * proximity_distance, 0.0, 1.0);
		base_uv.x += (1.0 - prox) * 0.2 * displace_intensity * bend_uv_direction;
		base_uv.y -= (1.0 - prox) * 0.5 * displace_intensity;
	}
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	vec4 normal_tex = texture(texture_normal, base_uv);

	// discard distant grass
	// PORT: the original's `discard; return;` pair is redundant - `discard` already ends
	// the invocation, and several users reported the stray `return` failing to compile.
	if (!use_normal_map_alpha && albedo_tex.a < alpha_scissors) {
		discard;
	} else if (use_normal_map_alpha && normal_tex.a < alpha_scissors) {
		discard;
	}

	ALBEDO = COLOR.rgb * albedo_tex.rgb * (1.0 + instance_offset) * prox;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	RIM = rim;
	// PORT: Godot 4 dropped TRANSMISSION; BACKLIGHT is the equivalent light-bleed term.
	BACKLIGHT = vec3(transmission);
	// PORT: NORMALMAP -> NORMAL_MAP
	NORMAL_MAP = normal_tex.rgb;
}
