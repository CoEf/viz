// ═══════════════════════════════════════════════════════════════════
//  wt_shoal.gdshaderinc — 해변 쇄파 (수심 연동 파고)
//  docs/water-shader-analysis.md 5.2
//
//  기본 Gerstner 는 파고가 수심과 무관하다. 경사가 완만한 해변에서는
//  큰 파도의 마루가 물가 위로 올라타 모래 위에 고립된 폼 덩어리를 만든다.
//  (4단계에서 남긴 알려진 한계)
//
//  실제 쇄파는 세 가지가 동시에 일어난다:
//    ① 파고가 먼저 커진다 (shoaling — 에너지가 얕은 물에 갇혀 위로 솟는다)
//    ② 속도가 느려진다 (파도가 앞뒤로 몰린다)
//    ③ 물가 직전에 부서지며 파고가 죽고 거품이 폭증한다
//  ①만 있으면 해변에 벽이 서고, ③만 있으면 파도가 그냥 사라진다. 셋 다 필요하다.
//
//  seabed_tex 를 안 물리면 (기본 검정 → bed = seabed_min_y = -100)
//  어디서나 깊은 물로 판정되어 무해한 no-op 이 된다.
//
//  requires: wt_core.gdshaderinc
// ═══════════════════════════════════════════════════════════════════
#ifndef WT_SHOAL_INC
#define WT_SHOAL_INC

group_uniforms shoal;
/// R = 해저 높이(seabed_min_y ~ seabed_max_y 로 정규화). scripts/water_depth_field.gd 가 굽는다.
uniform sampler2D seabed_tex : hint_default_black, filter_linear, repeat_disable;
uniform vec2  seabed_center = vec2(0.0);
uniform float seabed_size   = 300.0;
uniform float seabed_min_y  = -100.0;
uniform float seabed_max_y  = 20.0;
uniform float water_level   = 0.0;

/// 이 수심보다 얕아지면 파도가 변형되기 시작한다 (m)
uniform float shoal_depth   : hint_range(0.5, 40.0) = 11.0;
/// 얕아지며 파고가 부푸는 정도 (①)
uniform float shoal_swell   : hint_range(0.0, 3.0) = 1.5;
/// 얕아지며 느려지는 정도 (②)
uniform float shoal_slow    : hint_range(0.0, 0.9) = 0.55;
/// 부서지기 시작하는 지점 (shoal 값, 1 = 물가)
uniform float shoal_break   : hint_range(0.0, 1.0) = 0.72;
/// 부서진 뒤 파고를 얼마나 죽일지 (③). 1 이면 완전히 평평해진다.
uniform float shoal_flatten : hint_range(0.0, 1.0) = 0.95;
uniform float shoal_foam    : hint_range(0.0, 3.0) = 1.3;
group_uniforms;

/// 0 = 깊은 바다, 1 = 물가
float wt_shoal_factor(vec2 world_xz) {
	vec2 uv = (world_xz - seabed_center) / max(seabed_size, 0.001) + 0.5;
	if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
		return 0.0;
	}
	float bed   = mix(seabed_min_y, seabed_max_y, textureLod(seabed_tex, uv, 0.0).r);
	float depth = max(water_level - bed, 0.0);
	return 1.0 - clamp(depth / shoal_depth, 0.0, 1.0);
}

/// 파고 배율. 중간 수심에서 부풀었다가 물가에서 죽는다.
float wt_shoal_amp(float shoal) {
	float swell = 1.0 + shoal * shoal_swell;
	float die   = 1.0 - smoothstep(shoal_break, 1.0, shoal) * shoal_flatten;
	return swell * die;
}

/// 위상 속도 배율.
float wt_shoal_speed(float shoal) {
	return 1.0 - shoal * shoal_slow;
}

#endif
