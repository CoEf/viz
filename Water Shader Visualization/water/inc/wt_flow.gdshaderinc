// ═══════════════════════════════════════════════════════════════════
//  wt_flow.gdshaderinc — L0 흐름 (강 / 해류)
//
//  ★ 스크롤과 흐름은 다르다.
//    스크롤은 텍스처를 한 방향으로 미는 것이고, 흐름은 위치마다 방향이 다르다.
//    강물이 바위를 타고 돌고, 해류가 굽이치는 건 스크롤로는 표현이 안 된다.
//
//  ⚠ godotshaders 의 cs-2-water(#19) 는 flow map 을 이렇게 쓴다:
//        uv1 = uv + flow * t
//        uv2 = uv + flow * (t + 0.5)
//    시간이 갈수록 오프셋이 무한히 커져서 텍스처가 끝없이 늘어난다.
//    올바른 flow map 은 주기적으로 리셋하고, 왜곡이 0 인 순간에 가중치를
//    최대로 주는 크로스페이드다. 아래 wt_flow_sample 참조.
//
//  requires: wt_core.gdshaderinc, wt_noise.gdshaderinc
// ═══════════════════════════════════════════════════════════════════
#ifndef WT_FLOW_INC
#define WT_FLOW_INC

group_uniforms flow;
/// 기본 흐름 방향 (월드 XZ). 균일 해류는 이것만으로 충분하다.
uniform vec2  flow_dir = vec2(0.0, 1.0);
/// 텍스처가 한 주기에 밀리는 양 (UV 단위). 크면 늘어짐이 보인다.
uniform float flow_warp  : hint_range(0.0, 1.0) = 0.16;
/// 주기 속도. 낮을수록 느리게 흐른다.
uniform float flow_speed : hint_range(0.0, 2.0) = 0.28;
/// 흐름 세기 → 급류 거품 양에 연결된다.
uniform float flow_foam  : hint_range(0.0, 3.0) = 0.0;
/// 급류 거품이 나는 수심 한계 (m). 이보다 깊으면 유속이 빨라도 거품이 안 난다.
uniform float flow_foam_depth : hint_range(0.05, 6.0) = 1.0;

#ifdef FLOW_MAP
/// R,G = 흐름 방향 (0.5 가 정지). 지형 경사에서 굽는 강에 쓴다.
uniform sampler2D flow_map : filter_linear, repeat_enable;
uniform vec2  flow_map_scale  = vec2(0.01);
uniform vec2  flow_map_offset = vec2(0.0);
#endif

#ifdef FLOW_NOISE
/// 저주파 노이즈로 기본 방향을 휘게 한다 — 텍스처 없이 사행(蛇行)을 만든다.
uniform float flow_noise_scale : hint_range(0.001, 0.2) = 0.012;
uniform float flow_noise_turn  : hint_range(0.0, 3.14) = 0.9;   // 최대 회전각 (rad)
#endif


/// 이 지점의 흐름 벡터.
vec2 wt_flow_vector(vec2 world_xz) {
	vec2 f = flow_dir;

#ifdef FLOW_MAP
	f = texture(flow_map, world_xz * flow_map_scale + flow_map_offset).rg * 2.0 - 1.0;
#endif

#ifdef FLOW_NOISE
	// 방향을 노이즈 각도만큼 회전. 크기는 보존되므로 유속이 들쭉날쭉해지지 않는다.
	float ang = (wt_value_noise(world_xz * flow_noise_scale) - 0.5) * flow_noise_turn;
	float c = cos(ang);
	float s = sin(ang);
	f = vec2(f.x * c - f.y * s, f.x * s + f.y * c);
#endif

	return f;
}


/// Flow map 크로스페이드 (Valve / Portal 2 방식).
///
/// 두 위상을 0.5 어긋나게 돌리고, 각 위상의 왜곡이 0 이 되는 순간(p = 0.5)에
/// 그 쪽 가중치가 1 이 되도록 맞춘다. w0 + w1 == 1 이 항상 성립하므로
/// 밝기가 맥동하지 않는다. 이 두 줄이 flow map 의 전부다.
vec3 wt_flow_sample(sampler2D tex, vec2 uv, vec2 flow, float time, float warp) {
	float p0 = fract(time);
	float p1 = fract(time + 0.5);
	vec3  s0 = texture(tex, uv - flow * (p0 - 0.5) * warp).rgb;
	vec3  s1 = texture(tex, uv - flow * (p1 - 0.5) * warp).rgb;
	float w0 = 1.0 - abs(1.0 - 2.0 * p0);
	return mix(s1, s0, w0);
}

/// 단일 채널 버전 (폼 노이즈용).
float wt_flow_sample_r(sampler2D tex, vec2 uv, vec2 flow, float time, float warp) {
	return wt_flow_sample(tex, uv, flow, time, warp).r;
}

#endif
