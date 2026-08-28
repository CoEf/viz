/**
 * Grass shader
 * Original: kiwio - https://godotshaders.com/shader/grass-shader/
 * License: CC0
 * Original engine: Godot 3.x
 * Ported to Godot 4.7 - see NOTES.md.
 *
 * Idea: the only one of the ten that is properly *lit* - it keeps the mesh normal pointing
 * straight up so a whole field shades like a single soft surface, then modulates ROUGHNESS
 * by the wind value so gusts read as a moving sheen sweeping across the field. That sheen
 * is the effect worth stealing from this shader.
 */
shader_type spatial;
render_mode cull_disabled;

uniform float sway = 1.14;
uniform float sway_ = 0.34;
uniform float sway_pow = 1.3;
uniform float grass_roughness = 0.3;
uniform float sway_noise_sampeling_scale = 0.12;
uniform float sway_time_scale = 0.2;
uniform vec3 sway_dir = vec3(1.0,0.0,1.0);
uniform sampler2D sway_noise : filter_linear_mipmap, repeat_enable; //noise with with and height 1000
uniform float color_scale = 0.3;
uniform float color_grad_height = -0.5;
// PORT: hint_color -> source_color (both lines).
uniform vec4 top_color : source_color;
uniform vec4 bot_color : source_color;
uniform vec3 grass_scale = vec3(1.0,1.0,1.0);

varying vec3 vert;
varying float curent_wind;

float sclamp(float f,float sc){
	return clamp(((f-0.5)*sc)+0.5,0.0,1.0);
}

void fragment()
{
	ALBEDO = mix(bot_color,top_color,(vert.y+color_grad_height)*color_scale).xyz;
	NORMAL *= FRONT_FACING ? 1.0 : -1.0;
	SPECULAR = 0.5;
	// PORT: clamp(x, 0.2, 1) mixes an int literal into a float call - a compile error in
	// Godot 4's stricter shader language.
	ROUGHNESS = clamp(1.0-(sclamp(curent_wind,0.8)*grass_roughness),0.2,1.0);
}

void vertex()
{
	VERTEX *= grass_scale;
	vert = VERTEX;
	NORMAL = vec3(0.0,1.0,0.0);
	// PORT: WORLD_MATRIX -> MODEL_MATRIX (both lines).
	vec4 sway_dir_local = vec4(sway_dir,0.0) * MODEL_MATRIX;
	vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	curent_wind = texture(sway_noise,normalize(sway_dir.xz) * (-TIME*sway_time_scale) + world_vertex.xz*vec2(sway_noise_sampeling_scale)).x;
	VERTEX += normalize(sway_dir_local.xyz) * sway * (VERTEX.y) *  sclamp(curent_wind,1.5);
	// PORT: the original is `sway_ * abs(pow(VERTEX.x, sway_pow))`. pow() of a negative
	// base with a fractional exponent is undefined in GLSL and returns NaN on Vulkan, so
	// every blade on the -X half of the mesh disappeared. abs() has to be on the base.
	VERTEX.y -= sway_*pow(abs(VERTEX.x),sway_pow);
}
