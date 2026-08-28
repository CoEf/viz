// ═══════════════════════════════════════════════════════════════════
//  wt_noise.gdshaderinc — 절차적 노이즈
//  텍스처 없이 굴절/폼/코스틱을 흔들 때 사용. uniform 없음.
// ═══════════════════════════════════════════════════════════════════
#ifndef WT_NOISE_INC
#define WT_NOISE_INC

// Dave Hoskins 계열 해시. sin() 기반 해시보다 GPU 간 결과가 안정적이다.
float wt_hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 wt_hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.x, p.y, p.x) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

// 값 노이즈. smoothstep 보간이라 미분이 연속이고 물 흔들림에 적합.
float wt_value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = wt_hash12(i);
	float b = wt_hash12(i + vec2(1.0, 0.0));
	float c = wt_hash12(i + vec2(0.0, 1.0));
	float d = wt_hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 프랙탈 브라운 운동. octaves 를 올릴수록 디테일이 붙지만 그만큼 비싸다.
float wt_fbm(vec2 p, int octaves, float lacunarity, float gain) {
	float sum  = 0.0;
	float amp  = 0.5;
	float norm = 0.0;
	for (int i = 0; i < octaves; i++) {
		sum  += amp * wt_value_noise(p);
		norm += amp;
		p    *= lacunarity;
		amp  *= gain;
	}
	return sum / max(norm, 0.00001);
}

// Voronoi(F1). 코스틱의 그물 무늬, 급류 거품 덩어리에 쓴다.
float wt_voronoi(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float best = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = wt_hash22(i + g);
			best = min(best, length(g + o - f));
		}
	}
	return best;
}

// UV 를 노이즈로 부드럽게 흔든다. 폼/코스틱이 "스크롤하는 텍스처" 티가 나는 걸 막는다.
vec2 wt_warp(vec2 p, float scale, float strength, float t) {
	return p + (vec2(
		wt_value_noise(p * scale + vec2(t, 0.0)),
		wt_value_noise(p * scale + vec2(31.7, -t))
	) - 0.5) * strength;
}

#endif
