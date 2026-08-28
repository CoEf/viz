// ═══════════════════════════════════════════════════════════════════
//  wt_waves.gdshaderinc — L1 형상 (정점 변위 + 해석적 법선)
//  requires: wt_core.gdshaderinc  (WT_TAU, WT_GRAVITY)
// ═══════════════════════════════════════════════════════════════════
#ifndef WT_WAVES_INC
#define WT_WAVES_INC

// ─── Gerstner (Trochoidal) 파 ──────────────────────────────────────
//
//  sin 합성으로는 실사 파도가 절대 안 나온다. 실제 물 입자는 원운동을 해서
//  마루가 뾰족하고 골이 평평한데, sin 은 위아래가 대칭이라 "출렁이는 젤리"가 된다.
//  Gerstner 는 수평 변위까지 넣어 그 원운동을 그대로 재현한다.
//
//  params: xy = 진행 방향, z = steepness(0~1), w = 파장(m)
//
//  ⚠ 여러 파를 더할 때 steepness 의 합이 1 을 넘으면 파형이 자기교차해서
//    뒤집힌 면이 생긴다. 4파를 쓰면 각각 0.2~0.25.
//
//  법선은 유한차분이 아니라 파형 함수의 편미분에서 직접 나온다.
//  → 텍스처 샘플 3회를 아끼면서 정확도는 더 높다. Gerstner 만의 이점.
//
//  dPdx / dPdz 는 호출 전에 각각 vec3(1,0,0), vec3(0,0,1) 로 초기화할 것.
/// 위상 속도 배율을 받는 버전. 해변 쇄파에서 얕을수록 파도를 늦출 때 쓴다.
vec3 wt_gerstner_ex(vec4 params, vec2 pos, float t, float speed_mul,
					inout vec3 dPdx, inout vec3 dPdz) {
	float k = WT_TAU / max(params.w, 0.001);   // 파수
	float c = sqrt(WT_GRAVITY / k) * speed_mul;   // 심해 분산관계 + 쇄파 감속
	vec2  d = normalize(params.xy);
	float s = params.z;                        // steepness
	float f = k * (dot(d, pos) - c * t);
	float a = s / k;                           // 진폭 = steepness / 파수
	float sf = sin(f);
	float cf = cos(f);

	// ∂P/∂x
	dPdx += vec3(-d.x * d.x * s * sf,  d.x * s * cf, -d.x * d.y * s * sf);
	// ∂P/∂z
	dPdz += vec3(-d.x * d.y * s * sf,  d.y * s * cf, -d.y * d.y * s * sf);

	return vec3(d.x * a * cf, a * sf, d.y * a * cf);
}

/// 기본 버전 (속도 배율 1).
vec3 wt_gerstner(vec4 params, vec2 pos, float t, inout vec3 dPdx, inout vec3 dPdz) {
	return wt_gerstner_ex(params, pos, t, 1.0, dPdx, dPdz);
}

// 수평 변위의 야코비안. 1 이면 평평, 0 에 가까울수록 파형이 접히는 중 =
// 파도가 부서지는 지점이다. 마루 거품(whitecap)의 물리적으로 올바른 마스크.
float wt_jacobian(vec3 dPdx, vec3 dPdz) {
	return dPdx.x * dPdz.z - dPdz.x * dPdx.z;
}

// ─── 저가형 대안 ───────────────────────────────────────────────────

// 노이즈 텍스처 높이. 잔잔한 호수/연못용. 법선은 호출부에서 유한차분으로.
float wt_noise_height(sampler2D tex, vec2 pos, vec2 scale_uv, vec2 dir, float t) {
	float h  = texture(tex, pos * scale_uv.x + dir * t).r;
	h       += texture(tex, pos * scale_uv.y - dir.yx * t * 0.73).r * 0.5;
	return h / 1.5 - 0.5;
}

// sin 합성. 가장 싸고 가장 티가 난다. 폭포/물줄기의 미세 흔들림 정도에만.
float wt_sine_height(vec2 pos, vec2 freq, vec2 amp, vec2 speed, float t) {
	return amp.x * sin(pos.x * freq.x + t * speed.x)
	     + amp.y * sin(pos.y * freq.y + t * speed.y);
}

#endif
