// dither.gdshaderinc
//
// binbun's "Billboard Grass with Wind" does `#include "util/dither.gdshaderinc"` but the
// file was never posted alongside the shader (three separate commenters asked for it), so
// this is a stand-in: the classic 4x4 ordered Bayer matrix, returning a 0..1 threshold for
// a screen-space pixel coordinate.
//
// Used as `step(bayer4(FRAGCOORD.xy) + 0.01, alpha)` it turns a soft alpha edge into a
// stable stipple, which lets grass stay in the opaque pass (no sorting, no blend order
// artefacts) while still fading out.

const float BAYER_4X4[16] = float[16](
	 0.0,  8.0,  2.0, 10.0,
	12.0,  4.0, 14.0,  6.0,
	 3.0, 11.0,  1.0,  9.0,
	15.0,  7.0, 13.0,  5.0
);

float bayer4(vec2 frag_coord) {
	int x = int(mod(frag_coord.x, 4.0));
	int y = int(mod(frag_coord.y, 4.0));
	return BAYER_4X4[y * 4 + x] / 16.0;
}
