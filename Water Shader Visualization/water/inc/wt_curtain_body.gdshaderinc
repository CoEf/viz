// ═══════════════════════════════════════════════════════════════════════════
//  wt_curtain_body.gdshaderinc — "수직으로 흐르는 물" 본문
//  폭포 · 물줄기 · 분수 커튼이 전부 이 하나를 쓴다.
//
//  수면(wt_surface_body)과 왜 다른 셰이더인가:
//    수면은 "위에서 내려다보는 볼륨"이라 깊이 흡수·굴절·수심 폼이 주인공이다.
//    폭포는 "옆에서 보는 얇은 막"이라 깊이가 거의 의미가 없고,
//    대신 UV.y 방향 스크롤·낙하 가속·공기 혼입(하얘짐)이 전부다.
//    같은 레이어 스택으로 우겨넣으면 양쪽 다 어중간해진다.
//
//  다만 L7(연산자 스위치·툰 라이팅)과 깊이 유틸은 그대로 공유한다.
//
//  얇은 진입 파일에서 shader_type / render_mode / #define 을 정하고 include 할 것.
//    water_curtain.gdshader  → 폭포 / 커튼
//    water_jet.gdshader      → 물줄기 / 분수 (#define JET)
// ═══════════════════════════════════════════════════════════════════════════
#ifndef WT_CURTAIN_BODY_INC
#define WT_CURTAIN_BODY_INC

#include "res://water/inc/wt_core.gdshaderinc"
#include "res://water/inc/wt_noise.gdshaderinc"
#ifdef STYLE_TOON
	#include "res://water/inc/wt_light_toon.gdshaderinc"
#endif

group_uniforms curtain;
uniform sampler2D fall_noise : filter_linear_mipmap, repeat_enable;
/// UV.y 를 이 지수로 왜곡한다. 1 보다 크면 위가 압축되고 아래가 늘어나
/// 낙하 가속감이 생긴다. 1.0 이면 벽지처럼 등속으로 흐른다.
uniform float uv_gamma : hint_range(0.5, 3.0) = 1.45;
uniform bool  flip_v = false;

/// 3레이어 패럴랙스 — 속도·스케일이 다른 세 장이 폭포의 "덩어리감"을 만든다.
/// 한 장만 쓰면 아무리 튜닝해도 흐르는 벽지에서 못 벗어난다.
uniform vec2 layer_scale_a = vec2(1.0, 0.55);
uniform vec2 layer_scale_b = vec2(1.7, 1.10);
uniform vec2 layer_scale_c = vec2(3.1, 2.30);
uniform vec3 layer_speed  = vec3(0.75, 1.35, 2.20);
uniform vec3 layer_weight = vec3(0.50, 0.30, 0.20);

uniform float streak_bias : hint_range(-1.0, 1.0) = 0.28;
uniform float streak_gain : hint_range(0.1, 6.0)  = 2.2;
group_uniforms;

group_uniforms shape;
/// 바위를 타고 도는 흐름: 높이에 따라 좌우로 휜다.
uniform float bend       : hint_range(0.0, 0.5) = 0.05;
uniform float bend_scale : hint_range(0.1, 8.0) = 1.6;
/// 좌우 가장자리 페이드. 없으면 딱 잘린 사각형 티가 난다.
uniform float edge_soft : hint_range(0.0, 0.5) = 0.14;
/// 커튼이 좌우로 살랑이는 폭 (정점). 메시에 세로 분할이 있어야 보인다.
uniform float sway : hint_range(0.0, 1.0) = 0.06;
group_uniforms;

group_uniforms color;
uniform vec3  water_color : source_color = vec3(0.55, 0.78, 0.88);
uniform vec3  foam_color  : source_color = vec3(0.96, 0.99, 1.0);
/// 낙하하며 공기가 섞여 아래로 갈수록 하얘진다. 이게 폭포의 핵심 신호다.
uniform float whiten_power : hint_range(0.2, 6.0) = 1.5;
uniform float base_alpha   : hint_range(0.0, 1.0) = 0.9;
#ifdef STYLE_TOON
uniform float toon_streak_steps : hint_range(2.0, 8.0) = 3.0;
#else
uniform float curtain_roughness : hint_range(0.0, 1.0) = 0.18;
#endif
group_uniforms;

#ifdef SOFT_EDGE
group_uniforms soft;
/// 바닥·바위와 만나는 곳을 부드럽게. 없으면 폭포가 판때기처럼 딱 잘린다.
/// ⚠ 커튼 메시를 뒤 벽에서 이 거리보다 가깝게 두면 폭포 전체가 사라진다.
uniform float soft_distance : hint_range(0.05, 6.0) = 0.7;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
group_uniforms;
#endif

