// =============================================================================
// 24 - Sine Wave Camera View (full-screen underwater wobble)
// src : https://godotshaders.com/shader/sine-wave-camera-view-shader/
// type: canvas_item (2D, screen-reading)
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES
//   * Compiles unchanged on 4.7.
//   * This is a POST-PROCESS, not a water surface: it wobbles whatever is
//     already on screen. Put it on a full-rect ColorRect placed above the game
//     content in a CanvasLayer. The demo runs it as an optional overlay on top
//     of the 3D viewer so you can stack it with any of the 3D shaders.
//   * Frequency (10.0) and amplitude (0.01) are hard-coded in the original;
//     they are lifted to uniforms below so you can actually tune it from the
//     inspector. The defaults reproduce the published values exactly.
// =============================================================================
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

// 4.7 demo addition: the published shader hard-coded 10.0 and 0.01 inline.
uniform float frequency = 10.0;
uniform float amplitude = 0.01;
uniform float speed = 1.0;

void fragment() {
	// Calculate UV coordinates
	vec2 uv = SCREEN_UV;
	// Offset the UV coordinates based on a sine wave
	uv.x += sin(SCREEN_UV.y * frequency + TIME * speed) * amplitude;
	uv.y += sin(SCREEN_UV.x * frequency + TIME * speed) * amplitude;

	// Sample the texture using the modified UV coordinates
	COLOR = texture(screen_texture, uv);
}
