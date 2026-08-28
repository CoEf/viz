// ═══════════════════════════════════════════════════════════════════════════
//  ripple_sim.gdshader — 파문 레벨 3 (파동 방정식 시뮬레이션)
//  docs/water-shader-analysis.md 5.7
//
//  SubViewport 안에서 자기 자신의 직전 프레임을 읽어 한 스텝 전진시킨다.
//  레벨 2(스프라이트 마스크)와 달리 파문이 실제로 퍼지고, 서로 간섭하고,
//  장애물이 있으면 반사된다.
//
//  ★ 출력 규약은 레벨 2 와 동일하다 — 소비자(wt_ripple.gdshaderinc)는 한 줄도 안 바뀐다.
//    R = 높이(부호 있음), G = 0  →  소비자의 (s.r - s.g) 가 그대로 높이가 된다.
//    B 에 직전 프레임 높이를 얹어 2차 시간미분을 만든다.
//    부호 있는 값을 쓰려면 SubViewport.use_hdr_2d 가 켜져 있어야 한다.
// ═══════════════════════════════════════════════════════════════════════════

shader_type canvas_item;
render_mode blend_disabled, unshaded;

/// clear_mode = NEVER 이므로 이 스크린 텍스처가 곧 "직전 프레임의 상태"다.
/// BackBufferCopy 노드가 앞에 있어야 채워진다.
uniform sampler2D state_tex : hint_screen_texture, filter_linear, repeat_disable;

/// 감쇠. 1.0 이면 파문이 영원히 안 죽는다. 0.99 근처가 물처럼 보인다.
uniform float damping : hint_range(0.9, 1.0) = 0.993;
/// c² · Δt²/Δx². ⚠ 0.5 를 넘으면 수치적으로 발산한다 (CFL 조건).
uniform float wave_speed : hint_range(0.0, 0.49) = 0.30;
/// 가장자리 흡수 폭. 0 이면 필드 경계가 벽이 되어 파문이 튕겨 나온다.
uniform float absorb_edge : hint_range(0.0, 0.3) = 0.04;

void fragment() {
	vec2  px   = SCREEN_PIXEL_SIZE;
	vec4  s    = texture(state_tex, SCREEN_UV);
	float h    = s.r;   // 현재 높이
	float prev = s.b;   // 직전 높이

	float l = texture(state_tex, SCREEN_UV - vec2(px.x, 0.0)).r;
	float r = texture(state_tex, SCREEN_UV + vec2(px.x, 0.0)).r;
	float d = texture(state_tex, SCREEN_UV - vec2(0.0, px.y)).r;
	float u = texture(state_tex, SCREEN_UV + vec2(0.0, px.y)).r;

	// 파동 방정식:  h(t+1) = 2·h(t) − h(t−1) + c²·∇²h
	// 2차 시간미분이라 직전 프레임이 필요하다. 이게 "퍼져나감"을 만든다 —
	// 1차만 쓰면 확산(번짐)이 되고 파문이 되지 않는다.
	float lap = (l + r + d + u) - 4.0 * h;
	float nh  = (2.0 * h - prev + wave_speed * lap) * damping;

	// 경계 흡수 — 안 하면 필드 가장자리가 수조 벽처럼 파문을 되쏜다.
	vec2 e = smoothstep(vec2(0.0), vec2(absorb_edge), SCREEN_UV)
		   * (1.0 - smoothstep(vec2(1.0 - absorb_edge), vec2(1.0), SCREEN_UV));
	nh *= e.x * e.y;

	COLOR = vec4(nh, 0.0, h, 1.0);
}
