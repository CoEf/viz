// ═══════════════════════════════════════════════════════════════════
//  wt_domain.gdshaderinc — L0 대체 좌표계
//
//  L0(좌표계)는 가장 과소평가되는 레이어다. 여기만 바꾸면 같은 표면 렌더링으로
//  전혀 다른 물이 나온다 — 원형 연못, 온천, 소용돌이, 착탄 파문.
//
//  requires: wt_core.gdshaderinc (WT_TAU)
// ═══════════════════════════════════════════════════════════════════
#ifndef WT_DOMAIN_INC
#define WT_DOMAIN_INC

/// 월드 XZ → 극좌표. x = 중심에서의 거리, y = 각도(0~1).
/// x 를 시간으로 밀면 무늬가 중심에서 바깥으로 계속 흘러나간다 —
/// 온천에서 물이 솟아 퍼지는 그 움직임이 이 한 줄에서 나온다.
vec2 wt_polar(vec2 world_xz, vec2 center, float radius, float zoom, float repeat) {
	vec2  d = world_xz - center;
	float r = length(d) / max(radius, 0.001);
	float a = atan(d.y, d.x) / WT_TAU + 0.5;
	return vec2(r * zoom, a * repeat);
}

/// 중심에서 퍼져나가는 동심 링.
/// #8(hotspring)은 이걸 픽셀마다 for(i<20) 루프로 그리는데, 링은 주기적이므로
/// fract 한 줄이면 같은 결과가 나온다. 20배 싸다.
float wt_rings(float dist_norm, float count, float speed, float time, float width) {
	float f = fract(dist_norm * count - time * speed);
	return smoothstep(1.0 - width, 1.0, f) * (1.0 - clamp(dist_norm, 0.0, 1.0));
}

/// 원형 페이드. 탕 가장자리에서 무늬가 딱 잘리지 않게 한다.
float wt_vignette(float dist_norm, float size, float blend) {
	return 1.0 - smoothstep(size, size + blend, dist_norm);
}

#endif
