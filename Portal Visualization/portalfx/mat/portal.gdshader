// 이식본: effects/portal/portal/mat/portal.gdshader
// 원본과의 차이: use_screen_uv(UV vs SCREEN_UV 비교 토글)와
// darken(원본 상수 0.58)을 uniform으로 뺐다. 기본값이 곧 원본 동작.
shader_type spatial;
render_mode unshaded;

uniform sampler2D viewport_sampler : filter_linear, source_color;

// --- 시각화용 ---
uniform float use_screen_uv = 1.0; // 0 = UV로 샘플링(TV 모드)
uniform float darken = 0.58;       // 원본: * 0.58

void fragment(){
	float dist = distance(UV, vec2(0.5));
	vec2 sample_uv = mix(UV, SCREEN_UV, use_screen_uv);
	vec3 viewport_texture = texture(viewport_sampler, sample_uv).rgb;
	ALBEDO = viewport_texture * darken;
	ALPHA = step(dist, 0.5);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
