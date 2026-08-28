// =============================================================================
// 22 - FBM Toon Water (colour ramp + foam factor driven by a noise texture)
// src : https://godotshaders.com/shader/fbm-toon-water/
// type: spatial (3D)   original target: Godot 3.x
// -----------------------------------------------------------------------------
// 4.7 CONVERSION NOTES
//   * hint_black -> hint_default_black on nTexture.
//   * TRANSMISSION was REMOVED in Godot 4 - it is a hard "Unknown identifier"
//     error, not a rename. Its 4.x stand-in is BACKLIGHT, which serves the same
//     purpose (light bleeding through a thin surface), so
//         TRANSMISSION = vec3(0.2, 0.7, 0.3);
//     became
//         BACKLIGHT = vec3(0.2, 0.7, 0.3);
//     BACKLIGHT is scaled differently from 3.x TRANSMISSION, so tweak to taste.
//   * Added repeat_enable so the vertex-stage lookup wraps instead of clamping.
//   * Author's setup: nTexture is meant to be a *canvas_item shader rendered
//     into a SubViewport* used as the wave/foam source. The demo binds a
//     scrolling FastNoiseLite texture instead, which gives the same look with
//     far less setup - swap in a ViewportTexture for the original behaviour.
//   * `mediump` / `highp` precision qualifiers still parse on 4.7, untouched.
// =============================================================================
shader_type spatial;

render_mode cull_back, diffuse_burley, specular_toon;

uniform sampler2D nTexture : hint_default_black, repeat_enable; // 4.7: was hint_black

varying vec2 vertPos;

void vertex() {
	vec3 ns = texture(nTexture, UV).rgb * 1.6;
	vertPos = VERTEX.xz / 2.0;
	VERTEX.y = VERTEX.y + (ns.z * 0.9 * NORMAL.y);
}

void fragment() {
	mediump vec3 ns = texture(nTexture, UV).rgb;                 // noise_texture (from Viewport)
	mediump vec3 fFac = smoothstep(vec3(0.8), vec3(0.4), ns);    // foam_factor
	mediump float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	mediump vec3 col_1 = vec3(0.0, 0.1, 0.3);
	mediump vec3 col_2 = vec3(0.1, 0.3, 0.4);
	mediump vec3 col_3 = vec3(0.4, 0.8, 0.8);
	mediump vec3 col_4 = vec3(0.8, 0.9, 0.9);
	// Color_ramp
	mediump vec3 col = mix(mix(col_1, col_2, ns * 0.6), mix(col_3, col_4, ns * 1.2), smoothstep(0.0, 1.0, ns));
	mediump vec3 fCol = clamp(mix(vec3(0.999), col, fFac), 0.0, 1.0); // final_color
	ALBEDO = min(fCol + (0.1 * fresnel), 1.0);
	SPECULAR = 0.2 * fresnel;
	ROUGHNESS = mix(0.9, 0.7, fFac.z) * (1.0 - fresnel * 0.2);
	BACKLIGHT = vec3(0.2, 0.7, 0.3); // 4.7: was TRANSMISSION (removed in Godot 4)
}
