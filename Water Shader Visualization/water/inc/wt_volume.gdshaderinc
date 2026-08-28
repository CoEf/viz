// ═══════════════════════════════════════════════════════════════════
//  wt_volume.gdshaderinc — L4 볼륨 (흡수 / 산란 / 투명도)
//  uniform 없음. 모든 계수는 인자로 받는다.
// ═══════════════════════════════════════════════════════════════════
#ifndef WT_VOLUME_INC
#define WT_VOLUME_INC

// ─── Beer-Lambert 흡수 ─────────────────────────────────────────────
//
//  실사 물의 정체는 파도가 아니라 "빛이 깊이에 따라 파장별로 다르게 죽는 것"이다.
//  물은 빨강을 가장 빨리 흡수하고 파랑을 가장 늦게 흡수한다. 그래서
//  깊어질수록 청록이 된다 — 물이 파란 게 아니라 빨강이 먼저 사라지는 것.
//
//  단일 float 계수로 mix() 하는 흔한 구현(godotshaders 다수)은 이 색상 변화를
//  아예 표현하지 못한다. 계수는 반드시 RGB 각각이어야 한다.
//
//  absorption 참고값 (1/m):
//    맑은 바다   vec3(0.35, 0.05, 0.02)
//    연안/호수   vec3(0.45, 0.07, 0.03)
//    탁한 강     vec3(2.00, 1.60, 1.40)   ← RGB 차이를 줄이면 흙탕물
//    온천/유백   vec3(3.00, 2.80, 2.60)   ← 50cm 만 되어도 불투명
vec3 wt_absorb(vec3 behind, vec3 absorption, float depth) {
	return behind * exp(-absorption * depth);
}

// 산란: 깊은 물이 가진 고유색이 더해지는 항.
// 흡수만 있으면 깊은 곳이 그냥 검게 죽는다. 이게 있어야 "물색"이 생긴다.
vec3 wt_scatter(vec3 col, vec3 scatter_color, float scatter_k, float depth) {
	return mix(col, scatter_color, 1.0 - exp(-scatter_k * depth));
}

// 흡수 + 산란 한 번에.
vec3 wt_volume_color(vec3 behind, vec3 absorption, vec3 scatter_color,
					 float scatter_k, float depth) {
	return wt_scatter(wt_absorb(behind, absorption, depth), scatter_color, scatter_k, depth);
}

// 얕은 가장자리를 투명하게. 이게 없으면 물이 물가에서 딱 잘린 판때기로 보인다.
float wt_depth_alpha(float depth, float k) {
	return clamp(1.0 - exp(-depth * k), 0.0, 1.0);
}

// ─── 툰용: 깊이를 밴딩 ─────────────────────────────────────────────
// 같은 수심 값을 연속 함수 대신 2~3 단으로 자른다.
vec3 wt_volume_banded(vec3 shallow, vec3 mid, vec3 deep,
					  float depth, float t0, float t1, float aa) {
	vec3 c = mix(shallow, mid,  smoothstep(t0 - aa, t0 + aa, depth));
	return  mix(c,        deep, smoothstep(t1 - aa, t1 + aa, depth));
}

#endif
