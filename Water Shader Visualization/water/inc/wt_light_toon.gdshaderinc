// ═══════════════════════════════════════════════════════════════════
//  wt_light_toon.gdshaderinc — L7 툰 라이팅
//
//  render_mode unshaded 는 쉽지만 그림자·여러 광원·시간대 변화를 전부 포기하는 것이다.
//  게임에 쓸 거면 light() 를 직접 쓰는 게 맞다. 램프는 계단이지만 광원 계산은 살아있다.
//
//  requires: wt_core.gdshaderinc
//  이 파일은 uniform 만 선언한다. light() 본문은 wt_surface_body 가 갖는다
//  (Godot 셰이더는 light() 안에서만 LIGHT / ATTENUATION 등에 접근할 수 있으므로).
// ═══════════════════════════════════════════════════════════════════
#ifndef WT_LIGHT_TOON_INC
#define WT_LIGHT_TOON_INC

group_uniforms toon_light;
// 확산 램프: NdotL 을 이 경계에서 잘라 명/암 2단으로 만든다.
// ★ 경계는 반드시 "수면의 실제 NdotL 범위 안"에 놓여야 한다.
//   태양 고도 35도 → 평평한 수면은 NdotL ≈ sin(35도) = 0.57,
//   파도 경사 ±20도 → 0.26 ~ 0.82 사이를 오간다.
//   경계가 이 범위 밖이면(예: 0.34) 모든 프래그먼트가 한쪽 밴드로 떨어져
//   셀 음영이 아예 안 보이고 물이 평평한 색종이처럼 보인다.
uniform float toon_shadow_edge  : hint_range(0.0, 1.0)   = 0.50;
uniform float toon_shadow_width : hint_range(0.001, 0.4) = 0.035;
// 그늘은 ALBEDO 에 곱해진다. 튁툰 수면은 그늘도 밝고 푸른 게 맞다 —
// 0.6 대에서는 깊은 밴드와 곱해져 검은 얼룩이 된다.
uniform vec3  toon_shadow_color : source_color = vec3(0.76, 0.84, 0.98);

// 스펙큘러: 1/gloss 승 → 아주 좁은 스팟을 만들고, smoothstep 으로 가장자리를 잘라
// "덩어리진" 하이라이트가 된다. gloss 를 키우면 덩어리가 커진다.
uniform float toon_gloss         : hint_range(0.005, 0.5) = 0.09;
uniform float toon_spec_width    : hint_range(0.0, 0.5)   = 0.05;
uniform float toon_spec_strength : hint_range(0.0, 3.0)   = 1.3;
group_uniforms;

// ─── 공유 light(): 수면도 폭포도 같은 셀 램프를 써야 한 장면에서 따로 놀지 않는다.
#ifdef STYLE_TOON
void light() {
	// 확산: NdotL 을 하드 컷 → 명/암 2단 셀
	float NdotL = dot(normalize(NORMAL), normalize(LIGHT)) * ATTENUATION;
	float band  = smoothstep(toon_shadow_edge - toon_shadow_width,
							 toon_shadow_edge + toon_shadow_width, NdotL);
	DIFFUSE_LIGHT += mix(ALBEDO * toon_shadow_color, ALBEDO * LIGHT_COLOR, band);

	// 스펙큘러: 아주 좁은 스팟을 만든 뒤 가장자리를 잘라 "덩어리진" 하이라이트로
	vec3  H = normalize(VIEW + LIGHT);
	float s = pow(max(dot(normalize(NORMAL), H), 0.0), 1.0 / max(toon_gloss, 0.005));
	SPECULAR_LIGHT += smoothstep(0.5 - toon_spec_width, 0.5 + toon_spec_width, s)
					* LIGHT_COLOR * ATTENUATION * toon_spec_strength;
}
#endif

#endif
