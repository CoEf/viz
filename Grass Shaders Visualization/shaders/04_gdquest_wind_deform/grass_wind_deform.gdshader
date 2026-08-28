/**
 * Stylized grass with wind and deformation
 * Original: GDQuest - https://godotshaders.com/shader/stylized-grass-with-wind-and-deformation/
 * License: MIT
 * Original engine: Godot 3.2
 * Ported to Godot 4.7 - see NOTES.md.
 *
 * Idea: Breath-of-the-Wild style. A tiling noise texture scrolled along the wind direction
 * drives the bend, and a single character position pushes blades outward through a curve
 * texture. Both displacements are converted into *vertex* space first, which is the whole
 * trick - it means randomly rotated blades all bend the same way in world terms.
 *
 * Limitation kept from the original: exactly one pusher. More would need the positions
 * packed into a texture.
 */
shader_type spatial;
render_mode cull_disabled, unshaded;

uniform float wind_speed = 0.2;
uniform float wind_strength = 2.0;
// How big, in world space, is the noise texture
// wind will tile every wind_texture_tile_size
uniform float wind_texture_tile_size = 20.0;
uniform float wind_vertical_strength = 0.3;
uniform vec2 wind_horizontal_direction = vec2(1.0,0.5);

// PORT: hint_black_albedo -> source_color + hint_default_black. This exact line is the
// one every 4.x user hits ("Not working for 4.2 / Error: hint_black_albedo").
// repeat_disable matters here: a ramp that wraps mirrors the tip colour onto the root.
uniform sampler2D color_ramp : source_color, hint_default_black, filter_linear, repeat_disable;
// we need a tiling noise here!
// PORT: hint_black -> hint_default_black
uniform sampler2D wind_noise : hint_default_black, filter_linear_mipmap, repeat_enable;

uniform vec3 character_position;
uniform float character_radius = 3.0;
// PORT: repeat_disable is REQUIRED here. Godot 4 defaults curve textures to repeat, which
// wraps the falloff lookup and makes far-away grass react to the character. (Reported by
// "Benight" in the comments after hours of debugging - it is not obvious from the code.)
uniform sampler2D character_distance_falloff_curve : source_color, hint_default_black, filter_linear, repeat_disable;
uniform float character_push_strength = 1.0;

varying float debug_wind;

void vertex() {
	// PORT: WORLD_MATRIX -> MODEL_MATRIX (all four uses below).
	vec3 world_vert = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec2 normalized_wind_direction = normalize(wind_horizontal_direction);
	vec2 world_uv = world_vert.xz / wind_texture_tile_size + normalized_wind_direction * TIME * wind_speed;
	// we displace only the top part of the mesh
	// note that this means that the mesh needs to have UV in a way that the bottom of UV space
	// is at the top of the mesh
	float displacement_affect = (1.0 - UV.y);
	float wind_noise_intensity = (textureLod(wind_noise, world_uv , 0.0).r - 0.5);

	// We convert the direction of the wind into vertex space from world space
	// if we used it directly in vertex space, rotated blades of grass wouldn't behave properly
	vec2 vert_space_horizontal_dir = (inverse(MODEL_MATRIX) * vec4(wind_horizontal_direction, 0.0,0.0)).xy;
	vert_space_horizontal_dir = normalize(vert_space_horizontal_dir);

	vec3 bump_wind = vec3(
		wind_noise_intensity * vert_space_horizontal_dir.x,
		1.0 - wind_noise_intensity,
		wind_noise_intensity * vert_space_horizontal_dir.y
	);
	// NOTE: kept verbatim from the original - normalize() returns a value that is thrown
	// away here, so bump_wind is NOT normalised. Removing the line changes nothing;
	// making it `bump_wind = normalize(bump_wind);` changes the look, so it is left alone.
	normalize(bump_wind);
	bump_wind *= vec3(
		wind_strength,
		wind_vertical_strength,
		wind_strength
	);
	VERTEX += bump_wind * displacement_affect;

	// At the moment the blades are pushed away in a perfectly circular manner.
	// We could distort the distance to the character based on a noise, to break a bit the
	// circular shape. We could distort the falloff by sampling in a noise based on the xz coordinates.
	// The task is left to the reader

	vec3 dir_to_character = character_position - MODEL_MATRIX[3].xyz;
	// uncomment the following line to have a horizontal only character push
//	dir_to_character.y = 0.0;
	float distance_to_character = length(dir_to_character);
	float falloff = 1.0 - smoothstep(0.0, 1.0, distance_to_character/character_radius);
	// Because we operate in vertex space, we need to convert the direction to the character
	// in vertex space. Otherwise, it wouldn't work for rotated blades of grass.
	// comment the next line to observe how the blades are not all facing away from the character.
	dir_to_character = (inverse(MODEL_MATRIX) * vec4(dir_to_character, 0.0)).xyz;
	dir_to_character = normalize(dir_to_character);

	// sample the curve based on how far we are from the character, in normalized coordinates
	float falloff_curve = texture(character_distance_falloff_curve, vec2(falloff)).x;
	// direction to character is inverted because we want to point away from it
	VERTEX += normalize(-dir_to_character) * falloff_curve * character_push_strength * displacement_affect;
}

void fragment() {
	ALBEDO = texture(color_ramp, vec2(1.0 - UV.y, 0)).rgb ;
}
