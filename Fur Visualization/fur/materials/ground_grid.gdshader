shader_type spatial;
render_mode unshaded;

uniform vec3 grid_color : source_color = vec3(0.0);
uniform float grid_opacity = 0.1;
uniform float speed_factor = 0.1;

// --- 시각화용 (이식본 추가 — 원본은 상수 8.0 / 0.03) ---
uniform float grid_res = 8.0;
uniform float grid_thickness = 0.03;

float grid(vec2 st, float res, float thickness){
	vec2 grid = fract(st*res);
	return (step(thickness, grid.x) * step(thickness, grid.y));
}

void fragment() {
	float mask = smoothstep(0.5, 0.0, distance(vec2(0.5), UV));
	ALPHA = (1.0 - grid(UV + vec2(0.0, TIME * speed_factor), grid_res, grid_thickness)) * mask * grid_opacity;
	ALBEDO = grid_color;
}