// =============================================================================
// 20 - Water Toon Torrent   (Leon Denise, from https://www.shadertoy.com/view/mtfBRr)
// src : https://godotshaders.com/shader/water-toon-torrent-shader/
// type: canvas_item (2D)
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES
//   * Compiles unchanged on 4.7. Two things that look suspicious but are legal:
//       - `uniform vec3 direction = vec3(1,1,0);` - int literals inside a vector
//         constructor are fine even in a uniform initialiser (only a *scalar*
//         float uniform like `= 2` is rejected).
//       - `for (int i = 0; i < steps; ++i, a /= 2.)` - 4.7 does support the
//         comma operator in the loop's increment clause.
//   * `R` is the shadertoy resolution stand-in; it controls aspect/framing, not
//     pixel count. Leave it near vec2(.8, .6) unless you want to re-frame.
//   * A gyroid FBM, so `steps` is a direct cost multiplier.
// =============================================================================
shader_type canvas_item;

uniform vec2 R = vec2(.8, .6);
uniform float scale = 0.5;
uniform float speed = 1.0;
uniform vec3 direction = vec3(1, 1, 0);
uniform float distortion = 0.5;
uniform float layers = 2.;
uniform float shades = 3.;
uniform int steps = 6;

uniform vec3 tint : source_color = vec3(.459, .765, 1.);

float gyroid(vec3 seed) { return dot(sin(seed), cos(seed.yzx)); }

float fbm(vec3 seed)
{
	float result = 0., a = .5;
	for (int i = 0; i < steps; ++i, a /= 2.) {
		seed += direction * TIME * speed * .01 / a;
		seed.z += result * distortion;
		result += gyroid(seed / a) * a;
	}
	return result;
}

void fragment()
{
	vec2 p = (2. * UV - R) / R.y;
	float shape = fbm(vec3(p * scale, 0.));
	float gradient = fract(shape * layers);
	float shade = round(pow(gradient, 4.) * shades) / shades;
	vec3 color = mix(tint * mix(.6, .8, gradient), vec3(1), shade);
	COLOR = vec4(color, 1.0);
}