#ifdef JET
group_uniforms jet;
/// 진행할수록 가늘어진다.
uniform float taper_power : hint_range(0.2, 6.0) = 1.5;
/// 끝단에서 흩어져 사라진다 (dissolve).
uniform float dissolve_bias : hint_range(0.0, 2.0) = 1.15;
uniform float dissolve_gain : hint_range(0.0, 4.0) = 1.5;
/// 나선 하이라이트 — 물줄기가 회전하며 나가는 느낌.
uniform float helix_turns : hint_range(0.5, 8.0)  = 2.5;
uniform float helix_freq  : hint_range(0.0, 60.0) = 18.0;
uniform float helix_speed : hint_range(0.0, 30.0) = 9.0;
uniform float helix_mix   : hint_range(0.0, 1.0)  = 0.55;
group_uniforms;
#endif


void vertex() {
	// 얇은 커튼이 좌우로 살랑이는 정도. 폭포의 형태 자체는 메시가 잡는다.
	float v = flip_v ? 1.0 - UV.y : UV.y;
	VERTEX.x += sin(v * 6.0 + TIME * 1.7) * sway * v;
}


void fragment() {
	// v = 0 이 물이 나오는 쪽(폭포는 위, 제트는 노즐), 1 이 끝나는 쪽.
	float v = flip_v ? 1.0 - UV.y : UV.y;
	vec2  uv = vec2(UV.x, pow(clamp(v, 0.0, 1.0), uv_gamma));

	// 바위를 타고 도는 흐름
	uv.x += (wt_value_noise(vec2(v * bend_scale, TIME * 0.05)) - 0.5) * bend;

	// ── 3레이어 패럴랙스 ────────────────────────────────────────
	float t  = TIME;
	float l0 = texture(fall_noise, uv * layer_scale_a - vec2(0.0, t * layer_speed.x)).r;
	float l1 = texture(fall_noise, uv * layer_scale_b - vec2(0.0, t * layer_speed.y)).r;
	float l2 = texture(fall_noise, uv * layer_scale_c - vec2(0.0, t * layer_speed.z)).r;

	float streak = l0 * layer_weight.x + l1 * layer_weight.y + l2 * layer_weight.z;
	streak = clamp((streak - streak_bias) * streak_gain, 0.0, 1.0);
#ifdef STYLE_TOON
	streak = wt_posterize(streak, toon_streak_steps);
#endif

	// ── 색: 아래로 갈수록 공기가 섞여 하얘진다 ──────────────────
	float whiten = pow(clamp(v, 0.0, 1.0), whiten_power);
	vec3  col = mix(water_color, foam_color, clamp(streak + whiten, 0.0, 1.0));

	// ── 알파 ────────────────────────────────────────────────────
	float side = smoothstep(0.0, edge_soft, UV.x)
			   * (1.0 - smoothstep(1.0 - edge_soft, 1.0, UV.x));
	// streak 로 투과에 변화를 주되 하한을 충분히 높인다. 하한이 낮으면
	// 뒤 절벽이 그대로 비쳐서 물이 아니라 회색 안개처럼 보인다.
	float a = base_alpha * side * clamp(streak * 0.42 + 0.66, 0.0, 1.0);

#ifdef JET
	// 굵기 감쇠 + 끝단 dissolve. 이게 없으면 그냥 흰 리본이다.
	a *= 1.0 - pow(clamp(v, 0.0, 1.0), taper_power);
	a *= clamp(streak + dissolve_bias - v * dissolve_gain, 0.0, 1.0);

	float helix = sin(UV.x * WT_TAU * helix_turns + v * helix_freq - TIME * helix_speed) * 0.5 + 0.5;
	col = mix(col, foam_color, wt_edge(0.55, helix) * helix_mix);
#endif

#ifdef SOFT_EDGE
	// 소프트 파티클과 같은 원리 — 뒤 지오메트리와 가까울수록 투명해진다.
	float raw     = texture(depth_texture, SCREEN_UV).x;
	float scene_d = wt_linear_depth(SCREEN_UV, raw, INV_PROJECTION_MATRIX);
	a *= clamp((scene_d - (-VERTEX.z)) / soft_distance, 0.0, 1.0);
#endif

	ALBEDO = col;
	ALPHA  = clamp(a, 0.0, 1.0);
#ifdef STYLE_TOON
	ROUGHNESS = 1.0;
	SPECULAR  = 0.0;
#else
	ROUGHNESS = curtain_roughness;
	SPECULAR  = 0.4;
#endif
	METALLIC = 0.0;
}

#endif
