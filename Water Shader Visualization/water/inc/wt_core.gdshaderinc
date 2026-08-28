// ═══════════════════════════════════════════════════════════════════
//  wt_core.gdshaderinc — 좌표 / 깊이 / 스타일 공용 유틸
//  uniform 을 선언하지 않는 순수 함수 모듈. 어느 셰이더에나 안전하게 include.
// ═══════════════════════════════════════════════════════════════════
#ifndef WT_CORE_INC
#define WT_CORE_INC

const float WT_TAU     = 6.283185307179586;
const float WT_GRAVITY = 9.81;

// ─── 일반 유틸 ─────────────────────────────────────────────────────

float wt_remap(float v, float in_lo, float in_hi, float out_lo, float out_hi) {
	return out_lo + (v - in_lo) * (out_hi - out_lo) / (in_hi - in_lo);
}

// 화면 해상도·거리·각도에 무관하게 항상 ~1픽셀 폭인 step.
// 툰 셰이딩에서 step() 을 그냥 쓰면 계단 경계가 지글거린다. fwidth 로 화면공간
// 변화율을 재서 그만큼만 부드럽게 만드는 것이 정답. (fragment 전용)
float wt_aa_step(float edge, float v) {
	float w = fwidth(v) * 0.5;
	return smoothstep(edge - w, edge + w, v);
}

// 연속값을 steps 단계로 양자화. 툰 밴딩의 기본.
float wt_posterize(float v, float steps) {
	return floor(v * steps) / steps;
}

// 좌표를 격자에 스냅. 픽셀아트 물의 전부다 —
// #4(psx)의 floor 방식과 #1/#3 의 round_to_pixel 은 결국 같은 연산이다.
// 샘플링 좌표를 스냅하면 노멀·폼이 통째로 계단이 되어 도트 느낌이 난다.
vec2 wt_snap(vec2 v, float n) {
	return floor(v * n) / max(n, 0.001);
}

// [연산자 스위치] 레이어 구조는 그대로 두고 이것만 바꾸면 스타일이 갈린다.
//   Realistic -> 부드러운 그라데이션 / Toon -> 화면공간 1픽셀 폭 계단
// 수면과 폭포가 같은 것을 써야 한 장면에서 따로 놀지 않는다.
float wt_edge(float e, float v) {
#ifdef STYLE_TOON
	return wt_aa_step(e, v);
#else
	return smoothstep(e - 0.11, e + 0.11, v);
#endif
}

// Schlick 근사. 물(굴절률 1.333) 의 F0 은 0.02 —
// 정면에서는 2% 만 반사(바닥이 보임), 스치듯 보면 100% 반사(하늘만 보임).
float wt_fresnel(vec3 normal, vec3 view, float f0) {
	float c = clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0);
	return f0 + (1.0 - f0) * pow(1.0 - c, 5.0);
}

// ─── 깊이 (Godot 4.3+ reverse-Z) ───────────────────────────────────
//
//  ⚠ Godot 4.3 부터 깊이 버퍼가 reverse-Z 다.
//     depth_texture 값은 1.0 = 근평면, 0.0 = 원평면 이고 비선형이다.
//     NDC 의 z 범위는 [0,1] 이므로 예전처럼 `depth * 2.0 - 1.0` 하면 안 된다.
//     (godotshaders 의 옛 셰이더 대부분이 여기서 깨진다)
//
//  ✅ x,y 만 [-1,1] 로 펴고 z 는 raw 그대로 넣는다.

vec3 wt_view_from_screen(vec2 screen_uv, float raw_depth, mat4 inv_proj) {
	vec4 v = inv_proj * vec4(screen_uv * 2.0 - 1.0, raw_depth, 1.0);
	return v.xyz / v.w;
}

// 카메라로부터의 선형 거리(양수).
float wt_linear_depth(vec2 screen_uv, float raw_depth, mat4 inv_proj) {
	return -wt_view_from_screen(screen_uv, raw_depth, inv_proj).z;
}

// 깊이 버퍼에 기록된 지점의 월드 좌표. 수직 수심(y 차이)을 구할 때 쓴다.
vec3 wt_world_from_screen(vec2 screen_uv, float raw_depth, mat4 inv_proj, mat4 inv_view) {
	return (inv_view * vec4(wt_view_from_screen(screen_uv, raw_depth, inv_proj), 1.0)).xyz;
}

// UV 가 화면 밖으로 나갔는지. 굴절 오프셋 폴백 판정용.
bool wt_in_screen(vec2 uv) {
	return uv == clamp(uv, vec2(0.0), vec2(1.0));
}

#endif
